import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsJson, corsPreflight } from "../_shared/cors.ts";
import {
  classifyError,
  nowMs,
  recordMetric,
} from "../_shared/metrics.ts";
import {
  buildPrompt,
  validateGrid,
  type CommercialProfileInput,
  type GeneratedGrid,
} from "./grid_schema.ts";
import {
  buildProfilePrompt,
  prospectingToCommercialInput,
  validateProspectingProfile,
  type ProspectingProfile,
} from "./profile_schema.ts";
import { openRouterJson } from "./openrouter_json.ts";

const DEFAULT_MODEL = "mistralai/mistral-nemo";

interface GenerateRequest {
  business: string;
  productsServices?: string;
  /** Présent uniquement si le client a un profil validé. */
  commercialProfile?: CommercialProfileInput;
  /** Phase 5 : "profile" (proposer ICP) ou "grid" (défaut, rétrocompat). */
  step?: "profile" | "grid";
  /** Profil de prospection validé par l'utilisateur (étape grille). */
  prospectingProfile?: ProspectingProfile;
}

/** Normalisation du métier : minuscules, sans accents, espaces réduits. */
function normalizeBusiness(raw: string): string {
  return raw
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

async function sha256(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

interface TierLimits {
  maxGrids: number | null;
  maxAiPerMonth: number | null;
}

function limitsForTier(tier: string | undefined): TierLimits {
  switch (tier) {
    case "premium":
      return { maxGrids: 2, maxAiPerMonth: 2 };
    case "premium_plus":
      return { maxGrids: 5, maxAiPerMonth: 5 };
    case "pro":
      return { maxGrids: null, maxAiPerMonth: null };
    default:
      return { maxGrids: 1, maxAiPerMonth: null };
  }
}

function currentPeriodMonth(): string {
  const now = new Date();
  const y = now.getUTCFullYear();
  const m = String(now.getUTCMonth() + 1).padStart(2, "0");
  return `${y}-${m}-01`;
}

async function getAiUsage(
  admin: ReturnType<typeof createClient>,
  userId: string,
): Promise<number> {
  const { data } = await admin
    .from("ai_generation_usage")
    .select("used_count")
    .eq("user_id", userId)
    .eq("period_month", currentPeriodMonth())
    .maybeSingle();
  return data?.used_count ?? 0;
}

async function incrementAiUsage(
  admin: ReturnType<typeof createClient>,
  userId: string,
): Promise<void> {
  const period = currentPeriodMonth();
  const { data } = await admin
    .from("ai_generation_usage")
    .select("used_count")
    .eq("user_id", userId)
    .eq("period_month", period)
    .maybeSingle();
  if (data) {
    await admin
      .from("ai_generation_usage")
      .update({ used_count: data.used_count + 1 })
      .eq("user_id", userId)
      .eq("period_month", period);
  } else {
    await admin.from("ai_generation_usage").insert({
      user_id: userId,
      period_month: period,
      used_count: 1,
    });
  }
}

async function callOpenRouterGrid(
  apiKey: string,
  model: string,
  business: string,
  productsServices: string,
  profile?: CommercialProfileInput | null,
): Promise<GeneratedGrid> {
  const parsed = await openRouterJson(
    apiKey,
    model,
    buildPrompt(business, productsServices, profile),
  );
  return validateGrid(parsed);
}

async function callOpenRouterProfile(
  apiKey: string,
  model: string,
  business: string,
  productsServices: string,
): Promise<ProspectingProfile> {
  const parsed = await openRouterJson(
    apiKey,
    model,
    buildProfilePrompt(business, productsServices),
  );
  const profile = validateProspectingProfile(parsed);
  if (!profile) {
    throw new Error("Profil de prospection invalide (réponse IA)");
  }
  return profile;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return corsPreflight();
  }

  const started = nowMs();
  // deno-lint-ignore no-explicit-any
  let admin: any = null;
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return corsJson({ error: "Non authentifié" }, { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const apiKey = Deno.env.get("OPENROUTER_API_KEY");
    const model = Deno.env.get("OPENROUTER_MODEL") ?? DEFAULT_MODEL;
    if (!apiKey) {
      return corsJson(
        { error: "OPENROUTER_API_KEY manquante" },
        { status: 500 },
      );
    }

    const userClient = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return corsJson({ error: "Token invalide" }, { status: 401 });
    }
    const userId = userData.user.id;

    admin = createClient(supabaseUrl, serviceKey);

    const { data: profile } = await admin
      .from("profiles")
      .select("subscription_tier")
      .eq("id", userId)
      .maybeSingle();
    const tier = profile?.subscription_tier ?? "freemium";
    const limits = limitsForTier(tier);

    if (limits.maxGrids !== null) {
      const { count } = await admin
        .from("scoring_grids")
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId);
      if ((count ?? 0) >= limits.maxGrids) {
        await recordMetric(admin, {
          source: "grid_gen",
          status: "skip",
          errorType: "quota",
          durationMs: nowMs() - started,
        });
        return corsJson(
          {
            error:
              "Quota grilles de scoring atteint pour votre offre. " +
              "Pour plus de grilles, changez d'offre.",
          },
          { status: 403 },
        );
      }
    }

    const body: GenerateRequest = await req.json();
    const business = body.business?.trim();
    if (!business || business.length < 3 || business.length > 120) {
      return corsJson(
        { error: "business requis (3 à 120 caractères)" },
        { status: 400 },
      );
    }
    const productsServices = body.productsServices?.trim().slice(0, 1000) ?? "";
    const step = body.step === "profile" ? "profile" : "grid";

    // --- Étape 1 : proposer un profil de prospection (pas de cache grille) ---
    if (step === "profile") {
      if (limits.maxAiPerMonth !== null) {
        const used = await getAiUsage(admin, userId);
        if (used >= limits.maxAiPerMonth) {
          return corsJson(
            {
              error:
                `Quota mensuel de génération IA atteint (${limits.maxAiPerMonth}/mois). ` +
                "Pour plus de générations, changez d'offre.",
            },
            { status: 403 },
          );
        }
      }
      const prospectingProfile = await callOpenRouterProfile(
        apiKey,
        model,
        business,
        productsServices,
      );
      // Le quota est consommé à la génération de grille (étape 2), pas ici.
      await recordMetric(admin, {
        source: "grid_gen_profile",
        status: "success",
        durationMs: nowMs() - started,
      });
      return corsJson({ profile: prospectingProfile });
    }

    // --- Étape 2 : grille (rétrocompat si step absent) ---------------------
    const fromProspecting = body.prospectingProfile
      ? validateProspectingProfile(body.prospectingProfile)
      : null;
    const commercialProfile: CommercialProfileInput | null =
      fromProspecting != null
        ? {
          ...prospectingToCommercialInput(fromProspecting),
          ...(body.commercialProfile ?? {}),
        }
        : (body.commercialProfile ?? null);

    const normalized = normalizeBusiness(business);
    // Cache : métier seul (historique) OU offer|target|métier (Phase 5).
    let cacheKey: string;
    let cacheBusinessLabel: string;
    if (commercialProfile != null) {
      const offer = normalizeBusiness(commercialProfile.offer ?? "");
      const target = normalizeBusiness(
        commercialProfile.target_client_type ?? "",
      );
      cacheBusinessLabel = `${offer}|${target}|${normalized}`;
      cacheKey = await sha256(cacheBusinessLabel);
    } else {
      cacheBusinessLabel = normalized;
      cacheKey = await sha256(normalized);
    }

    {
      const { data: cached } = await admin
        .from("grid_generation_cache")
        .select("id, grid, hit_count")
        .eq("cache_key", cacheKey)
        .maybeSingle();

      if (cached) {
        await admin
          .from("grid_generation_cache")
          .update({ hit_count: cached.hit_count + 1 })
          .eq("id", cached.id);
        await recordMetric(admin, {
          source: "grid_gen",
          status: "cache_hit",
          durationMs: nowMs() - started,
        });
        return corsJson({ grid: cached.grid, fromCache: true });
      }
    }

    if (limits.maxAiPerMonth !== null) {
      const used = await getAiUsage(admin, userId);
      if (used >= limits.maxAiPerMonth) {
        await recordMetric(admin, {
          source: "grid_gen",
          status: "skip",
          errorType: "quota",
          durationMs: nowMs() - started,
        });
        return corsJson(
          {
            error:
              `Quota mensuel de génération IA atteint (${limits.maxAiPerMonth}/mois). ` +
              "Pour plus de générations, changez d'offre.",
          },
          { status: 403 },
        );
      }
    }

    const grid = await callOpenRouterGrid(
      apiKey,
      model,
      business,
      productsServices,
      commercialProfile,
    );

    if (limits.maxAiPerMonth !== null) {
      await incrementAiUsage(admin, userId);
    }

    await admin.from("grid_generation_cache").upsert(
      {
        cache_key: cacheKey,
        business: cacheBusinessLabel.slice(0, 200),
        grid,
        model,
      },
      { onConflict: "cache_key" },
    );

    await recordMetric(admin, {
      source: "grid_gen",
      status: "success",
      durationMs: nowMs() - started,
    });
    return corsJson({ grid, fromCache: false });
  } catch (e) {
    if (admin) {
      await recordMetric(admin, {
        source: "grid_gen",
        status: "failure",
        errorType: classifyError(e),
        durationMs: nowMs() - started,
      });
    }
    return corsJson({ error: String(e) }, { status: 502 });
  }
});
