/**
 * tree.js — 資料夾樹狀結構 UI 模組
 */

let _onFileSelect = null;
let _activeBtn = null;
let _pathButtons = new Map();

/**
 * 渲染資料夾樹
 * @param {TreeEntry[]} entries
 * @param {function(entry: TreeEntry, content: string): Promise<void>} onFileSelect
 */
export function renderTree(entries, onFileSelect, { expandDirectories = false } = {}) {
  _onFileSelect = onFileSelect;
  _activeBtn = null;
  _pathButtons = new Map();

  const container = document.getElementById('tree-container');
  container.innerHTML = '';
  if (!entries.length) {
    const empty = document.createElement('p');
    empty.className = 'tree-empty';
    empty.textContent = '沒有符合此標籤的文件';
    container.appendChild(empty);
    return;
  }
  container.appendChild(_buildList(entries, 0, expandDirectories));
}

/** 清除樹狀結構 */
export function clearTree() {
  const container = document.getElementById('tree-container');
  if (container) container.innerHTML = '';
  _activeBtn = null;
  _pathButtons.clear();
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
}

/* ──────────────────── 建立 DOM 樹 ──────────────────── */

function _buildList(entries, depth, expandDirectories) {
  const ul = document.createElement('ul');
  ul.className = depth === 0 ? 'tree-list' : 'tree-list tree-nested';

  for (const entry of entries) {
    ul.appendChild(entry.type === 'dir'
      ? _makeDirItem(entry, depth, expandDirectories)
      : _makeFileItem(entry));
  }

  return ul;
}

function _makeDirItem(entry, depth, expandDirectories) {
  const li = document.createElement('li');
  li.className = 'tree-dir';

  const toggle = document.createElement('button');
  toggle.className = 'tree-toggle';
  toggle.innerHTML =
    `<span class="tree-arrow" aria-hidden="true"></span>` +
    `<span class="tree-icon" aria-hidden="true"></span>` +
    `<span class="tree-label">${_esc(entry.name)}</span>`;

  const nested = _buildList(entry.children, depth + 1, expandDirectories);
  _setDirectoryExpanded(toggle, nested, expandDirectories);

  toggle.addEventListener('click', () => {
    _setDirectoryExpanded(toggle, nested, nested.classList.contains('collapsed'));
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
