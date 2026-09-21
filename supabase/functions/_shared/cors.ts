// CORS Edge Functions — requis pour Flutter Web (preflight + réponses).

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, prefer, accept",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function corsPreflight(): Response {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export function corsJson(
  body: unknown,
  init?: { status?: number },
): Response {
  return Response.json(body, {
    status: init?.status ?? 200,
    headers: corsHeaders,
  });
}
