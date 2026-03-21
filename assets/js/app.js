/**
 * app.js — 主應用邏輯
 * 協調 theme / fileLoader / renderer / tree 模組
 */

import { initTheme, cycleTheme }           from './theme.js';
import { openFile, openDirectory, isSupportedFile } from './fileLoader.js';
import { setupRenderer, renderMarkdown, renderText } from './renderer.js';
import { renderTree, clearTree }           from './tree.js';

/* ──────────────────── 初始化 ──────────────────── */

setupRenderer();
initTheme();

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

/* ──────────────────── 按鈕事件 ──────────────────── */

document.getElementById('btn-theme').addEventListener('click', cycleTheme);

document.getElementById('btn-open-file').addEventListener('click', handleOpenFile);
document.getElementById('btn-open-dir').addEventListener('click', handleOpenDir);
document.getElementById('welcome-btn-file').addEventListener('click', handleOpenFile);
document.getElementById('welcome-btn-dir').addEventListener('click', handleOpenDir);

async function handleOpenFile() {
  try {
    const { name, content } = await openFile();
    await _displayFile(name, content);
    _enterSingleMode();
  } catch (err) {
    if (err.name !== 'AbortError') _showToast(err.message, 'error');
  }
}

async function handleOpenDir() {
  try {
    const { rootName, entries } = await openDirectory();
    _enterFolderMode(rootName, entries);
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

  welcomeEl.hidden = true;
  readerEl.hidden = false;

  // 捲回頂部
  readerEl.scrollIntoView({ block: 'start' });
  document.getElementById('content-area').scrollTop = 0;
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
