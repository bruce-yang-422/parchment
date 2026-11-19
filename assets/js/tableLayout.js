/**
 * 判斷表格內容是否為應維持單行的短數值。
 * 金額與數量若在標點處被拆行，會顯著降低掃讀效率。
 */
export function isCompactTableValue(value) {
  const text = String(value ?? '').replace(/\u00a0/g, ' ').trim();
  if (!text || text.length > 32 || /[\r\n]/.test(text)) return false;

  return /^(?:[(（]\s*)?[+\-−]?\s*(?:(?:NT|US|HK|CA|AU|NZ|SG)\$|[$€£¥￥₩₹])?\s*\d[\d\s,.'’]*(?:[.,]\d+)?\s*(?:%|％|元|圓|円|원|USD|EUR|GBP|JPY|CNY|RMB|KRW)?\s*[)）]?$/iu.test(text);
}

/** 讓短表頭與數值保持完整，長文字欄位仍可自然換行。 */
export function enhanceTableReadability(root) {
  if (!root?.querySelectorAll) return;

  root.querySelectorAll('table').forEach(table => {
    table.querySelectorAll('th').forEach(cell => cell.classList.add('table-compact-cell'));
    table.querySelectorAll('td').forEach(cell => {
      if (isCompactTableValue(cell.textContent)) cell.classList.add('table-compact-cell');
    });
  });
}
