/**
 * lightboxZoom.js — 燈箱圖片縮放與平移
 * 滾輪 / 觸控板縮放（以游標為中心）、拖曳平移、雙擊切換、雙指縮放、
 * 鍵盤 + / - / 0，以及工具列按鈕。
 */

export const ZOOM_MIN = 1;
export const ZOOM_MAX = 10;

/**
 * 以 (px, py) 為固定點，將縮放由 state.scale 改為 nextScale。
 * 座標以圖片未變形時的左上角為原點；transform-origin 為 0 0。
 */
export function zoomAt(state, nextScale, px, py) {
  const scale = Math.min(ZOOM_MAX, Math.max(ZOOM_MIN, nextScale));
  if (scale === ZOOM_MIN) return { scale, x: 0, y: 0 };
  const ratio = scale / state.scale;
  return {
    scale,
    x: px - (px - state.x) * ratio,
    y: py - (py - state.y) * ratio,
  };
}

export function initLightboxZoom({ lightbox, image, zoomIn, zoomOut, reset, level }) {
  let state = { scale: 1, x: 0, y: 0 };
  const pointers = new Map();
  let drag = null;
  let pinch = null;

  const apply = () => {
    image.style.transform = `translate(${state.x}px, ${state.y}px) scale(${state.scale})`;
    image.classList.toggle('is-zoomed', state.scale > ZOOM_MIN);
    if (level) level.textContent = `${Math.round(state.scale * 100)}%`;
  };

  // 未變形圖片左上角在視窗中的位置
  const origin = () => {
    const rect = image.getBoundingClientRect();
    return { left: rect.left - state.x, top: rect.top - state.y };
  };

  const zoomTo = (scale, clientX, clientY) => {
    const base = origin();
    if (clientX === undefined) {
      const rect = image.getBoundingClientRect();
      clientX = rect.left + rect.width / 2;
      clientY = rect.top + rect.height / 2;
    }
    state = zoomAt(state, scale, clientX - base.left, clientY - base.top);
    apply();
  };

  const resetZoom = () => {
    state = { scale: 1, x: 0, y: 0 };
    pointers.clear();
    drag = null;
    pinch = null;
    apply();
  };

  lightbox.addEventListener('wheel', (e) => {
    if (lightbox.hidden || !image.getAttribute('src')) return;
    e.preventDefault();
    const delta = e.deltaMode === 1 ? e.deltaY * 16 : e.deltaY;
    zoomTo(state.scale * Math.exp(-delta * 0.0015), e.clientX, e.clientY);
  }, { passive: false });

  image.addEventListener('dblclick', (e) => {
    e.preventDefault();
    if (state.scale > ZOOM_MIN) resetZoom();
    else zoomTo(2.5, e.clientX, e.clientY);
  });

  image.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    image.setPointerCapture(e.pointerId);
    pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pointers.size === 2) {
      const [a, b] = [...pointers.values()];
      pinch = {
        distance: Math.hypot(a.x - b.x, a.y - b.y),
        scale: state.scale,
      };
      drag = null;
    } else if (pointers.size === 1 && state.scale > ZOOM_MIN) {
      drag = { x: e.clientX - state.x, y: e.clientY - state.y };
    }
  });

  image.addEventListener('pointermove', (e) => {
    if (!pointers.has(e.pointerId)) return;
    pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
    if (pinch && pointers.size === 2) {
      const [a, b] = [...pointers.values()];
      const distance = Math.hypot(a.x - b.x, a.y - b.y);
      if (pinch.distance > 0) {
        zoomTo(pinch.scale * (distance / pinch.distance), (a.x + b.x) / 2, (a.y + b.y) / 2);
      }
    } else if (drag) {
      state = { ...state, x: e.clientX - drag.x, y: e.clientY - drag.y };
      apply();
    }
  });

  const endPointer = (e) => {
    pointers.delete(e.pointerId);
    if (pointers.size < 2) pinch = null;
    if (pointers.size === 0) drag = null;
  };
  image.addEventListener('pointerup', endPointer);
  image.addEventListener('pointercancel', endPointer);

  zoomIn?.addEventListener('click', () => zoomTo(state.scale * 1.5));
  zoomOut?.addEventListener('click', () => zoomTo(state.scale / 1.5));
  reset?.addEventListener('click', resetZoom);

  document.addEventListener('keydown', (e) => {
    if (lightbox.hidden || e.ctrlKey || e.metaKey || e.altKey) return;
    if (e.key === '+' || e.key === '=') zoomTo(state.scale * 1.5);
    else if (e.key === '-' || e.key === '_') zoomTo(state.scale / 1.5);
    else if (e.key === '0') resetZoom();
    else return;
    e.preventDefault();
  });

  apply();
  return { reset: resetZoom };
}
