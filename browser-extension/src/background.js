/**
 * background.js — Parchment 外掛的背景 Service Worker
 * - 點擊工具列圖示：在新分頁開啟 Parchment
 * - 收到內容腳本的通知：把本機 .md 分頁導向 Parchment 檢視器
 * - 首次安裝：開啟設定頁，說明如何允許存取檔案網址
 */

const APP_URL = chrome.runtime.getURL('app/index.html');

function normalizeLocale(value) {
  const locale = String(value || '').replace('_', '-').toLowerCase();
  if (locale === 'zh' || /^(zh-(tw|hk|mo|hant))/.test(locale)) return 'zh-TW';
  if (/^zh-(cn|sg|hans)/.test(locale)) return 'zh-CN';
  return ['en', 'ja', 'ko', 'fr', 'de', 'es'].find(item => locale.startsWith(item)) || 'en';
}

async function appUrl(file = null) {
  const { uiLocale } = await chrome.storage.local.get({ uiLocale: null });
  const url = new URL(APP_URL);
  url.searchParams.set('lang', normalizeLocale(uiLocale || chrome.i18n.getUILanguage()));
  if (file) url.searchParams.set('file', file);
  return url.href;
}

chrome.action.onClicked.addListener(() => {
  appUrl().then(url => chrome.tabs.create({ url }));
});

chrome.runtime.onMessage.addListener((message, sender) => {
  if (message?.type !== 'parchment:open-file') return;
  // 只接受本外掛內容腳本、且來自 file:// 分頁的請求
  if (sender.id !== chrome.runtime.id || !sender.tab?.id) return;
  if (!/^file:\/\//i.test(message.url) || !/^file:\/\//i.test(sender.url || '')) return;

  appUrl(message.url).then(url => chrome.tabs.update(sender.tab.id, { url }));
});

chrome.runtime.onInstalled.addListener(({ reason }) => {
  if (reason === chrome.runtime.OnInstalledReason.INSTALL) {
    chrome.runtime.openOptionsPage();
  }
});
