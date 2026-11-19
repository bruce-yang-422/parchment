/**
 * background.js — Parchment 外掛的背景 Service Worker
 * - 點擊工具列圖示：在新分頁開啟 Parchment
 * - 收到內容腳本的通知：把本機 .md 分頁導向 Parchment 檢視器
 * - 首次安裝：開啟設定頁，說明如何允許存取檔案網址
 */

const APP_URL = chrome.runtime.getURL('app/index.html');

chrome.action.onClicked.addListener(() => {
  chrome.tabs.create({ url: APP_URL });
});

chrome.runtime.onMessage.addListener((message, sender) => {
  if (message?.type !== 'parchment:open-file') return;
  // 只接受本外掛內容腳本、且來自 file:// 分頁的請求
  if (sender.id !== chrome.runtime.id || !sender.tab?.id) return;
  if (!/^file:\/\//i.test(message.url) || !/^file:\/\//i.test(sender.url || '')) return;

  chrome.tabs.update(sender.tab.id, {
    url: `${APP_URL}?file=${encodeURIComponent(message.url)}`,
  });
});

chrome.runtime.onInstalled.addListener(({ reason }) => {
  if (reason === chrome.runtime.OnInstalledReason.INSTALL) {
    chrome.runtime.openOptionsPage();
  }
});
