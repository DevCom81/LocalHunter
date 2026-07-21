import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  fetchSubscriptionV2,
  getPlayAccessToken,
  syncPlaySubscription,
} from "../_shared/play_google.ts";

interface VerifyRequest {
  purchaseToken: string;
  productId: string;
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
    const userClient = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return Response.json({ error: "Token invalide" }, { status: 401 });
    }

    const body: VerifyRequest = await req.json();
    const purchaseToken = body.purchaseToken?.trim();
    const productId = body.productId?.trim();
    if (!purchaseToken || !productId) {
      return Response.json(
        { error: "purchaseToken et productId requis" },
        { status: 400 },
      );
    }

    const accessToken = await getPlayAccessToken();
    const googleData = await fetchSubscriptionV2(accessToken, purchaseToken);
    const admin = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const result = await syncPlaySubscription(
      admin,
      userData.user.id,
      purchaseToken,
      productId,
      googleData,
    );

    return Response.json({
      tier: result.tier,
      entitled: result.entitled,
    });
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 502 });
  }
});
