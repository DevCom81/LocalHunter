import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleAuth } from "https://esm.sh/google-auth-library@9";

export const PACKAGE_NAME = "com.localhunter.localhunter";

export const PRODUCT_TO_TIER: Record<string, string> = {
  localhunter_premium_monthly: "premium",
  localhunter_premium_plus_monthly: "premium_plus",
  localhunter_pro_monthly: "pro",
};

const TIER_RANK: Record<string, number> = {
  freemium: 0,
  premium: 1,
  premium_plus: 2,
  pro: 3,
};

export interface PlayLineItem {
  productId?: string;
  expiryTime?: string;
  autoRenewingPlan?: { autoRenewEnabled?: boolean };
}

export interface PlaySubscriptionV2 {
  subscriptionState?: string;
  lineItems?: PlayLineItem[];
  externalAccountIdentifiers?: {
    obfuscatedExternalAccountId?: string;
  };
}

export function tierFromProductId(productId: string): string | null {
  return PRODUCT_TO_TIER[productId] ?? null;
}

export function tierRank(tier: string): number {
  return TIER_RANK[tier] ?? 0;
}

export function pickHigherTier(a: string, b: string): string {
  return tierRank(a) >= tierRank(b) ? a : b;
}

export function primaryLineItem(data: PlaySubscriptionV2): PlayLineItem | undefined {
  return data.lineItems?.[0];
}

export function isSubscriptionEntitled(
  state: string | undefined,
  expiryTime: string | undefined,
): boolean {
  if (state === "SUBSCRIPTION_STATE_ACTIVE") return true;
  if (state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD") return true;
  if (state === "SUBSCRIPTION_STATE_CANCELED" && expiryTime) {
    return new Date(expiryTime) > new Date();
  }
  return false;
}

export async function getPlayAccessToken(): Promise<string> {
  const raw = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT");
  if (!raw) throw new Error("GOOGLE_PLAY_SERVICE_ACCOUNT manquante");

  const auth = new GoogleAuth({
    credentials: JSON.parse(raw),
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  if (!token.token) throw new Error("Impossible d'obtenir un token Google Play");
  return token.token;
}

export async function fetchSubscriptionV2(
  accessToken: string,
  purchaseToken: string,
): Promise<PlaySubscriptionV2> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    throw new Error(`Google Play API ${res.status}: ${await res.text()}`);
  }
  return await res.json();
}

export async function syncPlaySubscription(
  admin: SupabaseClient,
  userId: string,
  purchaseToken: string,
  productId: string,
  googleData: PlaySubscriptionV2,
): Promise<{ tier: string; entitled: boolean }> {
  const mappedTier = tierFromProductId(productId);
  if (!mappedTier) throw new Error(`Produit Play inconnu: ${productId}`);

  const line = primaryLineItem(googleData);
  const expiryTime = line?.expiryTime ?? null;
  const entitled = isSubscriptionEntitled(googleData.subscriptionState, expiryTime ?? undefined);
  const effectiveTier = entitled ? mappedTier : "freemium";

  await admin.from("play_subscriptions").upsert(
    {
      user_id: userId,
      product_id: productId,
      purchase_token: purchaseToken,
      subscription_tier: mappedTier,
      subscription_state: googleData.subscriptionState ?? "UNKNOWN",
      expiry_time: expiryTime,
      auto_renewing: line?.autoRenewingPlan?.autoRenewEnabled ?? null,
      obfuscated_account_id:
        googleData.externalAccountIdentifiers?.obfuscatedExternalAccountId ?? null,
      raw_payload: googleData,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "purchase_token" },
  );

  const { data: rows } = await admin
    .from("play_subscriptions")
    .select("subscription_tier, subscription_state, expiry_time")
    .eq("user_id", userId);

  let bestTier = "freemium";
  for (const row of rows ?? []) {
    if (
      isSubscriptionEntitled(
        row.subscription_state,
        row.expiry_time ?? undefined,
      )
    ) {
      bestTier = pickHigherTier(bestTier, row.subscription_tier);
    }
  }

  await admin.from("profiles").update({ subscription_tier: bestTier }).eq("id", userId);

  return { tier: bestTier, entitled: effectiveTier !== "freemium" };
}

export function createAdminClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}
