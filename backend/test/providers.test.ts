import {test} from 'node:test';
import assert from 'node:assert/strict';
import {fetchCatalog, malUrl, normalizeMal, validateRequest} from '../../supabase/functions/catalog/providers.ts';

test('rejects arbitrary paths, huge pages and unsafe genres', () => {
  for (const body of [{path: '../users'}, {path: 'anime', query: {page: 101}}, {path: 'anime', query: {genres: '1&nsfw=true'}}]) assert.throws(() => validateRequest(body));
  assert.equal(validateRequest({path: 'anime', query: {sfw: 'false'}}).query.sfw, 'true');
});
test('MAL request preserves safety and page offset; genre search uses the compatible public API', () => {
  const url = malUrl('anime', {q: 'naruto', page: '2'});
  assert.equal(url?.searchParams.get('offset'), '25');
  assert.equal(url?.searchParams.get('nsfw'), 'false');
  assert.equal(malUrl('anime', {q: 'naruto', page: '1', genres: '1'}), null);
});
test('normalizes missing MAL episode totals and pagination', () => {
  const value = normalizeMal({data: [{node: {id: 1, title: 'Example', num_episodes: 0}}], paging: {next: 'next'}}, false);
  assert.equal(value.data[0].episodes, null);
  assert.equal(value.pagination.has_next_page, true);
});
test('falls back to Tenrai when official API fails', async () => {
  const urls: string[] = [];
  const mock: typeof fetch = async (url) => {
    urls.push(String(url));
    return urls.length === 1 ? new Response('{}', {status: 503}) : Response.json({data: [], pagination: {has_next_page: false}});
  };
  const result = await fetchCatalog('anime', {q: 'naruto', page: '1', sfw: 'true'}, 'test-client', mock);
  assert.equal(result.source, 'tenrai');
  assert.match(urls[0], /myanimelist/); assert.match(urls[1], /^https:\/\/api\.tenrai\.org\/v1\/anime\?/);
});

test('season, search and detail use Tenrai without credentials and preserve MAL IDs', async () => {
  for (const path of ['seasons/2026/fall', 'anime', 'anime/52991/full']) {
    const input = validateRequest({path, query: {q: 'A & B', genres: '7', page: 2}});
    const result = await fetchCatalog(input.path, input.query, undefined, async (url) => {
      const uri = new URL(String(url));
      assert.equal(uri.origin, 'https://api.tenrai.org');
      assert.equal(uri.pathname, `/v1/${path}`);
      assert.equal(uri.searchParams.get('sfw'), 'true');
      if (path === 'anime') {
        assert.equal(uri.searchParams.get('q'), 'A & B');
        assert.equal(uri.searchParams.get('genres'), '7');
        assert.equal(uri.searchParams.get('page'), '2');
      }
      const anime = {mal_id: 52991, title: 'Frieren'};
      return Response.json({data: path.endsWith('/full') ? anime : [anime]});
    });
    assert.equal(result.source, 'tenrai');
    assert.equal(path.endsWith('/full') ? result.data.mal_id : result.data[0].mal_id, 52991);
  }
});

test('invalid upstream payload is rejected instead of cached as a valid empty catalog', async () => {
  await assert.rejects(fetchCatalog('anime', {}, undefined, async () => Response.json({error: 'unavailable'})));
  await assert.rejects(fetchCatalog('anime/1/full', {}, undefined, async () => Response.json({data: {title: 'Missing ID'}})));
});
