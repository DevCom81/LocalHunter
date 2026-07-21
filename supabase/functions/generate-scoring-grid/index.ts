import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { buildPrompt, validateGrid, type GeneratedGrid } from "./grid_schema.ts";

const DEFAULT_MODEL = "mistralai/mistral-nemo";

interface GenerateRequest {
  business: string;
  productsServices?: string;
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

async function callOpenRouter(
  apiKey: string,
  model: string,
  business: string,
  productsServices: string,
): Promise<GeneratedGrid> {
  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
      "HTTP-Referer": "https://localhunter.app",
      "X-Title": "LocalHunter",
    },
    body: JSON.stringify({
      model,
      temperature: 0.3,
      response_format: { type: "json_object" },
      messages: buildPrompt(business, productsServices),
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    const msg = data?.error?.message ?? JSON.stringify(data);
    throw new Error(`OpenRouter: ${msg}`);
  }

  const content = data?.choices?.[0]?.message?.content;
  if (!content) throw new Error("OpenRouter: réponse vide");

  let parsed: unknown;
  try {
    parsed = JSON.parse(content);
  } catch {
    throw new Error("OpenRouter: la réponse n'est pas un JSON valide");
  }
  return validateGrid(parsed);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return Response.json({ error: "Non authentifié" }, { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const apiKey = Deno.env.get("OPENROUTER_API_KEY");
    const model = Deno.env.get("OPENROUTER_MODEL") ?? DEFAULT_MODEL;
    if (!apiKey) {
      return Response.json(
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
      return Response.json({ error: "Token invalide" }, { status: 401 });
    }
    const userId = userData.user.id;

    const admin = createClient(supabaseUrl, serviceKey);

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
        return Response.json(
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
      return Response.json(
        { error: "business requis (3 à 120 caractères)" },
        { status: 400 },
      );
    }
    const productsServices = body.productsServices?.trim().slice(0, 1000) ?? "";

    // Cache partagé : clé = métier normalisé uniquement, pour que deux
    // utilisateurs du même métier partagent la même grille générée.
    const normalized = normalizeBusiness(business);
    const cacheKey = await sha256(normalized);

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
      return Response.json({ grid: cached.grid, fromCache: true });
    }

    if (limits.maxAiPerMonth !== null) {
      const used = await getAiUsage(admin, userId);
      if (used >= limits.maxAiPerMonth) {
        return Response.json(
          {
            error:
              `Quota mensuel de génération IA atteint (${limits.maxAiPerMonth}/mois). ` +
              "Pour plus de générations, changez d'offre.",
          },
          { status: 403 },
        );
      }
    }

    const grid = await callOpenRouter(apiKey, model, business, productsServices);

    if (limits.maxAiPerMonth !== null) {
      await incrementAiUsage(admin, userId);
    }

    await admin.from("grid_generation_cache").upsert(
      {
        cache_key: cacheKey,
        business: normalized,
        grid,
        model,
      },
      { onConflict: "cache_key" },
    );

    return Response.json({ grid, fromCache: false });
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 502 });
  }
});
