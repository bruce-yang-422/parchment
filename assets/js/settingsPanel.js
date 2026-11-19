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
