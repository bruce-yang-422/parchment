import assert from 'node:assert/strict';
import { pngFileName, exportScale } from '../assets/js/imageExport.js';

assert.equal(pngFileName('02_備份機制說明.md'), '02_備份機制說明.png');
assert.equal(pngFileName('images/diagram.svg'), 'diagram.png');
assert.equal(pngFileName('a:b*c?.jpg'), 'abc.png');
assert.equal(pngFileName('', 'diagram'), 'diagram.png');
assert.equal(pngFileName(undefined), 'image.png');

// 一般圖表維持偏好倍率；過大時縮小以符合 canvas 上限
assert.equal(exportScale(800, 600, 2), 2);
assert.ok(exportScale(12000, 1000, 2) * 12000 <= 16384);
assert.ok(exportScale(9000, 9000, 2) * 9000 <= 16384);
assert.equal(exportScale(0, 0, 2), 1);

console.log('image-export-test: passed');
