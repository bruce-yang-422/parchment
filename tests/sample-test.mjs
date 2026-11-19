import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import MarkdownIt from 'markdown-it';
import {
  noteSyntaxPlugin, parseFrontmatter, parseWikiTarget, resolveWikiPath, extractNoteSection,
} from '../assets/js/noteSyntax.js';

const locales = ['zh-TW', 'zh-CN', 'en', 'ja', 'ko', 'fr', 'de', 'es'];
const noteSets = locales.map(locale => {
  const directory = locale === 'zh-TW' ? 'samples' : `samples/${locale}`;
  return {
    locale,
    directory,
    notes: [`${directory}/parchment-guide.md`, `${directory}/linked-note.md`],
  };
});
const notes = noteSets.flatMap(set => set.notes);
const assets = ['image/parchment-logo-transparent.png'];
const exists = file => stat(file).then(() => true, () => false);

const md = new MarkdownIt({ html: true }).use(noteSyntaxPlugin);
const guide = await readFile(noteSets[0].notes[0], 'utf8');
const html = md.render(parseFrontmatter(guide).body);

/* 使用導覽示範的語法都有渲染出來 */
assert.deepEqual(parseFrontmatter(guide).data.tags, ['範例', '入門']);
for (const category of ['tip', 'note', 'warning', 'question']) {
  assert.match(html, new RegExp(`data-callout="${category}"`), `缺少 ${category} 提示區塊`);
}
assert.match(html, /<details class="callout" data-callout="question"/, '缺少可收合提示區塊');
assert.match(html, /class="mermaid"|language-mermaid/);
assert.match(guide, /```dot/);
assert.match(html, /class="wiki-link"/);
assert.match(html, /class="note-embed-placeholder"/);
assert.match(html, /class="wiki-embed-image"[^>]*width="96"/);

/* 每個語言的兩份範例都存在，且 Wiki Link、內嵌與圖片可解析。 */
for (const { locale, directory, notes: localizedNotes } of noteSets) {
  const notePaths = localizedNotes.map(file => file.split('/'));
  const allFiles = [...notePaths, ...assets.map(file => file.split('/'))];
  for (const note of localizedNotes) {
    assert.ok(await exists(note), `${locale} 缺少 ${note}`);
    const source = (await readFile(note, 'utf8'))
      .replace(/```[\s\S]*?```/g, '')
      .replace(/`[^`\n]*`/g, '');
    for (const match of source.matchAll(/!?\[\[([^\]]+)\]\]/g)) {
      const meta = parseWikiTarget(match[1]);
      const isImage = /\.(png|jpe?g|gif|webp|svg)$/i.test(meta.target);
      const resolved = resolveWikiPath(meta.target, note.split('/'), isImage ? allFiles : notePaths, { markdown: !isImage });
      assert.ok(resolved, `${note}：找不到 [[${match[1]}]]`);
      if (!isImage && (meta.heading || meta.blockId)) {
        const target = await readFile(resolved.join('/'), 'utf8');
        assert.notEqual(extractNoteSection(target, meta), null, `${note}：找不到段落 [[${match[1]}]]`);
      }
    }
  }
  const localizedGuide = await readFile(localizedNotes[0], 'utf8');
  for (const match of localizedGuide.matchAll(/!\[[^\]]*\]\((\.\.\/[^)]+)\)/g)) {
    const target = new URL(match[1], `file:///root/${directory}/`).pathname.replace('/root/', '');
    assert.ok(await exists(target), `${locale} 找不到圖片 ${target}`);
  }
}

/* 範例與其圖片已加入離線快取，首頁有開啟按鈕 */
const serviceWorker = await readFile('service-worker.js', 'utf8');
for (const file of [...notes, ...assets]) assert.ok(serviceWorker.includes(`"./${file}"`), `${file} 未加入離線快取`);
const index = await readFile('index.html', 'utf8');
assert.match(index, /id="welcome-btn-sample"/);
const app = await readFile('assets/js/app.js', 'utf8');
assert.match(app, /currentLocale\(\)/);
assert.match(app, /samples\/\$\{locale\}/);

console.log('sample-test: passed');
