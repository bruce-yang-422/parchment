import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { SUPPORTED_LOCALES, LOCALE_NAMES, FALLBACK_LOCALE, normalizeLocale, resolveLocale, catalogEntries } from '../assets/js/i18n.js';

const expected = ['zh-TW', 'zh-CN', 'en', 'ja', 'ko', 'fr', 'de', 'es'];
assert.deepEqual(SUPPORTED_LOCALES, expected);
assert.deepEqual(Object.keys(LOCALE_NAMES), expected);
assert.equal(FALLBACK_LOCALE, 'en');

assert.equal(normalizeLocale('zh-Hant-TW'), 'zh-TW');
assert.equal(normalizeLocale('zh-HK'), 'zh-TW');
assert.equal(normalizeLocale('zh-Hans-CN'), 'zh-CN');
assert.equal(normalizeLocale('ja-JP'), 'ja');
assert.equal(normalizeLocale('ko-KR'), 'ko');
assert.equal(normalizeLocale('fr-CA'), 'fr');
assert.equal(normalizeLocale('de-AT'), 'de');
assert.equal(normalizeLocale('es-MX'), 'es');
assert.equal(normalizeLocale('it-IT'), null);
assert.equal(resolveLocale({ languages: ['ja-JP'] }), 'ja');
assert.equal(resolveLocale({ saved: 'de-DE', languages: ['ja-JP'] }), 'de');
assert.equal(resolveLocale({ requested: 'es-MX', saved: 'de-DE', languages: ['ja-JP'] }), 'es');
assert.equal(resolveLocale({ languages: ['it-IT', 'nl-NL'] }), 'en');

for (const [source, translations] of catalogEntries()) {
  assert.ok(source.trim(), '翻譯來源不可為空');
  assert.equal(translations.length, expected.length - 1, `${source} 的翻譯數量不正確`);
  translations.forEach((translation, index) => {
    assert.ok(String(translation).trim(), `${source} 缺少 ${expected[index + 1]} 翻譯`);
  });
}

const catalog = new Set(catalogEntries().map(([source]) => source));
const nativeNames = new Set(['繁體中文', '简体中文', '日本語', '한국어', 'Français', 'Deutsch', 'Español']);
const fontNames = new Set(['微軟正黑體', '新細明體', '標楷體']);
const html = (await readFile('index.html', 'utf8'))
  .replace(/<noscript[\s\S]*?<\/noscript>/gi, '')
  .replace(/<script[\s\S]*?<\/script>/gi, '')
  .replace(/<style[\s\S]*?<\/style>/gi, '');
for (const match of html.matchAll(/>([^<>]+)</g)) {
  const source = match[1].replace(/\s+/g, ' ').trim();
  if (!/[\u3400-\u9fff]/u.test(source) || nativeNames.has(source) || fontNames.has(source)) continue;
  assert.ok(catalog.has(source), `index.html 缺少靜態翻譯：${source}`);
}
for (const match of html.matchAll(/(?:aria-label|title|placeholder)="([^"]+)"/g)) {
  const source = match[1].trim();
  if (!/[\u3400-\u9fff]/u.test(source)) continue;
  assert.ok(catalog.has(source), `index.html 缺少屬性翻譯：${source}`);
}

for (const file of (await readdir('assets/js')).filter(name => name.endsWith('.js') && name !== 'i18n.js')) {
  const sourceCode = await readFile(`assets/js/${file}`, 'utf8');
  for (const match of sourceCode.matchAll(/\bt\(\s*(['"])(.*?)\1/g)) {
    const source = match[2].replaceAll('\\n', '\n');
    assert.ok(catalog.has(source), `${file} 使用未登錄的翻譯：${source}`);
  }
}

console.log('i18n-test: passed');
