/** Extraction déterministe des liens réseaux sociaux depuis le HTML d'un site. */

export interface SocialLinks {
  facebook_url: string | null;
  instagram_url: string | null;
  linkedin_url: string | null;
  tiktok_url: string | null;
  youtube_url: string | null;
  x_url: string | null;
  social_network_count: number;
  social_presence_detected: boolean;
}

const HOST_PATTERNS: Array<{ key: keyof Omit<SocialLinks, "social_network_count" | "social_presence_detected">; re: RegExp }> = [
  { key: "facebook_url", re: /https?:\/\/(?:www\.)?(?:facebook\.com|fb\.com)\/[^\s"'<>]+/i },
  { key: "instagram_url", re: /https?:\/\/(?:www\.)?instagram\.com\/[^\s"'<>]+/i },
  { key: "linkedin_url", re: /https?:\/\/(?:www\.)?linkedin\.com\/[^\s"'<>]+/i },
  { key: "tiktok_url", re: /https?:\/\/(?:www\.)?tiktok\.com\/[^\s"'<>]+/i },
  { key: "youtube_url", re: /https?:\/\/(?:www\.)?(?:youtube\.com|youtu\.be)\/[^\s"'<>]+/i },
  { key: "x_url", re: /https?:\/\/(?:www\.)?(?:twitter\.com|x\.com)\/[^\s"'<>]+/i },
];

function cleanUrl(raw: string): string {
  return raw.replace(/[),.;]+$/g, "").slice(0, 500);
}

/** Parse href / texte HTML — best-effort, pas d'IA. */
export function extractSocialLinks(html: string): SocialLinks {
  const empty: SocialLinks = {
    facebook_url: null,
    instagram_url: null,
    linkedin_url: null,
    tiktok_url: null,
    youtube_url: null,
    x_url: null,
    social_network_count: 0,
    social_presence_detected: false,
  };
  if (!html) return empty;

  const found: SocialLinks = { ...empty };
  for (const { key, re } of HOST_PATTERNS) {
    const m = html.match(re);
    if (m?.[0]) {
      found[key] = cleanUrl(m[0]);
    }
  }
  const urls = [
    found.facebook_url,
    found.instagram_url,
    found.linkedin_url,
    found.tiktok_url,
    found.youtube_url,
    found.x_url,
  ].filter((u): u is string => !!u);
  found.social_network_count = urls.length;
  found.social_presence_detected = urls.length > 0;
  return found;
}
