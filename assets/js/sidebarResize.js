/** Resize a side pane with a pointer or the keyboard. */
const MIN_PANE_WIDTH = 160;
const MAX_PANE_WIDTH = 640;
const CONTENT_WIDTH = 320;
const KEYBOARD_STEP = 16;

export function initPaneResize(layout, pane, separator, oppositePane, {
  side,
  storageKey,
}) {
  const measuredWidth = Number.parseFloat(getComputedStyle(pane).width);
  const defaultWidth = Number.isFinite(measuredWidth) && measuredWidth > 0
    ? measuredWidth
    : (side === 'right' ? 238 : 260);
  const direction = side === 'right' ? -1 : 1;
  let preferredWidth = readWidth(storageKey, defaultWidth);
  let currentWidth;
  let minWidth;
  let maxWidth;
  let drag = null;

  function updateBounds(restorePreferred = true) {
    const availableWidth = layout.clientWidth - visibleWidth(oppositePane);
    const reservedWidth = Math.min(CONTENT_WIDTH, Math.ceil(availableWidth / 2));
    maxWidth = Math.max(0, Math.min(MAX_PANE_WIDTH, availableWidth - reservedWidth));
    minWidth = Math.min(MIN_PANE_WIDTH, Math.floor(maxWidth * 0.8));
    separator.setAttribute('aria-valuemin', String(minWidth));
    separator.setAttribute('aria-valuemax', String(maxWidth));
    applyWidth(restorePreferred ? preferredWidth : (currentWidth ?? preferredWidth));
    syncVisibility();
  }

  function applyWidth(width) {
    const nextWidth = Math.min(maxWidth, Math.max(minWidth, Math.round(width)));
    if (currentWidth !== nextWidth) pane.style.width = String(nextWidth) + 'px';
    currentWidth = nextWidth;
    separator.setAttribute('aria-valuenow', String(currentWidth));
  }

  function resizeTo(width) {
    applyWidth(width);
    preferredWidth = currentWidth;
  }

  separator.addEventListener('pointerdown', event => {
    if (event.button !== 0 || drag) return;
    updateBounds(false);
    event.preventDefault();
    separator.focus({ preventScroll: true });
    separator.setPointerCapture(event.pointerId);
    drag = { id: event.pointerId, startX: event.clientX, startWidth: currentWidth };
    layout.classList.add('pane-resizing');
    separator.classList.add('is-resizing');
  });

  separator.addEventListener('pointermove', event => {
    if (drag?.id !== event.pointerId) return;
    resizeTo(drag.startWidth + direction * (event.clientX - drag.startX));
  });

  function finishDrag(event) {
    if (drag?.id !== event.pointerId) return;
    drag = null;
    layout.classList.remove('pane-resizing');
    separator.classList.remove('is-resizing');
    saveWidth(storageKey, preferredWidth);
  }

  separator.addEventListener('pointerup', finishDrag);
  separator.addEventListener('pointercancel', finishDrag);
  separator.addEventListener('lostpointercapture', finishDrag);

  separator.addEventListener('keydown', event => {
    updateBounds(false);
    switch (event.key) {
      case 'ArrowLeft': resizeTo(currentWidth - direction * KEYBOARD_STEP); break;
      case 'ArrowRight': resizeTo(currentWidth + direction * KEYBOARD_STEP); break;
      case 'Home': resizeTo(minWidth); break;
      case 'End': resizeTo(maxWidth); break;
      default: return;
    }
    event.preventDefault();
    saveWidth(storageKey, preferredWidth);
  });

  function syncVisibility() {
    separator.hidden = pane.hidden || getComputedStyle(pane).display === 'none';
  }

  updateBounds();
  new ResizeObserver(() => updateBounds()).observe(layout);
  new ResizeObserver(() => updateBounds(false)).observe(oppositePane);
  new MutationObserver(() => updateBounds()).observe(pane, {
    attributes: true,
    attributeFilter: ['class', 'hidden'],
  });
  new MutationObserver(() => updateBounds(false)).observe(oppositePane, {
    attributes: true,
    attributeFilter: ['class', 'hidden'],
  });
}

function visibleWidth(pane) {
  return pane.hidden || getComputedStyle(pane).display === 'none'
    ? 0
    : pane.offsetWidth;
}

function readWidth(storageKey, defaultWidth) {
  try {
    const width = Number(localStorage.getItem(storageKey));
    if (Number.isFinite(width) && width > 0) return width;
  } catch {
    // The current session can still resize the pane.
  }
  return defaultWidth;
}

function saveWidth(storageKey, width) {
  try {
    localStorage.setItem(storageKey, String(width));
  } catch {
    // Storage is optional for resizing.
  }
}
