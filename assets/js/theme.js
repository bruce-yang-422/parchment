/**
 * theme.js — 主題切換模組
 * - 明暗模式：system / light / dark
 * - 配色：parchment（預設）/ amethyst / ink / lake / aluminum，每套皆有亮色與暗色
 */

const THEMES = ['system', 'light', 'dark'];
const LABELS = { system: '跟隨系統', light: '淺色', dark: '深色' };
const STORAGE_KEY = 'parchment-theme';

export const PALETTES = ['parchment', 'amethyst', 'ink', 'lake', 'aluminum'];
export const DEFAULT_PALETTE = 'parchment';
const PALETTE_STORAGE_KEY = 'parchment-palette';

let currentTheme = 'system';

/** 初始化主題與配色（從 localStorage 讀取） */
export function initTheme() {
  applyPalette(_read(PALETTE_STORAGE_KEY) || DEFAULT_PALETTE, { save: false });
  applyTheme(_read(STORAGE_KEY) || 'system', { save: false });

  // 系統主題變化時自動更新
  window.matchMedia('(prefers-color-scheme: dark)')
    .addEventListener('change', () => {
      if (currentTheme === 'system') _updateDarkClass();
    });
}

/** 循環切換至下一個主題，回傳新 theme */
export function cycleTheme() {
  const idx = THEMES.indexOf(currentTheme);
  applyTheme(THEMES[(idx + 1) % THEMES.length]);
  return currentTheme;
}

/** 套用指定明暗模式 */
export function applyTheme(theme, { save = true } = {}) {
  if (!THEMES.includes(theme)) theme = 'system';
  currentTheme = theme;
  document.documentElement.dataset.theme = theme;
  if (save) _write(STORAGE_KEY, theme);
  _updateDarkClass();

  const btn = document.getElementById('btn-theme');
  if (btn) {
    const label = `切換主題（目前：${LABELS[theme]}）`;
    btn.setAttribute('aria-label', label);
    btn.title = label;
    for (const icon of btn.querySelectorAll('[data-theme-icon]')) {
      icon.classList.toggle('hidden', icon.dataset.themeIcon !== theme);
    }
  }
}

/** 套用指定配色，回傳實際套用的配色 */
export function applyPalette(palette, { save = true } = {}) {
  const value = PALETTES.includes(palette) ? palette : DEFAULT_PALETTE;
  document.documentElement.dataset.palette = value;
  if (save) _write(PALETTE_STORAGE_KEY, value);
  _syncThemeColor();
  return value;
}

export function currentPalette() {
  return document.documentElement.dataset.palette || DEFAULT_PALETTE;
}

/** 根據當前有效深色狀態更新 .dark class 與 hljs 樣式 */
function _updateDarkClass() {
  const isDark =
    currentTheme === 'dark' ||
    (currentTheme === 'system' &&
      window.matchMedia('(prefers-color-scheme: dark)').matches);

  document.documentElement.classList.toggle('dark', isDark);

  const lightLink = document.getElementById('hljs-light');
  const darkLink  = document.getElementById('hljs-dark');
  if (lightLink) lightLink.disabled = isDark;
  if (darkLink)  darkLink.disabled  = !isDark;
  _syncThemeColor();
}

/** 讓瀏覽器或 PWA 標題列顏色跟隨目前配色。 */
function _syncThemeColor() {
  if (typeof getComputedStyle !== 'function') return;
  const meta = document.querySelector?.('meta[name="theme-color"]');
  if (!meta) return;
  const color = getComputedStyle(document.documentElement).getPropertyValue('--header-bg').trim();
  if (color) meta.setAttribute('content', color);
}

function _read(key) {
  try { return localStorage.getItem(key); } catch { return null; }
}

function _write(key, value) {
  try { localStorage.setItem(key, value); } catch { /* 偏好僅在本次頁面有效 */ }
}
