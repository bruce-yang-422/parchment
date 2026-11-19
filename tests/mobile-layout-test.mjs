import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { MOBILE_MEDIA_QUERY } from '../assets/js/mobileLayout.js';

assert.equal(MOBILE_MEDIA_QUERY, '(max-width: 640px)');

const index = await readFile('index.html', 'utf8');
for (const id of ['btn-mobile-tree', 'btn-mobile-info', 'mobile-pane-backdrop']) {
  assert.match(index, new RegExp(`id="${id}"`));
}
assert.doesNotMatch(index, /no-toc:hidden/);
assert.match(index, /<dl class="about-meta">/);
assert.match(index, /<dt>作者<\/dt><dd>Bruce Yang<\/dd>/);
assert.match(index, /<dt>最後更新<\/dt><dd><time datetime="2026-11-19">2026-11-19<\/time><\/dd>/);

const css = await readFile('src/styles/shell.css', 'utf8');
assert.match(css, /#main\.mobile-tree-open #sidebar/);
assert.match(css, /#main\.mobile-info-open #toc-sidebar/);
assert.match(css, /width:\s*min\(86vw, 320px\)/);
assert.match(css, /#main\s*\{[\s\S]*?overflow-x:\s*clip/);
assert.match(css, /#current-filename[\s\S]*?text-ellipsis/);
assert.doesNotMatch(css, /#btn-theme,\s*#btn-about/);
assert.match(css, /#content-area\s*\{[\s\S]*?overflow-x:\s*hidden/);
assert.match(css, /#reader\s*\{[\s\S]*?width:\s*100%/);

const app = await readFile('assets/js/app.js', 'utf8');
assert.match(app, /initMobileLayout\(\{/);
assert.match(app, /contentArea\.scrollLeft\s*=\s*0/);

const mobileLayout = await readFile('assets/js/mobileLayout.js', 'utf8');
assert.match(mobileLayout, /layout\.scrollLeft\s*=\s*0/);

console.log('mobile-layout-test: passed');
