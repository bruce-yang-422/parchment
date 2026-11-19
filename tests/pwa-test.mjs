import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PWA_INSTALL_REMINDER_DELAYS } from '../assets/js/pwa.js';

const manifest = JSON.parse(await readFile('manifest.webmanifest', 'utf8'));
const index = await readFile('index.html', 'utf8');
const serviceWorker = await readFile('service-worker.js', 'utf8');
const pwaScript = await readFile('assets/js/pwa.js', 'utf8');
const shellStyles = await readFile('src/styles/shell.css', 'utf8');

assert.equal(manifest.display, 'standalone');
assert.equal(manifest.start_url, './');
assert.deepEqual(manifest.icons.map(icon => icon.sizes), ['192x192', '512x512']);
assert.match(index, /rel="manifest" href="manifest\.webmanifest"/);
assert.match(index, /id="btn-install-pwa"/);
assert.match(index, /id="btn-install-pwa"[\s\S]*?<span>安裝 App<\/span>/);
assert.match(shellStyles, /\.header-install\s*\{\s*@apply[^;]*\bjustify-center\b/);
assert.match(index, /id="workspace-toggle"/);
assert.match(index, /id="settings-dialog"/);
assert.match(index, /id="setting-cjk-font"/);
assert.match(index, /id="setting-latin-font"/);
assert.match(index, /id="pwa-install-card"/);
assert.match(index, /id="pwa-install-action"/);
assert.match(index, /id="pwa-install-later"/);
assert.match(index, /id="pwa-install-decline"/);
assert.match(index, /class="welcome-logo-image" src="image\/parchment-logo-transparent\.png"/);
// 不使用內嵌腳本或事件屬性，以符合瀏覽器外掛的內容安全政策（CSP）
assert.doesNotMatch(index, /\son(load|error|click)=/);
assert.doesNotMatch(index.replace(/<script type="application\/ld\+json">[\s\S]*?<\/script>/, ''), /<script>/);
assert.match(index, /<script src="assets\/js\/boot\.js"><\/script>/);
assert.match(index, /<script src="assets\/js\/btoa-patch\.js"><\/script>\s*<script src="assets\/vendor\/mermaid\.min\.js">/);
assert.match(pwaScript, /beforeinstallprompt/);
assert.match(pwaScript, /加入主畫面/);
assert.equal(PWA_INSTALL_REMINDER_DELAYS.later, 12 * 60 * 60 * 1000);
assert.equal(PWA_INSTALL_REMINDER_DELAYS.declined, 60 * 24 * 60 * 60 * 1000);
assert.match(serviceWorker, /icons\/pwa-icon-192x192\.png/);
assert.match(serviceWorker, /icons\/pwa-icon-512x512\.png/);
assert.match(serviceWorker, /image\/parchment-logo-transparent\.png/);
assert.match(serviceWorker, /assets\/js\/pwa\.js/);
// 頁面與資產只能從同一版本的快取取用，避免部署後新 HTML 搭配舊 CSS／JS
assert.doesNotMatch(serviceWorker, /(?<!cache\.)caches\.match\(request/);
assert.match(serviceWorker, /caches\.open\(CACHE_NAME\)[\s\S]*cache\.match\(request, \{ ignoreSearch: true \}\)/);
assert.match(pwaScript, /controllerchange/);
assert.match(serviceWorker, /assets\/css\/style\.css/);
assert.match(serviceWorker, /assets\/js\/readerFont\.js/);
assert.match(serviceWorker, /assets\/js\/settingsPanel\.js/);
assert.match(serviceWorker, /assets\/js\/sidebarResize\.js/);
assert.match(serviceWorker, /assets\/js\/taskState\.js/);

for (const [file, width, height] of [
  ['icons/pwa-icon-192x192.png', 192, 192],
  ['icons/pwa-icon-512x512.png', 512, 512],
]) {
  const png = await readFile(file);
  assert.equal(png.toString('ascii', 1, 4), 'PNG');
  assert.equal(png.readUInt32BE(16), width);
  assert.equal(png.readUInt32BE(20), height);
}

console.log('pwa-test: passed');
