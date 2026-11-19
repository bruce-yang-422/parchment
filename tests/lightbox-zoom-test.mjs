import assert from 'node:assert/strict';
import { zoomAt, ZOOM_MAX } from '../assets/js/lightboxZoom.js';

// 縮放後，游標下方的圖片點維持在同一個畫面位置
const before = { scale: 1, x: 0, y: 0 };
const after = zoomAt(before, 2, 100, 50);
assert.deepEqual(after, { scale: 2, x: -100, y: -50 });
assert.equal(after.x + 100 * after.scale, 100);

const further = zoomAt(after, 4, 300, 200);
const localX = (300 - after.x) / after.scale;
assert.equal(further.x + localX * further.scale, 300);

// 上下限；回到 1 倍時位置歸零
assert.equal(zoomAt(before, 99, 0, 0).scale, ZOOM_MAX);
assert.deepEqual(zoomAt(after, 0.2, 10, 10), { scale: 1, x: 0, y: 0 });

console.log('lightbox-zoom-test: passed');
