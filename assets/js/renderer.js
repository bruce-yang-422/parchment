/**
 * renderer.js — Markdown / TXT 渲染模組
 * 依賴本機 vendor 全域：window.ParchmentMarkdown, window.hljs, window.DOMPurify
 * （由 index.html 的本機 <script> 標籤載入）
 */

let _ready = false;
let _markdown = null;

/** 初始化 markdown-it 與完整語法插件，整合 highlight.js。 */
export function setupRenderer() {
  if (_ready) return;
  _ready = true;

  if (window.mermaid) {
    window.mermaid.initialize({
      startOnLoad: false,
      theme: 'neutral',
      xyChart: {
        yAxis: {
          showTitle: false,
          labelPadding: 10,
        },
      },
    });
  }

  _markdown = window.ParchmentMarkdown.create({
    highlight(code, language) {
      const validLang = language && window.hljs.getLanguage(language)
        ? language
        : 'plaintext';
      try {
        return window.hljs.highlight(code, { language: validLang }).value;
      } catch {
        return _escapeHtml(code);
      }
    },
  });

  const defaultFence = _markdown.renderer.rules.fence.bind(_markdown.renderer.rules);
  _markdown.renderer.rules.fence = (tokens, index, options, env, self) => {
    const token = tokens[index];
    const language = token.info.trim().split(/\s+/)[0].toLowerCase();
    if (language === 'mermaid') {
      return `<div class="mermaid" data-source="diagram">${_escapeHtml(token.content)}</div>\n`;
    }
    if (language === 'dot' || language === 'graphviz') {
      return `<div class="graphviz" data-source="diagram">${_escapeHtml(token.content)}</div>\n`;
    }
    return defaultFence(tokens, index, options, env, self);
  };
}

/**
 * 渲染 Markdown 內容
 * @param {string} content
 * @returns {string} 安全的 HTML 字串
 */
export function renderMarkdown(content) {
  const rawHtml = _markdown.render(content);
  return window.DOMPurify.sanitize(rawHtml, {
    USE_PROFILES: { html: true, svg: true, svgFilters: true, mathMl: true },
    ADD_ATTR: ['class', 'target'],
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

function _escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
