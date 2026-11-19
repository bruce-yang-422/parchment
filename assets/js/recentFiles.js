/**
 * recentFiles.js — 最近開啟紀錄（IndexedDB）
 * FileSystemHandle 可直接序列化存入 IndexedDB（Chrome/Edge 86+）
 */

const DB_NAME = 'parchment';
const DB_VER  = 1;
const STORE   = 'recents';
const MAX     = 8;

function _db() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VER);
    req.onupgradeneeded = ({ target: { result: db } }) => {
      if (!db.objectStoreNames.contains(STORE))
        db.createObjectStore(STORE, { keyPath: 'id' });
    };
    req.onsuccess = ({ target: { result } }) => resolve(result);
    req.onerror  = ({ target: { error  } }) => reject(error);
  });
}

/** 儲存或更新一筆紀錄（以 handle.name 為 id，重複時覆蓋） */
export async function saveRecent(type, handle) {
  const db = await _db();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE, 'readwrite');
    tx.objectStore(STORE).put({ id: handle.name, type, handle, ts: Date.now() });
    tx.oncomplete = resolve;
    tx.onerror = ({ target: { error } }) => reject(error);
  });
}

/** 取得紀錄，依時間倒序，可依類型篩選。 */
export async function getRecents({ type = null, limit = MAX } = {}) {
  const db = await _db();
  return new Promise((resolve, reject) => {
    const req = db.transaction(STORE, 'readonly').objectStore(STORE).getAll();
    req.onsuccess = () => {
      const sorted = req.result.sort((a, b) => b.ts - a.ts);
      const filtered = type ? sorted.filter(item => item.type === type) : sorted;
      resolve(filtered.slice(0, limit));
    };
    req.onerror = ({ target: { error } }) => reject(error);
  });
}

/** 刪除一筆紀錄 */
export async function removeRecent(id) {
  const db = await _db();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE, 'readwrite');
    tx.objectStore(STORE).delete(id);
    tx.oncomplete = resolve;
    tx.onerror = ({ target: { error } }) => reject(error);
  });
}
