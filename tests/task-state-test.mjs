import assert from 'node:assert/strict';
import {
  loadTaskState,
  saveTaskState,
  taskDocumentKey,
  taskIdentity,
} from '../assets/js/taskState.js';

const document = {
  name: 'plan.md',
  path: ['docs', 'plan.md'],
  folder: { rootName: 'project' },
};

assert.match(taskDocumentKey(document), /^parchment:tasks:v1:/);
assert.notEqual(taskDocumentKey(document), taskDocumentKey({ name: 'other.md' }));
assert.equal(taskIdentity('  完成   測試  '), taskIdentity('完成 測試'));
assert.notEqual(taskIdentity('完成測試', 0), taskIdentity('完成測試', 1));
assert.doesNotMatch(taskIdentity('不應儲存原始任務內容'), /不應儲存/);

const values = new Map();
const storage = {
  getItem: key => values.get(key) ?? null,
  setItem: (key, value) => values.set(key, value),
};
const state = { [taskIdentity('第一項')]: true };

assert.equal(saveTaskState(document, state, storage), true);
assert.deepEqual(loadTaskState(document, storage), state);
values.set(taskDocumentKey(document), '{invalid');
assert.deepEqual(loadTaskState(document, storage), {});

console.log('task-state-test: passed');
