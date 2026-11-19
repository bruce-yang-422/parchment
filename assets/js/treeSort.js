/**
 * treeSort.js — 資料夾樹排序（不依賴 DOM）
 * 資料夾一律排在檔案前；依時間排序時，資料夾維持名稱 A→Z。
 */

export const TREE_SORT_MODES = ['name-asc', 'name-desc', 'mtime-desc', 'mtime-asc'];
export const DEFAULT_TREE_SORT = 'name-asc';

export const TREE_SORT_LABELS = {
  'name-asc': '依檔案名稱（A → Z）',
  'name-desc': '依檔案名稱（Z → A）',
  'mtime-desc': '依編輯時間（從新到舊）',
  'mtime-asc': '依編輯時間（從舊到新）',
};

export function isTimeSort(mode) {
  return mode === 'mtime-desc' || mode === 'mtime-asc';
}

export function treePathKey(path) {
  return path.join('/').toLocaleLowerCase();
}

/**
 * 回傳排序後的新樹（不修改原陣列；節點物件沿用）。
 * @param {Array} entries
 * @param {string} mode
 * @param {Map<string, number>} [mtimes] 檔案路徑鍵 → 最後修改時間（毫秒）
 */
export function sortTreeEntries(entries, mode = DEFAULT_TREE_SORT, mtimes = new Map()) {
  const sortMode = TREE_SORT_MODES.includes(mode) ? mode : DEFAULT_TREE_SORT;
  const byName = (a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base', numeric: true });
  const time = entry => mtimes.get(treePathKey(entry.path)) ?? 0;

  const compareFiles = {
    'name-asc': byName,
    'name-desc': (a, b) => byName(b, a),
    'mtime-desc': (a, b) => time(b) - time(a) || byName(a, b),
    'mtime-asc': (a, b) => time(a) - time(b) || byName(a, b),
  }[sortMode];
  const compareDirs = sortMode === 'name-desc' ? (a, b) => byName(b, a) : byName;

  const sortLevel = list => {
    const dirs = list.filter(entry => entry.type === 'dir')
      .map(entry => ({ ...entry, children: sortLevel(entry.children || []) }))
      .sort(compareDirs);
    const files = list.filter(entry => entry.type !== 'dir').sort(compareFiles);
    return [...dirs, ...files];
  };
  return sortLevel(entries);
}

/** 列出樹中所有檔案節點。 */
export function collectTreeFiles(entries, output = []) {
  for (const entry of entries) {
    if (entry.type === 'dir') collectTreeFiles(entry.children || [], output);
    else output.push(entry);
  }
  return output;
}
