import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { MOBILE_MEDIA_QUERY } from '../assets/js/mobileLayout.js';

assert.equal(MOBILE_MEDIA_QUERY, '(max-width: 640px)');

const index = await readFile('index.html', 'utf8');
for (const id of ['btn-mobile-tree', 'btn-mobile-info', 'mobile-pane-backdrop']) {
  assert.match(index, new RegExp(`id="${id}"`));
}
assert.doesNotMatch(index, /no-toc:hidden/);

const css = await readFile('src/styles/shell.css', 'utf8');
assert.match(css, /#main\.mobile-tree-open #sidebar/);
assert.match(css, /#main\.mobile-info-open #toc-sidebar/);
assert.match(css, /width:\s*min\(86vw, 320px\)/);
assert.match(css, /#current-filename[\s\S]*?text-ellipsis/);

const app = await readFile('assets/js/app.js', 'utf8');
assert.match(app, /initMobileLayout\(\{/);

console.log('mobile-layout-test: passed');
