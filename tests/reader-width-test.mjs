import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { applyReaderWidth, currentReaderWidth } from '../assets/js/readerWidth.js';

const storage = new Map();
global.localStorage = {
  getItem: key => storage.get(key) ?? null,
  setItem: (key, value) => storage.set(key, String(value)),
};
global.document = { documentElement: { dataset: {} } };

assert.equal(currentReaderWidth(), 'standard');
assert.equal(applyReaderWidth('full'), 'full');
assert.equal(document.documentElement.dataset.readerWidth, 'full');
assert.equal(storage.get('parchment-reader-width'), 'full');
assert.equal(applyReaderWidth('weird'), 'standard');
assert.equal(applyReaderWidth('full', { save: false }), 'full');
assert.equal(storage.get('parchment-reader-width'), 'standard');

// 滿版規則必須比各配色的欄寬規則權重高
const css = await readFile('src/styles/palette-reader.css', 'utf8');
assert.match(css, /:root\[data-reader-width='full'\] main #reader \{ max-width: none; \}/);
const index = await readFile('index.html', 'utf8');
assert.match(index, /id="reader-width-toggle"/);
const boot = await readFile('assets/js/boot.js', 'utf8');
assert.match(boot, /parchment-reader-width/);

console.log('reader-width-test: passed');
