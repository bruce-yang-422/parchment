/**
 * app.js — 主應用邏輯
 * 協調 theme / fileLoader / renderer / tree 模組
 */

import { initTheme, cycleTheme }           from './theme.js';
import { openFile, openDirectory, openFileFromHandle, openDirectoryFromHandle, isSupportedFile, normalizeRelativePath } from './fileLoader.js';
import { setupRenderer, renderMarkdown, renderText } from './renderer.js';
import { renderTree, clearTree, setActiveTreePath } from './tree.js';
import { saveRecent, getRecents, removeRecent } from './recentFiles.js';
import { renderTOC, clearTOC, scrollToHash } from './toc.js';
import { initPWA } from './pwa.js';
import { wireTaskCheckboxes } from './taskState.js';
import { initReaderFont } from './readerFont.js';
import { initPaneResize } from './sidebarResize.js';
import { initLightboxZoom } from './lightboxZoom.js';
import { buildDocumentIndex } from './noteLinks.js';
import { initRightPanel } from './rightPanel.js';

/* ──────────────────── 初始化 ──────────────────── */

setupRenderer();
initTheme();
initReaderFont();
_refreshRecents();

/* ──────────────────── DOM 參照 ──────────────────── */

const mainEl          = document.getElementById('main');
const sidebarEl       = document.getElementById('sidebar');
const sidebarResizer  = document.getElementById('sidebar-resizer');
const treeRootName    = document.getElementById('tree-root-name');
const tagFilterStatus = document.getElementById('tag-filter-status');
const tagFilterLabel  = document.getElementById('tag-filter-label');
const tagFilterClear  = document.getElementById('tag-filter-clear');
const welcomeEl       = document.getElementById('welcome');
const readerEl        = document.getElementById('reader');
const readerBody      = document.getElementById('reader-body');
const currentFilename = document.getElementById('current-filename');
const folderPlaceholder = document.getElementById('folder-placeholder');
const dragOverlay     = document.getElementById('drag-overlay');
const lightboxEl      = document.getElementById('image-lightbox');
const lightboxImage   = document.getElementById('lightbox-image');
const lightboxClose   = document.getElementById('lightbox-close');
const contentArea     = document.getElementById('content-area');
const tocSidebar      = document.getElementById('toc-sidebar');
const tocResizer      = document.getElementById('toc-resizer');
const tocContainer    = document.getElementById('toc-container');
const hotReloadStatus = document.getElementById('hot-reload-status');
const todoLocalStatus = document.getElementById('todo-local-status');

let _folderContext = null;
let _currentDocument = null;
let _hotReloadTimer = null;
let _saveScrollTimer = null;
let _objectUrls = [];
let _activeTagFilter = null;
let _tagFilterGeneration = 0;

const rightPanel = initRightPanel({
  sidebar: tocSidebar,
  onSelectTag: _filterFolderByTag,
  onOpenDocument: _openIndexedDocument,
});

initPWA({ onFileLaunch: _openFileFromLaunchQueue });
initPaneResize(mainEl, sidebarEl, sidebarResizer, tocSidebar, {
  side: 'left',
  storageKey: 'parchment-sidebar-width',
});
initPaneResize(mainEl, tocSidebar, tocResizer, sidebarEl, {
  side: 'right',
  storageKey: 'parchment-toc-width',
});

contentArea.addEventListener('scroll', () => {
  clearTimeout(_saveScrollTimer);
  _saveScrollTimer = setTimeout(_saveReadingPosition, 160);
}, { passive: true });
window.addEventListener('beforeunload', _saveReadingPosition);

/* ──────────────────── 按鈕事件 ──────────────────── */

document.getElementById('btn-theme').addEventListener('click', cycleTheme);

document.getElementById('btn-open-file').addEventListener('click', handleOpenFile);
document.getElementById('btn-open-dir').addEventListener('click', handleOpenDir);
document.getElementById('welcome-btn-file').addEventListener('click', handleOpenFile);
document.getElementById('welcome-btn-dir').addEventListener('click', handleOpenDir);
tagFilterClear.addEventListener('click', _clearTagFilter);
readerBody.addEventListener('click', (event) => {
  const tagButton = event.target.closest('.metadata-tag');
  if (!tagButton || !readerBody.contains(tagButton)) return;
  _filterFolderByTag(tagButton.dataset.tag);
});
if (lightboxClose) {
  lightboxClose.addEventListener('click', _closeImageLightbox);
}
const lightboxZoom = lightboxEl && lightboxImage
  ? initLightboxZoom({
    lightbox: lightboxEl,
    image: lightboxImage,
    zoomIn: document.getElementById('lightbox-zoom-in'),
    zoomOut: document.getElementById('lightbox-zoom-out'),
    reset: document.getElementById('lightbox-zoom-reset'),
    level: document.getElementById('lightbox-zoom-level'),
  })
  : null;
if (lightboxEl) {
  lightboxEl.addEventListener('click', (e) => {
    if (e.target === lightboxEl) _closeImageLightbox();
  });
}
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && lightboxEl && !lightboxEl.hidden) _closeImageLightbox();
});
new ResizeObserver(() => _refreshImageOverflow(readerBody)).observe(contentArea);

async function handleOpenFile() {
  try {
    const document = await openFile();
    await _displayFile(document);
    _enterSingleMode();
    if (document.handle) saveRecent('file', document.handle).then(_refreshRecents).catch(() => {});
  } catch (err) {
    if (err.name !== 'AbortError') _showToast(err.message, 'error');
  }
}

async function handleOpenDir() {
  try {
    const directory = await openDirectory();
    _enterFolderMode(directory);
    const { handle } = directory;
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
    await _displayFile({ name: file.name, content, path: [file.name] });
    _enterSingleMode();
  } catch (err) {
    _showToast(`無法讀取檔案：${err.message}`, 'error');
  }
});

/* ──────────────────── 模式切換 ──────────────────── */

function _enterSingleMode() {
  _resetTagFilter();
  _folderContext = null;
  mainEl.classList.replace('folder-mode', 'single-mode');
  sidebarEl.hidden = true;
  sidebarResizer.hidden = true;
  folderPlaceholder.hidden = true;
  clearTree();
}

function _enterFolderMode(directory) {
  _saveReadingPosition();
  _currentDocument = null;
  if (lightboxEl && !lightboxEl.hidden) _closeImageLightbox();
  _revokeObjectUrls();
  const { rootName, entries, getFileByPath } = directory;
  _resetTagFilter();
  _folderContext = {
    rootName,
    entries,
    getFileByPath,
    documentIndex: null,
    documentIndexPromise: null,
    indexGeneration: 0,
  };
  mainEl.classList.replace('single-mode', 'folder-mode');
  sidebarEl.hidden = false;
  sidebarResizer.hidden = false;
  treeRootName.textContent = rootName;

  // 顯示 placeholder，等待使用者選擇檔案
  welcomeEl.hidden = true;
  readerEl.hidden = true;
  folderPlaceholder.hidden = false;
  clearTOC(tocSidebar, tocContainer);
  rightPanel.clear();
  _stopHotReload();

  _renderFolderTree(entries);
}

function _renderFolderTree(entries, options = {}) {
  renderTree(entries, async (entry, content) => {
    await _displayFile({ ...entry, content, folder: _folderContext });
    folderPlaceholder.hidden = true;
  }, options);
}

async function _openFileFromLaunchQueue(handle) {
  const file = await handle.getFile();
  if (!isSupportedFile(file.name)) {
    _showToast(`不支援的格式：${file.name}。請使用 .md 或 .txt 檔案。`, 'error');
    return;
  }
  await _displayFile({
    name: file.name,
    content: await file.text(),
    handle,
    path: [file.name],
  });
  _enterSingleMode();
  saveRecent('file', handle).then(_refreshRecents).catch(() => {});
}

/* ──────────────────── 內容顯示 ──────────────────── */

async function _displayFile(doc, options = {}) {
  const { name, content } = doc;
  const previousTop = contentArea.scrollTop;
  if (!options.hotReload) _saveReadingPosition();
  _currentDocument = doc;
  if (lightboxEl && !lightboxEl.hidden) _closeImageLightbox();
  _revokeObjectUrls();

  // 大檔案警告（> 5 MB）
  if (content.length > 5 * 1024 * 1024) {
    _showToast(`檔案較大（${_formatSize(content.length)}），渲染可能較慢。`, 'info');
  }

  currentFilename.textContent = name;

  const isMarkdown = /\.md$/i.test(name);
  readerBody.innerHTML = isMarkdown
    ? renderMarkdown(content)
    : renderText(content);
  _syncActiveTagButtons();

  let taskStorageWarningShown = false;
  const taskCount = isMarkdown
    ? wireTaskCheckboxes(readerBody, doc, {
      onStorageError: () => {
        if (taskStorageWarningShown) return;
        taskStorageWarningShown = true;
        _showToast('無法保存 TODO 檢核狀態；本次勾選不會保留。', 'error');
      },
    })
    : 0;
  if (todoLocalStatus) todoLocalStatus.hidden = taskCount === 0;

  if (isMarkdown) {
    await _resolveRelativeImages(readerBody, doc);
    _wireDocumentLinks(readerBody, doc);
  }

  // ── Mermaid 渲染 ──────────────────────────────────────────────────
  // 以 mermaid.render 產生 SVG，經 DOMPurify 清理後替換原節點。
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
        wrapper.appendChild(_sanitizeDiagramSvg(svg, { allowForeignObject: true }));
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

  await _renderGraphvizDiagrams(readerBody);

  _enhanceImages(readerBody);
  _attachCopyButtons(readerBody);

  welcomeEl.hidden = true;
  readerEl.hidden = false;

  renderTOC(readerBody, tocSidebar, tocContainer, contentArea);
  if (isMarkdown) {
    rightPanel.render(doc, doc.folder ? _getFolderDocumentIndex(doc.folder) : null);
  } else {
    rightPanel.clear();
  }
  _startHotReload(doc);

  if (options.hotReload) {
    contentArea.scrollTop = previousTop;
  } else if (options.hash && scrollToHash(options.hash, contentArea)) {
    history.replaceState(null, '', options.hash);
  } else {
    if (location.hash) history.replaceState(null, '', location.pathname + location.search);
    _restoreReadingPosition(doc);
  }
}

/* ──────────────────── 標籤篩選 ──────────────────── */

async function _filterFolderByTag(rawTag) {
  const tag = String(rawTag || '').trim().replace(/^#/, '');
  if (!tag) return;
  if (!_folderContext) {
    _showToast('請先開啟資料夾，再用標籤篩選文件。');
    return;
  }

  const context = _folderContext;
  const generation = ++_tagFilterGeneration;
  _activeTagFilter = tag;
  tagFilterStatus.hidden = false;
  tagFilterLabel.textContent = `#${tag} · 搜尋中…`;
  _syncActiveTagButtons();

  try {
    const index = await _getFolderTagIndex(context);
    if (generation !== _tagFilterGeneration || context !== _folderContext) return;

    const matches = index.get(_normalizedTag(tag)) || new Set();
    const filteredEntries = _filterEntriesByPath(context.entries, matches);
    _renderFolderTree(filteredEntries, { expandDirectories: true });
    tagFilterLabel.textContent = `#${tag} · ${matches.size} 個文件`;

    const currentPath = _currentDocument?.path;
    if (currentPath && matches.has(_treePathKey(currentPath))) setActiveTreePath(currentPath);
    _syncActiveTagButtons();
  } catch (error) {
    if (generation !== _tagFilterGeneration) return;
    _showToast(`無法建立標籤索引：${error.message}`, 'error');
    _clearTagFilter();
  }
}

function _clearTagFilter() {
  _tagFilterGeneration += 1;
  _activeTagFilter = null;
  tagFilterStatus.hidden = true;
  tagFilterLabel.textContent = '';
  if (!_folderContext) return;

  _renderFolderTree(_folderContext.entries);
  if (_currentDocument?.path) setActiveTreePath(_currentDocument.path);
  _syncActiveTagButtons();
}

function _resetTagFilter() {
  _tagFilterGeneration += 1;
  _activeTagFilter = null;
  tagFilterStatus.hidden = true;
  tagFilterLabel.textContent = '';
}

function _syncActiveTagButtons() {
  const active = _activeTagFilter ? _normalizedTag(_activeTagFilter) : null;
  readerBody.querySelectorAll('.metadata-tag').forEach(button => {
    button.setAttribute('aria-pressed', String(active === _normalizedTag(button.dataset.tag)));
  });
}

async function _getFolderTagIndex(context) {
  return (await _getFolderDocumentIndex(context)).tags;
}

function _getFolderDocumentIndex(context) {
  if (context.documentIndex) return Promise.resolve(context.documentIndex);
  if (context.documentIndexPromise) return context.documentIndexPromise;

  const generation = context.indexGeneration;
  const promise = buildDocumentIndex(context.entries)
    .then(index => {
      if (generation === context.indexGeneration) context.documentIndex = index;
      return index;
    })
    .finally(() => {
      if (context.documentIndexPromise === promise) context.documentIndexPromise = null;
    });
  context.documentIndexPromise = promise;
  return promise;
}

function _invalidateDocumentIndex(context) {
  context.indexGeneration += 1;
  context.documentIndex = null;
  context.documentIndexPromise = null;
}

async function _openIndexedDocument(entry) {
  if (!_folderContext) return;
  if (_activeTagFilter) _clearTagFilter();
  try {
    const file = await entry.handle.getFile();
    await _displayFile({ ...entry, content: await file.text(), folder: _folderContext });
    setActiveTreePath(entry.path);
    folderPlaceholder.hidden = true;
  } catch (error) {
    _showToast(`無法開啟連結文件：${error.message}`, 'error');
  }
}

function _filterEntriesByPath(entries, matches) {
  const filtered = [];
  for (const entry of entries) {
    if (entry.type === 'dir') {
      const children = _filterEntriesByPath(entry.children, matches);
      if (children.length) filtered.push({ ...entry, children });
    } else if (matches.has(_treePathKey(entry.path))) {
      filtered.push(entry);
    }
  }
  return filtered;
}

function _treePathKey(path) {
  return path.join('/').toLocaleLowerCase();
}

function _normalizedTag(tag) {
  return String(tag || '').trim().replace(/^#/, '').toLocaleLowerCase();
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
  const intrinsicWidth = Math.ceil(viewBox?.width || widthAttr || 0);
  const intrinsicHeight = Math.ceil(viewBox?.height || heightAttr || 0);

  // 縮放至欄寬（不放大超過原始尺寸），由 viewBox 維持比例。
  svg.removeAttribute('height');
  svg.style.width = '100%';
  svg.style.height = 'auto';
  svg.style.maxWidth = intrinsicWidth ? `${intrinsicWidth}px` : '100%';

  // 點擊以原始尺寸在燈箱中檢視。
  wrapper.classList.add('diagram-zoomable');
  wrapper.title = '點擊放大檢視';
  wrapper.addEventListener('click', () => {
    const clone = svg.cloneNode(true);
    clone.removeAttribute('style');
    if (intrinsicWidth) clone.setAttribute('width', intrinsicWidth);
    if (intrinsicHeight) clone.setAttribute('height', intrinsicHeight);
    const markup = new XMLSerializer().serializeToString(clone);
    const url = URL.createObjectURL(new Blob([markup], { type: 'image/svg+xml' }));
    _objectUrls.push(url);
    _openImageLightbox({ src: url, alt: 'Mermaid 圖表' });
  });
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
  lightboxZoom?.reset();
  lightboxImage.src = img.currentSrc || img.src;
  lightboxImage.alt = img.alt || '';
  lightboxEl.hidden = false;
  document.body.style.overflow = 'hidden';
}

function _closeImageLightbox() {
  if (!lightboxEl || !lightboxImage) return;
  lightboxEl.hidden = true;
  lightboxZoom?.reset();
  lightboxImage.removeAttribute('src');
  lightboxImage.alt = '';
  document.body.style.overflow = '';
}

/* ──────────────────── 本機相對路徑 ──────────────────── */

async function _resolveRelativeImages(container, document) {
  const images = [...container.querySelectorAll('img[src]')];
  await Promise.all(images.map(async img => {
    const source = img.getAttribute('src');
    if (!_isRelativeReference(source)) return;

    if (!document.folder?.getFileByPath) {
      img.classList.add('local-resource-unavailable');
      img.title = '請用「開啟資料夾」授權後，才能載入本機相對圖片。';
      return;
    }

    try {
      const path = _resolvePath(document.path, source);
      const file = await document.folder.getFileByPath(path);
      const objectUrl = URL.createObjectURL(file);
      _objectUrls.push(objectUrl);
      img.src = objectUrl;
    } catch (err) {
      img.classList.add('local-resource-unavailable');
      img.title = `找不到相對圖片：${source}`;
      console.warn('無法載入相對圖片：', source, err);
    }
  }));
}

function _wireDocumentLinks(container, document) {
  container.querySelectorAll('a[href]').forEach(anchor => {
    const href = anchor.getAttribute('href');
    if (!href) return;

    if (href.startsWith('#')) {
      anchor.addEventListener('click', event => {
        if (scrollToHash(href, contentArea)) event.preventDefault();
      });
      return;
    }

    if (!_isRelativeReference(href)) {
      if (/^https?:/i.test(href)) {
        anchor.target = '_blank';
        anchor.rel = 'noopener noreferrer';
      }
      return;
    }

    const { pathname, hash } = _splitReference(href);
    if (!isSupportedFile(pathname)) return;
    anchor.addEventListener('click', async event => {
      event.preventDefault();
      if (!document.folder?.getFileByPath) {
        _showToast('請用「開啟資料夾」授權後，再開啟相對文件連結。', 'error');
        return;
      }
      try {
        const path = _resolvePath(document.path, pathname);
        const file = await document.folder.getFileByPath(path);
        const entry = _findEntryByPath(document.folder.entries, path);
        await _displayFile({
          name: file.name,
          content: await file.text(),
          path,
          handle: entry?.handle,
          folder: document.folder,
        }, { hash });
        setActiveTreePath(path);
      } catch (err) {
        _showToast(`無法開啟連結：${href}`, 'error');
        console.warn('Relative document navigation failed:', err);
      }
    });
  });
}

function _resolvePath(currentPath, reference) {
  const { pathname } = _splitReference(reference);
  const referenceParts = pathname.split('/').map(part => {
    try { return decodeURIComponent(part); } catch { return part; }
  });
  return normalizeRelativePath([...currentPath.slice(0, -1), ...referenceParts]);
}

function _splitReference(reference) {
  const hashIndex = reference.indexOf('#');
  const withoutHash = hashIndex >= 0 ? reference.slice(0, hashIndex) : reference;
  const queryIndex = withoutHash.indexOf('?');
  return {
    pathname: queryIndex >= 0 ? withoutHash.slice(0, queryIndex) : withoutHash,
    hash: hashIndex >= 0 ? reference.slice(hashIndex) : '',
  };
}

function _isRelativeReference(value) {
  return Boolean(value)
    && !value.startsWith('#')
    && !value.startsWith('/')
    && !value.startsWith('//')
    && !/^[a-z][a-z\d+.-]*:/i.test(value);
}

function _findEntryByPath(entries, path) {
  const target = path.join('/').toLocaleLowerCase();
  for (const entry of entries) {
    if (entry.type === 'file' && entry.path.join('/').toLocaleLowerCase() === target) return entry;
    if (entry.type === 'dir') {
      const found = _findEntryByPath(entry.children, path);
      if (found) return found;
    }
  }
  return null;
}

function _revokeObjectUrls() {
  for (const url of _objectUrls) URL.revokeObjectURL(url);
  _objectUrls = [];
}

/* ──────────────────── Graphviz ──────────────────── */

async function _renderGraphvizDiagrams(container) {
  const nodes = [...container.querySelectorAll('.graphviz')];
  if (!nodes.length) return;

  if (!window.ParchmentViz) {
    nodes.forEach(node => node.replaceWith(_createDiagramFallback('Graphviz', node.textContent, new Error('Graphviz 引擎未載入'))));
    return;
  }

  const viz = await window.ParchmentViz.instance();
  for (const node of nodes) {
    const source = node.textContent.trim();
    try {
      const svg = viz.renderSVGElement(source);
      const wrapper = document.createElement('div');
      wrapper.className = 'graphviz diagram-scroll';
      wrapper.appendChild(_sanitizeDiagramSvg(svg.outerHTML));
      node.replaceWith(wrapper);
    } catch (err) {
      node.replaceWith(_createDiagramFallback('Graphviz', source, err));
    }
  }
}

function _createDiagramFallback(name, source, err) {
  const wrapper = document.createElement('div');
  wrapper.className = 'diagram-fallback';
  const message = document.createElement('div');
  message.className = 'mermaid-error';
  message.textContent = `${name} 圖表無法渲染：${err?.message || '未知錯誤'}`;
  const pre = document.createElement('pre');
  const code = document.createElement('code');
  code.className = 'hljs language-plaintext';
  code.textContent = source;
  pre.appendChild(code);
  wrapper.append(message, pre);
  return wrapper;
}

function _sanitizeDiagramSvg(svg, { allowForeignObject = false } = {}) {
  // Mermaid 的 htmlLabels 把節點文字以 HTML 放在 <foreignObject> 內。
  // DOMPurify 預設會移除 <foreignObject>，且只把 annotation-xml 視為
  // HTML 整合點，SVG 底下的 HTML 元素會被刪除，導致圖表沒有文字。
  const foreignObjectOptions = allowForeignObject
    ? {
      ADD_TAGS: ['foreignObject'],
      HTML_INTEGRATION_POINTS: { 'annotation-xml': true, foreignobject: true },
    }
    : {};
  return window.DOMPurify.sanitize(svg, {
    USE_PROFILES: { html: true, svg: true, svgFilters: true },
    ...foreignObjectOptions,
    RETURN_DOM_FRAGMENT: true,
  });
}

/* ──────────────────── 閱讀位置與熱更新 ──────────────────── */

function _readingKey(document = _currentDocument) {
  if (!document) return null;
  const root = document.folder?.rootName || 'single';
  return `parchment:position:${root}/${document.path?.join('/') || document.name}`;
}

function _saveReadingPosition() {
  const key = _readingKey();
  if (!key || readerEl.hidden) return;
  const max = Math.max(0, contentArea.scrollHeight - contentArea.clientHeight);
  localStorage.setItem(key, JSON.stringify({
    top: contentArea.scrollTop,
    ratio: max ? contentArea.scrollTop / max : 0,
    updatedAt: Date.now(),
  }));
}

function _restoreReadingPosition(document) {
  const key = _readingKey(document);
  let saved = null;
  try { saved = JSON.parse(localStorage.getItem(key)); } catch { /* ignore */ }
  requestAnimationFrame(() => {
    const max = Math.max(0, contentArea.scrollHeight - contentArea.clientHeight);
    contentArea.scrollTop = saved
      ? Math.min(saved.top ?? saved.ratio * max, max)
      : 0;
  });
}

function _startHotReload(document) {
  _stopHotReload();
  const handle = document.handle;
  if (!handle?.getFile || typeof handle.queryPermission !== 'function') return;

  let signature = null;
  hotReloadStatus.hidden = false;
  _hotReloadTimer = setInterval(async () => {
    if (_currentDocument !== document) return;
    try {
      const file = await handle.getFile();
      const nextSignature = `${file.lastModified}:${file.size}`;
      if (signature === null) {
        signature = nextSignature;
      } else if (signature !== nextSignature) {
        signature = nextSignature;
        const updated = { ...document, content: await file.text() };
        if (document.folder) _invalidateDocumentIndex(document.folder);
        await _displayFile(updated, { hotReload: true });
        _showToast(`${file.name} 已自動更新`);
      }
    } catch (err) {
      console.warn('Hot reload stopped:', err);
      _stopHotReload();
    }
  }, 1000);
}

function _stopHotReload() {
  clearInterval(_hotReloadTimer);
  _hotReloadTimer = null;
  if (hotReloadStatus) hotReloadStatus.hidden = true;
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
      const document = await openFileFromHandle(item.handle);
      await _displayFile(document);
      _enterSingleMode();
    } else {
      const directory = await openDirectoryFromHandle(item.handle);
      _enterFolderMode(directory);
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
