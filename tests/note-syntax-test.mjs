import assert from 'node:assert/strict';
import MarkdownIt from 'markdown-it';
import {
  parseWikiTarget, wikiDisplayText, resolveWikiPath, extractNoteSection,
  parseFrontmatter, frontmatterTags, frontmatterAliases, calloutCategory, noteSyntaxPlugin,
  renderPropertiesHtml,
} from '../assets/js/noteSyntax.js';

/* Wiki Link 解析 */
assert.deepEqual(parseWikiTarget('筆記#標題|別名'), { target: '筆記', heading: '標題', blockId: '', alias: '別名' });
assert.deepEqual(parseWikiTarget('筆記#^abc'), { target: '筆記', heading: '', blockId: 'abc', alias: '' });
assert.deepEqual(parseWikiTarget('#章節'), { target: '', heading: '章節', blockId: '', alias: '' });
assert.equal(parseWikiTarget('a\\|b').target, 'a');
assert.equal(parseWikiTarget('筆記#章#節').heading, '節');
assert.equal(wikiDisplayText(parseWikiTarget('資料夾/筆記.md#標題')), '筆記 > 標題');

/* 路徑解析 */
const files = [
  ['README.md'],
  ['notes', 'alpha.md'],
  ['notes', 'deep', 'beta.md'],
  ['archive', 'beta.md'],
  ['attachments', 'pic.png'],
  ['notes', 'pic.png'],
];
assert.deepEqual(resolveWikiPath('alpha', ['README.md'], files, { markdown: true }), ['notes', 'alpha.md']);
assert.deepEqual(resolveWikiPath('beta', ['notes', 'alpha.md'], files, { markdown: true }), ['archive', 'beta.md']);
assert.deepEqual(resolveWikiPath('beta', ['notes', 'deep', 'x.md'], files, { markdown: true }), ['notes', 'deep', 'beta.md']);
assert.deepEqual(resolveWikiPath('deep/beta', ['README.md'], files, { markdown: true }), ['notes', 'deep', 'beta.md']);
assert.deepEqual(resolveWikiPath('pic.png', ['notes', 'alpha.md'], files), ['notes', 'pic.png']);
assert.deepEqual(resolveWikiPath('pic.png', ['README.md'], files), ['attachments', 'pic.png']);
assert.equal(resolveWikiPath('missing', ['README.md'], files, { markdown: true }), null);
assert.equal(resolveWikiPath('../../etc/passwd', ['README.md'], files), null);

/* 段落擷取 */
const note = [
  '---', 'title: x', '---',
  '# 一', 'intro',
  '## 二', 'two',
  '```', '# 不是標題', '```',
  '### 二之一', 'sub',
  '## 三', 'three ^blk',
  '- item ^li',
].join('\n');
assert.equal(extractNoteSection(note, { heading: '二' }), '## 二\ntwo\n```\n# 不是標題\n```\n### 二之一\nsub');
assert.equal(extractNoteSection(note, { heading: '三' }), '## 三\nthree ^blk\n- item ^li');
assert.equal(extractNoteSection(note, { blockId: 'blk' }), 'three');
assert.equal(extractNoteSection(note, { blockId: 'li' }), '- item');
assert.equal(extractNoteSection(note, { heading: '沒有' }), null);
assert.ok(!extractNoteSection(note).includes('title: x'));

/* Frontmatter */
const fm = parseFrontmatter([
  '---',
  'title: "Hello: World"',
  'tags: [工作, "專案 A"]',
  'aliases:',
  '  - 別名一',
  '  - 別名二',
  'done: true',
  'note: |',
  '  line 1',
  '  line 2',
  'empty:',
  'url: https://example.com # comment',
  '---',
  '# Body',
].join('\n'));
assert.equal(fm.body, '# Body');
assert.equal(fm.data.title, 'Hello: World');
assert.deepEqual(fm.data.tags, ['工作', '專案 A']);
assert.deepEqual(fm.data.aliases, ['別名一', '別名二']);
assert.equal(fm.data.done, 'true');
assert.equal(fm.data.note, 'line 1\nline 2');
assert.equal(fm.data.empty, null);
assert.equal(fm.data.url, 'https://example.com');
assert.deepEqual(frontmatterTags({ tags: '#a, b c' }), ['a', 'b', 'c']);
assert.deepEqual(frontmatterTags(fm.data), ['工作', '專案 A']);
assert.deepEqual(frontmatterAliases(fm.data), ['別名一', '別名二']);
assert.equal(parseFrontmatter('---\n---\nbody').body, 'body');
assert.equal(parseFrontmatter('no frontmatter').data, null);
assert.deepEqual(parseFrontmatter('---\ntags:\n- a\n- b\n---\n').data.tags, ['a', 'b']);

/* markdown-it 外掛 */
const md = new MarkdownIt({ html: true });
md.use(noteSyntaxPlugin);
const render = text => md.render(text);

let html = render('See [[notes/alpha#Intro|Alpha]] and [[#Local]].');
assert.match(html, /<a class="wiki-link" href="notes\/alpha#Intro" data-wiki-target="notes\/alpha" data-wiki-heading="Intro" data-wiki-block="">Alpha<\/a>/);
assert.match(html, /data-wiki-target="" data-wiki-heading="Local"[^>]*>Local<\/a>/);

html = render('![[pic.png|300]] ![[pic 2.jpg|說明]]');
assert.match(html, /<img class="wiki-embed-image" data-wiki-embed="pic.png" alt="pic.png" width="300">/);
assert.match(html, /data-wiki-embed="pic 2.jpg" alt="說明"/);

html = render('![[筆記#章節]]');
assert.match(html, /<span class="note-embed-placeholder" data-wiki-target="筆記" data-wiki-heading="章節"/);

html = render('`[[not a link]]`');
assert.ok(!html.includes('wiki-link'));

html = render('> [!tip] 自訂 **標題**\n> 內容');
assert.match(html, /<div class="callout" data-callout="tip" data-callout-type="tip">/);
assert.match(html, /<span class="callout-title-inner">自訂 <strong>標題<\/strong><\/span>/);
assert.match(html, /<div class="callout-content">\n<p>內容<\/p>/);
assert.ok(!html.includes('<blockquote'));

html = render('> [!FAQ]- 可收合\n> 內容');
assert.match(html, /<details class="callout" data-callout="question" data-callout-type="faq"><summary class="callout-title">/);

html = render('> [!warning]+\n> 內容');
assert.match(html, /<details class="callout" data-callout="warning"[^>]* open>/);
assert.match(html, /Warning<\/span>/);

html = render('> [!note] 只有標題');
assert.match(html, /<div class="callout-content">\n<\/div><\/div>/);

html = render('> [!info] 外層\n> > [!bug] 內層\n> > 錯誤');
assert.equal((html.match(/class="callout"/g) || []).length, 2);

html = render('> 一般引用');
assert.match(html, /<blockquote>/);

html = render('段落結尾 ^abc123');
assert.equal(html, '<p>段落結尾</p>\n');

assert.equal(calloutCategory('TLDR'), 'abstract');
assert.equal(calloutCategory('custom'), 'note');

/* 屬性區塊 */
const props = renderPropertiesHtml(fm.data, {
  renderInline: text => md.renderInline(text),
  escapeHtml: md.utils.escapeHtml,
});
assert.match(props, /class="metadata-tag" data-tag="工作"/);
assert.match(props, /<span class="metadata-chip">別名一<\/span>/);
assert.match(props, /<input type="checkbox" disabled checked/);
assert.equal(renderPropertiesHtml(null, {}), '');

console.log('note-syntax-test: passed');
