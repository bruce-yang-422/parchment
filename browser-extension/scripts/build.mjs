/**
 * 建置 Parchment 瀏覽器外掛（Chrome、Edge，Manifest V3）。
 *
 * 1. 將 browser-extension/src 複製到 browser-extension/dist
 * 2. 將網站（index.html、assets、icons、image）複製到 dist/app，移除 PWA 專用的 manifest 連結
 * 3. 寫入 package.json 的版本號，並檢查 Chrome Web Store 的常見限制
 * 4. 輸出上架用的 browser-extension/release/parchment-extension-<版本>.zip
 *
 * 用法：npm run extension（請先執行 npm run pwa，確保網站資產為最新）
 */

import { cp, mkdir, readFile, readdir, rm, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { crc32, deflateRawSync } from 'node:zlib';

const extensionRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const projectRoot = path.resolve(extensionRoot, '..');
const srcDir = path.join(extensionRoot, 'src');
const distDir = path.join(extensionRoot, 'dist');
const appDir = path.join(distDir, 'app');
const releaseDir = path.join(extensionRoot, 'release');

const { version } = JSON.parse(await readFile(path.join(projectRoot, 'package.json'), 'utf8'));

await rm(distDir, { recursive: true, force: true });
await mkdir(appDir, { recursive: true });

// 1. 外掛原始碼
await cp(srcDir, distDir, { recursive: true });

// 2. 網站
for (const entry of ['assets', 'icons', 'image']) {
  await cp(path.join(projectRoot, entry), path.join(appDir, entry), { recursive: true });
}
let indexHtml = await readFile(path.join(projectRoot, 'index.html'), 'utf8');
indexHtml = indexHtml.replace(/^\s*<link rel="manifest"[^>]*>\r?\n/m, '');
await writeFile(path.join(appDir, 'index.html'), indexHtml);
// 隱私權政策頁：外掛中無法以「./」載入 index.html，改為明確的檔名
const privacyHtml = (await readFile(path.join(projectRoot, 'privacy.html'), 'utf8'))
  .replace(/href="\.\/"/g, 'href="index.html"');
await writeFile(path.join(appDir, 'privacy.html'), privacyHtml);
for (const file of ['LICENSE', 'THIRD_PARTY_LICENSES.md']) {
  await cp(path.join(projectRoot, file), path.join(distDir, file));
}

// 3. 版本號與檢查
const manifestPath = path.join(distDir, 'manifest.json');
const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
manifest.version = version;
await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);

const problems = [];
const exists = async file => stat(path.join(distDir, file)).then(() => true, () => false);

if (manifest.manifest_version !== 3) problems.push('manifest_version 必須為 3');
for (const file of [
  ...Object.values(manifest.icons),
  ...Object.values(manifest.action.default_icon),
  manifest.background.service_worker,
  manifest.options_ui.page,
  ...manifest.content_scripts.flatMap(script => script.js),
]) {
  if (!(await exists(file))) problems.push(`manifest 引用的檔案不存在：${file}`);
}

for (const locale of await readdir(path.join(distDir, '_locales'))) {
  const messages = JSON.parse(await readFile(path.join(distDir, '_locales', locale, 'messages.json'), 'utf8'));
  const description = messages.extDescription?.message || '';
  const name = messages.extName?.message || '';
  if (!description || [...description].length > 132) problems.push(`${locale} 的描述需為 1–132 字元（目前 ${[...description].length}）`);
  if (!name || [...name].length > 75) problems.push(`${locale} 的名稱需為 1–75 字元`);
}

// Manifest V3 的擴充功能頁面禁止內嵌腳本與內嵌事件屬性
for (const page of ['app/index.html', 'app/privacy.html', manifest.options_ui.page]) {
  const html = (await readFile(path.join(distDir, page), 'utf8'))
    .replace(/<script type="application\/ld\+json">[\s\S]*?<\/script>/g, '');
  if (/<script(?![^>]*\bsrc=)[^>]*>/i.test(html)) problems.push(`${page} 含有內嵌 <script>`);
  if (/\son[a-z]+=/i.test(html)) problems.push(`${page} 含有內嵌事件屬性（onload= 等）`);
  if (/<script[^>]+src="https?:/i.test(html)) problems.push(`${page} 載入遠端腳本（Chrome Web Store 禁止遠端程式碼）`);
}

if (problems.length) {
  console.error(`外掛建置檢查失敗：\n- ${problems.join('\n- ')}`);
  process.exit(1);
}

// 4. 打包 zip（manifest.json 位於 zip 根目錄）
const files = await listFiles(distDir);
await mkdir(releaseDir, { recursive: true });
const zipPath = path.join(releaseDir, `parchment-extension-${version}.zip`);
await writeFile(zipPath, await createZip(distDir, files));
const zipSize = (await stat(zipPath)).size;

console.log(`browser-extension：版本 ${version}，${files.length} 個檔案`);
console.log(`  未封裝：${path.relative(projectRoot, distDir)}`);
console.log(`  上架檔：${path.relative(projectRoot, zipPath)}（${(zipSize / 1024 / 1024).toFixed(1)} MB）`);

/* ──────────────────── helpers ──────────────────── */

async function listFiles(dir, base = dir) {
  const output = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) output.push(...await listFiles(full, base));
    else output.push(path.relative(base, full).split(path.sep).join('/'));
  }
  return output.sort();
}

/** 以 deflate 壓縮寫出標準 zip（無需額外套件）。 */
async function createZip(root, relativePaths) {
  const localParts = [];
  const centralParts = [];
  let offset = 0;
  const { time, date } = dosDateTime(new Date());

  for (const relativePath of relativePaths) {
    const data = await readFile(path.join(root, relativePath));
    const compressed = deflateRawSync(data, { level: 9 });
    const useDeflate = compressed.length < data.length;
    const body = useDeflate ? compressed : data;
    const name = Buffer.from(relativePath, 'utf8');
    const checksum = crc32(data);

    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4);
    local.writeUInt16LE(0x0800, 6); // UTF-8 檔名
    local.writeUInt16LE(useDeflate ? 8 : 0, 8);
    local.writeUInt16LE(time, 10);
    local.writeUInt16LE(date, 12);
    local.writeUInt32LE(checksum, 14);
    local.writeUInt32LE(body.length, 18);
    local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(name.length, 26);
    localParts.push(local, name, body);

    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0);
    central.writeUInt16LE(20, 4);
    central.writeUInt16LE(20, 6);
    central.writeUInt16LE(0x0800, 8);
    central.writeUInt16LE(useDeflate ? 8 : 0, 10);
    central.writeUInt16LE(time, 12);
    central.writeUInt16LE(date, 14);
    central.writeUInt32LE(checksum, 16);
    central.writeUInt32LE(body.length, 20);
    central.writeUInt32LE(data.length, 24);
    central.writeUInt16LE(name.length, 28);
    central.writeUInt32LE(offset, 42);
    centralParts.push(central, name);

    offset += local.length + name.length + body.length;
  }

  const centralDirectory = Buffer.concat(centralParts);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(relativePaths.length, 8);
  end.writeUInt16LE(relativePaths.length, 10);
  end.writeUInt32LE(centralDirectory.length, 12);
  end.writeUInt32LE(offset, 16);
  return Buffer.concat([...localParts, centralDirectory, end]);
}

function dosDateTime(value) {
  return {
    time: (value.getHours() << 11) | (value.getMinutes() << 5) | Math.floor(value.getSeconds() / 2),
    date: ((value.getFullYear() - 1980) << 9) | ((value.getMonth() + 1) << 5) | value.getDate(),
  };
}
