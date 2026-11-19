import { build } from 'esbuild';
import { cp, mkdir, rm } from 'node:fs/promises';
import path from 'node:path';

const root = process.cwd();
const out = path.join(root, 'assets', 'vendor');

await rm(out, { recursive: true, force: true });
await mkdir(out, { recursive: true });

await build({
  entryPoints: [path.join(root, 'scripts', 'vendor-entry.js')],
  outfile: path.join(out, 'markdown-engine.min.js'),
  bundle: true,
  minify: true,
  format: 'iife',
  target: ['es2020'],
  legalComments: 'eof',
});

await build({
  entryPoints: [path.join(root, 'scripts', 'highlight-entry.js')],
  outfile: path.join(out, 'highlight.min.js'),
  bundle: true,
  minify: true,
  format: 'iife',
  target: ['es2020'],
  legalComments: 'eof',
});

await build({
  entryPoints: [path.join(root, 'scripts', 'graphviz-entry.js')],
  outfile: path.join(out, 'graphviz.min.js'),
  bundle: true,
  minify: true,
  format: 'iife',
  target: ['es2020'],
  legalComments: 'eof',
});

const copies = [
  ['dompurify/dist/purify.min.js', 'dompurify.min.js'],
  ['highlight.js/styles/github.min.css', 'github.min.css'],
  ['highlight.js/styles/github-dark.min.css', 'github-dark.min.css'],
  ['mermaid/dist/mermaid.min.js', 'mermaid.min.js'],
  ['katex/dist/katex.min.css', 'katex/katex.min.css'],
  ['katex/dist/fonts', 'katex/fonts'],
];

for (const [source, target] of copies) {
  await cp(path.join(root, 'node_modules', source), path.join(out, target), {
    recursive: true,
  });
}

const licenses = [
  '@traptitech/markdown-it-katex',
  'dompurify',
  'highlight.js',
  'katex',
  'markdown-it',
  'markdown-it-abbr',
  'markdown-it-deflist',
  'markdown-it-emoji',
  'markdown-it-footnote',
  'markdown-it-ins',
  'markdown-it-mark',
  'markdown-it-sub',
  'markdown-it-sup',
  'markdown-it-task-lists',
  'mermaid',
];
await mkdir(path.join(out, 'licenses'), { recursive: true });
for (const packageName of licenses) {
  const filename = packageName === 'dompurify' ? 'LICENSE-MPL' : 'LICENSE';
  await cp(
    path.join(root, 'node_modules', packageName, filename),
    path.join(out, 'licenses', `${packageName.replaceAll('/', '__')}.txt`),
  );
}

// @viz-js/viz 的 npm 套件未附 LICENSE 檔，且內含以 Emscripten 編譯的 Graphviz。
// 授權全文取自上游（Viz.js v3 分支、Graphviz 15.1.1 標籤），保存在 scripts/licenses/。
const vendoredLicenses = [
  ['viz-js.txt', '@viz-js__viz.txt'],
  ['graphviz.txt', 'graphviz.txt'],
];
for (const [source, target] of vendoredLicenses) {
  await cp(path.join(root, 'scripts', 'licenses', source), path.join(out, 'licenses', target));
}
