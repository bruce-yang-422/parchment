import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { isCompactTableValue } from '../assets/js/tableLayout.js';

for (const value of ['1', '$9,950', 'NT$ 12,500', '€1.299,00', '25%', '（1）']) {
  assert.equal(isCompactTableValue(value), true, `${value} should stay on one line`);
}

for (const value of ['', 'Intel Core Ultra 7 265K', '備註內容', '$9,950\n含稅']) {
  assert.equal(isCompactTableValue(value), false, `${value} should remain wrappable`);
}

const css = await readFile('src/styles/reader.css', 'utf8');
assert.match(css, /#reader-body \.table-compact-cell/);
assert.match(css, /white-space:\s*nowrap/);

const app = await readFile('assets/js/app.js', 'utf8');
assert.match(app, /enhanceTableReadability\(readerBody\)/);

console.log('table-layout-test: passed');
