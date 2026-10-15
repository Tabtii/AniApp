// Test-phase kill switch. A source whose register status is 'blocked' is never
// contacted. This is NOT a permission check: sources still under review keep
// running during testing, while approval-gated sources (Anime2You, AniNews and
// the additional publishers) check for an explicit approval themselves.
export type SourceRight = {source_key: string; status: string};

export function blockedSources(rights: SourceRight[]): Set<string> {
  if (!Array.isArray(rights)) throw new Error('Invalid source register');
  return new Set(rights.filter(r => r?.status === 'blocked').map(r => r.source_key));
}

// Reads the public register at most once per `ttl`. A failed refresh reuses the
// last known register for up to `stale`; without one the caller must fail closed.
export function registerReader(url: string, key: string, fetcher: typeof fetch = fetch,
  ttl = 60000, stale = 600000, now = () => Date.now()) {
  let known: {at: number; blocked: Set<string>} | null = null;
  return async (): Promise<Set<string>> => {
    if (known && now() - known.at < ttl) return known.blocked;
    try {
      const r = await fetcher(`${url}/rest/v1/source_rights?select=source_key,status`,
        {headers: {apikey: key, Authorization: `Bearer ${key}`}, signal: AbortSignal.timeout(4000)});
      if (!r.ok) throw new Error(`Source register ${r.status}`);
      known = {at: now(), blocked: blockedSources(await r.json())};
      return known.blocked;
    } catch (error) {
      if (known && now() - known.at < stale) return known.blocked;
      throw error;
    }
  };
}
