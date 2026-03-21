/**
 * tree.js — 資料夾樹狀結構 UI 模組
 */

let _onFileSelect = null;
let _activeBtn = null;

/**
 * 渲染資料夾樹
 * @param {TreeEntry[]} entries
 * @param {function(name: string, content: string): Promise<void>} onFileSelect
 */
export function renderTree(entries, onFileSelect) {
  _onFileSelect = onFileSelect;
  _activeBtn = null;

  const container = document.getElementById('tree-container');
  container.innerHTML = '';
  container.appendChild(_buildList(entries, 0));
}

/** 清除樹狀結構 */
export function clearTree() {
  const container = document.getElementById('tree-container');
  if (container) container.innerHTML = '';
  _activeBtn = null;
}

/* ──────────────────── 建立 DOM 樹 ──────────────────── */

function _buildList(entries, depth) {
  const ul = document.createElement('ul');
  ul.className = depth === 0 ? 'tree-list' : 'tree-list tree-nested';

  for (const entry of entries) {
    ul.appendChild(entry.type === 'dir'
      ? _makeDirItem(entry, depth)
      : _makeFileItem(entry));
  }

  return ul;
}

function _makeDirItem(entry, depth) {
  const li = document.createElement('li');
  li.className = 'tree-dir';

  const toggle = document.createElement('button');
  toggle.className = 'tree-toggle';
  toggle.setAttribute('aria-expanded', 'true');
  toggle.innerHTML =
    `<span class="tree-arrow" aria-hidden="true">▾</span>` +
    `<span class="tree-icon" aria-hidden="true">📁</span>` +
    `<span class="tree-label">${_esc(entry.name)}</span>`;

  const nested = _buildList(entry.children, depth + 1);

  toggle.addEventListener('click', () => {
    const collapsed = nested.classList.toggle('collapsed');
    toggle.setAttribute('aria-expanded', String(!collapsed));
    toggle.querySelector('.tree-arrow').textContent = collapsed ? '▸' : '▾';
    toggle.querySelector('.tree-icon').textContent  = collapsed ? '📁' : '📂';
  });

  li.appendChild(toggle);
  li.appendChild(nested);
  return li;
}

function _makeFileItem(entry) {
  const li = document.createElement('li');
  li.className = 'tree-file';

  const btn = document.createElement('button');
  btn.className = 'tree-file-btn';
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
      await _onFileSelect(entry.name, content);
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
