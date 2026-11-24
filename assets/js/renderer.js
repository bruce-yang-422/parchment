/**
 * renderer.js — Markdown / TXT 渲染模組
 * 依賴本機 vendor 全域：window.ParchmentMarkdown, window.hljs, window.DOMPurify
 * （由 index.html 的本機 <script> 標籤載入）
 */

import { noteSyntaxPlugin, parseFrontmatter, frontmatterTags, renderPropertiesHtml, wikiDisplayText } from './noteSyntax.js';
import { t } from './i18n.js';

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
        .map(tag => `<button type="button" class="metadata-tag" data-tag="${_escapeHtml(tag)}" aria-label="${_escapeHtml(t('以標籤 {tag} 篩選文件', { tag }))}">#${_escapeHtml(tag)}</button>`)
        .join('');
      inline.children = [tagMarkup];
    }
  });

  const defaultHeadingOpen = _markdown.renderer.rules.heading_open;
  const defaultHeadingClose = _markdown.renderer.rules.heading_close;
  _markdown.renderer.rules.heading_open = (tokens, index, options, env, self) => {
    if (tokens[index].meta?.tagsProperty) {
      return `<div class="metadata-property metadata-property-tags" role="group" aria-label="${_escapeHtml(t('標籤'))}">`
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
    const rendered = defaultFence(tokens, index, options, env, self);
    if (!token.content) return rendered;
    const count = token.content.replace(/\n$/, '').split('\n').length;
    const lineNumbers = Array.from({ length: count }, (_, i) => i + 1).join('\n');
    // Generated content in a separate gutter keeps the highlighted source intact.
    const gutter = `<span class="code-line-numbers" aria-hidden="true" data-lines="${lineNumbers}"></span>`;
    return rendered.replace(/^<pre>/, `<pre class="numberable-code">${gutter}`);
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

/** Count prose, treating each CJK character as a word as in the mobile reader. */
export function countDocumentWords(content, { markdown = false } = {}) {
  const text = markdown ? _markdown.parse(parseFrontmatter(content).body, {})
    .map(token => {
      if (token.type === 'html_block') return token.content.replace(/<[^>]+>/g, ' ');
      if (token.type !== 'inline') return '';
      return token.children.map(part => {
        if (part.type === 'text' || part.type === 'image') return part.content;
        if (part.type === 'wikilink') return wikiDisplayText(part.meta);
        return ['softbreak', 'hardbreak', 'code_inline', 'wiki_embed'].includes(part.type) ? ' ' : '';
      }).join('');
    }).join('\n').replace(/https?:\/\/\S+/gi, ' ') : content;

  let cjk = 0;
  const words = text.replace(/[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}]/gu, () => {
    cjk += 1;
    return ' ';
  });
  return cjk + (words.match(/[\p{Letter}\p{Number}][\p{Letter}\p{Number}\p{Mark}]*(?:['’][\p{Letter}\p{Mark}]+)*/gu)?.length ?? 0);
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
