/**
 * renderer.js — Markdown / TXT 渲染模組
 * 依賴全域變數：window.marked, window.hljs, window.DOMPurify
 * （由 index.html 的 CDN <script> 標籤載入）
 */

let _ready = false;

/** 初始化 marked，整合 highlight.js 語法高亮 */
export function setupRenderer() {
  if (_ready) return;
  _ready = true;

  window.marked.use({
    gfm: true,
    breaks: false,
    renderer: {
      /**
       * 程式碼區塊渲染
       * marked v12 傳入 token 物件 { text, lang }
       * 相容舊版（傳入 string）
       */
      code(tokenOrCode, maybeLanguage) {
        const text = _isObj(tokenOrCode) ? (tokenOrCode.text ?? '') : (tokenOrCode ?? '');
        const lang = _isObj(tokenOrCode) ? tokenOrCode.lang : maybeLanguage;

        const validLang = lang && window.hljs.getLanguage(lang) ? lang : 'plaintext';
        let highlighted;
        try {
          highlighted = window.hljs.highlight(text, { language: validLang }).value;
        } catch {
          highlighted = _escapeHtml(text);
        }

        return `<pre><code class="hljs language-${validLang}">${highlighted}</code></pre>\n`;
      },
    },
  });
}

/**
 * 渲染 Markdown 內容
 * @param {string} content
 * @returns {string} 安全的 HTML 字串
 */
export function renderMarkdown(content) {
  const rawHtml = window.marked.parse(content);
  return window.DOMPurify.sanitize(rawHtml, {
    USE_PROFILES: { html: true },
    ADD_ATTR: ['class'],   // 保留 hljs class
  });
}

/**
 * 渲染純文字（.txt）
 * @param {string} content
 * @returns {string} HTML 字串
 */
export function renderText(content) {
  return `<pre class="txt-view">${_escapeHtml(content)}</pre>`;
}

/* ──────────────────── Helpers ──────────────────── */

function _isObj(v) {
  return typeof v === 'object' && v !== null;
}

function _escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
