import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const SITE = 'https://parchment.stack-base.com/';
const index = await readFile('index.html', 'utf8');
const privacy = await readFile('privacy.html', 'utf8');
const serviceWorker = await readFile('service-worker.js', 'utf8');
const sitemap = await readFile('sitemap.xml', 'utf8');

const meta = (html, attr, key) =>
  html.match(new RegExp(`<meta ${attr}="${key}" content="([^"]*)"`))?.[1];

/* 首頁：標題、描述、索引、canonical */
const title = index.match(/<title>([^<]+)<\/title>/)[1];
assert.ok(title.startsWith('Parchment'), '標題以品牌開頭');
assert.ok(title.length <= 60, `標題過長（${title.length}）`);
const description = meta(index, 'name', 'description');
assert.ok(description && description.length >= 50, '描述需具體');
assert.match(description, /Markdown/);
assert.match(meta(index, 'name', 'robots'), /index, follow/);
assert.match(index, new RegExp(`<link rel="canonical" href="${SITE}">`));
assert.equal(meta(index, 'property', 'og:title'), title);
assert.ok(meta(index, 'property', 'og:description'));

/* 結構化資料可解析，且包含 Google 要求的 priceCurrency */
const jsonLd = JSON.parse(index.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/)[1]);
assert.equal(jsonLd['@type'], 'WebApplication');
assert.equal(jsonLd.url, SITE);
assert.equal(jsonLd.offers.priceCurrency, 'USD');
assert.ok(Array.isArray(jsonLd.featureList) && jsonLd.featureList.length >= 3);
const { webVersion } = JSON.parse(await readFile('package.json', 'utf8'));
assert.equal(jsonLd.softwareVersion, webVersion, 'JSON-LD 版本需與 package.json 的 webVersion 一致');
const about = index.match(/<dialog id="about-dialog"[\s\S]*?<\/dialog>/)?.[0] ?? '';
assert.ok(about.includes(`<span>版本 ${webVersion}</span>`), '關於 Parchment 需顯示官網版本');

/* 隱私權政策頁：首頁連結、可被索引、無內嵌腳本 */
assert.match(index, /<link rel="privacy-policy" href="privacy\.html">/);
assert.ok((index.match(/href="privacy\.html"/g) || []).length >= 3, '首頁需連到隱私權政策');
assert.match(privacy, new RegExp(`<link rel="canonical" href="${SITE}privacy\\.html">`));
assert.ok(meta(privacy, 'name', 'description'));
assert.match(privacy, /lang="zh-TW"/);
assert.match(privacy, /lang="en"/);
assert.doesNotMatch(privacy, /<script(?![^>]*\bsrc=)[^>]*>/, '隱私權頁不得有內嵌腳本');
assert.doesNotMatch(privacy, /\son[a-z]+=/);

/* Android 介紹與封閉測試報名頁 */
const android = await readFile('android.html', 'utf8');
assert.match(android, new RegExp(`<link rel="canonical" href="${SITE}android\\.html">`));
assert.ok(meta(android, 'name', 'description'));
assert.match(android, /https:\/\/forms\.gle\/x7bz1HXKfJ64gUbg6/);
assert.ok(index.includes('android.html"'), '首頁需連到 Android 頁');
assert.doesNotMatch(android, /<script(?![^>]*\bsrc=)[^>]*>/, 'Android 頁不得有內嵌腳本');
for (const src of android.matchAll(/src="(image\/android\/[^"]+)"/g)) await readFile(src[1]);
assert.match(sitemap, new RegExp(`<loc>${SITE}android\\.html</loc>`));

/* 離線快取與網站地圖 */
assert.match(serviceWorker, /"\.\/privacy\.html"/);
assert.match(sitemap, new RegExp(`<loc>${SITE}</loc>`));
assert.match(sitemap, new RegExp(`<loc>${SITE}privacy\\.html</loc>`));

/* GitHub Pages 不使用 Jekyll：否則含 Frontmatter 的 samples/*.md 會被轉成 .html，
   範例無法開啟，Service Worker 預先快取也會因 404 而安裝失敗 */
await readFile('.nojekyll', 'utf8');

/* 自訂網域：CNAME 與 robots.txt 必須與網站網址一致 */
const cname = (await readFile('CNAME', 'utf8')).trim();
assert.equal(`https://${cname}/`, SITE, 'CNAME 需與網站網址一致');
const robots = await readFile('robots.txt', 'utf8');
assert.match(robots, /^User-agent: \*$/m);
assert.ok(robots.includes(`Sitemap: ${SITE}sitemap.xml`));
for (const file of ['index.html', 'privacy.html', 'sitemap.xml', 'README.md', 'README.en.md']) {
  const text = await readFile(file, 'utf8');
  assert.doesNotMatch(text, /bruce-yang-422\.github\.io\/parchment/, `${file} 仍含舊網址`);
}

/* 外掛上架時填寫的隱私權政策網址 */
const listing = await readFile('browser-extension/STORE_LISTING.md', 'utf8');
assert.ok(listing.includes(`${SITE}privacy.html`));

console.log('seo-test: passed');
