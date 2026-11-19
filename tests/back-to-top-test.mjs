import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import {
  BACK_TO_TOP_MEDIA_QUERY,
  BACK_TO_TOP_MOBILE_QUERY,
  shouldShowMobileBackToTop,
} from '../assets/js/backToTop.js';

assert.match(BACK_TO_TOP_MEDIA_QUERY, /hover:\s*hover/);
assert.match(BACK_TO_TOP_MEDIA_QUERY, /pointer:\s*fine/);
assert.match(BACK_TO_TOP_MEDIA_QUERY, /min-width:\s*641px/);
assert.equal(BACK_TO_TOP_MOBILE_QUERY, '(max-width: 640px)');

// 只有兩個畫面長，不論滑到哪裡都不顯示。
assert.equal(shouldShowMobileBackToTop({ scrollTop: 800, scrollHeight: 1600, clientHeight: 800 }), false);
// 長文章尚未讀過可捲動距離的一半時不顯示。
assert.equal(shouldShowMobileBackToTop({ scrollTop: 799, scrollHeight: 2400, clientHeight: 800 }), false);
// 長文章讀到一半後顯示，往上滑回一半以前就會隱藏。
assert.equal(shouldShowMobileBackToTop({ scrollTop: 800, scrollHeight: 2400, clientHeight: 800 }), true);
assert.equal(shouldShowMobileBackToTop({ scrollTop: 1500, scrollHeight: 2400, clientHeight: 800 }), true);
assert.equal(shouldShowMobileBackToTop({ scrollTop: 0, scrollHeight: 0, clientHeight: 0 }), false);

const index = await readFile('index.html', 'utf8');
assert.match(index, /id="back-to-top-dock"/);
assert.match(index, /id="back-to-top-button"/);

const css = await readFile('src/styles/shell.css', 'utf8');
assert.match(css, /\.back-to-top-dock:hover \.back-to-top-button/);
assert.match(css, /@media \(max-width: 640px\)[\s\S]*?\.back-to-top-button[\s\S]*?opacity-100/);

const app = await readFile('assets/js/app.js', 'utf8');
assert.match(app, /initBackToTop\(\{/);

console.log('back-to-top-test: passed');
