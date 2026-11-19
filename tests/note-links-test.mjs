import assert from 'node:assert/strict';
import { buildDocumentIndex, extractDocumentLinks, getDocumentRelations } from '../assets/js/noteLinks.js';

const fileEntry = (name, path, content) => ({
  type: 'file',
  name,
  path,
  handle: { getFile: async () => ({ text: async () => content }) },
});

const entries = [
  fileEntry('A.md', ['A.md'], `# A

## tags: [核心]

[筆記 B](B.md)
[[Folder/C|筆記 C]]
[官方網站](https://example.com)
![圖片不算連結](B.md)`),
  fileEntry('B.md', ['B.md'], '# B\n\n[回到 A](A.md)'),
  {
    type: 'dir',
    name: 'Folder',
    path: ['Folder'],
    children: [fileEntry('C.md', ['Folder', 'C.md'], '# C\n\n[[A]]')],
  },
];

const source = await (await entries[0].handle.getFile()).text();
const extracted = extractDocumentLinks(source);
assert.equal(extracted.length, 3);
assert.ok(extracted.some(link => link.syntax === 'wiki' && link.label === '筆記 C'));
assert.deepEqual(extractDocumentLinks('純文字網址：https://openai.com。'), [{
  href: 'https://openai.com',
  label: 'https://openai.com',
  syntax: 'url',
}]);

const index = await buildDocumentIndex(entries);
assert.deepEqual([...index.tags.get('核心')], ['a.md']);

const relations = getDocumentRelations(index, ['A.md']);
assert.deepEqual(relations.linkedNotes.map(record => record.entry.name), ['B.md', 'C.md']);
assert.deepEqual(relations.backlinks.map(item => item.record.entry.name), ['B.md', 'C.md']);

console.log('note-links-test: passed');
