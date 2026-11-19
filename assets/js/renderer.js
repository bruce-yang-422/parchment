/**
 * renderer.js — Markdown / TXT 渲染模組
 * 依賴本機 vendor 全域：window.ParchmentMarkdown, window.hljs, window.DOMPurify
 * （由 index.html 的本機 <script> 標籤載入）
 */

import { noteSyntaxPlugin, parseFrontmatter, frontmatterTags, renderPropertiesHtml } from './noteSyntax.js';

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

  // 筆記擴充語法；> [!type] 由 callout 規則處理（相容 GitHub 提示區塊）
  _markdown.use(noteSyntaxPlugin);

  _markdown.core.ruler.after('inline', 'tags-property', (state) => {
    for (let index = 0; index < state.tokens.length - 2; index += 1) {
      const opening = state.tokens[index];
      const inline = state.tokens[index + 1];
      const closing = state.tokens[index + 2];
      if (opening.type !== 'heading_open' || opening.tag !== 'h2'
        || inline.type !== 'inline' || closing.type !== 'heading_close') continue;

      const tags = _parseTagsProperty(inline.content);
      if (!tags) continue;

      opening.meta = { ...opening.meta, tagsProperty: true };
      closing.meta = { ...closing.meta, tagsProperty: true };
      const tagMarkup = new state.Token('html_inline', '', 0);
      tagMarkup.content = tags
        .map(tag => `<button type="button" class="metadata-tag" data-tag="${_escapeHtml(tag)}" aria-label="以標籤 ${_escapeHtml(tag)} 篩選文件">#${_escapeHtml(tag)}</button>`)
        .join('');
      inline.children = [tagMarkup];
    }
  });

  const defaultHeadingOpen = _markdown.renderer.rules.heading_open;
  const defaultHeadingClose = _markdown.renderer.rules.heading_close;
  _markdown.renderer.rules.heading_open = (tokens, index, options, env, self) => {
    if (tokens[index].meta?.tagsProperty) {
      return '<div class="metadata-property metadata-property-tags" role="group" aria-label="標籤">'
        + '<span class="metadata-property-key">tags</span>'
        + '<div class="metadata-property-value">';
    }
    return defaultHeadingOpen
      ? defaultHeadingOpen(tokens, index, options, env, self)
      : self.renderToken(tokens, index, options);
  };
  _markdown.renderer.rules.heading_close = (tokens, index, options, env, self) => {
    if (tokens[index].meta?.tagsProperty) return '</div></div>\n';
    return defaultHeadingClose
      ? defaultHeadingClose(tokens, index, options, env, self)
      : self.renderToken(tokens, index, options);
  };

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
export function renderMarkdown(content, { properties = true } = {}) {
  const { data, body } = parseFrontmatter(content);
  const propertiesHtml = properties
    ? renderPropertiesHtml(data, {
      renderInline: text => _markdown.renderInline(text),
      escapeHtml: _escapeHtml,
    })
    : '';
  const rawHtml = propertiesHtml + _markdown.render(body);
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

/** 將 `## tags: [標籤一, 標籤二]` 解析成標籤屬性。 */
function _parseTagsProperty(content) {
  const match = String(content).match(/^\s*tags\s*:\s*(.*?)\s*$/i);
  if (!match) return null;

  let value = match[1];
  if (value.startsWith('[') && value.endsWith(']')) value = value.slice(1, -1);

  const tags = value
    .split(/[,，]/)
    .map(tag => tag.trim().replace(/^(['"])(.*)\1$/, '$2').replace(/^#/, '').trim())
    .filter(Boolean);
  return tags.length ? tags : null;
}

/** 擷取 YAML Frontmatter 與 `## tags:` 屬性中的標籤，供資料夾標籤篩選使用。 */
export function extractMarkdownTags(content) {
  const tags = [];
  const seen = new Set();
  for (const tag of frontmatterTags(parseFrontmatter(content).data)) {
    const key = tag.toLocaleLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    tags.push(tag);
  }
  const pattern = /^##[\t ]+tags[\t ]*:[\t ]*(.*)$/gmi;
  for (const match of String(content).matchAll(pattern)) {
    for (const tag of _parseTagsProperty(`tags: ${match[1]}`) || []) {
      const key = tag.toLocaleLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      tags.push(tag);
    }
  }
  return tags;
}
