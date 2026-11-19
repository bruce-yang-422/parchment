/**
 * tree.js — 資料夾樹狀結構 UI 模組
 */

import { t } from './i18n.js';

let _onFileSelect = null;
let _activeBtn = null;
let _pathButtons = new Map();
let _directoryToggles = [];
let _onExpansionChange = null;

/**
 * 渲染資料夾樹
 * @param {TreeEntry[]} entries
 * @param {function(entry: TreeEntry, content: string): Promise<void>} onFileSelect
 */
export function renderTree(entries, onFileSelect, {
  expandDirectories = false,
  expandedKeys = null,
  onExpansionChange = null,
} = {}) {
  _onFileSelect = onFileSelect;
  _onExpansionChange = onExpansionChange;
  _activeBtn = null;
  _pathButtons = new Map();
  _directoryToggles = [];

  const container = document.getElementById('tree-container');
  container.innerHTML = '';
  if (!entries.length) {
    const empty = document.createElement('p');
    empty.className = 'tree-empty';
    empty.textContent = t('沒有符合此標籤的文件');
    container.appendChild(empty);
    return;
  }
  container.appendChild(_buildList(entries, 0, { expandDirectories, expandedKeys }, []));
  _onExpansionChange?.();
}

/** 全部展開或全部折疊資料夾。 */
export function setAllDirectoriesExpanded(expanded) {
  for (const { toggle, nested } of _directoryToggles) _setDirectoryExpanded(toggle, nested, expanded);
  _onExpansionChange?.();
}

/** 是否有任何資料夾處於展開狀態。 */
export function hasExpandedDirectory() {
  return _directoryToggles.some(({ nested }) => !nested.classList.contains('collapsed'));
}

/** 目前展開中的資料夾路徑，重新排序或篩選後可據此還原。 */
export function getExpandedDirectoryKeys() {
  return new Set(_directoryToggles
    .filter(({ nested }) => !nested.classList.contains('collapsed'))
    .map(({ key }) => key));
}

/** 清除樹狀結構 */
export function clearTree() {
  const container = document.getElementById('tree-container');
  if (container) container.innerHTML = '';
  _activeBtn = null;
  _pathButtons.clear();
  _directoryToggles = [];
}

/** 讓從文章相對連結開啟的文件也能同步反白資料夾樹。 */
export function setActiveTreePath(path) {
  const btn = _pathButtons.get(path.join('/').toLocaleLowerCase());
  if (!btn) return;

  let nested = btn.closest('.tree-nested');
  while (nested) {
    if (nested.classList.contains('collapsed')) {
      _setDirectoryExpanded(nested.previousElementSibling, nested, true);
    }
    nested = nested.parentElement.closest('.tree-nested');
  }

  if (_activeBtn) _activeBtn.classList.remove('active');
  btn.classList.add('active');
  btn.scrollIntoView({ block: 'nearest' });
  _activeBtn = btn;
  _onExpansionChange?.();
}

/* ──────────────────── 建立 DOM 樹 ──────────────────── */

function _buildList(entries, depth, options, parentPath) {
  const ul = document.createElement('ul');
  ul.className = depth === 0 ? 'tree-list' : 'tree-list tree-nested';

  for (const entry of entries) {
    ul.appendChild(entry.type === 'dir'
      ? _makeDirItem(entry, depth, options, parentPath)
      : _makeFileItem(entry));
  }

  return ul;
}

function _makeDirItem(entry, depth, options, parentPath) {
  const path = entry.path || [...parentPath, entry.name];
  const key = path.join('/').toLocaleLowerCase();
  const li = document.createElement('li');
  li.className = 'tree-dir';

  const toggle = document.createElement('button');
  toggle.className = 'tree-toggle';
  toggle.innerHTML =
    `<span class="tree-arrow" aria-hidden="true"></span>` +
    `<span class="tree-icon" aria-hidden="true"></span>` +
    `<span class="tree-label">${_esc(entry.name)}</span>`;

  const nested = _buildList(entry.children, depth + 1, options, path);
  const expanded = options.expandDirectories || Boolean(options.expandedKeys?.has(key));
  _setDirectoryExpanded(toggle, nested, expanded);
  _directoryToggles.push({ toggle, nested, key });

  toggle.addEventListener('click', () => {
    _setDirectoryExpanded(toggle, nested, nested.classList.contains('collapsed'));
    _onExpansionChange?.();
  });

  li.appendChild(toggle);
  li.appendChild(nested);
  return li;
}

function _setDirectoryExpanded(toggle, nested, expanded) {
  nested.classList.toggle('collapsed', !expanded);
  toggle.setAttribute('aria-expanded', String(expanded));
  toggle.querySelector('.tree-arrow').textContent = expanded ? '▾' : '▸';
  toggle.querySelector('.tree-icon').textContent = expanded ? '📂' : '📁';
}

function _makeFileItem(entry) {
  const li = document.createElement('li');
  li.className = 'tree-file';

  const btn = document.createElement('button');
  btn.className = 'tree-file-btn';
  _pathButtons.set(entry.path.join('/').toLocaleLowerCase(), btn);
  const icon = /\.md$/i.test(entry.name) ? '📄' : '📝';
  btn.innerHTML =
    `<span class="tree-icon" aria-hidden="true">${icon}</span>` +
    `<span class="tree-label">${_esc(entry.name)}</span>`;

  btn.addEventListener('click', async () => {
    if (_activeBtn === btn) return; // already selected

    if (_activeBtn) _activeBtn.classList.remove('active');
    btn.classList.add('active');
    _activeBtn = btn;

    try {
      const file = await entry.handle.getFile();
      const content = await file.text();
      await _onFileSelect(entry, content);
    } catch (err) {
      console.error('Failed to read file:', err);
    }
  });

  li.appendChild(btn);
  return li;
}

/* ──────────────────── Helpers ──────────────────── */

function _esc(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}
