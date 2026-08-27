/** 文章目錄：為標題建立穩定錨點、捲動追蹤與導覽。 */

let _scrollContainer = null;
let _headings = [];
let _buttons = [];
let _onScroll = null;
let _contentRoot = null;

export function renderTOC(content, sidebar, container, scrollContainer) {
  clearTOC(sidebar, container);

  const headings = [...content.querySelectorAll('h1, h2, h3, h4, h5, h6')]
    .filter(heading => heading.textContent.trim());
  if (!headings.length) return;

  const used = new Map();
  const fragment = document.createDocumentFragment();
  _headings = headings;
  _contentRoot = content;
  _buttons = [];

  for (const heading of headings) {
    const title = heading.textContent.trim();
    const base = _slug(title) || 'section';
    const count = used.get(base) || 0;
    used.set(base, count + 1);
    heading.id = count ? `${base}-${count + 1}` : base;

    const button = document.createElement('button');
    button.className = 'toc-link';
    const depth = Math.min(Number(heading.tagName.slice(1)) - 1, 3);
    button.style.setProperty('--toc-indent', `${depth * 12}px`);
    button.textContent = title;
    button.title = title;
    button.addEventListener('click', () => {
      const top = _headingTop(heading, scrollContainer);
      scrollContainer.scrollTo({ top, behavior: 'smooth' });
      history.replaceState(null, '', `#${encodeURIComponent(heading.id)}`);
    });
    fragment.appendChild(button);
    _buttons.push(button);
  }

  container.appendChild(fragment);
  sidebar.hidden = false;
  _scrollContainer = scrollContainer;
  _onScroll = () => _syncActive();
  scrollContainer.addEventListener('scroll', _onScroll, { passive: true });
  _syncActive();
}

export function clearTOC(sidebar, container) {
  if (_scrollContainer && _onScroll) {
    _scrollContainer.removeEventListener('scroll', _onScroll);
  }
  _scrollContainer = null;
  _onScroll = null;
  _headings = [];
  _buttons = [];
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

function _syncActive() {
  if (!_scrollContainer || !_headings.length) return;
  const threshold = _scrollContainer.getBoundingClientRect().top + 40;
  let active = 0;
  for (let index = 0; index < _headings.length; index++) {
    if (_headings[index].getBoundingClientRect().top <= threshold) active = index;
    else break;
  }
  _buttons.forEach((button, index) => {
    button.classList.toggle('active', index === active);
  });
  _buttons[active]?.scrollIntoView({ block: 'nearest' });
}

function _headingTop(heading, scrollContainer) {
  return Math.max(0,
    heading.getBoundingClientRect().top
    - scrollContainer.getBoundingClientRect().top
    + scrollContainer.scrollTop
    - 20);
}

function _slug(value) {
  return value.toLocaleLowerCase()
    .normalize('NFKC')
    .replace(/[^\p{Letter}\p{Number}\s-]/gu, '')
    .trim()
    .replace(/[\s-]+/g, '-');
}
