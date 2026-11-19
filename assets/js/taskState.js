/**
 * Markdown TODO 的本機檢核狀態。
 * 僅儲存文件識別、任務文字指紋與布林值，不會寫回來源檔案。
 */

import { t } from './i18n.js';

const STORAGE_PREFIX = 'parchment:tasks:v1:';

export function taskDocumentKey(document) {
  const root = document?.folder?.rootName || 'single';
  const path = document?.path?.join('/') || document?.name || 'untitled';
  return `${STORAGE_PREFIX}${encodeURIComponent(`${root}/${path}`)}`;
}

export function taskIdentity(text, occurrence = 0) {
  const normalized = String(text).replace(/\s+/g, ' ').trim();
  let first = 0x811c9dc5;
  let second = 0x9e3779b9;

  for (let index = 0; index < normalized.length; index++) {
    const code = normalized.charCodeAt(index);
    first = Math.imul(first ^ code, 0x01000193);
    second = Math.imul(second ^ code, 0x85ebca6b);
  }

  const fingerprint = [first, second]
    .map(value => (value >>> 0).toString(16).padStart(8, '0'))
    .join('');
  return `${fingerprint}:${normalized.length.toString(36)}:${occurrence}`;
}

export function loadTaskState(document, storage = localStorage) {
  try {
    const parsed = JSON.parse(storage.getItem(taskDocumentKey(document)) || '{}');
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : {};
  } catch {
    return {};
  }
}

export function saveTaskState(document, state, storage = localStorage) {
  try {
    storage.setItem(taskDocumentKey(document), JSON.stringify(state));
    return true;
  } catch {
    return false;
  }
}

export function wireTaskCheckboxes(container, document, { onStorageError } = {}) {
  const checkboxes = [...container.querySelectorAll('.task-list-item-checkbox')];
  if (!checkboxes.length) return 0;

  const state = loadTaskState(document);
  const occurrences = new Map();

  for (const checkbox of checkboxes) {
    const taskText = checkbox.closest('label')?.textContent
      || checkbox.closest('.task-list-item')?.textContent
      || '';
    const baseIdentity = taskIdentity(taskText).split(':').slice(0, 2).join(':');
    const occurrence = occurrences.get(baseIdentity) || 0;
    occurrences.set(baseIdentity, occurrence + 1);
    const identity = taskIdentity(taskText, occurrence);

    checkbox.disabled = false;
    checkbox.classList.add('local-task-checkbox');
    checkbox.dataset.taskIdentity = identity;
    checkbox.title = t('檢核狀態只儲存在此瀏覽器，不會修改 Markdown 文件');

    if (Object.hasOwn(state, identity)) {
      checkbox.checked = state[identity] === true;
    }

    checkbox.addEventListener('change', () => {
      state[identity] = checkbox.checked;
      if (!saveTaskState(document, state)) onStorageError?.();
    });
  }

  return checkboxes.length;
}
