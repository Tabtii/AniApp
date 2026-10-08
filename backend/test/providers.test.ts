import {test} from 'node:test';
import assert from 'node:assert/strict';
import {fetchCatalog, malUrl, normalizeMal, validateRequest} from '../../supabase/functions/catalog/providers.ts';

test('rejects arbitrary paths, huge pages and unsafe genres', () => {
  for (const body of [{path: '../users'}, {path: 'anime', query: {page: 101}}, {path: 'anime', query: {genres: '1&nsfw=true'}}]) assert.throws(() => validateRequest(body));
  assert.equal(validateRequest({path: 'anime', query: {sfw: 'false'}}).query.sfw, 'true');
});
test('MAL request preserves safety and page offset; genre search stays on Jikan', () => {
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
test('falls back to Jikan when official API fails', async () => {
  const urls: string[] = [];
  const mock: typeof fetch = async (url) => {
    urls.push(String(url));
    return urls.length === 1 ? new Response('{}', {status: 503}) : Response.json({data: [], pagination: {has_next_page: false}});
  };
  const result = await fetchCatalog('anime', {q: 'naruto', page: '1', sfw: 'true'}, 'test-client', mock);
  assert.equal(result.source, 'jikan');
  assert.match(urls[0], /myanimelist/); assert.match(urls[1], /jikan/);
});
