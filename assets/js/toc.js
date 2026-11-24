/** 文章目錄：為標題建立穩定錨點、捲動追蹤與導覽。 */

import { t } from './i18n.js';

let _scrollContainer = null;
let _entries = [];
let _tools = null;
let _onScroll = null;
let _contentRoot = null;

export function renderTOC(content, sidebar, container, scrollContainer, { preserveExpansion = false } = {}) {
  const collapsed = new Set(preserveExpansion
    ? _entries.filter(entry => entry.children?.hidden).map(entry => entry.heading.id)
    : []);
  clearTOC(sidebar, container);

  const headings = [...content.querySelectorAll('h1, h2, h3, h4, h5, h6')]
    .filter(heading => heading.textContent.trim() && !heading.closest('.note-embed'));
  _contentRoot = content;
  if (!headings.length) return;

  const used = new Map();
  const tree = document.createElement('ul');
  tree.className = 'toc-tree';
  const parents = [];

  for (const heading of headings) {
    const title = heading.textContent.trim();
    const base = _slug(title) || 'section';
    const count = used.get(base) || 0;
    used.set(base, count + 1);
    heading.id = count ? `${base}-${count + 1}` : base;

    const level = Number(heading.tagName.slice(1));
    while (parents.length && parents.at(-1).level >= level) parents.pop();
    const parent = parents.at(-1);
    if (parent && !parent.children) _makeBranch(parent, collapsed.has(parent.heading.id));

    const item = document.createElement('li');
    item.className = 'toc-node';
    const row = document.createElement('div');
    row.className = 'toc-row';
    const spacer = document.createElement('span');
    spacer.className = 'toc-branch-spacer';
    spacer.setAttribute('aria-hidden', 'true');
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'toc-link';
    button.textContent = title;
    button.title = title;
    button.addEventListener('click', () => {
      const top = _headingTop(heading, scrollContainer);
      scrollContainer.scrollTo({ top, behavior: 'smooth' });
      history.replaceState(null, '', `#${encodeURIComponent(heading.id)}`);
    });
    row.append(spacer, button);
    item.append(row);
    (parent?.children || tree).append(item);
    const entry = { heading, index: _entries.length, level, parent, item, spacer, button };
    _entries.push(entry);
    parents.push(entry);
  }

  container.appendChild(tree);
  _initOutlineTools(container);
  sidebar.hidden = false;
  _scrollContainer = scrollContainer;
  _onScroll = () => _syncActive(true);
  scrollContainer.addEventListener('scroll', _onScroll, { passive: true });
  _syncActive(true);
}

function _makeBranch(entry, collapsed) {
  const toggle = document.createElement('button');
  toggle.type = 'button';
  toggle.className = 'toc-branch-toggle';
  toggle.innerHTML = '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="m6 4 4 4-4 4"/></svg>';
  const children = document.createElement('ul');
  children.className = 'toc-children';
  children.id = 'toc-children-' + entry.index;
  toggle.setAttribute('aria-controls', children.id);
  entry.toggle = toggle;
  entry.children = children;
  _setExpanded(entry, !collapsed);
  toggle.addEventListener('click', () => {
    _setExpanded(entry, children.hidden);
    _syncActive();
  });
  entry.spacer.replaceWith(toggle);
  entry.item.append(children);
}

function _setExpanded({ children, toggle, button }, expanded) {
  children.hidden = !expanded;
  toggle.setAttribute('aria-expanded', String(expanded));
  const title = button.textContent;
  const label = expanded ? t('收合「{title}」', { title }) : t('展開「{title}」', { title });
  toggle.setAttribute('aria-label', label);
  toggle.title = label;
}

function _initOutlineTools(container) {
  _tools = container.closest('[data-right-panel="outline"]')?.querySelector('.toc-tools');
  if (!_tools) return;
  const branches = _entries.filter(entry => entry.children);
  _tools.hidden = !branches.length;
  _tools.onclick = event => {
    const action = event.target.closest('[data-toc-action]')?.dataset.tocAction;
    if (!action) return;
    for (const branch of branches) _setExpanded(branch, action === 'expand');
    _syncActive();
  };
}

export function clearTOC(sidebar, container) {
  if (_scrollContainer && _onScroll) {
    _scrollContainer.removeEventListener('scroll', _onScroll);
  }
  _scrollContainer = null;
  _onScroll = null;
  _entries = [];
  if (_tools) {
    _tools.hidden = true;
    _tools.onclick = null;
    _tools = null;
  }
  _contentRoot = null;
  if (container) container.innerHTML = '';
  if (sidebar) sidebar.hidden = true;
}

export function scrollToHash(hash, scrollContainer) {
  if (!hash) return false;
  let id;
  try { id = decodeURIComponent(hash.replace(/^#/, '')); } catch { return false; }
  const target = _contentRoot?.querySelector(`#${CSS.escape(id)}`);
  if (!target) return false;
  scrollContainer.scrollTop = _headingTop(target, scrollContainer);
  return true;
}

function _syncActive(reveal = false) {
  if (!_scrollContainer || !_entries.length) return;
  const threshold = _scrollContainer.getBoundingClientRect().top + 40;
  let active = _entries[0];
  for (const entry of _entries) {
    if (entry.heading.getBoundingClientRect().top <= threshold) active = entry;
    else break;
  }
  let visible = active;
  for (let parent = active.parent; parent; parent = parent.parent) {
    if (parent.children.hidden) visible = parent;
  }
  for (const entry of _entries) {
    entry.button.classList.toggle('active', entry === visible);
    if (entry === active) entry.button.setAttribute('aria-current', 'location');
    else entry.button.removeAttribute('aria-current');
  }
  if (reveal) visible.button.scrollIntoView({ block: 'nearest' });
}

function _headingTop(heading, scrollContainer) {
  return Math.max(0,
    heading.getBoundingClientRect().top
    - scrollContainer.getBoundingClientRect().top
    + scrollContainer.scrollTop
    - 20);
}

/** 與文章目錄相同的標題錨點規則，供 [[筆記#標題]] 跳轉使用。 */
export function headingSlug(value) {
  return _slug(String(value || '')) || 'section';
}

function _slug(value) {
  return value.toLocaleLowerCase()
    .normalize('NFKC')
    .replace(/[^\p{Letter}\p{Number}\s-]/gu, '')
    .trim()
    .replace(/[\s-]+/g, '-');
}
