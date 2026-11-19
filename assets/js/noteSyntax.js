/**
 * noteSyntax.js — 筆記擴充語法（不依賴 DOM，可在 Node 測試）
 * - Wiki Links：[[筆記]]、[[筆記#標題|別名]]、[[#標題]]
 * - 內嵌：![[圖片.png|300]]、![[筆記]]、![[筆記#標題]]、![[筆記#^區塊]]
 * - Callouts：> [!note] 標題、> [!tip]- 可收合
 * - YAML Frontmatter：解析常見屬性並渲染為屬性區塊
 * - 依最短路徑規則解析筆記與附件路徑
 */

export const IMAGE_EXTENSIONS = /\.(?:png|jpe?g|gif|webp|svg|bmp|avif|ico)$/i;

/* ──────────────────── Wiki Link 解析 ──────────────────── */

/** 拆解 `筆記#標題|別名` 或 `筆記#^區塊`。 */
export function parseWikiTarget(raw) {
  const text = String(raw || '').trim();
  const pipe = text.indexOf('|');
  // 表格中常以 \| 跳脫別名分隔符號
  const linkPart = (pipe >= 0 ? text.slice(0, pipe) : text).replace(/\\$/, '').trim();
  const alias = pipe >= 0 ? text.slice(pipe + 1).trim() : '';
  const hashIndex = linkPart.indexOf('#');
  const target = (hashIndex >= 0 ? linkPart.slice(0, hashIndex) : linkPart).trim();
  const subpath = hashIndex >= 0 ? linkPart.slice(hashIndex + 1).trim() : '';

  let heading = '';
  let blockId = '';
  if (subpath.startsWith('^')) {
    blockId = subpath.slice(1).trim();
  } else if (subpath) {
    // 巢狀標題 [[筆記#章#節]] 以最後一段為準
    heading = subpath.split('#').map(part => part.trim()).filter(Boolean).at(-1) || '';
  }
  return { target, heading, blockId, alias };
}

/** Wiki Link 預設顯示文字。 */
export function wikiDisplayText({ target, heading, blockId, alias }) {
  if (alias) return alias;
  const name = target.split('/').at(-1).replace(/\.md$/i, '');
  if (heading) return name ? `${name} > ${heading}` : heading;
  if (blockId) return name ? `${name} > ^${blockId}` : `^${blockId}`;
  return name;
}

/**
 * 解析 Wiki 連結目標：
 * 1. 相對於來源筆記的路徑  2. 相對於根目錄的路徑  3. 全庫檔名比對（同資料夾優先，再取最短路徑）
 * @param {string} target
 * @param {string[]} sourcePath 來源文件路徑片段
 * @param {string[][]} filePaths 可供比對的檔案路徑
 * @param {{ markdown?: boolean }} options markdown：未寫副檔名時補上 .md
 * @returns {string[] | null}
 */
export function resolveWikiPath(target, sourcePath, filePaths, { markdown = false } = {}) {
  let value = String(target || '').trim().replace(/^\/+/, '');
  try { value = decodeURIComponent(value); } catch { /* 保留原字串 */ }
  if (!value) return null;

  const byKey = new Map();
  for (const path of filePaths) byKey.set(_key(path), path);

  const variants = [value];
  if (markdown && !/\.[a-z0-9]{1,8}$/i.test(value)) variants.unshift(`${value}.md`);

  const sourceDirectory = (sourcePath || []).slice(0, -1);
  for (const variant of variants) {
    const parts = variant.split('/');
    for (const candidate of [[...sourceDirectory, ...parts], parts]) {
      const normalized = _normalize(candidate);
      if (!normalized) continue;
      const found = byKey.get(_key(normalized));
      if (found) return found;
    }
  }

  for (const variant of variants) {
    const suffix = _normalize(variant.split('/'));
    if (!suffix?.length) continue;
    const suffixKey = _key(suffix);
    const matches = filePaths.filter(path => {
      if (path.length < suffix.length) return false;
      return _key(path.slice(path.length - suffix.length)) === suffixKey;
    });
    if (!matches.length) continue;
    const sourceDirKey = _key(sourceDirectory);
    matches.sort((a, b) => {
      const aSame = _key(a.slice(0, -1)) === sourceDirKey ? 0 : 1;
      const bSame = _key(b.slice(0, -1)) === sourceDirKey ? 0 : 1;
      return aSame - bSame || a.length - b.length || _key(a).localeCompare(_key(b));
    });
    return matches[0];
  }
  return null;
}

function _normalize(parts) {
  const output = [];
  for (const raw of parts) {
    const part = String(raw).trim();
    if (!part || part === '.') continue;
    if (part === '..') {
      if (!output.length) return null;
      output.pop();
    } else {
      output.push(part);
    }
  }
  return output;
}

function _key(path) {
  return path.join('/').toLocaleLowerCase();
}

/* ──────────────────── 段落擷取（內嵌筆記） ──────────────────── */

/**
 * 擷取標題段落（含標題，至下一個同級或更高級標題為止）或 ^區塊。
 * 未指定時回傳全文；找不到時回傳 null。
 */
export function extractNoteSection(markdown, { heading = '', blockId = '' } = {}) {
  const body = parseFrontmatter(markdown).body;
  if (!heading && !blockId) return body;
  const lines = body.split(/\r?\n/);

  if (heading) {
    const wanted = _headingKey(heading);
    let fence = null;
    let start = -1;
    let level = 0;
    for (let index = 0; index < lines.length; index += 1) {
      const line = lines[index];
      const fenceMatch = line.match(/^\s{0,3}(`{3,}|~{3,})/);
      if (fenceMatch) {
        if (!fence) fence = fenceMatch[1][0];
        else if (fenceMatch[1][0] === fence) fence = null;
        continue;
      }
      if (fence) continue;
      const match = line.match(/^\s{0,3}(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$/);
      if (!match) continue;
      if (start < 0) {
        if (_headingKey(match[2]) === wanted) {
          start = index;
          level = match[1].length;
        }
      } else if (match[1].length <= level) {
        return lines.slice(start, index).join('\n').trimEnd();
      }
    }
    return start >= 0 ? lines.slice(start).join('\n').trimEnd() : null;
  }

  const marker = new RegExp(`(?:^|\\s)\\^${_escapeRegExp(blockId)}\\s*$`);
  const index = lines.findIndex(line => marker.test(line));
  if (index < 0) return null;
  const strip = line => line.replace(marker, '').trimEnd();
  if (/^\s*(?:[-*+]|\d+[.)])\s/.test(lines[index])) return strip(lines[index]);
  // 段落以空行、標題、清單項目或程式碼圍欄為界
  const isBoundary = line => !line.trim()
    || /^\s{0,3}(?:#{1,6}[ \t]|`{3,}|~{3,}|[-*+][ \t]|\d+[.)][ \t])/.test(line);
  let start = index;
  let end = index;
  while (start > 0 && !isBoundary(lines[start - 1])) start -= 1;
  while (end < lines.length - 1 && !isBoundary(lines[end + 1])) end += 1;
  return lines.slice(start, end + 1).map(strip).join('\n');
}

function _headingKey(text) {
  return String(text)
    .replace(/\[\[([^\]|]*\|)?([^\]]*)\]\]/g, '$2')
    .replace(/[*_`~=]/g, '')
    .trim()
    .toLocaleLowerCase()
    .normalize('NFKC');
}

function _escapeRegExp(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/* ──────────────────── YAML Frontmatter ──────────────────── */

const FRONTMATTER = /^﻿?---[ \t]*\r?\n(?:([\s\S]*?)\r?\n)?(?:---|\.\.\.)[ \t]*(?:\r?\n|$)/;

/** 拆出 YAML Frontmatter；回傳 { data, body }，沒有時 data 為 null。 */
export function parseFrontmatter(source) {
  const text = String(source ?? '');
  const match = text.match(FRONTMATTER);
  if (!match) return { data: null, body: text };
  return { data: parseYamlSubset(match[1] || ''), body: text.slice(match[0].length) };
}

/**
 * 解析筆記屬性常用的 YAML 子集：純量、引號字串、行內陣列、
 * 區塊清單與 | / > 多行字串。巢狀物件保留原始文字。
 */
export function parseYamlSubset(raw) {
  const data = {};
  const lines = String(raw).split(/\r?\n/);
  let index = 0;

  while (index < lines.length) {
    const line = lines[index];
    if (!line.trim() || /^\s*#/.test(line) || /^\s/.test(line)) { index += 1; continue; }

    const match = line.match(/^([^:#][^:]*?)[ \t]*:(?:[ \t]+(.*?))?[ \t]*$/);
    if (!match) { index += 1; continue; }
    const key = _unquote(match[1].trim());
    const value = match[2] ?? '';
    index += 1;

    const block = [];
    while (index < lines.length && (!lines[index].trim() || /^\s/.test(lines[index]) || /^-(\s|$)/.test(lines[index]))) {
      block.push(lines[index]);
      index += 1;
    }
    while (block.length && !block.at(-1).trim()) block.pop();

    if (/^[|>][+-]?\d*$/.test(value)) {
      const content = _dedent(block);
      data[key] = value.startsWith('|') ? content.join('\n') : content.join(' ').replace(/\s+/g, ' ').trim();
    } else if (value) {
      data[key] = _parseScalarOrFlow(value);
    } else if (block.length && block.every(l => !l.trim() || /^\s*-(\s|$)/.test(l))) {
      data[key] = block.filter(l => l.trim()).map(l => _parseScalar(l.replace(/^\s*-\s?/, '')));
    } else if (block.length) {
      data[key] = _dedent(block).join('\n');
    } else {
      data[key] = null;
    }
  }
  return data;
}

function _dedent(lines) {
  const indents = lines.filter(line => line.trim()).map(line => line.match(/^\s*/)[0].length);
  const indent = indents.length ? Math.min(...indents) : 0;
  return lines.map(line => line.slice(indent));
}

function _parseScalarOrFlow(value) {
  const trimmed = value.trim();
  if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
    return _splitFlow(trimmed.slice(1, -1)).map(_parseScalar).filter(item => item !== '');
  }
  return _parseScalar(trimmed);
}

function _splitFlow(text) {
  const items = [];
  let current = '';
  let quote = null;
  let depth = 0;
  for (const char of text) {
    if (quote) {
      current += char;
      if (char === quote) quote = null;
    } else if (char === '"' || char === "'") {
      quote = char;
      current += char;
    } else if (char === '[') {
      depth += 1;
      current += char;
    } else if (char === ']') {
      depth -= 1;
      current += char;
    } else if (char === ',' && depth === 0) {
      items.push(current);
      current = '';
    } else {
      current += char;
    }
  }
  if (current.trim()) items.push(current);
  return items;
}

function _parseScalar(value) {
  const text = String(value).trim();
  if (!text || text === '~' || text === 'null') return text === '' ? '' : null;
  if (/^"(?:[^"\\]|\\.)*"$/.test(text)) {
    return text.slice(1, -1).replace(/\\(.)/g, (_, c) => ({ n: '\n', t: '\t' }[c] ?? c));
  }
  if (/^'(?:[^']|'')*'$/.test(text)) return text.slice(1, -1).replace(/''/g, "'");
  // 未加引號時移除行尾註解
  return text.replace(/\s+#.*$/, '');
}

function _unquote(text) {
  return /^(["']).*\1$/.test(text) ? text.slice(1, -1) : text;
}

/** 由 Frontmatter 取出標籤（tags / tag，支援陣列或以逗號、空白分隔的字串）。 */
export function frontmatterTags(data) {
  if (!data) return [];
  const raw = data.tags ?? data.tag ?? data.Tags ?? null;
  const values = Array.isArray(raw) ? raw : raw == null ? [] : String(raw).split(/[,，\s]+/);
  return values
    .map(tag => String(tag ?? '').trim().replace(/^#/, ''))
    .filter(Boolean);
}

/** 由 Frontmatter 取出別名（aliases / alias）。 */
export function frontmatterAliases(data) {
  if (!data) return [];
  const raw = data.aliases ?? data.alias ?? null;
  const values = Array.isArray(raw) ? raw : raw == null ? [] : String(raw).split(/[,，]/);
  return values.map(value => String(value ?? '').trim()).filter(Boolean);
}

/* ──────────────────── Callouts ──────────────────── */

const CALLOUT_ALIASES = {
  summary: 'abstract', tldr: 'abstract',
  hint: 'tip', important: 'tip',
  check: 'success', done: 'success',
  help: 'question', faq: 'question',
  caution: 'warning', attention: 'warning',
  fail: 'failure', missing: 'failure',
  error: 'danger',
  cite: 'quote',
};
const CALLOUT_TYPES = new Set([
  'note', 'abstract', 'info', 'todo', 'tip', 'success', 'question',
  'warning', 'failure', 'danger', 'bug', 'example', 'quote',
]);

export function calloutCategory(type) {
  const value = String(type || '').toLowerCase();
  const canonical = CALLOUT_ALIASES[value] || value;
  return CALLOUT_TYPES.has(canonical) ? canonical : 'note';
}

/* ──────────────────── markdown-it 外掛 ──────────────────── */

/**
 * 註冊 Wiki Link、內嵌、Callouts 與 ^區塊標記隱藏。
 * @param {import('markdown-it')} md
 */
export function noteSyntaxPlugin(md) {
  md.inline.ruler.before('link', 'wikilink', (state, silent) => {
    const { src } = state;
    const embed = src.charCodeAt(state.pos) === 0x21; // !
    const start = embed ? state.pos + 1 : state.pos;
    if (src.charCodeAt(start) !== 0x5B || src.charCodeAt(start + 1) !== 0x5B) return false;
    const end = src.indexOf(']]', start + 2);
    if (end < 0) return false;
    const inner = src.slice(start + 2, end);
    if (!inner.trim() || /[\n[]/.test(inner)) return false;

    if (!silent) {
      const token = state.push(embed ? 'wiki_embed' : 'wikilink', '', 0);
      token.meta = parseWikiTarget(inner);
      token.content = inner;
    }
    state.pos = end + 2;
    return true;
  });

  md.renderer.rules.wikilink = (tokens, index) => {
    const meta = tokens[index].meta;
    return _wikiLinkHtml(meta, md.utils.escapeHtml);
  };

  md.renderer.rules.wiki_embed = (tokens, index) => {
    const meta = tokens[index].meta;
    const esc = md.utils.escapeHtml;
    if (!meta.target && !meta.heading && !meta.blockId) return esc(`![[${tokens[index].content}]]`);

    if (IMAGE_EXTENSIONS.test(meta.target)) {
      const size = meta.alias.match(/^(\d+)(?:x(\d+))?$/);
      const alt = size ? meta.target.split('/').at(-1) : (meta.alias || meta.target.split('/').at(-1));
      const width = size ? ` width="${size[1]}"` : '';
      const height = size?.[2] ? ` height="${size[2]}"` : '';
      return `<img class="wiki-embed-image" data-wiki-embed="${esc(meta.target)}" alt="${esc(alt)}"${width}${height}>`;
    }

    if (/\.[a-z0-9]{1,8}$/i.test(meta.target) && !/\.(?:md|txt)$/i.test(meta.target)) {
      // 不支援內嵌的附件（PDF、音訊等）改以連結呈現
      return _wikiLinkHtml(meta, esc);
    }

    return `<span class="note-embed-placeholder" data-wiki-target="${esc(meta.target)}"`
      + ` data-wiki-heading="${esc(meta.heading)}" data-wiki-block="${esc(meta.blockId)}">`
      + `${esc(wikiDisplayText(meta))}</span>`;
  };

  md.core.ruler.after('block', 'callout', state => _transformCallouts(state, md));
  md.core.ruler.after('block', 'block_id', state => {
    for (const token of state.tokens) {
      if (token.type === 'inline') {
        token.content = token.content.replace(/[ \t]\^[A-Za-z0-9-]+[ \t]*(?=\n|$)/g, '');
      }
    }
  });
}

function _wikiLinkHtml(meta, esc) {
  const text = wikiDisplayText(meta) || meta.target;
  const href = meta.target
    ? encodeURI(meta.target) + (meta.heading ? `#${encodeURIComponent(meta.heading)}` : '')
    : `#${encodeURIComponent(meta.heading)}`;
  return `<a class="wiki-link" href="${esc(href)}" data-wiki-target="${esc(meta.target)}"`
    + ` data-wiki-heading="${esc(meta.heading)}" data-wiki-block="${esc(meta.blockId)}">${esc(text)}</a>`;
}

function _transformCallouts(state, md) {
  const tokens = state.tokens;
  for (let index = 0; index < tokens.length; index += 1) {
    if (tokens[index].type !== 'blockquote_open') continue;
    const paragraph = tokens[index + 1];
    const inline = tokens[index + 2];
    if (paragraph?.type !== 'paragraph_open' || inline?.type !== 'inline') continue;

    const match = inline.content.match(/^\[!([^\]\s]+)\]([+-]?)(?:[ \t]+([^\n]*))?[ \t]*(?:\n|$)/);
    if (!match) continue;

    let depth = 0;
    let closeIndex = -1;
    for (let cursor = index; cursor < tokens.length; cursor += 1) {
      if (tokens[cursor].type === 'blockquote_open') depth += 1;
      else if (tokens[cursor].type === 'blockquote_close' && --depth === 0) { closeIndex = cursor; break; }
    }
    if (closeIndex < 0) continue;

    const rawType = match[1].toLowerCase();
    const category = calloutCategory(rawType);
    const fold = match[2];
    const titleText = match[3]?.trim() || rawType.charAt(0).toUpperCase() + rawType.slice(1);
    const titleHtml = md.renderInline(titleText, state.env);
    const esc = md.utils.escapeHtml;
    const attrs = `class="callout" data-callout="${esc(category)}" data-callout-type="${esc(rawType)}"`;
    const titleInner = `<span class="callout-icon" aria-hidden="true"></span><span class="callout-title-inner">${titleHtml}</span>`;

    const open = new state.Token('html_block', '', 0);
    const close = new state.Token('html_block', '', 0);
    if (fold) {
      open.content = `<details ${attrs}${fold === '+' ? ' open' : ''}><summary class="callout-title">${titleInner}</summary><div class="callout-content">\n`;
      close.content = '</div></details>\n';
    } else {
      open.content = `<div ${attrs}><div class="callout-title">${titleInner}</div><div class="callout-content">\n`;
      close.content = '</div></div>\n';
    }
    open.block = true;
    close.block = true;

    tokens[closeIndex] = close;
    const rest = inline.content.slice(match[0].length);
    if (rest.trim()) {
      inline.content = rest;
      tokens[index] = open;
    } else {
      // 只有標題列：移除空段落
      tokens.splice(index, 4, open);
    }
  }
}

/* ──────────────────── 屬性區塊 HTML ──────────────────── */

/**
 * 將 Frontmatter 渲染為屬性區塊。
 * @param {object | null} data
 * @param {{ renderInline: (text: string) => string, escapeHtml: (text: string) => string }} helpers
 */
export function renderPropertiesHtml(data, { renderInline, escapeHtml }) {
  if (!data) return '';
  const keys = Object.keys(data);
  if (!keys.length) return '';

  const rows = keys.map(key => {
    const value = data[key];
    const lower = key.toLowerCase();
    let valueHtml;
    if (lower === 'tags' || lower === 'tag') {
      const tags = frontmatterTags({ tags: value });
      valueHtml = tags.length
        ? tags.map(tag => `<button type="button" class="metadata-tag" data-tag="${escapeHtml(tag)}" aria-label="以標籤 ${escapeHtml(tag)} 篩選文件">#${escapeHtml(tag)}</button>`).join('')
        : '<span class="metadata-empty">—</span>';
    } else if (Array.isArray(value)) {
      valueHtml = value.length
        ? value.map(item => `<span class="metadata-chip">${renderInline(String(item ?? ''))}</span>`).join('')
        : '<span class="metadata-empty">—</span>';
    } else if (value === null || value === '') {
      valueHtml = '<span class="metadata-empty">—</span>';
    } else if (/^(true|false)$/i.test(String(value))) {
      valueHtml = `<input type="checkbox" disabled${/^true$/i.test(String(value)) ? ' checked' : ''} aria-label="${escapeHtml(key)}">`;
    } else if (String(value).includes('\n')) {
      valueHtml = `<span class="metadata-text metadata-multiline">${escapeHtml(String(value))}</span>`;
    } else {
      valueHtml = `<span class="metadata-text">${renderInline(String(value))}</span>`;
    }
    return `<div class="metadata-property" data-property="${escapeHtml(key)}">`
      + `<span class="metadata-property-key">${escapeHtml(key)}</span>`
      + `<div class="metadata-property-value">${valueHtml}</div></div>`;
  });

  return `<div class="metadata-properties" role="group" aria-label="筆記屬性">${rows.join('')}</div>\n`;
}
