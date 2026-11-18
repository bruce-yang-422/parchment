/**
 * theme.js — 主題切換模組
 * 支援 system / light / dark 三種模式
 */

const THEMES = ['system', 'light', 'dark'];
const LABELS = { system: '跟隨系統', light: '淺色', dark: '深色' };
const STORAGE_KEY = 'parchment-theme';

let currentTheme = 'system';

/** 初始化主題（從 localStorage 讀取），回傳當前 theme */
export function initTheme() {
  const saved = localStorage.getItem(STORAGE_KEY) || 'system';
  applyTheme(saved);

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

/** 套用指定主題 */
export function applyTheme(theme) {
  if (!THEMES.includes(theme)) theme = 'system';
  currentTheme = theme;
  document.documentElement.dataset.theme = theme;
  localStorage.setItem(STORAGE_KEY, theme);
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
}
