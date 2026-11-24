import { applyTheme, applyPalette, currentPalette } from './theme.js';
import { currentLocale, setLocale } from './i18n.js';

/** 設定與工具資訊對話框。 */
export function initSettingsPanel() {
  const settingsDialog = document.getElementById('settings-dialog');
  const aboutDialog = document.getElementById('about-dialog');
  const settingsButton = document.getElementById('btn-settings');
  const aboutButton = document.getElementById('btn-about');
  const themeSelect = document.getElementById('setting-theme');
  const localeSelect = document.getElementById('setting-locale');
  if (!settingsDialog || !aboutDialog || !settingsButton || !aboutButton || !themeSelect) return;

  const paletteSelect = document.getElementById('setting-palette');
  initReadingControls(document.documentElement);

  settingsButton.addEventListener('click', () => {
    themeSelect.value = document.documentElement.dataset.theme || 'system';
    if (localeSelect) localeSelect.value = currentLocale();
    if (paletteSelect) paletteSelect.value = currentPalette();
    settingsDialog.showModal();
  });
  aboutButton.addEventListener('click', () => aboutDialog.showModal());
  themeSelect.addEventListener('change', () => applyTheme(themeSelect.value));
  localeSelect?.addEventListener('change', () => setLocale(localeSelect.value));
  paletteSelect?.addEventListener('change', () => {
    paletteSelect.value = applyPalette(paletteSelect.value);
  });

  [settingsDialog, aboutDialog].forEach(dialog => {
    dialog.querySelector('[data-close-dialog]')?.addEventListener('click', () => dialog.close());
    dialog.addEventListener('click', event => {
      if (event.target === dialog) dialog.close();
    });
  });
}

function initReadingControls(root) {
  initSelectSetting('setting-text-size', 'parchment-reader-text-size', value => {
    root.style.setProperty('--reader-text-scale', Number(value) / 100);
  });
  initSelectSetting('setting-line-spacing', 'parchment-reader-line-spacing', value => {
    if (value === 'default') root.style.removeProperty('--reader-line-height');
    else root.style.setProperty('--reader-line-height', value);
  });

  const lineNumbers = document.getElementById('setting-code-line-numbers');
  if (!lineNumbers) return;
  const key = 'parchment-reader-code-line-numbers';
  lineNumbers.checked = loadSetting(key) === 'true';
  root.toggleAttribute('data-reader-code-line-numbers', lineNumbers.checked);
  lineNumbers.addEventListener('change', () => {
    root.toggleAttribute('data-reader-code-line-numbers', lineNumbers.checked);
    saveSetting(key, String(lineNumbers.checked));
  });
}

function initSelectSetting(id, key, apply) {
  const select = document.getElementById(id);
  if (!select) return;
  const saved = loadSetting(key);
  if (Array.from(select.options).some(option => option.value === saved)) select.value = saved;
  apply(select.value);
  select.addEventListener('change', () => {
    apply(select.value);
    saveSetting(key, select.value);
  });
}

function loadSetting(key) {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function saveSetting(key, value) {
  try {
    localStorage.setItem(key, value);
  } catch {
    // The current page still uses the selected setting.
  }
}
