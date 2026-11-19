import assert from 'node:assert/strict';
import { extractMarkdownTags } from '../assets/js/renderer.js';

assert.deepEqual(
  extractMarkdownTags('## tags: [住院, 陪病，#清單]\n\n# 住院準備指南'),
  ['住院', '陪病', '清單'],
);

assert.deepEqual(
  extractMarkdownTags('## TAGS: "工作", \'待辦\'\n\n## tags: [工作, 重要]'),
  ['工作', '待辦', '重要'],
);

assert.deepEqual(extractMarkdownTags('## 不是 tags: [忽略]\n\ntags: [忽略]'), []);

assert.deepEqual(
  extractMarkdownTags('---\ntags:\n  - 專案\n  - "#工作"\n---\n\n## tags: [工作, 筆記]'),
  ['專案', '工作', '筆記'],
);

console.log('tag-test: passed');
