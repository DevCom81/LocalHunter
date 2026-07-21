import {
  createAdminClient,
  fetchSubscriptionV2,
  getPlayAccessToken,
  syncPlaySubscription,
  tierFromProductId,
} from "../_shared/play_google.ts";

interface PubSubPush {
  message?: { data?: string };
}

interface RtdnPayload {
  subscriptionNotification?: {
    purchaseToken?: string;
    subscriptionId?: string;
  };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const expected = Deno.env.get("PLAY_RTDN_TOKEN");
  const urlToken = new URL(req.url).searchParams.get("token");
  if (!expected || urlToken !== expected) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    const envelope: PubSubPush = await req.json();
    const raw = envelope.message?.data;
    if (!raw) return Response.json({ ok: true, skipped: "no data" });

    const payload: RtdnPayload = JSON.parse(atob(raw));
    const note = payload.subscriptionNotification;
    const purchaseToken = note?.purchaseToken?.trim();
    const productId = note?.subscriptionId?.trim();
    if (!purchaseToken || !productId) {
      return Response.json({ ok: true, skipped: "not a subscription event" });
    }
    if (!tierFromProductId(productId)) {
      return Response.json({ ok: true, skipped: "unknown product" });
    }

    const admin = createAdminClient();
    const { data: existing } = await admin
      .from("play_subscriptions")
      .select("user_id")
      .eq("purchase_token", purchaseToken)
      .maybeSingle();

    if (!existing?.user_id) {
      return Response.json({ ok: true, skipped: "unknown purchase token" });
    }

    const accessToken = await getPlayAccessToken();
    const googleData = await fetchSubscriptionV2(accessToken, purchaseToken);
    await syncPlaySubscription(
      admin,
      existing.user_id,
      purchaseToken,
      productId,
      googleData,
    );

    return Response.json({ ok: true });
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 502 });
  }
});
