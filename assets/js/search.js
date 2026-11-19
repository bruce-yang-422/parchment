/**
 * search.js — 資料夾全文搜尋（不依賴 DOM）
 * 以空白分隔多個關鍵字，所有關鍵字都需出現在檔名或內容中（不分大小寫）。
 * 以 "..." 包住的片語視為單一關鍵字。
 */

/** 將查詢字串拆成關鍵字。 */
export function parseQuery(query) {
  const terms = [];
  for (const match of String(query || '').matchAll(/"([^"]+)"|(\S+)/g)) {
    const term = (match[1] ?? match[2]).trim();
    if (term) terms.push(term);
  }
  return [...new Set(terms.map(term => term.toLocaleLowerCase()))];
}

/**
 * @param {Iterable<{ key: string, entry: { name: string, path: string[] }, content: string }>} records
 * @param {string} query
 * @param {{ limit?: number, snippetRadius?: number }} options
 * @returns {{ terms: string[], total: number, results: Array<{ record, score: number, matchCount: number, snippet: { text: string, ranges: [number, number][] } }> }}
 */
export function searchDocuments(records, query, { limit = 100, snippetRadius = 60 } = {}) {
  const terms = parseQuery(query);
  if (!terms.length) return { terms, total: 0, results: [] };

  const results = [];
  for (const record of records) {
    const name = record.entry.name.toLocaleLowerCase();
    const pathText = record.entry.path.join('/').toLocaleLowerCase();
    const content = String(record.content || '');
    const lower = content.toLocaleLowerCase();

    let score = 0;
    let matchCount = 0;
    let firstIndex = -1;
    let matchedAll = true;
    for (const term of terms) {
      const inName = name.includes(term);
      const inPath = !inName && pathText.includes(term);
      const count = _countOccurrences(lower, term, 200);
      if (!inName && !inPath && !count) { matchedAll = false; break; }
      score += (inName ? 20 : 0) + (inPath ? 5 : 0) + Math.min(count, 20);
      matchCount += count;
      const index = lower.indexOf(term);
      if (index >= 0 && (firstIndex < 0 || index < firstIndex)) firstIndex = index;
    }
    if (!matchedAll) continue;

    results.push({
      record,
      score,
      matchCount,
      snippet: buildSnippet(content, terms, firstIndex, snippetRadius),
    });
  }

  results.sort((a, b) => b.score - a.score
    || a.record.entry.name.localeCompare(b.record.entry.name, undefined, { sensitivity: 'base' }));
  return { terms, total: results.length, results: results.slice(0, limit) };
}

/** 擷取關鍵字附近的文字，並回傳要標示的範圍。 */
export function buildSnippet(content, terms, index, radius = 60) {
  const text = String(content || '');
  if (index < 0) {
    const head = _collapse(text.slice(0, radius * 2));
    return { text: head + (text.length > radius * 2 ? '…' : ''), ranges: [] };
  }

  let start = Math.max(0, index - radius);
  let end = Math.min(text.length, index + radius * 2);
  // 盡量從行首或詞界開始
  const lineStart = text.lastIndexOf('\n', index);
  if (lineStart >= start) start = lineStart + 1;

  const raw = text.slice(start, end);
  const prefix = start > 0 ? '…' : '';
  const suffix = end < text.length ? '…' : '';
  const body = _collapse(raw);
  const snippet = prefix + body + suffix;

  const ranges = [];
  const lower = snippet.toLocaleLowerCase();
  for (const term of terms) {
    let from = 0;
    let found;
    while ((found = lower.indexOf(term, from)) >= 0) {
      ranges.push([found, found + term.length]);
      from = found + term.length;
    }
  }
  return { text: snippet, ranges: _mergeRanges(ranges) };
}

function _collapse(text) {
  return text.replace(/\s+/g, ' ').trim();
}

function _countOccurrences(text, term, max) {
  let count = 0;
  let from = 0;
  let found;
  while (count < max && (found = text.indexOf(term, from)) >= 0) {
    count += 1;
    from = found + term.length;
  }
  return count;
}

function _mergeRanges(ranges) {
  ranges.sort((a, b) => a[0] - b[0]);
  const merged = [];
  for (const range of ranges) {
    const last = merged.at(-1);
    if (last && range[0] <= last[1]) last[1] = Math.max(last[1], range[1]);
    else merged.push([...range]);
  }
  return merged;
}
