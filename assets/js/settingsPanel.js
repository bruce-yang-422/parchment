import { applyTheme } from './theme.js';

/** 設定與工具資訊對話框。 */
export function initSettingsPanel() {
  const settingsDialog = document.getElementById('settings-dialog');
  const aboutDialog = document.getElementById('about-dialog');
  const settingsButton = document.getElementById('btn-settings');
  const aboutButton = document.getElementById('btn-about');
  const themeSelect = document.getElementById('setting-theme');
  if (!settingsDialog || !aboutDialog || !settingsButton || !aboutButton || !themeSelect) return;

  settingsButton.addEventListener('click', () => {
    themeSelect.value = document.documentElement.dataset.theme || 'system';
    settingsDialog.showModal();
  });
  aboutButton.addEventListener('click', () => aboutDialog.showModal());
  themeSelect.addEventListener('change', () => applyTheme(themeSelect.value));

  [settingsDialog, aboutDialog].forEach(dialog => {
    dialog.querySelector('[data-close-dialog]')?.addEventListener('click', () => dialog.close());
    dialog.addEventListener('click', event => {
      if (event.target === dialog) dialog.close();
    });
  });
}
