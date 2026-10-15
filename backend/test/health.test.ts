import {test} from 'node:test';
import assert from 'node:assert/strict';
import {importHealth} from '../../supabase/functions/content-sync/health.ts';
import {parsePage} from '../../supabase/functions/content-sync/dub-sources.ts';

test('import health marks a register key degraded when any of its imports failed', () => {
  assert.deepEqual(importHealth({myanimelist:{count:15},schedule:{count:97},adn:{count:48,failed:[]},adn_news:{count:1,failed:[]},
    anime2you:{state:'ok',failed:[]}}),{anime2you:'ok',tenrai:'ok',adn:'ok'});
  assert.deepEqual(importHealth({myanimelist:{count:15},schedule:{error:'Schedule pagination incomplete'},
    adn:{count:48,failed:[{day:'2026-10-16'}]},adn_news:{count:1,failed:[]}}),{tenrai:'degraded',adn:'degraded'});
});

test('blocked, permission-pending and skipped imports report no health', () => {
  assert.deepEqual(importHealth({myanimelist:{state:'blocked'},schedule:{state:'blocked'},anime2you:{state:'permission_pending'}}),{});
  assert.deepEqual(importHealth({}),{});
});

test('article parse errors name the failed check', () => {
  const url='https://www.crunchyroll.com/de/news/latest/2026/10/5/example-article';
  const page=(head:string)=>`<html><head>${head}</head><body><article>${'Text '.repeat(40)}</article></body></html>`;
  assert.throws(()=>parsePage(page('<meta property="og:type" content="article">'),url),/no canonical/);
  assert.throws(()=>parsePage(page(`<link rel="canonical" href="${url}"><meta property="og:type" content="website">`),url),/type unexpected \(website\)/);
  assert.throws(()=>parsePage(page('<link rel="canonical" href="https://www.crunchyroll.com/de/news/latest/2026/10/5/other"><meta property="og:type" content="article">'),url),/mismatched/);
});
