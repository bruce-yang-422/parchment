/**
 * boot.js — 在樣式套用前還原配色、閱讀寬度與深色模式，避免載入時閃爍。
 * 以一般（非 module）腳本同步載入；完整邏輯見 theme.js 與 readerWidth.js。
 * 獨立成檔案而非內嵌，以符合瀏覽器外掛的內容安全政策（CSP）。
 */
(function () {
  try {
    var root = document.documentElement;
    var palette = localStorage.getItem('parchment-palette');
    if (palette) root.dataset.palette = palette;
    var readerWidth = localStorage.getItem('parchment-reader-width');
    if (readerWidth) root.dataset.readerWidth = readerWidth;
    var theme = localStorage.getItem('parchment-theme') || 'system';
    if (theme === 'dark' || (theme === 'system' && matchMedia('(prefers-color-scheme: dark)').matches)) {
      root.classList.add('dark');
    }
  } catch (error) { /* 使用預設外觀 */ }
})();
