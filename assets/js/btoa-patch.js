/**
 * btoa-patch.js — 讓 window.btoa 接受非 Latin-1 字元（Mermaid 以 btoa 編碼含中文的 SVG）。
 * 必須在 mermaid.min.js 之前以一般腳本載入。
 */
(function () {
  const nativeBtoa = window.btoa.bind(window);
  window.btoa = function patchedBtoa(value) {
    try {
      return nativeBtoa(value);
    } catch (err) {
      if (!(err instanceof DOMException)) throw err;

      const bytes = new TextEncoder().encode(String(value));
      let binary = '';
      for (const byte of bytes) binary += String.fromCharCode(byte);
      return nativeBtoa(binary);
    }
  };
})();
