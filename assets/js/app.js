/**
 * app.js — 主應用邏輯
 * 協調 theme / fileLoader / renderer / tree 模組
 */

import { initTheme, cycleTheme }           from './theme.js';
import { openFile, openDirectory, openFileFromHandle, openDirectoryFromHandle, isSupportedFile } from './fileLoader.js';
import { setupRenderer, renderMarkdown, renderText } from './renderer.js';
import { renderTree, clearTree }           from './tree.js';
import { saveRecent, getRecents, removeRecent } from './recentFiles.js';

/* ──────────────────── 初始化 ──────────────────── */

setupRenderer();
initTheme();
_refreshRecents();

/* ──────────────────── DOM 參照 ──────────────────── */

const mainEl          = document.getElementById('main');
const sidebarEl       = document.getElementById('sidebar');
const treeRootName    = document.getElementById('tree-root-name');
const welcomeEl       = document.getElementById('welcome');
const readerEl        = document.getElementById('reader');
const readerBody      = document.getElementById('reader-body');
const currentFilename = document.getElementById('current-filename');
const folderPlaceholder = document.getElementById('folder-placeholder');
const dragOverlay     = document.getElementById('drag-overlay');
const lightboxEl      = document.getElementById('image-lightbox');
const lightboxImage   = document.getElementById('lightbox-image');
const lightboxClose   = document.getElementById('lightbox-close');

/* ──────────────────── 按鈕事件 ──────────────────── */

document.getElementById('btn-theme').addEventListener('click', cycleTheme);

document.getElementById('btn-open-file').addEventListener('click', handleOpenFile);
document.getElementById('btn-open-dir').addEventListener('click', handleOpenDir);
document.getElementById('welcome-btn-file').addEventListener('click', handleOpenFile);
document.getElementById('welcome-btn-dir').addEventListener('click', handleOpenDir);
if (lightboxClose) {
  lightboxClose.addEventListener('click', _closeImageLightbox);
}
if (lightboxEl) {
  lightboxEl.addEventListener('click', (e) => {
    if (e.target === lightboxEl) _closeImageLightbox();
  });
}
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && lightboxEl && !lightboxEl.hidden) _closeImageLightbox();
});
window.addEventListener('resize', () => _refreshImageOverflow(readerBody));

async function handleOpenFile() {
  try {
    const { name, content, handle } = await openFile();
    await _displayFile(name, content);
    _enterSingleMode();
    if (handle) saveRecent('file', handle).then(_refreshRecents).catch(() => {});
  } catch (err) {
    if (err.name !== 'AbortError') _showToast(err.message, 'error');
  }
}

async function handleOpenDir() {
  try {
    const { rootName, entries, handle } = await openDirectory();
    _enterFolderMode(rootName, entries);
    if (handle) saveRecent('dir', handle).then(_refreshRecents).catch(() => {});
  } catch (err) {
    if (err.name !== 'AbortError') _showToast(err.message, 'error');
  }
}

/* ──────────────────── 拖放（Drag & Drop） ──────────────────── */

let _dragCounter = 0;

document.addEventListener('dragenter', (e) => {
  if (!e.dataTransfer.types.includes('Files')) return;
  _dragCounter++;
  dragOverlay.hidden = false;
});

document.addEventListener('dragleave', () => {
  _dragCounter--;
  if (_dragCounter <= 0) {
    _dragCounter = 0;
    dragOverlay.hidden = true;
  }
});

dragOverlay.addEventListener('dragover', (e) => e.preventDefault());

dragOverlay.addEventListener('drop', async (e) => {
  e.preventDefault();
  _dragCounter = 0;
  dragOverlay.hidden = true;

  const file = e.dataTransfer.files[0];
  if (!file) return;

  if (!isSupportedFile(file.name)) {
    _showToast(`不支援的格式：${file.name}。請使用 .md 或 .txt 檔案。`, 'error');
    return;
  }

  try {
    const content = await file.text();
    await _displayFile(file.name, content);
    _enterSingleMode();
  } catch (err) {
    _showToast(`無法讀取檔案：${err.message}`, 'error');
  }
});

/* ──────────────────── 模式切換 ──────────────────── */

function _enterSingleMode() {
  mainEl.className = 'single-mode';
  sidebarEl.hidden = true;
  folderPlaceholder.hidden = true;
  clearTree();
}

function _enterFolderMode(rootName, entries) {
  mainEl.className = 'folder-mode';
  sidebarEl.hidden = false;
  treeRootName.textContent = rootName;

  // 顯示 placeholder，等待使用者選擇檔案
  welcomeEl.hidden = true;
  readerEl.hidden = true;
  folderPlaceholder.hidden = false;

  renderTree(entries, async (name, content) => {
    await _displayFile(name, content);
    folderPlaceholder.hidden = true;
  });
}

/* ──────────────────── 內容顯示 ──────────────────── */

async function _displayFile(name, content) {
  // 大檔案警告（> 5 MB）
  if (content.length > 5 * 1024 * 1024) {
    _showToast(`檔案較大（${_formatSize(content.length)}），渲染可能較慢。`, 'info');
  }

  currentFilename.textContent = name;

  const isMarkdown = /\.md$/i.test(name);
  readerBody.innerHTML = isMarkdown
    ? renderMarkdown(content)
    : renderText(content);

  // ── Mermaid 渲染 ──────────────────────────────────────────────────
  // 直接交給 mermaid.run 處理 DOM 節點，兼容性比手動 render SVG 更穩。
  const mermaidNodes = [...readerBody.querySelectorAll('.mermaid')];

  if (window.mermaid && mermaidNodes.length) {
    for (const node of mermaidNodes) {
      const source = node.textContent.trim();
      if (!source) continue;
      const normalizedSource = _normalizeMermaidSource(source);

      try {
        const svg = await _renderMermaidSource(normalizedSource);
        const wrapper = document.createElement('div');
        wrapper.className = 'mermaid';
        wrapper.innerHTML = svg;
        _prepareMermaidDiagram(wrapper);
        node.replaceWith(wrapper);
      } catch (err) {
        console.warn('Mermaid 首次渲染失敗：', err);
        if (node.isConnected) {
          node.replaceWith(_createMermaidFallback(normalizedSource, err));
        }
      }
    }
  }

  _enhanceImages(readerBody);
  _attachCopyButtons(readerBody);

  welcomeEl.hidden = true;
  readerEl.hidden = false;

  // 捲回頂部
  readerEl.scrollIntoView({ block: 'start' });
  document.getElementById('content-area').scrollTop = 0;
}

/* ──────────────────── 複製按鈕 ──────────────────── */

function _attachCopyButtons(container) {
  container.querySelectorAll('pre').forEach(pre => {
    const code = pre.querySelector('code');
    if (!code) return;

    // Wrap pre in a div so the button sits outside pre's overflow context
    const wrapper = document.createElement('div');
    wrapper.className = 'code-wrapper';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    const btn = document.createElement('button');
    btn.className = 'copy-btn';
    btn.textContent = '複製';
    btn.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(code.textContent);
        btn.textContent = '已複製';
        btn.classList.add('copied');
        setTimeout(() => {
          btn.textContent = '複製';
          btn.classList.remove('copied');
        }, 1500);
      } catch {
        btn.textContent = '失敗';
        setTimeout(() => { btn.textContent = '複製'; }, 1500);
      }
    });
    wrapper.appendChild(btn);
  });
}

function _createMermaidFallback(source, err) {
  const wrapper = document.createElement('div');
  wrapper.className = 'mermaid-fallback';

  const error = document.createElement('div');
  error.className = 'mermaid-error';
  const message = err && typeof err.message === 'string'
    ? err.message
    : '未知錯誤';
  error.textContent = `Mermaid 圖表目前無法渲染，以下保留原始碼。\n錯誤：${message}`;

  const pre = document.createElement('pre');
  const code = document.createElement('code');
  code.className = 'hljs language-plaintext';
  code.textContent = source;
  pre.appendChild(code);

  wrapper.append(error, pre);
  return wrapper;
}

async function _retryMermaidRender(source, err) {
  if (!window.mermaid) return { error: err };

  const variants = _buildMermaidRetryVariants(source, err);
  let lastError = err;

  for (const variant of variants) {
    const renderId = `mm-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
    try {
      const result = await window.mermaid.render(renderId, variant);
      const svg = typeof result === 'string' ? result : result?.svg;
      if (svg) return { svg };
      lastError = new Error('Mermaid fallback 未產生 SVG 輸出');
    } catch (retryErr) {
      lastError = retryErr;
    } finally {
      document.getElementById('d' + renderId)?.remove();
      document.getElementById(renderId)?.remove();
    }
  }

  return { error: lastError };
}

function _buildMermaidRetryVariants(source, err) {
  const variants = [];
  const message = err && typeof err.message === 'string' ? err.message : '';
  const isFlowchart = /^\s*(%%\{.*\}%%\s*)?(flowchart|graph)\b/m.test(source);

  if (!isFlowchart) {
    variants.push(source);
    return variants;
  }

  variants.push(_withMermaidInit(source, {
    flowchart: {
      htmlLabels: true,
      defaultRenderer: 'elk',
      curve: 'linear',
      useMaxWidth: true,
    },
  }));

  variants.push(_withMermaidInit(source, {
    flowchart: {
      htmlLabels: true,
      curve: 'linear',
      useMaxWidth: true,
    },
  }));

  // Layout bug workaround for complex flowcharts with labels/curves.
  if (/suitable point for the given distance/i.test(message)) {
    variants.push(_withMermaidInit(source, {
      flowchart: {
        htmlLabels: true,
        defaultRenderer: 'elk',
        curve: 'basis',
        useMaxWidth: true,
      },
    }));
  }

  return variants;
}

function _withMermaidInit(source, config) {
  const init = `%%{init: ${JSON.stringify(config)}}%%`;
  return `${init}\n${source}`;
}

async function _renderMermaidSource(source) {
  const firstError = new Error('Mermaid 未開始渲染');
  const result = await _retryMermaidRender(source, firstError);
  if (result?.svg) return result.svg;
  throw result?.error ?? firstError;
}

function _normalizeMermaidSource(source) {
  return source.replace(/\\n/g, '<br/>');
}

function _prepareMermaidDiagram(wrapper) {
  const svg = wrapper.querySelector('svg');
  if (!svg) return;

  const viewBox = svg.viewBox?.baseVal;
  const widthAttr = Number.parseFloat(svg.getAttribute('width') || '');
  const heightAttr = Number.parseFloat(svg.getAttribute('height') || '');
  const intrinsicWidth = viewBox?.width || widthAttr;
  const intrinsicHeight = viewBox?.height || heightAttr;

  if (intrinsicWidth) {
    svg.style.width = `${Math.ceil(intrinsicWidth)}px`;
    svg.style.maxWidth = 'none';
  }

  if (intrinsicHeight) {
    svg.style.height = `${Math.ceil(intrinsicHeight)}px`;
  } else {
    svg.style.height = 'auto';
  }
}

function _enhanceImages(container) {
  container.querySelectorAll('img').forEach(img => {
    if (img.closest('#image-lightbox')) return;

    if (!img.parentElement?.classList.contains('image-scroll-inner')) {
      const frame = document.createElement('div');
      frame.className = 'image-scroll-frame';

      const inner = document.createElement('div');
      inner.className = 'image-scroll-inner';

      img.parentNode.insertBefore(frame, img);
      frame.appendChild(inner);
      inner.appendChild(img);
    }

    img.classList.add('image-zoomable');
    if (!img.dataset.zoomBound) {
      img.addEventListener('click', () => _openImageLightbox(img));
      img.dataset.zoomBound = 'true';
    }

    if (img.complete) {
      _syncImageOverflowState(img);
    } else {
      img.addEventListener('load', () => _syncImageOverflowState(img), { once: true });
    }
  });
}

function _refreshImageOverflow(container) {
  container.querySelectorAll('img.image-zoomable').forEach(_syncImageOverflowState);
}

function _syncImageOverflowState(img) {
  const inner = img.parentElement;
  const frame = inner?.parentElement;
  if (!frame) return;

  const naturalWidth = img.naturalWidth || img.width;
  const frameWidth = frame.clientWidth;
  img.classList.toggle('is-overflowing', naturalWidth > frameWidth + 8);
}

function _openImageLightbox(img) {
  if (!lightboxEl || !lightboxImage) return;
  lightboxImage.src = img.currentSrc || img.src;
  lightboxImage.alt = img.alt || '';
  lightboxEl.hidden = false;
  document.body.style.overflow = 'hidden';
}

function _closeImageLightbox() {
  if (!lightboxEl || !lightboxImage) return;
  lightboxEl.hidden = true;
  lightboxImage.removeAttribute('src');
  lightboxImage.alt = '';
  document.body.style.overflow = '';
}

/* ──────────────────── 最近開啟 ──────────────────── */

async function _refreshRecents() {
  const items = await getRecents().catch(() => []);
  _renderRecents(items);
}

function _renderRecents(items) {
  const section = document.getElementById('recent-section');
  const list    = document.getElementById('recent-list');
  if (!section || !list) return;

  if (!items.length) { section.hidden = true; return; }

  section.hidden = false;
  list.innerHTML = '';

  for (const item of items) {
    const li  = document.createElement('li');
    const btn = document.createElement('button');
    btn.className = 'recent-item';

    const icon = item.type === 'dir' ? '📂' : (/\.md$/i.test(item.handle.name) ? '📄' : '📝');
    btn.innerHTML =
      `<span class="recent-icon">${icon}</span>` +
      `<span class="recent-name">${_esc(item.handle.name)}</span>` +
      `<span class="recent-type">${item.type === 'dir' ? '資料夾' : '檔案'}</span>`;

    btn.addEventListener('click', () => _openRecent(item));
    li.appendChild(btn);
    list.appendChild(li);
  }
}

async function _openRecent(item) {
  try {
    if (item.type === 'file') {
      const { name, content } = await openFileFromHandle(item.handle);
      await _displayFile(name, content);
      _enterSingleMode();
    } else {
      const { rootName, entries } = await openDirectoryFromHandle(item.handle);
      _enterFolderMode(rootName, entries);
    }
    saveRecent(item.type, item.handle).catch(() => {}); // 更新 timestamp
  } catch (err) {
    if (err.name === 'NotAllowedError') {
      _showToast('存取被拒絕，請重新從「開啟」按鈕選擇。', 'error');
    } else if (err.name !== 'AbortError') {
      _showToast(err.message, 'error');
    }
  }
}

function _esc(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/* ──────────────────── Toast 通知 ──────────────────── */

function _showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast${type === 'error' ? ' toast-error' : ''}`;
  toast.textContent = message;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.transition = 'opacity 0.3s';
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

/* ──────────────────── Helpers ──────────────────── */

function _formatSize(bytes) {
  if (bytes >= 1024 * 1024) return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
  if (bytes >= 1024)        return `${(bytes / 1024).toFixed(0)} KB`;
  return `${bytes} B`;
}
