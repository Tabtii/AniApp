import test from 'node:test';
import assert from 'node:assert/strict';
import {acceptsPublishableKey} from '../../supabase/functions/catalog/auth.ts';

test('catalog accepts only configured publishable keys and fails closed', () => {
  const config = JSON.stringify({default: 'sb_publishable_example'});
  assert.equal(acceptsPublishableKey('sb_publishable_example', config), true);
  for (const key of [null, '', 'sb_publishable_unknown', 'sb_secret_example', 'eyJlegacy']) {
    assert.equal(acceptsPublishableKey(key, config), false);
  }
  for (const config of [undefined, '', '{broken', 'null', '[]']) {
    assert.equal(acceptsPublishableKey('sb_publishable_example', config), false);
  }
});
