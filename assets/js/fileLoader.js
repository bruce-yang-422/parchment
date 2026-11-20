/**
 * fileLoader.js — 檔案讀取模組
 * 支援 File System Access API（Chrome/Edge 86+）及降級方案（Firefox/Safari）
 */

import { t } from './i18n.js';

const SUPPORTED_EXT = /\.(md|txt)$/i;
const PICKER_MIME_TYPES = {
  'text/markdown': ['.md'],
  'text/plain': ['.txt'],
};
const PICKER_EXTENSIONS = Object.values(PICKER_MIME_TYPES).flat();

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
  const handle = 'showOpenFilePicker' in window ? await _pickFileHandle() : null;
  const file = handle ? await handle.getFile() : await _pickFileWithInput();
  if (!isSupportedFile(file.name)) {
    throw new Error(t('不支援的格式：{name}。請使用 .md 或 .txt 檔案。', { name: file.name }));
  }
  const document = { name: file.name, content: await file.text(), path: [file.name] };
  return handle ? { ...document, handle, getFileByPath: null } : document;
}

async function _pickFileHandle() {
  const isAndroid = navigator.userAgentData?.platform === 'Android' || /\bAndroid\b/i.test(navigator.userAgent);
  const [handle] = await window.showOpenFilePicker({
    types: [{
      description: 'Markdown / Text (.md, .txt)',
      // Desktop Chromium expands known MIME types into extra extensions. Android filters by MIME type.
      accept: isAndroid ? PICKER_MIME_TYPES : { 'application/x-parchment-document': PICKER_EXTENSIONS },
    }],
    excludeAcceptAllOption: true,
    multiple: false,
  });
  return handle;
}

function _pickFileWithInput() {
  return new Promise((resolve, reject) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = PICKER_EXTENSIONS.join(',');

    input.addEventListener('change', () => {
      const file = input.files[0];
      if (!file) { reject(new DOMException('No file selected', 'AbortError')); return; }
      resolve(file);
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
  const files = [];
  const entries = await _buildTree(handle, [], files);
  return {
    rootName: handle.name,
    entries,
    files,
    handle,
    getFileByPath: path => _getFileFromDirectory(handle, path),
  };
}

/**
 * 遞迴建立樹狀結構
 * @param {FileSystemDirectoryHandle} dirHandle
 * @param {string[]} parentPath
 * @param {string[][]} files 收集所有檔案路徑（含附件），供 Wiki 內嵌依檔名解析
 * @returns {Promise<TreeEntry[]>}
 */
async function _buildTree(dirHandle, parentPath = [], files = []) {
  const entries = [];

  for await (const [name, handle] of dirHandle.entries()) {
    if (handle.kind === 'directory') {
      const path = [...parentPath, name];
      const children = await _buildTree(handle, path, _isHiddenName(name) ? [] : files);
      entries.push({ type: 'dir', name, path, children });
    } else {
      if (!_isHiddenName(name)) files.push([...parentPath, name]);
      if (isSupportedFile(name)) {
        entries.push({ type: 'file', name, path: [...parentPath, name], handle });
      }
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
        reject(new Error(t('所選資料夾中沒有 .md 或 .txt 檔案。')));
        return;
      }

      const rootName = files[0].webkitRelativePath.split('/')[0] || t('資料夾');
      const entries = _buildTreeFromFiles(supported);
      const fileMap = new Map(files.map(file => [
        _pathKey(file.webkitRelativePath.split('/').slice(1)),
        file,
      ]));
      resolve({
        rootName,
        entries,
        files: files
          .map(file => file.webkitRelativePath.split('/').slice(1))
          .filter(path => path.length && !path.some(_isHiddenName)),
        getFileByPath: async path => {
          const file = fileMap.get(_pathKey(path));
          if (!file) throw new DOMException('File not found', 'NotFoundError');
          return file;
        },
      });
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
      path: parts.slice(1),
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
  return {
    name: file.name,
    content: await file.text(),
    handle,
    path: [file.name],
    getFileByPath: null,
  };
}

/**
 * 使用已儲存的 FileSystemDirectoryHandle 重新開啟資料夾
 */
export async function openDirectoryFromHandle(handle) {
  await _ensureReadPermission(handle);
  const files = [];
  const entries = await _buildTree(handle, [], files);
  return {
    rootName: handle.name,
    entries,
    files,
    handle,
    getFileByPath: path => _getFileFromDirectory(handle, path),
  };
}

/** 由根目錄 handle 讀取正規化後的相對路徑。 */
async function _getFileFromDirectory(rootHandle, path) {
  const parts = normalizeRelativePath(path);
  if (!parts.length) throw new DOMException('Invalid path', 'NotFoundError');

  let directory = rootHandle;
  for (const part of parts.slice(0, -1)) {
    directory = await directory.getDirectoryHandle(part);
  }
  const fileHandle = await directory.getFileHandle(parts.at(-1));
  return fileHandle.getFile();
}

/** 將字串或片段陣列正規化，並阻止路徑逃出已授權根目錄。 */
export function normalizeRelativePath(path) {
  const input = Array.isArray(path) ? path : String(path).split('/');
  const output = [];
  for (const rawPart of input) {
    const part = String(rawPart).trim();
    if (!part || part === '.') continue;
    if (part === '..') {
      if (!output.length) throw new DOMException('Path leaves selected folder', 'SecurityError');
      output.pop();
    } else {
      output.push(part);
    }
  }
  return output;
}

async function _ensureReadPermission(handle) {
  // Origin Private File System handles are already scoped to this origin and
  // do not expose the user-file permission methods used by picker handles.
  if (typeof handle.queryPermission !== 'function') return;
  if ((await handle.queryPermission({ mode: 'read' })) === 'granted') return;
  if (typeof handle.requestPermission !== 'function')
    throw new DOMException('Permission denied', 'NotAllowedError');
  const result = await handle.requestPermission({ mode: 'read' });
  if (result !== 'granted')
    throw new DOMException('Permission denied', 'NotAllowedError');
}

/* ──────────────────── Helpers ──────────────────── */

/** 以點開頭的隱藏檔案或資料夾不列入附件索引。 */
function _isHiddenName(name) {
  return String(name).startsWith('.');
}

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

function _pathKey(path) {
  return normalizeRelativePath(path).join('/').toLocaleLowerCase();
}
