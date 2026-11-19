import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PWA_INSTALL_REMINDER_DELAYS } from '../assets/js/pwa.js';

const manifest = JSON.parse(await readFile('manifest.webmanifest', 'utf8'));
const index = await readFile('index.html', 'utf8');
const serviceWorker = await readFile('service-worker.js', 'utf8');
const pwaScript = await readFile('assets/js/pwa.js', 'utf8');

assert.equal(manifest.display, 'standalone');
assert.equal(manifest.start_url, './');
assert.deepEqual(manifest.icons.map(icon => icon.sizes), ['192x192', '512x512']);
assert.match(index, /rel="manifest" href="manifest\.webmanifest"/);
assert.match(index, /id="btn-install-pwa"/);
assert.match(index, /id="pwa-install-card"/);
assert.match(index, /id="pwa-install-action"/);
assert.match(index, /id="pwa-install-later"/);
assert.match(index, /id="pwa-install-decline"/);
assert.match(index, /class="welcome-logo-image" src="image\/parchment-logo-transparent\.png"/);
assert.match(index, /onload="this\.previousElementSibling\.hidden = true"/);
assert.match(index, /onerror="this\.hidden = true"/);
assert.match(pwaScript, /beforeinstallprompt/);
assert.match(pwaScript, /加入主畫面/);
assert.equal(PWA_INSTALL_REMINDER_DELAYS.later, 12 * 60 * 60 * 1000);
assert.equal(PWA_INSTALL_REMINDER_DELAYS.declined, 60 * 24 * 60 * 60 * 1000);
assert.match(serviceWorker, /icons\/pwa-icon-192x192\.png/);
assert.match(serviceWorker, /icons\/pwa-icon-512x512\.png/);
assert.match(serviceWorker, /image\/parchment-logo-transparent\.png/);
assert.match(serviceWorker, /assets\/js\/pwa\.js/);
assert.match(serviceWorker, /assets\/css\/style\.css/);
assert.match(serviceWorker, /assets\/js\/readerFont\.js/);
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
