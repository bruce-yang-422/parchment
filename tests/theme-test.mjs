import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { applyPalette, currentPalette, PALETTES, DEFAULT_PALETTE } from '../assets/js/theme.js';

/* 配色套用與保存 */
const storage = new Map();
global.localStorage = {
  getItem: key => storage.get(key) ?? null,
  setItem: (key, value) => storage.set(key, String(value)),
};
global.document = { documentElement: { dataset: {} } };

assert.equal(applyPalette('lake'), 'lake');
assert.equal(document.documentElement.dataset.palette, 'lake');
assert.equal(storage.get('parchment-palette'), 'lake');
assert.equal(currentPalette(), 'lake');
assert.equal(applyPalette('unknown'), DEFAULT_PALETTE);
assert.equal(applyPalette('ink', { save: false }), 'ink');
assert.equal(storage.get('parchment-palette'), DEFAULT_PALETTE);

/* 每套配色都有完整的亮色與暗色變數 */
const shell = await readFile('src/styles/shell.css', 'utf8');
const palettes = await readFile('src/styles/palettes.css', 'utf8');
const index = await readFile('index.html', 'utf8');

const block = (css, selector) => {
  const start = css.indexOf(`${selector} {`);
  assert.ok(start >= 0, `找不到 ${selector}`);
  const body = css.slice(start, css.indexOf('}', start));
  return Object.fromEntries([...body.matchAll(/(--[\w-]+):\s*([^;]+);/g)].map(m => [m[1], m[2].trim()]));
};

const baseLight = block(shell, ':root');
const baseDark = block(shell, ':root.dark');
const colorKeys = Object.keys(baseDark);

const variants = { 'parchment light': baseLight, 'parchment dark': baseDark };
for (const palette of PALETTES.filter(name => name !== 'parchment')) {
  variants[`${palette} light`] = { ...baseLight, ...block(palettes, `:root[data-palette='${palette}']`) };
  variants[`${palette} dark`] = { ...baseLight, ...block(palettes, `:root.dark[data-palette='${palette}']`) };
  for (const mode of ['light', 'dark']) {
    const selector = mode === 'light' ? `:root[data-palette='${palette}']` : `:root.dark[data-palette='${palette}']`;
    const own = block(palettes, selector);
    const missing = colorKeys.filter(key => !(key in own));
    assert.deepEqual(missing, [], `${palette} ${mode} 缺少變數`);
  }
  assert.match(index, new RegExp(`<option value="${palette}">`), `設定選單缺少 ${palette}`);
}

/* 每套非預設配色都有自己的閱讀版面（欄寬、內文字級與標題） */
const readerLayout = await readFile('src/styles/palette-reader.css', 'utf8');
for (const palette of PALETTES.filter(name => name !== 'parchment')) {
  const prefix = `:root[data-palette='${palette}']`;
  assert.ok(readerLayout.includes(`${prefix} #reader { max-width:`), `${palette} 缺少閱讀欄寬`);
  assert.ok(readerLayout.includes(`${prefix} #reader-body {`), `${palette} 缺少內文字級`);
  assert.ok(readerLayout.includes(`${prefix} #reader-body h1 {`), `${palette} 缺少標題樣式`);
}

/* WCAG 對比度：內文 4.5、次要文字與連結 4.5、主要按鈕 4.5 */
const luminance = hex => {
  const value = hex.replace('#', '');
  const channels = [0, 2, 4].map(i => parseInt(value.slice(i, i + 2), 16) / 255)
    .map(c => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
};
const contrast = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};

const failures = [];
for (const [name, vars] of Object.entries(variants)) {
  const checks = [
    ['text/bg', vars['--text'], vars['--bg'], 4.5],
    ['text-muted/bg', vars['--text-muted'], vars['--bg'], 4.5],
    ['link/bg', vars['--link'], vars['--bg'], 4.5],
    ['accent-contrast/accent', vars['--accent-contrast'], vars['--accent'], 4.5],
    ['text/sidebar', vars['--text'], vars['--sidebar-bg'], 4.5],
    ['tree-active-text/tree-active', vars['--tree-active-text'], vars['--tree-active'], 4.5],
    ['inline-code/code-bg', vars['--inline-code-color'], vars['--code-bg'], 4.5],
  ];
  for (const [label, fg, bg, min] of checks) {
    const ratio = contrast(fg, bg);
    if (ratio < min) failures.push(`${name} ${label} ${ratio.toFixed(2)}`);
  }
}
assert.deepEqual(failures, [], `對比度不足：\n${failures.join('\n')}`);

console.log('theme-test: passed');
