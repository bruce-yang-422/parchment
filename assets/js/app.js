/**
 * app.js — 主應用邏輯
 * 協調 theme / fileLoader / renderer / tree 模組
 */

import { initTheme, cycleTheme }           from './theme.js';
import { openFile, openDirectory, openFileFromHandle, openDirectoryFromHandle, isSupportedFile, normalizeRelativePath, readFileDocument } from './fileLoader.js';
import { setupRenderer, renderMarkdown, renderText } from './renderer.js';
import { renderTree, clearTree, setActiveTreePath, setAllDirectoriesExpanded, hasExpandedDirectory, getExpandedDirectoryKeys } from './tree.js';
import { sortTreeEntries, collectTreeFiles, treePathKey, isTimeSort, TREE_SORT_MODES, DEFAULT_TREE_SORT } from './treeSort.js';
import { saveRecent, getRecents, removeRecent } from './recentFiles.js';
import { renderTOC, clearTOC, scrollToHash, headingSlug } from './toc.js';
import { initPWA } from './pwa.js';
import { wireTaskCheckboxes } from './taskState.js';
import { initReaderFont } from './readerFont.js';
import { initReaderWidth } from './readerWidth.js';
import { initPaneResize } from './sidebarResize.js';
import { initLightboxZoom } from './lightboxZoom.js';
import { saveImageAsPng, pngFileName } from './imageExport.js';
import { buildDocumentIndex } from './noteLinks.js';
import { initRightPanel } from './rightPanel.js';
import { resolveWikiPath, extractNoteSection, wikiDisplayText } from './noteSyntax.js';
import { initSearchPanel } from './searchPanel.js';
import { initSettingsPanel } from './settingsPanel.js';
import { currentLocale, initI18n, t } from './i18n.js';
import { enhanceTableReadability } from './tableLayout.js';
import { initMobileLayout } from './mobileLayout.js';
import { initBackToTop } from './backToTop.js';
import { initFootnotePreview } from './footnotePreview.js';

/* ──────────────────── 初始化 ──────────────────── */

initI18n();
setupRenderer();
initTheme();
initReaderFont();
initReaderWidth(document.getElementById('reader-width-toggle'));
initSettingsPanel();
_refreshRecents();
_initWelcomeLogo();

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
const workspaceSwitcher = document.getElementById('workspace-switcher');
const workspaceToggle = document.getElementById('workspace-toggle');
const workspaceMenu = document.getElementById('workspace-menu');
const workspaceList = document.getElementById('workspace-list');
const workspaceOpenNew = document.getElementById('workspace-open-new');
const workspaceCurrentName = document.getElementById('workspace-current-name');
const mobileTreeToggle = document.getElementById('btn-mobile-tree');
const mobileInfoToggle = document.getElementById('btn-mobile-info');
const mobilePaneBackdrop = document.getElementById('mobile-pane-backdrop');
const backToTopDock = document.getElementById('back-to-top-dock');
const backToTopButton = document.getElementById('back-to-top-button');

let _folderContext = null;
let _currentDocument = null;
let _hotReloadTimer = null;
let _saveScrollTimer = null;
let _objectUrls = [];
let _activeTagFilter = null;
let _tagFilterGeneration = 0;
let _workspaceRenderGeneration = 0;

initMobileLayout({
  layout: mainEl,
  sidebar: sidebarEl,
  sidebarToggle: mobileTreeToggle,
  infoPane: tocSidebar,
  infoToggle: mobileInfoToggle,
  backdrop: mobilePaneBackdrop,
});
initBackToTop({
  scrollContainer: contentArea,
  reader: readerEl,
  dock: backToTopDock,
  button: backToTopButton,
});

const rightPanel = initRightPanel({
  sidebar: tocSidebar,
  readerBody,
  onSelectTag: _filterFolderByTag,
  onOpenDocument: _openIndexedDocument,
});
const footnotePreview = initFootnotePreview(readerBody);

const searchPanel = initSearchPanel({
  input: document.getElementById('folder-search-input'),
  status: document.getElementById('folder-search-status'),
  results: document.getElementById('search-results'),
  tree: document.getElementById('tree-container'),
  getIndex: () => (_folderContext ? _getFolderDocumentIndex(_folderContext) : null),
  onOpen: (entry, terms) => _openIndexedDocument(entry, { highlight: terms }),
});
document.addEventListener('keydown', (e) => {
  if ((e.ctrlKey || e.metaKey) && e.shiftKey && (e.key === 'F' || e.key === 'f')) {
    if (!_folderContext || sidebarEl.hidden) return;
    e.preventDefault();
    searchPanel.focus();
  }
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
document.getElementById('welcome-btn-sample')?.addEventListener('click', _openSampleDocument);
workspaceToggle.addEventListener('click', () => _setWorkspaceMenu(workspaceMenu.hidden));
workspaceOpenNew.addEventListener('click', () => {
  _setWorkspaceMenu(false);
  handleOpenDir();
});
document.addEventListener('click', event => {
  if (!workspaceMenu.hidden && !workspaceSwitcher.contains(event.target)) _setWorkspaceMenu(false);
});
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && !workspaceMenu.hidden) {
    _setWorkspaceMenu(false);
    workspaceToggle.focus();
  }
});
tagFilterClear.addEventListener('click', _clearTagFilter);
document.addEventListener('click', event => {
  const button = event.target.closest('button.image-unavailable-toggle');
  if (!button) return;
  const message = button.parentElement.querySelector('.image-unavailable-message');
  if (!message) return;
  message.hidden = !message.hidden;
  button.setAttribute('aria-expanded', String(!message.hidden));
});
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
const lightboxSavePng = document.getElementById('lightbox-save-png');
lightboxSavePng?.addEventListener('click', _saveLightboxImage);
document.addEventListener('keydown', (e) => {
  if (lightboxEl && !lightboxEl.hidden && (e.key === 's' || e.key === 'S')
    && !e.ctrlKey && !e.metaKey && !e.altKey) {
    e.preventDefault();
    _saveLightboxImage();
  }
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && lightboxEl && !lightboxEl.hidden) _closeImageLightbox();
});

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
    _showToast(t('不支援的格式：{name}。請使用 .md 或 .txt 檔案。', { name: file.name }), 'error');
    return;
  }

  try {
    await _displayFile({ ...await readFileDocument(file), path: [file.name] });
    _enterSingleMode();
  } catch (err) {
    _showToast(t('無法讀取檔案：{message}', { message: err.message }), 'error');
  }
});

/* ──────────────────── 模式切換 ──────────────────── */

function _enterSingleMode() {
  _resetTagFilter();
  searchPanel.reset();
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
  footnotePreview.close();
  if (lightboxEl && !lightboxEl.hidden) _closeImageLightbox();
  _revokeObjectUrls();
  const { rootName, entries, getFileByPath, files = [], handle = null } = directory;
  _resetTagFilter();
  searchPanel.reset();
  _folderContext = {
    rootName,
    entries,
    files,
    notePaths: _collectNotePaths(entries),
    getFileByPath,
    handle,
    documentIndex: null,
    documentIndexPromise: null,
    indexGeneration: 0,
  };
  mainEl.classList.replace('single-mode', 'folder-mode');
  sidebarEl.hidden = false;
  sidebarResizer.hidden = false;
  treeRootName.textContent = rootName;
  workspaceCurrentName.textContent = rootName;
  workspaceCurrentName.title = rootName;
  _setWorkspaceMenu(false);

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
  const context = _folderContext;
  _treeEntries = entries;
  if (context && isTimeSort(_treeSortMode) && !context.mtimes) _loadModifiedTimes(context);
  renderTree(sortTreeEntries(entries, _treeSortMode, context?.mtimes || new Map()), async (entry, file) => {
    await _displayFile({ ...entry, ...await readFileDocument(file), folder: context });
    folderPlaceholder.hidden = true;
  }, { ...options, onExpansionChange: _syncTreeCollapseButton });
}

/* ──────────────────── 資料夾樹：排序與折疊 ──────────────────── */

const TREE_SORT_STORAGE_KEY = 'parchment-tree-sort';
const treeSortToggle = document.getElementById('tree-sort-toggle');
const treeSortMenu = document.getElementById('tree-sort-menu');
const treeCollapseToggle = document.getElementById('tree-collapse-toggle');
let _treeEntries = [];
let _treeSortMode = (() => {
  try {
    const saved = localStorage.getItem(TREE_SORT_STORAGE_KEY);
    return TREE_SORT_MODES.includes(saved) ? saved : DEFAULT_TREE_SORT;
  } catch {
    return DEFAULT_TREE_SORT;
  }
})();

function _syncTreeSortMenu() {
  treeSortMenu?.querySelectorAll('[data-tree-sort]').forEach(item => {
    item.setAttribute('aria-checked', String(item.dataset.treeSort === _treeSortMode));
  });
}

function _setTreeSortMenu(open) {
  if (!treeSortMenu || !treeSortToggle) return;
  treeSortMenu.hidden = !open;
  treeSortToggle.setAttribute('aria-expanded', String(open));
  if (open) {
    _syncTreeSortMenu();
    treeSortMenu.querySelector('[aria-checked="true"]')?.focus();
  }
}

/** 重新排序後保留展開狀態與目前文件的反白。 */
function _rerenderFolderTree() {
  if (!_folderContext) return;
  const expandedKeys = getExpandedDirectoryKeys();
  _renderFolderTree(_treeEntries, { expandedKeys });
  if (_currentDocument?.path) setActiveTreePath(_currentDocument.path);
}

/** 讀取所有檔案的最後修改時間（瀏覽器不提供建立時間），完成後依時間重新排序。 */
function _loadModifiedTimes(context) {
  if (context.mtimesPromise) return context.mtimesPromise;
  const files = collectTreeFiles(context.entries);
  const mtimes = new Map();
  let cursor = 0;
  const worker = async () => {
    while (cursor < files.length) {
      const entry = files[cursor++];
      try {
        const file = await entry.handle.getFile();
        mtimes.set(treePathKey(entry.path), file.lastModified);
      } catch { /* 無法讀取的檔案排在最後 */ }
    }
  };
  context.mtimesPromise = Promise.all(Array.from({ length: Math.min(16, files.length) }, worker))
    .then(() => {
      context.mtimes = mtimes;
      if (context === _folderContext && isTimeSort(_treeSortMode)) _rerenderFolderTree();
    });
  return context.mtimesPromise;
}

function _syncTreeCollapseButton() {
  if (!treeCollapseToggle) return;
  const expanded = hasExpandedDirectory();
  const label = t(expanded ? '全部折疊' : '全部展開');
  treeCollapseToggle.title = label;
  treeCollapseToggle.setAttribute('aria-label', label);
  treeCollapseToggle.querySelector('[data-tree-icon="expand"]').toggleAttribute('hidden', expanded);
  treeCollapseToggle.querySelector('[data-tree-icon="collapse"]').toggleAttribute('hidden', !expanded);
}

treeSortToggle?.addEventListener('click', () => _setTreeSortMenu(treeSortMenu.hidden));
treeSortMenu?.addEventListener('click', event => {
  const item = event.target.closest('[data-tree-sort]');
  if (!item) return;
  _treeSortMode = item.dataset.treeSort;
  try { localStorage.setItem(TREE_SORT_STORAGE_KEY, _treeSortMode); } catch { /* 僅本次有效 */ }
  _setTreeSortMenu(false);
  treeSortToggle.focus();
  _rerenderFolderTree();
});
treeSortMenu?.addEventListener('keydown', event => {
  const items = [...treeSortMenu.querySelectorAll('[data-tree-sort]')];
  const index = items.indexOf(document.activeElement);
  if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
    event.preventDefault();
    const next = (index + (event.key === 'ArrowDown' ? 1 : -1) + items.length) % items.length;
    items[next].focus();
  } else if (event.key === 'Escape') {
    event.preventDefault();
    event.stopPropagation();
    _setTreeSortMenu(false);
    treeSortToggle.focus();
  }
});
document.addEventListener('click', event => {
  if (treeSortMenu && !treeSortMenu.hidden && !event.target.closest('.tree-sort')) _setTreeSortMenu(false);
});
treeCollapseToggle?.addEventListener('click', () => setAllDirectoriesExpanded(!hasExpandedDirectory()));
_syncTreeSortMenu();

/* ──────────────────── 首頁標誌 ──────────────────── */

/** 標誌圖片載入成功時隱藏文字替代標誌；失敗時隱藏圖片（取代內嵌 onload／onerror，以符合 CSP）。 */
function _initWelcomeLogo() {
  const img = document.querySelector('.welcome-logo-image');
  if (!img) return;
  const showImage = () => {
    if (img.previousElementSibling) img.previousElementSibling.hidden = true;
  };
  const hideImage = () => { img.hidden = true; };
  if (img.complete) {
    if (img.naturalWidth) showImage();
    else hideImage();
    return;
  }
  img.addEventListener('load', showImage, { once: true });
  img.addEventListener('error', hideImage, { once: true });
}

/* ──────────────────── 範例文件 ──────────────────── */

const SAMPLE_ASSETS = ['image/parchment-logo-transparent.png'];

function _sampleNotes() {
  const locale = currentLocale();
  const directory = locale === 'zh-TW' ? 'samples' : `samples/${locale}`;
  return [`${directory}/parchment-guide.md`, `${directory}/linked-note.md`];
}

/**
 * 開啟隨網站提供的範例文件。兩份範例筆記與標誌圖片組成一個小型資料夾，
 * 讓 Wiki Links、內嵌、相對圖片與雙向連結也能示範；檔案以 fetch 從網站讀取，離線時由 Service Worker 提供。
 */
async function _openSampleDocument() {
  const sampleNotes = _sampleNotes();
  const fetchFile = async path => {
    const parts = normalizeRelativePath(path);
    const url = new URL(parts.map(encodeURIComponent).join('/'), document.baseURI);
    const response = await fetch(url);
    if (!response.ok) throw new DOMException(t('找不到檔案：{name}', { name: parts.join('/') }), 'NotFoundError');
    return new File([await response.blob()], parts.at(-1));
  };
  const notePaths = sampleNotes.map(file => file.split('/'));
  const entries = notePaths.map(path => ({
    type: 'file',
    name: path.at(-1),
    path,
    handle: { getFile: () => fetchFile(path) },
  }));
  const folder = {
    rootName: t('範例'),
    isSample: true,
    entries,
    files: [...notePaths, ...SAMPLE_ASSETS.map(file => file.split('/'))],
    notePaths,
    getFileByPath: fetchFile,
    documentIndex: null,
    documentIndexPromise: null,
    indexGeneration: 0,
  };

  try {
    const [entry] = entries;
    const file = await entry.handle.getFile();
    await _displayFile({ ...entry, ...await readFileDocument(file, { lastModified: null }), folder });
    _enterSingleMode();
  } catch (err) {
    _showToast(t('無法開啟範例文件：{message}', { message: err.message }), 'error');
  }
}

/* ──────────────────── 以網址開啟本機檔案（瀏覽器外掛） ──────────────────── */

/**
 * index.html?file=file:///D:/notes/a.md：讀取該檔案並以單檔模式顯示。
 * 瀏覽器外掛在使用者直接開啟本機 .md 檔時會導向此網址。
 * 相對圖片與相對 .md 連結以檔案所在資料夾解析，透過 XMLHttpRequest 讀取 file:// 網址。
 */
async function _openFromUrlParameter() {
  const fileUrl = new URLSearchParams(location.search).get('file');
  if (!fileUrl || !/^file:\/\//i.test(fileUrl)) return;
  try {
    const url = new URL(fileUrl);
    const segments = url.pathname.split('/').filter(Boolean).map(part => {
      try { return decodeURIComponent(part); } catch { return part; }
    });
    const base = `file://${url.host}/`;
    const folder = {
      rootName: url.host || segments[0] || '/',
      entries: [],
      files: [],
      notePaths: [],
      fileUrlBase: base,
      documentIndex: null,
      documentIndexPromise: null,
      indexGeneration: 0,
      getFileByPath: async path => {
        const parts = normalizeRelativePath(path);
        const target = base + parts.map(part => encodeURIComponent(part).replace(/%3A/gi, ':')).join('/');
        return _readFileUrl(target, parts.at(-1));
      },
    };
    const file = await folder.getFileByPath(segments);
    if (!isSupportedFile(file.name)) throw new Error(t('不支援的格式：{name}', { name: file.name }));
    await _displayFile({ ...await readFileDocument(file, { lastModified: null }), path: segments, folder });
    _enterSingleMode();
  } catch (err) {
    _showToast(err.message, 'error');
  }
}

/** 以 XMLHttpRequest 讀取 file:// 網址（fetch 不支援 file: 協定）。 */
function _readFileUrl(url, name) {
  return new Promise((resolve, reject) => {
    const request = new XMLHttpRequest();
    request.open('GET', url);
    request.responseType = 'blob';
    request.onload = () => {
      if ((request.status === 0 || request.status === 200) && request.response) {
        resolve(new File([request.response], name, { type: request.response.type }));
      } else {
        reject(new DOMException(t('找不到檔案：{name}', { name }), 'NotFoundError'));
      }
    };
    request.onerror = () => {
      const blocked = globalThis.chrome?.extension?.isAllowedFileSchemeAccess;
      reject(new Error(blocked
        ? t('無法讀取本機檔案：{name}。請在擴充功能詳細資料中開啟「允許存取檔案網址」。', { name })
        : t('無法讀取本機檔案：{name}', { name })));
    };
    request.send();
  });
}

async function _openFileFromLaunchQueue(handle) {
  const file = await handle.getFile();
  if (!isSupportedFile(file.name)) {
    _showToast(t('不支援的格式：{name}。請使用 .md 或 .txt 檔案。', { name: file.name }), 'error');
    return;
  }
  await _displayFile({
    ...await readFileDocument(file),
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
  // 寬表格與程式碼只允許在元件內捲動，切換文件時閱讀主容器必須回到水平原點。
  contentArea.scrollLeft = 0;
  if (!options.hotReload) _saveReadingPosition();
  _currentDocument = doc;
  footnotePreview.close();
  if (lightboxEl && !lightboxEl.hidden) _closeImageLightbox();
  _revokeObjectUrls();

  // 大檔案警告（> 5 MB）
  if (content.length > 5 * 1024 * 1024) {
    _showToast(t('檔案較大（{size}），渲染可能較慢。', { size: _formatSize(content.length) }), 'info');
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
        _showToast(t('無法保存 TODO 檢核狀態；本次勾選不會保留。'), 'error');
      },
    })
    : 0;
  if (todoLocalStatus) todoLocalStatus.hidden = taskCount === 0;

  if (isMarkdown) {
    await _resolveRelativeImages(readerBody, doc);
    await _resolveWikiImages(readerBody, doc);
    _wireDocumentLinks(readerBody, doc);
    await _renderNoteEmbeds(readerBody, doc);
  }

  enhanceTableReadability(readerBody);

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

  renderTOC(readerBody, tocSidebar, tocContainer, contentArea, { preserveExpansion: options.hotReload });
  footnotePreview.prepare();
  rightPanel.render(doc, isMarkdown && doc.folder ? _getFolderDocumentIndex(doc.folder) : null);
  _startHotReload(doc);

  if (doc.folder?.fileUrlBase && doc.path) {
    const current = doc.folder.fileUrlBase
      + doc.path.map(part => encodeURIComponent(part).replace(/%3A/gi, ':')).join('/');
    history.replaceState(null, '', `${location.pathname}?file=${encodeURIComponent(current)}`);
    document.title = `${doc.name} · Parchment`;
  } else if (new URLSearchParams(location.search).has('file')) {
    history.replaceState(null, '', location.pathname + location.hash);
    document.title = 'Parchment';
  }

  if (options.hotReload) {
    contentArea.scrollTop = previousTop;
  } else if (options.highlight?.length && _highlightSearchTerms(readerBody, options.highlight)) {
    if (location.hash) history.replaceState(null, '', location.pathname + location.search);
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
    _showToast(t('請先開啟資料夾，再用標籤篩選文件。'));
    return;
  }

  const context = _folderContext;
  const generation = ++_tagFilterGeneration;
  _activeTagFilter = tag;
  tagFilterStatus.hidden = false;
  tagFilterLabel.textContent = `#${tag} · ${t('搜尋中…')}`;
  _syncActiveTagButtons();

  try {
    const index = await _getFolderTagIndex(context);
    if (generation !== _tagFilterGeneration || context !== _folderContext) return;

    const matches = index.get(_normalizedTag(tag)) || new Set();
    const filteredEntries = _filterEntriesByPath(context.entries, matches);
    _renderFolderTree(filteredEntries, { expandDirectories: true });
    tagFilterLabel.textContent = `#${tag} · ${t('{count} 個文件', { count: matches.size })}`;

    const currentPath = _currentDocument?.path;
    if (currentPath && matches.has(_treePathKey(currentPath))) setActiveTreePath(currentPath);
    _syncActiveTagButtons();
  } catch (error) {
    if (generation !== _tagFilterGeneration) return;
    _showToast(t('無法建立標籤索引：{message}', { message: error.message }), 'error');
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

async function _openIndexedDocument(entry, options = {}) {
  if (!_folderContext) return;
  if (_activeTagFilter) _clearTagFilter();
  try {
    const file = await entry.handle.getFile();
    await _displayFile({ ...entry, ...await readFileDocument(file), folder: _folderContext }, options);
    setActiveTreePath(entry.path);
    folderPlaceholder.hidden = true;
  } catch (error) {
    _showToast(t('無法開啟連結文件：{message}', { message: error.message }), 'error');
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
    btn.textContent = t('複製');
    btn.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(code.textContent);
        btn.textContent = t('已複製');
        btn.classList.add('copied');
        setTimeout(() => {
          btn.textContent = t('複製');
          btn.classList.remove('copied');
        }, 1500);
      } catch {
        btn.textContent = t('失敗');
        setTimeout(() => { btn.textContent = t('複製'); }, 1500);
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
    : t('未知錯誤');
  error.textContent = t('Mermaid 圖表目前無法渲染，以下保留原始碼。\n錯誤：{message}', { message });

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
      lastError = new Error(t('Mermaid 備援渲染未產生 SVG 輸出'));
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
  const firstError = new Error(t('Mermaid 未開始渲染'));
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
  wrapper.title = t('點擊放大檢視');
  wrapper.addEventListener('click', () => {
    const clone = svg.cloneNode(true);
    clone.removeAttribute('style');
    if (intrinsicWidth) clone.setAttribute('width', intrinsicWidth);
    if (intrinsicHeight) clone.setAttribute('height', intrinsicHeight);
    const markup = new XMLSerializer().serializeToString(clone);
    const url = URL.createObjectURL(new Blob([markup], { type: 'image/svg+xml' }));
    _objectUrls.push(url);
    const index = [...readerBody.querySelectorAll('.mermaid')].indexOf(wrapper) + 1;
    const base = pngFileName(_currentDocument?.name, 'diagram').replace(/\.png$/, '');
    _openImageLightbox(
      { src: url, alt: t('Mermaid 圖表') },
      { downloadName: `${base}-diagram-${index || 1}.png` },
    );
  });
}

function _enhanceImages(container) {
  container.querySelectorAll('img').forEach(img => {
    if (img.closest('#image-lightbox')) return;

    const showFailure = () => {
      const source = img.currentSrc || img.getAttribute('src') || '';
      const message = /^(https?:)?\/\//i.test(source)
        ? t('無法載入遠端圖片。請檢查網路連線或圖片網址。')
        : t('無法讀取圖片內容。');
      _replaceUnavailableImage(img, message);
    };
    if (img.complete && img.naturalWidth === 0) {
      showFailure();
      return;
    }
    img.addEventListener('error', showFailure, { once: true });

    if (!img.parentElement?.classList.contains('image-scroll-inner')) {
      const frame = document.createElement('div');
      frame.className = 'image-scroll-frame';

      const inner = document.createElement('div');
      inner.className = 'image-scroll-inner';

      img.parentNode.insertBefore(frame, img);
      frame.appendChild(inner);
      inner.appendChild(img);
    }

    // 圖片縮放至閱讀欄寬（CSS max-width），點擊以燈箱檢視原始尺寸
    img.classList.add('image-zoomable');
    if (!img.dataset.zoomBound) {
      img.addEventListener('click', () => _openImageLightbox(img));
      img.dataset.zoomBound = 'true';
    }
  });
}

function _replaceUnavailableImage(img, reason) {
  const fallback = document.createElement('span');
  fallback.className = 'image-unavailable';
  const toggle = document.createElement('button');
  toggle.type = 'button';
  toggle.className = 'image-unavailable-toggle';
  toggle.setAttribute('aria-expanded', 'false');
  toggle.textContent = t('圖片無法顯示');
  const alt = img.alt?.trim();
  if (alt) {
    const label = document.createElement('span');
    label.className = 'image-unavailable-alt';
    label.textContent = alt;
    toggle.append(label);
  }
  const message = document.createElement('span');
  message.className = 'image-unavailable-message';
  message.textContent = reason;
  message.hidden = true;
  fallback.append(toggle, message);

  const frame = img.closest('.image-scroll-frame') || img;
  const link = img.closest('a');
  if (!link) {
    frame.replaceWith(fallback);
  } else if (link.textContent.trim() || link.querySelectorAll('img, svg').length > 1) {
    link.after(fallback);
    frame.remove();
  } else {
    link.replaceWith(fallback);
  }
}

function _openImageLightbox(img, { downloadName } = {}) {
  if (!lightboxEl || !lightboxImage) return;
  lightboxZoom?.reset();
  lightboxImage.src = img.currentSrc || img.src;
  lightboxImage.alt = img.alt || '';
  lightboxImage.dataset.downloadName = downloadName || _imageDownloadName(img);
  lightboxEl.hidden = false;
  document.body.style.overflow = 'hidden';
}

function _closeImageLightbox() {
  if (!lightboxEl || !lightboxImage) return;
  lightboxEl.hidden = true;
  lightboxZoom?.reset();
  lightboxImage.removeAttribute('src');
  lightboxImage.alt = '';
  delete lightboxImage.dataset.downloadName;
  document.body.style.overflow = '';
}

function _imageDownloadName(img) {
  // blob: URL 沒有可用檔名，改用 Markdown 原始 src、alt 或文件名稱。
  const original = img.getAttribute?.('src') || '';
  let fromSrc = /^(blob:|data:)/i.test(original) ? '' : original.split(/[?#]/)[0];
  try { fromSrc = decodeURIComponent(fromSrc); } catch { /* 保留原字串 */ }
  return pngFileName(fromSrc || img.alt || _currentDocument?.name, 'image');
}

async function _saveLightboxImage() {
  const src = lightboxImage?.getAttribute('src');
  if (!src || lightboxSavePng?.disabled) return;
  if (lightboxSavePng) lightboxSavePng.disabled = true;
  try {
    await saveImageAsPng(src, lightboxImage.dataset.downloadName || 'image.png');
  } catch (err) {
    _showToast(t('無法存成 PNG：{message}', { message: err.message }), 'error');
  } finally {
    if (lightboxSavePng) lightboxSavePng.disabled = false;
  }
}

/* ──────────────────── 本機相對路徑 ──────────────────── */

async function _resolveRelativeImages(container, document) {
  const images = [...container.querySelectorAll('img[src]')];
  await Promise.all(images.map(async img => {
    const source = img.getAttribute('src');
    if (!_isRelativeReference(source)) return;
    img.removeAttribute('src');

    if (!document.folder?.getFileByPath) {
      _replaceUnavailableImage(img, t('請用「開啟資料夾」授權後，才能載入本機相對圖片。'));
      return;
    }

    try {
      let file;
      try {
        file = await document.folder.getFileByPath(_resolvePath(document.path, source));
      } catch (err) {
        // 「最短路徑」連結格式只寫檔名，改依檔名在資料夾內尋找
        const fallback = resolveWikiPath(_splitReference(source).pathname, document.path, document.folder.files || []);
        if (!fallback) throw err;
        file = await document.folder.getFileByPath(fallback);
      }
      const objectUrl = URL.createObjectURL(file);
      _objectUrls.push(objectUrl);
      img.src = objectUrl;
    } catch (err) {
      const message = err.name === 'NotFoundError'
        ? t('找不到相對圖片：{source}', { source })
        : t('無法存取圖片：{source}', { source });
      _replaceUnavailableImage(img, message);
      console.warn('無法載入相對圖片：', source, err);
    }
  }));
}

function _wireDocumentLinks(container, document) {
  container.querySelectorAll('a[href]').forEach(anchor => {
    if (anchor.classList.contains('wiki-link')) {
      _wireWikiLink(anchor, document);
      return;
    }
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
        _showToast(t('請用「開啟資料夾」授權後，再開啟相對文件連結。'), 'error');
        return;
      }
      try {
        const path = _resolvePath(document.path, pathname);
        const file = await document.folder.getFileByPath(path);
        const entry = _findEntryByPath(document.folder.entries, path);
        await _displayFile({
          ...await readFileDocument(file, { lastModified: document.folder.fileUrlBase || document.folder.isSample ? null : file.lastModified }),
          path,
          handle: entry?.handle,
          folder: document.folder,
        }, { hash });
        setActiveTreePath(path);
      } catch (err) {
        _showToast(t('無法開啟連結：{target}', { target: href }), 'error');
        console.warn('Relative document navigation failed:', err);
      }
    });
  });
}

/* ──────────────────── Wiki Links 與內嵌 ──────────────────── */

const EMBED_MAX_DEPTH = 4;

function _collectNotePaths(entries, output = []) {
  for (const entry of entries) {
    if (entry.type === 'dir') _collectNotePaths(entry.children, output);
    else output.push(entry.path);
  }
  return output;
}

/** 依最短路徑規則解析筆記；找不到時比對已建立索引中的 aliases，再找附件。 */
function _resolveWikiTarget(target, sourcePath, folder) {
  const note = resolveWikiPath(target, sourcePath, folder.notePaths || [], { markdown: true });
  if (note) return { kind: 'note', path: note };

  const wanted = target.split('/').at(-1).toLocaleLowerCase();
  for (const record of folder.documentIndex?.records.values() || []) {
    if ((record.aliases || []).some(alias => alias.toLocaleLowerCase() === wanted)) {
      return { kind: 'note', path: record.entry.path };
    }
  }

  const attachment = resolveWikiPath(target, sourcePath, folder.files || []);
  return attachment ? { kind: 'attachment', path: attachment } : null;
}

function _wireWikiLink(anchor, doc) {
  const target = anchor.dataset.wikiTarget || '';
  const heading = anchor.dataset.wikiHeading || '';
  const hash = heading ? `#${encodeURIComponent(headingSlug(heading))}` : '';

  if (!target) {
    anchor.addEventListener('click', event => {
      event.preventDefault();
      if (hash) scrollToHash(hash, contentArea);
    });
    return;
  }

  const folder = doc.folder;
  const resolved = folder ? _resolveWikiTarget(target, doc.path, folder) : null;
  if (folder && !resolved) {
    anchor.classList.add('is-unresolved');
    anchor.title = t('找不到筆記：{target}', { target });
  }

  anchor.addEventListener('click', async event => {
    event.preventDefault();
    if (!folder?.getFileByPath) {
      _showToast(t('請用「開啟資料夾」授權後，再開啟 Wiki 連結。'), 'error');
      return;
    }
    const result = resolved || _resolveWikiTarget(target, doc.path, folder);
    if (!result) {
      _showToast(t('找不到筆記：{target}', { target }), 'error');
      return;
    }
    try {
      if (result.kind === 'attachment' && !isSupportedFile(result.path.at(-1))) {
        const file = await folder.getFileByPath(result.path);
        const url = URL.createObjectURL(file);
        _objectUrls.push(url);
        window.open(url, '_blank', 'noopener');
        return;
      }
      await _openFolderDocument(folder, result.path, { hash });
    } catch (err) {
      _showToast(t('無法開啟連結：{target}', { target }), 'error');
      console.warn('Wiki link navigation failed:', err);
    }
  });
}

async function _openFolderDocument(folder, path, options = {}) {
  const file = await folder.getFileByPath(path);
  const entry = _findEntryByPath(folder.entries, path);
  await _displayFile({
    ...await readFileDocument(file, { lastModified: folder.fileUrlBase || folder.isSample ? null : file.lastModified }),
    path,
    handle: entry?.handle,
    folder,
  }, options);
  setActiveTreePath(path);
  folderPlaceholder.hidden = true;
}

/** ![[圖片.png]]：依檔名在資料夾內尋找附件。 */
async function _resolveWikiImages(container, doc) {
  const images = [...container.querySelectorAll('img[data-wiki-embed]:not([src])')];
  await Promise.all(images.map(async img => {
    const target = img.dataset.wikiEmbed;
    if (!doc.folder?.getFileByPath) {
      _replaceUnavailableImage(img, t('請用「開啟資料夾」授權後，才能載入內嵌圖片。'));
      return;
    }
    const path = resolveWikiPath(target, doc.path, doc.folder.files || []);
    try {
      if (!path) throw new DOMException('File not found', 'NotFoundError');
      const objectUrl = URL.createObjectURL(await doc.folder.getFileByPath(path));
      _objectUrls.push(objectUrl);
      img.src = objectUrl;
    } catch (err) {
      const message = err.name === 'NotFoundError'
        ? t('找不到內嵌圖片：{target}', { target })
        : t('無法存取圖片：{source}', { source: target });
      _replaceUnavailableImage(img, message);
    }
  }));
}

/** ![[筆記]]、![[筆記#標題]]、![[筆記#^區塊]]：讀取並渲染被內嵌的筆記。 */
async function _renderNoteEmbeds(container, doc, depth = 0, seen = new Set([_treePathKey(doc.path || [doc.name])])) {
  const placeholders = [...container.querySelectorAll('.note-embed-placeholder')];
  for (const placeholder of placeholders) {
    const meta = {
      target: placeholder.dataset.wikiTarget || '',
      heading: placeholder.dataset.wikiHeading || '',
      blockId: placeholder.dataset.wikiBlock || '',
      alias: '',
    };
    const embed = await _buildNoteEmbed(meta, doc, depth, seen);
    const holder = placeholder.parentElement;
    if (holder?.tagName === 'P' && holder.children.length === 1
      && holder.textContent.trim() === placeholder.textContent.trim()) {
      holder.replaceWith(embed);
    } else {
      placeholder.replaceWith(embed);
    }
  }
}

async function _buildNoteEmbed(meta, doc, depth, seen) {
  const wrapper = document.createElement('div');
  wrapper.className = 'note-embed';

  const header = document.createElement('div');
  header.className = 'note-embed-header';
  const link = document.createElement('a');
  link.className = 'wiki-link';
  link.href = meta.target ? encodeURI(meta.target) : '#';
  link.dataset.wikiTarget = meta.target;
  link.dataset.wikiHeading = meta.heading;
  link.dataset.wikiBlock = meta.blockId;
  link.textContent = wikiDisplayText(meta) || doc.name;
  header.appendChild(link);
  wrapper.appendChild(header);

  const body = document.createElement('div');
  body.className = 'note-embed-body';
  wrapper.appendChild(body);

  const fail = message => {
    wrapper.classList.add('note-embed-missing');
    body.textContent = message;
    return wrapper;
  };

  const folder = doc.folder;
  _wireWikiLink(link, doc);
  if (meta.target && !folder?.getFileByPath) return fail(t('請用「開啟資料夾」授權後，才能顯示內嵌筆記。'));

  // ![[#標題]] 內嵌目前筆記的段落
  const resolved = meta.target
    ? _resolveWikiTarget(meta.target, doc.path, folder)
    : { kind: 'note', path: doc.path || [doc.name] };
  if (!resolved || resolved.kind !== 'note') return fail(t('找不到內嵌筆記：{target}', { target: meta.target }));

  const key = _treePathKey(resolved.path);
  if (depth >= EMBED_MAX_DEPTH) return fail(t('內嵌層數過多，已略過。'));
  if (seen.has(key) && !meta.heading && !meta.blockId) return fail(t('筆記內嵌了自己（循環內嵌），已略過。'));

  try {
    const file = meta.target ? await folder.getFileByPath(resolved.path) : null;
    const content = file ? await file.text() : doc.content;
    const name = file?.name || doc.name;
    const isMarkdown = /\.md$/i.test(name);
    const section = isMarkdown
      ? extractNoteSection(content, { heading: meta.heading, blockId: meta.blockId })
      : content;
    if (section === null) {
      return fail(meta.blockId
        ? t('在「{name}」找不到區塊 ^{block}。', { name, block: meta.blockId })
        : t('在「{name}」找不到標題「{heading}」。', { name, heading: meta.heading }));
    }

    body.innerHTML = isMarkdown ? renderMarkdown(section, { properties: false }) : renderText(section);
    const embedDoc = { name, path: resolved.path, folder, content };
    if (isMarkdown) {
      await _resolveRelativeImages(body, embedDoc);
      await _resolveWikiImages(body, embedDoc);
      _wireDocumentLinks(body, embedDoc);
      await _renderNoteEmbeds(body, embedDoc, depth + 1, new Set([...seen, key]));
    }
    return wrapper;
  } catch (err) {
    console.warn('Note embed failed:', err);
    return fail(t('無法讀取內嵌筆記：{target}', { target: meta.target }));
  }
}

/** 搜尋結果開啟後，標示關鍵字並捲動到第一個符合處。 */
function _highlightSearchTerms(container, terms) {
  const lowered = terms.map(term => term.toLocaleLowerCase()).filter(Boolean);
  if (!lowered.length) return false;
  const walker = document.createTreeWalker(container, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      if (!node.nodeValue.trim()) return NodeFilter.FILTER_REJECT;
      return node.parentElement?.closest('script, style, svg, .katex, .copy-btn, mark.search-hit')
        ? NodeFilter.FILTER_REJECT
        : NodeFilter.FILTER_ACCEPT;
    },
  });
  const nodes = [];
  while (walker.nextNode()) nodes.push(walker.currentNode);

  let count = 0;
  let first = null;
  for (const node of nodes) {
    if (count >= 500) break;
    const text = node.nodeValue;
    const lower = text.toLocaleLowerCase();
    const ranges = [];
    for (const term of lowered) {
      let from = 0;
      let found;
      while ((found = lower.indexOf(term, from)) >= 0) {
        ranges.push([found, found + term.length]);
        from = found + term.length;
      }
    }
    if (!ranges.length) continue;
    ranges.sort((a, b) => a[0] - b[0]);

    const fragment = document.createDocumentFragment();
    let cursor = 0;
    for (const [start, end] of ranges) {
      if (start < cursor) continue;
      if (start > cursor) fragment.append(text.slice(cursor, start));
      const mark = document.createElement('mark');
      mark.className = 'search-hit';
      mark.textContent = text.slice(start, end);
      fragment.append(mark);
      first ??= mark;
      cursor = end;
      count += 1;
    }
    if (cursor < text.length) fragment.append(text.slice(cursor));
    node.replaceWith(fragment);
  }

  if (!first) return false;
  const target = first;
  requestAnimationFrame(() => {
    const top = target.getBoundingClientRect().top - contentArea.getBoundingClientRect().top + contentArea.scrollTop;
    contentArea.scrollTop = Math.max(0, top - contentArea.clientHeight / 3);
  });
  return true;
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
    nodes.forEach(node => node.replaceWith(_createDiagramFallback('Graphviz', node.textContent, new Error(t('Graphviz 引擎未載入')))));
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
  message.textContent = t('{name} 圖表無法渲染：{message}', { name, message: err?.message || t('未知錯誤') });
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
        document.folder?.mtimes?.set(treePathKey(document.path), file.lastModified);
        const updated = { ...document, ...await readFileDocument(file) };
        if (document.folder) _invalidateDocumentIndex(document.folder);
        await _displayFile(updated, { hotReload: true });
        searchPanel.refresh();
        _showToast(t('{name} 已自動更新', { name: file.name }));
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
  const [items, folders] = await Promise.all([
    getRecents().catch(() => []),
    getRecents({ type: 'dir', limit: 16 }).catch(() => []),
  ]);
  _renderRecents(items);
  await _renderWorkspaceFolders(folders);
}

function _setWorkspaceMenu(open) {
  workspaceMenu.hidden = !open;
  workspaceToggle.setAttribute('aria-expanded', String(open));
  if (open) getRecents({ type: 'dir', limit: 16 }).then(_renderWorkspaceFolders).catch(() => {});
}

async function _renderWorkspaceFolders(items) {
  const generation = ++_workspaceRenderGeneration;
  const rows = await Promise.all(items.map(async item => {
    let permission = 'prompt';
    try {
      if (typeof item.handle.queryPermission === 'function') {
        permission = await item.handle.queryPermission({ mode: 'read' });
      }
    } catch { /* Keep the prompt state. */ }
    return { item, permission };
  }));
  if (generation !== _workspaceRenderGeneration) return;

  workspaceList.innerHTML = '';
  if (!rows.length) {
    const empty = document.createElement('p');
    empty.className = 'workspace-empty';
    empty.textContent = t('尚無已開啟的資料夾');
    workspaceList.appendChild(empty);
    return;
  }

  for (const { item, permission } of rows) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'workspace-item';
    const active = _folderContext?.rootName === item.handle.name;
    if (active) button.classList.add('active');
    button.setAttribute('aria-current', active ? 'true' : 'false');

    const icon = document.createElement('span');
    icon.className = 'workspace-item-icon';
    icon.textContent = active ? '▣' : '▢';
    icon.setAttribute('aria-hidden', 'true');
    const name = document.createElement('span');
    name.className = 'workspace-item-name';
    name.textContent = item.handle.name;
    const status = document.createElement('span');
    status.className = `workspace-permission ${permission}`;
    status.textContent = t(permission === 'granted' ? '已授權' : permission === 'denied' ? '需重新授權' : '需確認');
    button.append(icon, name, status);
    button.addEventListener('click', () => {
      _setWorkspaceMenu(false);
      _openRecent(item);
    });
    workspaceList.appendChild(button);
  }
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
      `<span class="recent-type">${t(item.type === 'dir' ? '資料夾' : '檔案')}</span>`;

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
    saveRecent(item.type, item.handle).then(_refreshRecents).catch(() => {}); // 更新 timestamp
  } catch (err) {
    if (err.name === 'NotAllowedError') {
      _showToast(t('存取被拒絕，請重新從「開啟」按鈕選擇。'), 'error');
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

_openFromUrlParameter();
