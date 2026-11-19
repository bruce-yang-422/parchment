/**
 * open-markdown.js — 在瀏覽器直接開啟本機 .md 檔（file://）時，改以 Parchment 顯示。
 * 只在使用者於擴充功能設定中開啟「允許存取檔案網址」後才會執行。
 * 不讀取頁面內容；實際讀檔由 Parchment 檢視器以唯讀方式進行。
 */
(async () => {
  // 從 Parchment 按「上一頁」回到此頁時保留原始文字，避免無法返回
  const navigation = performance.getEntriesByType('navigation')[0];
  if (navigation?.type === 'back_forward') return;

  try {
    const { autoOpen = true } = await chrome.storage.local.get('autoOpen');
    if (!autoOpen) return;
  } catch {
    // 讀不到設定時採用預設（開啟）
  }

  chrome.runtime.sendMessage({ type: 'parchment:open-file', url: location.href });
})();
