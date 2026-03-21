/**
 * fileLoader.js — 檔案讀取模組
 * 支援 File System Access API（Chrome/Edge 86+）及降級方案（Firefox/Safari）
 */

const SUPPORTED_EXT = /\.(md|txt)$/i;

/** 判斷檔名是否為支援格式 */
export function isSupportedFile(name) {
  return SUPPORTED_EXT.test(name);
}

/* ──────────────────── 單檔模式 ──────────────────── */

/**
 * 開啟單一檔案
 * @returns {Promise<{ name: string, content: string }>}
 */
export async function openFile() {
  if ('showOpenFilePicker' in window) {
    return _openFileWithFSA();
  }
  return _openFileWithInput();
}

async function _openFileWithFSA() {
  const [handle] = await window.showOpenFilePicker({
    types: [{
      description: 'Markdown / Text files',
      accept: { 'text/*': ['.md', '.txt'] },
    }],
    multiple: false,
  });
  const file = await handle.getFile();
  return { name: file.name, content: await file.text(), handle };
}

function _openFileWithInput() {
  return new Promise((resolve, reject) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.md,.txt';

    input.addEventListener('change', async () => {
      const file = input.files[0];
      if (!file) { reject(new DOMException('No file selected', 'AbortError')); return; }
      if (!isSupportedFile(file.name)) {
        reject(new Error(`不支援的格式：${file.name}。請使用 .md 或 .txt 檔案。`));
        return;
      }
      resolve({ name: file.name, content: await file.text() });
    });

    input.addEventListener('cancel', () =>
      reject(new DOMException('Cancelled', 'AbortError')));

    input.click();
  });
}

/* ──────────────────── 資料夾模式 ──────────────────── */

/**
 * 開啟資料夾
 * @returns {Promise<{ rootName: string, entries: TreeEntry[] }>}
 */
export async function openDirectory() {
  if ('showDirectoryPicker' in window) {
    return _openDirWithFSA();
  }
  return _openDirWithInput();
}

async function _openDirWithFSA() {
  const handle = await window.showDirectoryPicker({ mode: 'read' });
  const entries = await _buildTree(handle);
  return { rootName: handle.name, entries, handle };
}

/**
 * 遞迴建立樹狀結構
 * @param {FileSystemDirectoryHandle} dirHandle
 * @returns {Promise<TreeEntry[]>}
 */
async function _buildTree(dirHandle) {
  const entries = [];

  for await (const [name, handle] of dirHandle.entries()) {
    if (handle.kind === 'directory') {
      const children = await _buildTree(handle);
      entries.push({ type: 'dir', name, children });
    } else if (isSupportedFile(name)) {
      entries.push({ type: 'file', name, handle });
    }
  }

  return _sortEntries(entries);
}

/* ──────────────────── 降級：webkitdirectory ──────────────────── */

function _openDirWithInput() {
  return new Promise((resolve, reject) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.webkitdirectory = true;
    input.multiple = true;

    input.addEventListener('change', () => {
      const files = Array.from(input.files || []);
      if (!files.length) { reject(new DOMException('Cancelled', 'AbortError')); return; }

      const supported = files.filter(f => isSupportedFile(f.name));
      if (!supported.length) {
        reject(new Error('所選資料夾中沒有 .md 或 .txt 檔案。'));
        return;
      }

      const rootName = files[0].webkitRelativePath.split('/')[0] || '資料夾';
      const entries = _buildTreeFromFiles(supported);
      resolve({ rootName, entries });
    });

    input.addEventListener('cancel', () =>
      reject(new DOMException('Cancelled', 'AbortError')));

    input.click();
  });
}

/** 從 File 陣列（含 webkitRelativePath）建立樹狀結構 */
function _buildTreeFromFiles(files) {
  const root = [];

  for (const file of files) {
    const parts = file.webkitRelativePath.split('/');
    // parts[0] = root folder name, skip it
    let current = root;

    for (let i = 1; i < parts.length - 1; i++) {
      const dirName = parts[i];
      let dir = current.find(e => e.type === 'dir' && e.name === dirName);
      if (!dir) {
        dir = { type: 'dir', name: dirName, children: [] };
        current.push(dir);
      }
      current = dir.children;
    }

    current.push({
      type: 'file',
      name: file.name,
      // Wrap File as fake handle to match FSA interface
      handle: { getFile: async () => file },
    });
  }

  return _sortTree(root);
}

/* ──────────────────── 最近開啟：從已有 handle 重新開啟 ──────────────────── */

/**
 * 使用已儲存的 FileSystemFileHandle 重新開啟檔案
 * 若無權限會向使用者請求授權
 */
export async function openFileFromHandle(handle) {
  await _ensureReadPermission(handle);
  const file = await handle.getFile();
  return { name: file.name, content: await file.text() };
}

/**
 * 使用已儲存的 FileSystemDirectoryHandle 重新開啟資料夾
 */
export async function openDirectoryFromHandle(handle) {
  await _ensureReadPermission(handle);
  const entries = await _buildTree(handle);
  return { rootName: handle.name, entries };
}

async function _ensureReadPermission(handle) {
  if ((await handle.queryPermission({ mode: 'read' })) === 'granted') return;
  const result = await handle.requestPermission({ mode: 'read' });
  if (result !== 'granted')
    throw new DOMException('Permission denied', 'NotAllowedError');
}

/* ──────────────────── Helpers ──────────────────── */

function _sortEntries(entries) {
  return entries.sort((a, b) => {
    if (a.type !== b.type) return a.type === 'dir' ? -1 : 1;
    return a.name.localeCompare(b.name, undefined, { sensitivity: 'base' });
  });
}

function _sortTree(entries) {
  _sortEntries(entries);
  for (const e of entries) {
    if (e.type === 'dir') _sortTree(e.children);
  }
  return entries;
}
