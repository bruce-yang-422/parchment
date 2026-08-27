import assert from 'node:assert/strict';
import { normalizeRelativePath } from '../assets/js/fileLoader.js';

assert.deepEqual(
  normalizeRelativePath(['guides', '.', 'images', '..', 'intro.md']),
  ['guides', 'intro.md'],
);
assert.deepEqual(normalizeRelativePath(['100% real', '圖 片.png']), ['100% real', '圖 片.png']);
assert.throws(
  () => normalizeRelativePath(['..', 'outside.md']),
  error => error.name === 'SecurityError',
);

console.log('path-test: passed');
