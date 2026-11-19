/**
 * imageExport.js — 將燈箱中的圖片或圖表存成 PNG
 * SVG 以 data URL 載入後繪製到 canvas（避免含 <foreignObject> 的 blob URL
 * 污染 canvas），並以較高解析度輸出；點陣圖維持原始尺寸。
 */

const MAX_CANVAS_SIDE = 16384;
const MAX_CANVAS_AREA = 16384 * 16384 / 4;

/** 由文件或圖片名稱產生安全的 PNG 檔名。 */
export function pngFileName(name, fallback = 'image') {
  const base = String(name || '')
    .split(/[\\/]/).pop()
    .replace(/\.[a-z0-9]{1,5}$/i, '')
    .replace(/[<>:"|?*\u0000-\u001f]/g, '')
    .trim();
  return `${base || fallback}.png`;
}

/** 計算輸出倍率，避免超過瀏覽器 canvas 尺寸上限。 */
export function exportScale(width, height, preferred) {
  if (!width || !height) return 1;
  const bySide = MAX_CANVAS_SIDE / Math.max(width, height);
  const byArea = Math.sqrt(MAX_CANVAS_AREA / (width * height));
  return Math.max(0.1, Math.min(preferred, bySide, byArea));
}

export async function saveImageAsPng(src, filename, { svgScale = 2, background = '#ffffff' } = {}) {
  const response = await fetch(src);
  if (!response.ok) throw new Error(`無法讀取圖片（HTTP ${response.status}）`);
  const blob = await response.blob();
  const isSvg = /svg/i.test(blob.type) || /\.svg(?:[?#]|$)/i.test(src);

  let image;
  let objectUrl = null;
  try {
    if (isSvg) {
      const markup = await blob.text();
      image = await _loadImage(`data:image/svg+xml;charset=utf-8,${encodeURIComponent(markup)}`);
    } else {
      objectUrl = URL.createObjectURL(blob);
      image = await _loadImage(objectUrl);
    }

    const width = image.naturalWidth || image.width;
    const height = image.naturalHeight || image.height;
    if (!width || !height) throw new Error('無法判斷圖片尺寸');

    const scale = exportScale(width, height, isSvg ? svgScale : 1);
    const canvas = document.createElement('canvas');
    canvas.width = Math.round(width * scale);
    canvas.height = Math.round(height * scale);

    const ctx = canvas.getContext('2d');
    if (background) {
      ctx.fillStyle = background;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }
    ctx.drawImage(image, 0, 0, canvas.width, canvas.height);

    const png = await new Promise((resolve, reject) => {
      try {
        canvas.toBlob(result => (result ? resolve(result) : reject(new Error('PNG 編碼失敗'))), 'image/png');
      } catch (err) {
        reject(err.name === 'SecurityError'
          ? new Error('瀏覽器限制此圖片匯出（跨來源或安全性限制）')
          : err);
      }
    });

    _download(png, filename);
  } finally {
    if (objectUrl) URL.revokeObjectURL(objectUrl);
  }
}

function _loadImage(src) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.decoding = 'async';
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error('無法載入圖片以轉換為 PNG'));
    image.src = src;
  });
}

function _download(blob, filename) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
