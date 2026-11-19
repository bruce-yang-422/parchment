import assert from 'node:assert/strict';
import { applyReaderFonts } from '../assets/js/readerFont.js';

global.document = { documentElement: { dataset: {} } };

applyReaderFonts('kai', 'serif');
assert.equal(document.documentElement.dataset.readerCjkFont, 'kai');
assert.equal(document.documentElement.dataset.readerLatinFont, 'serif');

applyReaderFonts('invalid', 'invalid');
assert.equal(document.documentElement.dataset.readerCjkFont, 'system');
assert.equal(document.documentElement.dataset.readerLatinFont, 'system');

console.log('reader-font-test: passed');
