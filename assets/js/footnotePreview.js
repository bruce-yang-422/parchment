import { t } from './i18n.js';

const REFERENCE = '.footnote-ref > a[href]';
const ENDNOTE = '.footnote-item[id]';
const BACKLINK = '.footnote-backref[href]';

/** Preview the rendered footnote while keeping its content and controls in the reader. */
export function initFootnotePreview(reader) {
  const owner = reader.ownerDocument;
  const dialog = owner.createElement('dialog');
  if (typeof dialog.showModal !== 'function') {
    return { prepare() {}, close() {} };
  }

  dialog.className = 'footnote-preview';
  const header = owner.createElement('div');
  header.className = 'footnote-preview-header';
  const heading = owner.createElement('strong');
  const closeButton = owner.createElement('button');
  closeButton.className = 'dialog-close footnote-preview-close';
  closeButton.type = 'button';
  closeButton.textContent = '×';
  header.append(heading, closeButton);

  const content = owner.createElement('div');
  content.className = 'footnote-preview-content';
  content.tabIndex = 0;

  const footer = owner.createElement('div');
  footer.className = 'footnote-preview-footer';
  const jumpButton = owner.createElement('button');
  jumpButton.type = 'button';
  footer.append(jumpButton);
  dialog.append(header, content, footer);

  let active = null;

  function prepare() {
    reader.querySelectorAll(REFERENCE).forEach(reference => {
      reference.setAttribute('aria-haspopup', 'dialog');
    });
  }

  function scopeFor(element) {
    return element.closest('.note-embed-body') || reader;
  }

  function targetFor(link, selector) {
    const hash = link.getAttribute('href');
    if (!hash.startsWith('#')) return null;
    let id;
    try {
      id = decodeURIComponent(hash.slice(1));
    } catch {
      return null;
    }
    const scope = scopeFor(link);
    return [...scope.querySelectorAll(`${selector}[id="${CSS.escape(id)}"]`)]
      .find(target => scopeFor(target) === scope) || null;
  }

  function open(reference, note) {
    const displayNumber = reference.textContent.trim().match(/^\[(\d+)/)?.[1]
      || reference.textContent.trim();
    heading.textContent = t('註腳 {number}', { number: displayNumber });
    dialog.setAttribute('aria-label', heading.textContent);
    closeButton.setAttribute('aria-label', t('關閉註腳預覽'));
    jumpButton.textContent = t('前往原註腳');

    active = { reference, note, minBlockSize: note.style.minBlockSize };
    note.style.minBlockSize = `${Math.ceil(note.getBoundingClientRect().height)}px`;
    // Moving the rendered nodes preserves IDs, image URLs, and event listeners.
    content.replaceChildren(...note.childNodes);
    reader.append(dialog);
    dialog.showModal();
    content.scrollTop = 0;
    closeButton.focus({ preventScroll: true });
  }

  function dismiss(restoreFocus = true) {
    if (!active) return;
    const { reference, note, minBlockSize } = active;
    active = null;
    note.replaceChildren(...content.childNodes);
    note.style.minBlockSize = minBlockSize;
    dialog.close();
    dialog.remove();
    if (restoreFocus && reference.isConnected) reference.focus({ preventScroll: true });
  }

  function navigateTo(element) {
    if (!element.hasAttribute('tabindex') && element.tabIndex < 0) element.tabIndex = -1;
    element.focus({ preventScroll: true });
    element.scrollIntoView({ block: 'center' });
  }

  closeButton.addEventListener('click', () => dismiss());
  jumpButton.addEventListener('click', () => {
    const note = active?.note;
    dismiss(false);
    if (note?.isConnected) navigateTo(note);
  });
  dialog.addEventListener('cancel', event => {
    event.preventDefault();
    dismiss();
  });
  dialog.addEventListener('click', event => {
    if (event.target === dialog) dismiss();
  });

  reader.addEventListener('click', event => {
    if (event.defaultPrevented || event.button !== 0) return;
    // Restore linked content to the document before its existing navigation or lightbox handler fires.
    if (content.contains(event.target) && event.target.closest('a[href], .image-zoomable, .mermaid, .graphviz, .metadata-tag')) {
      dismiss();
    }
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;

    const reference = event.target.closest(REFERENCE);
    const backlink = event.target.closest(BACKLINK);
    if (!reference && !backlink) return;
    const target = reference ? targetFor(reference, ENDNOTE) : targetFor(backlink, REFERENCE);
    if (!target) return;

    event.preventDefault();
    event.stopPropagation();
    if (reference) open(reference, target);
    else navigateTo(target);
  }, { capture: true });

  return { prepare, close: () => dismiss(false) };
}
