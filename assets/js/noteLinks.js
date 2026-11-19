import { extractMarkdownTags } from './renderer.js';

/** 擷取一般 Markdown 連結與 Obsidian Wiki Links（排除圖片與頁內錨點）。 */
export function extractDocumentLinks(markdown) {
  const links = [];
  const seen = new Set();
  const source = String(markdown || '');

  const add = (href, label, syntax) => {
    const normalizedHref = href.trim();
    if (!normalizedHref || normalizedHref.startsWith('#')) return;
    const key = normalizedHref;
    if (seen.has(key)) return;
    seen.add(key);
    links.push({ href: normalizedHref, label: label.trim() || normalizedHref, syntax });
  };

  for (const match of source.matchAll(/(^|[^!])\[([^\]]+)\]\(([^)\s]+)(?:\s+["'][^"']*["'])?\)/gm)) {
    add(match[3], match[2], 'markdown');
  }
  for (const match of source.matchAll(/(^|[^!])\[\[([^\]]+)\]\]/gm)) {
    const [target, alias] = match[2].split('|', 2);
    add(target, alias || target.replace(/^.*\//, '').replace(/#.*$/, ''), 'wiki');
  }
  for (const match of source.matchAll(/https?:\/\/[^\s<>()\[\]"']+/g)) {
    const href = match[0].replace(/[.,;:!?，。；：！？]+$/u, '');
    add(href, href, 'url');
  }
  return links;
}

export function isExternalLink(href) {
  return /^(?:https?:|mailto:|tel:)/i.test(href);
}

/** 建立資料夾內的筆記索引，供標籤、連結筆記及雙向連結共用。 */
export async function buildDocumentIndex(entries) {
  const files = [];
  const collect = items => items.forEach(entry => {
    if (entry.type === 'dir') collect(entry.children);
    else if (/\.md$/i.test(entry.name)) files.push(entry);
  });
  collect(entries);

  const records = new Map();
  const tags = new Map();
  let cursor = 0;
  const worker = async () => {
    while (cursor < files.length) {
      const entry = files[cursor++];
      try {
        const content = await (await entry.handle.getFile()).text();
        const key = pathKey(entry.path);
        const record = {
          key,
          entry,
          content,
          tags: extractMarkdownTags(content),
          links: extractDocumentLinks(content),
        };
        records.set(key, record);
        record.tags.forEach(tag => {
          const normalized = normalizeTag(tag);
          if (!tags.has(normalized)) tags.set(normalized, new Set());
          tags.get(normalized).add(key);
        });
      } catch (error) {
        console.warn(`無法建立筆記索引：${entry.path.join('/')}`, error);
      }
    }
  };

  await Promise.all(Array.from({ length: Math.min(8, files.length) }, worker));
  return { records, tags };
}

/** 解析目前筆記連到的內部筆記，以及連入目前筆記的雙向連結。 */
export function getDocumentRelations(index, currentPath) {
  const currentKey = pathKey(currentPath);
  const current = index.records.get(currentKey);
  if (!current) return { linkedNotes: [], backlinks: [] };

  const lookup = _buildLookup(index.records);
  const linkedNotes = [];
  const linkedKeys = new Set();
  current.links.forEach(link => {
    if (isExternalLink(link.href)) return;
    const target = _resolveLink(current, link, index.records, lookup);
    if (!target || linkedKeys.has(target.key)) return;
    linkedKeys.add(target.key);
    linkedNotes.push(target);
  });

  const backlinks = [];
  for (const record of index.records.values()) {
    if (record.key === currentKey) continue;
    const matchingLinks = record.links.filter(link => {
      if (isExternalLink(link.href)) return false;
      return _resolveLink(record, link, index.records, lookup)?.key === currentKey;
    });
    if (matchingLinks.length) backlinks.push({ record, links: matchingLinks });
  }

  backlinks.sort((a, b) => a.record.entry.name.localeCompare(b.record.entry.name, undefined, { sensitivity: 'base' }));
  return { linkedNotes, backlinks };
}

export function pathKey(path) {
  return path.join('/').toLocaleLowerCase();
}

export function normalizeTag(tag) {
  return String(tag || '').trim().replace(/^#/, '').toLocaleLowerCase();
}

function _buildLookup(records) {
  const byStem = new Map();
  for (const record of records.values()) {
    const filename = record.entry.name.replace(/\.md$/i, '').toLocaleLowerCase();
    if (!byStem.has(filename)) byStem.set(filename, []);
    byStem.get(filename).push(record);
  }
  return { byStem };
}

function _resolveLink(source, link, records, lookup) {
  let href = link.href.split('#', 1)[0].trim();
  try { href = decodeURIComponent(href); } catch { /* 保留原字串 */ }
  if (!href) return source;

  const sourceDirectory = source.entry.path.slice(0, -1);
  const appendMarkdown = value => /\.[a-z0-9]+$/i.test(value) ? value : `${value}.md`;
  const candidates = [];
  if (link.syntax === 'wiki') {
    candidates.push([...sourceDirectory, ...appendMarkdown(href).split('/')]);
    candidates.push(appendMarkdown(href).split('/'));
  } else {
    candidates.push([...sourceDirectory, ...href.split('/')]);
  }

  for (const candidate of candidates) {
    const normalized = _normalizePath(candidate);
    const record = records.get(pathKey(normalized));
    if (record) return record;
  }

  if (link.syntax === 'wiki') {
    const stem = href.split('/').at(-1).replace(/\.md$/i, '').toLocaleLowerCase();
    const matches = lookup.byStem.get(stem) || [];
    if (matches.length === 1) return matches[0];
  }
  return null;
}

function _normalizePath(parts) {
  const output = [];
  for (const rawPart of parts) {
    const part = String(rawPart).trim();
    if (!part || part === '.') continue;
    if (part === '..') output.pop();
    else output.push(part);
  }
  return output;
}
