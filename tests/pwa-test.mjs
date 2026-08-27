import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const manifest = JSON.parse(await readFile('manifest.webmanifest', 'utf8'));
const index = await readFile('index.html', 'utf8');
const serviceWorker = await readFile('service-worker.js', 'utf8');

assert.equal(manifest.display, 'standalone');
assert.equal(manifest.start_url, './');
assert.deepEqual(manifest.icons.map(icon => icon.sizes), ['192x192', '512x512']);
assert.match(index, /rel="manifest" href="manifest\.webmanifest"/);
assert.match(index, /id="btn-install-pwa"/);
assert.match(serviceWorker, /icons\/pwa-icon-192x192\.png/);
assert.match(serviceWorker, /icons\/pwa-icon-512x512\.png/);
assert.match(serviceWorker, /assets\/js\/pwa\.js/);

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
