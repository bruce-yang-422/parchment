/**
 * searchPanel.js — 左側欄全文搜尋介面
 */

import { searchDocuments } from './search.js';

const RESULT_LIMIT = 100;

/**
 * @param {{
 *   input: HTMLInputElement,
 *   status: HTMLElement,
 *   results: HTMLElement,
 *   tree: HTMLElement,
 *   getIndex: () => Promise<{ records: Map }> | null,
 *   onOpen: (entry: object, terms: string[]) => void,
 * }} options
 */
export function initSearchPanel({ input, status, results, tree, getIndex, onOpen }) {
  let timer = null;
  let generation = 0;

  const showTree = () => {
    results.hidden = true;
    results.innerHTML = '';
    tree.hidden = false;
    status.hidden = true;
    status.textContent = '';
  };

  const run = async () => {
    const query = input.value.trim();
    const current = ++generation;
    if (!query) { showTree(); return; }

    const indexPromise = getIndex();
    if (!indexPromise) return;

    tree.hidden = true;
    results.hidden = false;
    status.hidden = false;
    status.textContent = '搜尋中…';

    try {
      const index = await indexPromise;
      if (current !== generation) return;
      const { terms, total, results: matches } = searchDocuments(index.records.values(), query, { limit: RESULT_LIMIT });
      status.textContent = total
        ? `${total} 個文件${total > RESULT_LIMIT ? `（顯示前 ${RESULT_LIMIT} 個）` : ''}`
        : '沒有符合的文件';
      _renderResults(results, matches, terms, onOpen);
    } catch (error) {
      if (current !== generation) return;
      status.textContent = `無法搜尋：${error.message}`;
      results.innerHTML = '';
    }
  };

  input.addEventListener('input', () => {
    clearTimeout(timer);
    timer = setTimeout(run, 180);
  });
  input.addEventListener('keydown', event => {
    if (event.key === 'Escape' && input.value) {
      event.preventDefault();
      event.stopPropagation();
      input.value = '';
      run();
    } else if (event.key === 'Enter') {
      event.preventDefault();
      clearTimeout(timer);
      run().then(() => results.querySelector('.search-result')?.focus());
    } else if (event.key === 'ArrowDown') {
      event.preventDefault();
      results.querySelector('.search-result')?.focus();
    }
  });
  results.addEventListener('keydown', event => {
    if (!['ArrowDown', 'ArrowUp'].includes(event.key)) return;
    const items = [...results.querySelectorAll('.search-result')];
    const index = items.indexOf(document.activeElement);
    if (index < 0) return;
    event.preventDefault();
    if (event.key === 'ArrowUp' && index === 0) input.focus();
    else items[Math.min(items.length - 1, Math.max(0, index + (event.key === 'ArrowDown' ? 1 : -1)))].focus();
  });

  return {
    focus() {
      input.focus();
      input.select();
    },
    /** 換資料夾或離開資料夾模式時清空搜尋。 */
    reset() {
      clearTimeout(timer);
      generation += 1;
      input.value = '';
      showTree();
    },
    /** 索引更新（例如檔案熱更新）後重新搜尋。 */
    refresh() {
      if (input.value.trim()) run();
    },
    get active() {
      return Boolean(input.value.trim());
    },
  };
}

function _renderResults(container, matches, terms, onOpen) {
  container.innerHTML = '';
  const fragment = document.createDocumentFragment();
  for (const match of matches) {
    const { entry } = match.record;
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'search-result';

    const title = document.createElement('span');
    title.className = 'search-result-title';
    _appendHighlighted(title, entry.name.replace(/\.(md|txt)$/i, ''), terms);

    const meta = document.createElement('span');
    meta.className = 'search-result-path';
    const directory = entry.path.slice(0, -1).join(' / ');
    meta.textContent = [directory, match.matchCount ? `${match.matchCount} 處` : '']
      .filter(Boolean).join(' · ');

    const snippet = document.createElement('span');
    snippet.className = 'search-result-snippet';
    _appendRanges(snippet, match.snippet.text, match.snippet.ranges);

    button.append(title);
    if (meta.textContent) button.append(meta);
    if (match.snippet.text) button.append(snippet);
    button.addEventListener('click', () => {
      container.querySelectorAll('.search-result.active').forEach(item => item.classList.remove('active'));
      button.classList.add('active');
      onOpen(entry, terms);
    });
    fragment.appendChild(button);
  }
  container.appendChild(fragment);
}

function _appendHighlighted(element, text, terms) {
  const lower = text.toLocaleLowerCase();
  const ranges = [];
  for (const term of terms) {
    let from = 0;
    let found;
    while ((found = lower.indexOf(term, from)) >= 0) {
      ranges.push([found, found + term.length]);
      from = found + term.length;
    }
  }
  ranges.sort((a, b) => a[0] - b[0]);
  const merged = [];
  for (const range of ranges) {
    const last = merged.at(-1);
    if (last && range[0] <= last[1]) last[1] = Math.max(last[1], range[1]);
    else merged.push([...range]);
  }
  _appendRanges(element, text, merged);
}

function _appendRanges(element, text, ranges) {
  let cursor = 0;
  for (const [start, end] of ranges) {
    if (start > cursor) element.append(text.slice(cursor, start));
    const mark = document.createElement('mark');
    mark.textContent = text.slice(start, end);
    element.append(mark);
    cursor = end;
  }
  if (cursor < text.length) element.append(text.slice(cursor));
}
