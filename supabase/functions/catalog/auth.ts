// This read-only endpoint accepts a project publishable key, including guests.
// A publishable key identifies the client, never a user or a privileged role.
export function acceptsPublishableKey(key: string | null, configured: string | undefined): boolean {
  if (!key?.startsWith('sb_publishable_') || !configured) return false;
  try {
    const keys: unknown = JSON.parse(configured);
    if (!keys || typeof keys !== 'object' || Array.isArray(keys)) return false;
    return Object.values(keys).some(value => typeof value === 'string' && value === key);
  } catch { return false; }
}
