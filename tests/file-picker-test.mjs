import assert from 'node:assert/strict';
import { openFile, openFileFromHandle, readFileDocument } from '../assets/js/fileLoader.js';

const lastModified = Date.UTC(2026, 10, 24, 1, 30);
const markdown = new File(['# Note'], 'note.MD', { lastModified });
const plainText = new File(['記事'], 'note.txt', { lastModified });
const unsupported = { name: 'other.text', text: () => assert.fail('Unsupported file was read') };
let selectedFile = markdown;
let pickerOptions;
const handle = { getFile: async () => selectedFile };
globalThis.window = {
  showOpenFilePicker: async options => {
    pickerOptions = options;
    return [handle];
  },
};

Object.defineProperty(globalThis, 'navigator', {
  configurable: true,
  value: { userAgent: 'Desktop' },
});
assert.deepEqual(await openFile(), {
  name: 'note.MD', content: '# Note', size: 6, lastModified,
  path: ['note.MD'], handle, getFileByPath: null,
});
assert.deepEqual(await openFileFromHandle(handle), await openFile());
assert.equal(pickerOptions.excludeAcceptAllOption, true);
assert.equal(pickerOptions.multiple, false);
assert.deepEqual(pickerOptions.types.map(type => type.accept), [
  { 'application/x-parchment-document': ['.md', '.txt'] },
]);
selectedFile = unsupported;
await assert.rejects(openFile(), /other\.text/);

Object.defineProperty(globalThis, 'navigator', {
  configurable: true,
  value: { userAgentData: { platform: 'Android' } },
});
selectedFile = plainText;
assert.equal((await openFile()).content, '記事');
assert.deepEqual(pickerOptions.types.map(type => type.accept), [
  { 'text/markdown': ['.md'], 'text/plain': ['.txt'] },
]);

globalThis.window = {};
let pickerEvent = 'change';
globalThis.document = {
  createElement(tag) {
    assert.equal(tag, 'input');
    const listeners = new Map();
    return {
      files: [selectedFile],
      addEventListener: (name, listener) => listeners.set(name, listener),
      click() {
        assert.equal(this.type, 'file');
        assert.equal(this.accept, '.md,.txt');
        listeners.get(pickerEvent)();
      },
    };
  },
};
assert.deepEqual(await openFile(), { name: 'note.txt', content: '記事', size: 6, lastModified, path: ['note.txt'] });
assert.equal((await readFileDocument(plainText, { lastModified: null })).lastModified, null);
selectedFile = unsupported;
await assert.rejects(openFile(), /other\.text/);
pickerEvent = 'cancel';
await assert.rejects(openFile(), { name: 'AbortError' });

console.log('file-picker-test: passed');
