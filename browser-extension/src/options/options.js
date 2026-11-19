/** options.js — 外掛設定頁：自動開啟開關與檔案網址存取狀態 */

const t = key => chrome.i18n.getMessage(key);

document.documentElement.lang = chrome.i18n.getUILanguage();
for (const element of document.querySelectorAll('[data-i18n]')) {
  const text = t(element.dataset.i18n);
  if (text) element.textContent = text;
}

document.getElementById('open-app').addEventListener('click', () => {
  chrome.tabs.create({ url: chrome.runtime.getURL('app/index.html') });
});

const autoOpen = document.getElementById('auto-open');
chrome.storage.local.get({ autoOpen: true }).then(({ autoOpen: enabled }) => {
  autoOpen.checked = enabled;
});
autoOpen.addEventListener('change', () => {
  chrome.storage.local.set({ autoOpen: autoOpen.checked });
});

const status = document.getElementById('file-access-status');
const detailsButton = document.getElementById('open-details');

async function refreshFileAccess() {
  const allowed = await chrome.extension.isAllowedFileSchemeAccess();
  status.textContent = t(allowed ? 'fileAccessEnabled' : 'fileAccessDisabled');
  status.classList.toggle('ok', allowed);
  status.classList.toggle('warn', !allowed);
  detailsButton.hidden = allowed;
}

detailsButton.addEventListener('click', () => {
  // Edge 的擴充功能頁位於 edge://，其他 Chromium 瀏覽器為 chrome://
  const isEdge = navigator.userAgentData?.brands?.some(brand => brand.brand === 'Microsoft Edge')
    || /\bEdg\//.test(navigator.userAgent);
  const scheme = isEdge ? 'edge' : 'chrome';
  chrome.tabs.create({ url: `${scheme}://extensions/?id=${chrome.runtime.id}` });
});

// 使用者切換開關後回到此頁時更新狀態
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') refreshFileAccess();
});
refreshFileAccess();
