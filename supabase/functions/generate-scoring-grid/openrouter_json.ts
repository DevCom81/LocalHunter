/** Appel OpenRouter → objet JSON (grille / profil). */

function extractMessageContent(message: unknown): string {
  if (!message || typeof message !== "object") return "";
  const content = (message as { content?: unknown }).content;
  if (typeof content === "string") return content.trim();
  if (Array.isArray(content)) {
    return content
      .map((part) => {
        if (typeof part === "string") return part;
        if (part && typeof part === "object" && "text" in part) {
          return String((part as { text?: unknown }).text ?? "");
        }
        return "";
      })
      .join("")
      .trim();
  }
  return "";
}

/** Retire un éventuel fence markdown ```json … ```. */
export function unwrapJsonPayload(raw: string): string {
  const trimmed = raw.trim();
  const fenced = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
  if (fenced?.[1]) return fenced[1].trim();
  return trimmed;
}

async function openRouterOnce(
  apiKey: string,
  model: string,
  messages: { role: string; content: string }[],
  useJsonObjectFormat: boolean,
): Promise<{ content: string; finishReason: string; rawError?: string }> {
  const body: Record<string, unknown> = {
    model,
    temperature: 0.3,
    messages,
  };
  if (useJsonObjectFormat) {
    body.response_format = { type: "json_object" };
  }

  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
      "HTTP-Referer": "https://localhunter.app",
      "X-Title": "LocalHunter",
    },
    body: JSON.stringify(body),
  });

  const data = await res.json();
  if (!res.ok) {
    const msg = data?.error?.message ?? JSON.stringify(data);
    return { content: "", finishReason: "", rawError: msg };
  }

  const choice = data?.choices?.[0];
  const content = extractMessageContent(choice?.message);
  const finishReason = String(choice?.finish_reason ?? "");
  return { content, finishReason };
}

/**
 * Parse JSON depuis OpenRouter.
 * Retry sans `response_format` si le 1er essai renvoie un contenu vide
 * (fréquent avec certains modèles + json_object).
 */
export async function openRouterJson(
  apiKey: string,
  model: string,
  messages: { role: string; content: string }[],
): Promise<unknown> {
  let attempt = await openRouterOnce(apiKey, model, messages, true);
  if (attempt.rawError) {
    throw new Error(`OpenRouter: ${attempt.rawError}`);
  }

  if (!attempt.content) {
    attempt = await openRouterOnce(apiKey, model, messages, false);
    if (attempt.rawError) {
      throw new Error(`OpenRouter: ${attempt.rawError}`);
    }
  }

  if (!attempt.content) {
    throw new Error(
      `OpenRouter: réponse vide (model=${model}, finish_reason=${
        attempt.finishReason || "unknown"
      })`,
    );
  }

  const payload = unwrapJsonPayload(attempt.content);
  try {
    return JSON.parse(payload);
  } catch {
    throw new Error("OpenRouter: la réponse n'est pas un JSON valide");
  }
}
