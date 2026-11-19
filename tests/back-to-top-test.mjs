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

// 四個畫面以內，不論滑到哪裡都不顯示。
assert.equal(shouldShowMobileBackToTop({ scrollTop: 2400, scrollHeight: 3200, clientHeight: 800 }), false);
// 超過四頁的長文章，尚未捲動滿兩個畫面時不顯示。
assert.equal(shouldShowMobileBackToTop({ scrollTop: 1599, scrollHeight: 4000, clientHeight: 800 }), false);
// 捲動滿兩個畫面後顯示；超長文章也不需要等待閱讀到 50%。
assert.equal(shouldShowMobileBackToTop({ scrollTop: 1600, scrollHeight: 4000, clientHeight: 800 }), true);
assert.equal(shouldShowMobileBackToTop({ scrollTop: 1600, scrollHeight: 8800, clientHeight: 800 }), true);
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
