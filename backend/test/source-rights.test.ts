import {test} from 'node:test';
import assert from 'node:assert/strict';
import {blockedSources, registerReader} from '../../supabase/functions/_shared/source-rights.ts';
import {fetchCatalog} from '../../supabase/functions/catalog/providers.ts';
import {Enrichment} from '../../supabase/functions/anime-enrichment/providers.ts';
import {syncDubAnnouncements} from '../../supabase/functions/content-sync/dub-sync.ts';

const must = (async () => { throw new Error('Must not request'); }) as typeof fetch;

test('only sources the register marks blocked are switched off', () => {
  const blocked = blockedSources([{source_key: 'tenrai', status: 'blocked'}, {source_key: 'adn', status: 'review_required'},
    {source_key: 'cr_de', status: 'permission_requested'}]);
  assert.deepEqual([...blocked], ['tenrai']);
  assert.throws(() => blockedSources({} as never));
});

test('register is cached, reuses a recent copy on failure and fails closed without one', async () => {
  let time = 0, calls = 0, fail = false;
  const fetcher = (async () => { calls++; if (fail) throw new Error('down');
    return Response.json([{source_key: 'kitsu', status: 'blocked'}]); }) as typeof fetch;
  const read = registerReader('https://db.test', 'key', fetcher, 60000, 600000, () => time);
  assert.ok((await read()).has('kitsu'));
  await read(); assert.equal(calls, 1);
  time = 120000; fail = true;
  assert.ok((await read()).has('kitsu'));
  time = 700000;
  await assert.rejects(read());
  await assert.rejects(registerReader('https://db.test', 'key', fetcher)());
});

test('catalog skips a blocked MAL API and never contacts a blocked Tenrai', async () => {
  const urls: string[] = [];
  const result = await fetchCatalog('anime', {q: 'naruto', page: '1'}, 'client', (async (url) => {
    urls.push(String(url)); return Response.json({data: []}); }) as typeof fetch, new Set(['jikan']));
  assert.equal(result.source, 'tenrai');
  assert.ok(urls.every(u => u.startsWith('https://api.tenrai.org/')));
  await assert.rejects(fetchCatalog('anime', {page: '1'}, undefined, must, new Set(['tenrai'])), /blocked/);
});

test('enrichment reports blocked sources as unavailable without a request', async () => {
  const service = new Enrichment({tmdbToken: 'token', anilistApproved: true}, must);
  const blocked = new Set(['mydublist', 'tmdb', 'kitsu', 'anilist']);
  const detail = await service.detail(21, 'de', 'DE', blocked);
  assert.equal(detail.dub.status, 'unavailable');
  assert.equal(detail.streaming.status, 'unavailable');
  assert.equal(detail.kitsu.status, 'unavailable');
  assert.equal(detail.anilist.status, 'unavailable');
  assert.equal((await service.calendar(blocked)).status, 'unavailable');
});

test('dub worker stops a blocked feed and its title lookups but keeps the others', async () => {
  const requests: string[] = [];
  const db = async (path: string, _body: unknown, method = 'POST') => {
    if (method !== 'GET') return null;
    if (path.startsWith('source_rights?')) return [{source_key: 'cr_de', status: 'blocked'}, {source_key: 'tenrai', status: 'blocked'}];
    return [];
  };
  const fetcher = (async (url: string) => { requests.push(String(url));
    return new Response('<rss><channel></channel></rss>'); }) as unknown as typeof fetch;
  await syncDubAnnouncements(db, fetcher, new Date('2026-10-10T10:00:00Z'), async () => {});
  assert.ok(!requests.some(u => u.includes('/de-DE/')));
  assert.ok(requests.some(u => u.includes('/en-US/')));
  assert.ok(!requests.some(u => u.startsWith('https://www.anime2you.de/')));
  assert.ok(!requests.some(u => u.startsWith('https://api.tenrai.org/')));
});
