import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';

const root = 'browser-extension/src';
const manifest = JSON.parse(await readFile(path.join(root, 'manifest.json'), 'utf8'));
const exists = file => stat(path.join(root, file)).then(() => true, () => false);

/* Manifest V3 與最小權限 */
assert.equal(manifest.manifest_version, 3);
assert.deepEqual(manifest.permissions, ['storage']);
assert.deepEqual(manifest.host_permissions, ['file:///*']);
assert.equal(manifest.default_locale, 'en');
assert.match(manifest.content_security_policy.extension_pages, /script-src 'self' 'wasm-unsafe-eval'/);
// 只允許 WebAssembly（Graphviz）；不允許一般 eval 或遠端來源
assert.doesNotMatch(manifest.content_security_policy.extension_pages, /'unsafe-eval'|'unsafe-inline'|https?:/);

/* 內容腳本只在本機 Markdown 檔執行 */
const [contentScript] = manifest.content_scripts;
assert.deepEqual(contentScript.matches, ['file:///*']);
assert.ok(contentScript.include_globs.every(glob => /^\*\.(md|MD|markdown|MARKDOWN|mdown|mkd)$/.test(glob)));

/* manifest 引用的檔案都存在 */
for (const file of [
  ...Object.values(manifest.icons),
  ...Object.values(manifest.action.default_icon),
  manifest.background.service_worker,
  manifest.options_ui.page,
  ...contentScript.js,
]) {
  assert.ok(await exists(file), `缺少 ${file}`);
}

/* 商店名稱與描述長度；八種語言的訊息鍵一致 */
const locales = {};
for (const locale of ['zh_TW', 'zh_CN', 'en', 'ja', 'ko', 'fr', 'de', 'es']) {
  locales[locale] = JSON.parse(await readFile(path.join(root, '_locales', locale, 'messages.json'), 'utf8'));
  const { extName, extDescription } = locales[locale];
  assert.ok([...extName.message].length <= 75, `${locale} 名稱過長`);
  assert.ok([...extDescription.message].length <= 132, `${locale} 描述超過 132 字元`);
}
for (const locale of Object.keys(locales)) {
  assert.deepEqual(Object.keys(locales[locale]).sort(), Object.keys(locales.en).sort(), `${locale} 的訊息鍵不一致`);
}

/* 設定頁不得使用內嵌腳本（Manifest V3 CSP） */
const options = await readFile(path.join(root, 'options/options.html'), 'utf8');
assert.doesNotMatch(options, /<script(?![^>]*\bsrc=)[^>]*>/);
assert.doesNotMatch(options, /\son[a-z]+=/);
for (const key of options.matchAll(/data-i18n="([^"]+)"/g)) {
  for (const [locale, messages] of Object.entries(locales)) {
    assert.ok(messages[key[1]], `${locale} 缺少翻譯：${key[1]}`);
  }
}
assert.match(options, /id="language-select"/);
const optionsScript = await readFile(path.join(root, 'options/options.js'), 'utf8');
for (const locale of ['zh-TW', 'zh-CN', 'en', 'ja', 'ko', 'fr', 'de', 'es']) {
  assert.ok(optionsScript.includes(`'${locale}'`) || optionsScript.includes(`${locale}:`), `設定頁缺少語言：${locale}`);
}

/* 背景只轉送來自 file:// 的請求到 Parchment 檢視器 */
const background = await readFile(path.join(root, 'background.js'), 'utf8');
assert.match(background, /sender\.id !== chrome\.runtime\.id/);
assert.match(background, /app\/index\.html/);

console.log('extension-test: passed');
