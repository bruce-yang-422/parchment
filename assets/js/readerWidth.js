/**
 * readerWidth.js — 閱讀區寬度：標準（依配色的閱讀欄寬）或滿版
 */

import { t } from './i18n.js';

export const READER_WIDTHS = ['standard', 'full'];
export const DEFAULT_READER_WIDTH = 'standard';
const STORAGE_KEY = 'parchment-reader-width';

export function initReaderWidth(button) {
  let saved = null;
  try { saved = localStorage.getItem(STORAGE_KEY); } catch { /* 使用預設 */ }
  applyReaderWidth(saved, { save: false });
  _syncButton(button);

  button?.addEventListener('click', () => {
    const next = currentReaderWidth() === 'full' ? 'standard' : 'full';
    applyReaderWidth(next);
    _syncButton(button);
  });
}

export function applyReaderWidth(width, { save = true } = {}) {
  const value = READER_WIDTHS.includes(width) ? width : DEFAULT_READER_WIDTH;
  document.documentElement.dataset.readerWidth = value;
  if (save) {
    try { localStorage.setItem(STORAGE_KEY, value); } catch { /* 僅本次有效 */ }
  }
  return value;
}

export function currentReaderWidth() {
  return document.documentElement.dataset.readerWidth || DEFAULT_READER_WIDTH;
}

function _syncButton(button) {
  if (!button) return;
  const full = currentReaderWidth() === 'full';
  const label = t(full ? '切換為標準寬度' : '切換為滿版寬度');
  button.setAttribute('aria-pressed', String(full));
  button.setAttribute('aria-label', label);
  button.title = label;
  const text = button.querySelector('[data-width-label]');
  if (text) text.textContent = t(full ? '標準寬度' : '滿版');
  button.querySelector('[data-width-icon="expand"]')?.toggleAttribute('hidden', full);
  button.querySelector('[data-width-icon="shrink"]')?.toggleAttribute('hidden', !full);
}
