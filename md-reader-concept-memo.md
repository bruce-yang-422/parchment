# Markdown / TXT 唯讀閱讀器 — 完整概念備忘錄（含實作規劃）

---

# 一、目的（Purpose）

建立一個 **Markdown / 純文字唯讀閱讀工具（Web-based）**，用於：

* 安全瀏覽本機 `.md` 與 `.txt` 檔案
* 避免任何誤編輯或誤覆寫
* 提供簡單、穩定、低干擾的閱讀體驗
* 透過網站形式免費提供使用

核心目標：

> **「內容可讀、可複製，但絕不可修改」**

---

# 二、設計理念（Design Philosophy）

## 1. 唯讀優先（Read-Only First）
不提供任何編輯能力；不存在編輯模式或切換；從設計上消除誤修改可能。

## 2. 最小干擾（Minimal Interaction）
不包含編輯、同步、插件等功能；不模擬 IDE 或筆記工具；專注閱讀行為。

## 3. 安全優先（Safety over Flexibility）
優先避免風險，而非增加彈性；降低功能複雜度。

## 4. 單一用途（Single Responsibility）
僅為閱讀器；不承擔內容管理或創作。

## 5. 本地優先（Local-first）
所有檔案處理皆在使用者本機完成；不上傳、不儲存、不同步。

---

# 三、部署與產品定位（Deployment & Positioning）

| 項目 | 說明 |
|------|------|
| 部署方式 | 靜態網站，部署於 **GitHub Pages** |
| 費用 | 免費 |
| 後端服務 | 無 |
| 資料傳輸 | 無，所有操作在瀏覽器本機執行 |
| 隱私 | 不上傳任何檔案、不存取未授權資料 |

> **產品定位：「Browser-based 本機 Markdown / TXT 唯讀瀏覽器」**

---

# 四、使用情境（Use Cases）

**主要情境**
* 瀏覽筆記資料夾
* 查閱技術文件
* 快速預覽 Markdown / 純文字

**次要情境**
* 作為編輯器的輔助閱讀工具
* 避免誤修改正式文件

---

# 五、功能需求（Functional Requirements）

## 1. 載入方式（Dual Input Modes）

### (1) 資料夾模式
選擇本機資料夾 → 顯示樹狀結構 → 可瀏覽多檔案

### (2) 單檔模式
選擇單一檔案 → 直接顯示內容 → 不顯示樹狀結構

### (3) 拖放支援（Drag & Drop）
支援拖放 `.md`、`.txt` 檔案 → 拖放後進入單檔模式

## 2. 檔案篩選規則（File Filtering）

| 模式 | 顯示 | 不顯示 |
|------|------|--------|
| 資料夾模式 | `.md`、`.txt`、資料夾、隱藏檔 | 其他類型 |
| 單檔模式 | `.md`、`.txt` | 其他格式（拒絕） |

* 副檔名不區分大小寫
* 無副檔名檔案不顯示

## 3. 內容顯示

| 格式 | 顯示方式 |
|------|--------|
| `.md` | 格式化渲染（含標題、清單、表格、程式碼區塊） |
| `.txt` | 原樣顯示，保留換行 |

## 4. 使用者操作
* 支援滑鼠選取、複製（Ctrl+C / 右鍵）
* 資料夾模式：左欄樹狀、右欄內容
* 單檔模式：全寬內容

## 5. 主題（Theme）
系統（System） / 淺色（Light） / 深色（Dark）

---

# 六、非功能需求（Non-Functional Requirements）

| 項目 | 要求 |
|------|------|
| 安全性 | 無任何寫入能力、無儲存行為 |
| 穩定性 | 穩定顯示常見 Markdown / TXT |
| 效能 | 中小型資料夾快速載入、即時切換 |
| 易用性 | 無學習成本、操作直覺 |

---

# 七、限制（Constraints）

**不支援功能：** 編輯 / 修改、儲存、插件、雲端同步、協作、版本控制

**平台限制：**
* 需支援 File System Access API 的瀏覽器（Chrome 86+ / Edge 86+）
* Firefox / Safari 目前不支援 `showDirectoryPicker`，資料夾模式降級為單檔模式
* 需使用者手動授權檔案存取

---

# 八、實作規劃（Implementation Plan）

## 8.1 技術棧選型（Tech Stack）

### 核心方案：純靜態單頁（推薦）

| 層次 | 技術 | 說明 |
|------|------|------|
| 結構 | HTML5 | 單一 `index.html` 入口 |
| 樣式 | CSS（原生 Custom Properties） | 主題切換無需 JS 框架 |
| 邏輯 | Vanilla JavaScript（ES Module） | 無框架依賴，易維護 |
| Markdown 渲染 | **marked.js v12** | 輕量（~50KB）、快速、支援 GFM |
| 語法高亮 | **highlight.js v11** | 搭配 marked，渲染程式碼區塊 |
| 安全過濾 | **DOMPurify v3** | 防止 Markdown XSS（`<script>` 注入） |
| 字型 | **Noto Sans TC**（Google Fonts） | 思源黑體 Web 版本 |
| 最近開啟 | **IndexedDB** | 儲存 FileSystemHandle，跨頁面恢復存取 |
| 建置工具 | **Vite**（可選） | 本地開發 HMR、打包壓縮 |

> **為何不用框架（React/Vue）？**
> 此工具邏輯簡單，不需要響應式狀態管理。Vanilla JS 體積更小、部署更直接，且 GitHub Pages 不需 build 步驟即可運作。

---

### 備選方案：輕量框架

若未來需擴充（搜尋、TOC、書籤），可考慮：

| 方案 | 適用時機 |
|------|---------|
| **Preact + htm** | 需元件化但不想設 build 工具 |
| **Alpine.js** | 保留 HTML 結構，加少量互動邏輯 |
| **Astro（static）** | 需 SSG、多頁架構時 |

---

## 8.2 關鍵瀏覽器 API

### File System Access API
```
window.showOpenFilePicker()       → 選擇單一檔案
window.showDirectoryPicker()      → 選擇資料夾（含子目錄遞迴）
FileSystemFileHandle.getFile()    → 讀取檔案內容（唯讀 Blob）
FileSystemDirectoryHandle.entries()  → 列出目錄內容
```

**重要特性：**
* 僅提供讀取（`read`）權限，本工具不請求 `readwrite`，徹底避免寫入
* ~~每次重新開啟頁面需重新授權（無持久化存取）~~ → 已透過 IndexedDB 儲存 handle，重新整理後可一鍵恢復（仍需使用者點擊確認授權）
* Safari / Firefox 不支援 `showDirectoryPicker`，需偵測並顯示提示

### Drag & Drop API
```
dragover → 阻止預設行為（避免瀏覽器直接開啟檔案）
drop     → 取得 DataTransferItem，再轉為 FileSystemFileHandle 或 File
```

### `prefers-color-scheme` Media Query
偵測系統主題，配合 CSS 變數自動切換淺 / 深色。

---

## 8.3 第三方套件清單

| 套件 | 版本 | 用途 | CDN 引入方式 |
|------|------|------|------------|
| [marked](https://marked.js.org/) | v12.x | Markdown → HTML | `<script type="module">` from jsDelivr |
| [highlight.js](https://highlightjs.org/) | v11.x | 程式碼語法高亮 | jsDelivr（僅載入需要的語言包） |
| [DOMPurify](https://github.com/cure53/DOMPurify) | v3.x | HTML 清理、防 XSS | jsDelivr |

> 全部透過 CDN 引入，**不需 `npm install`**，GitHub Pages 直接部署零設定。
> 若使用 Vite，改為本地安裝以支援 tree-shaking。

---

## 8.4 專案結構

```
parchment/
├── index.html              ← 主頁（單一 HTML 入口）
├── assets/
│   ├── css/
│   │   └── style.css       ← 全域樣式 + 主題 CSS 變數
│   └── js/
│       ├── app.js          ← 主邏輯（ES Module）
│       ├── fileLoader.js   ← File System Access API 封裝
│       ├── renderer.js     ← Markdown 渲染 + highlight 整合
│       ├── tree.js         ← 資料夾樹狀結構 UI
│       ├── theme.js        ← 主題切換邏輯
│       └── recentFiles.js  ← 最近開啟紀錄（IndexedDB）
└── README.md
```

> 若選擇 Vite，加入 `package.json` 與 `vite.config.js`，輸出至 `/dist` 再部署。

---

## 8.5 核心模組設計

### fileLoader.js — 檔案讀取

```javascript
// 單檔模式
async function openFile() {
  const [handle] = await window.showOpenFilePicker({
    types: [{ accept: { 'text/*': ['.md', '.txt'] } }]
  });
  const file = await handle.getFile();
  return { name: file.name, content: await file.text() };
}

// 資料夾模式（遞迴）
async function openDirectory() {
  const dirHandle = await window.showDirectoryPicker({ mode: 'read' });
  return buildTree(dirHandle);
}

async function buildTree(dirHandle, path = '') {
  const entries = [];
  for await (const [name, handle] of dirHandle.entries()) {
    if (handle.kind === 'directory') {
      entries.push({ type: 'dir', name, children: await buildTree(handle, path + name + '/') });
    } else if (isSupportedFile(name)) {
      entries.push({ type: 'file', name, path: path + name, handle });
    }
  }
  return entries.sort(sortDirFirst);
}

function isSupportedFile(name) {
  return /\.(md|txt)$/i.test(name);
}
```

---

### renderer.js — Markdown 渲染

```javascript
import { marked } from 'marked';
import hljs from 'highlight.js';
import DOMPurify from 'dompurify';

marked.setOptions({
  highlight: (code, lang) => {
    return lang && hljs.getLanguage(lang)
      ? hljs.highlight(code, { language: lang }).value
      : hljs.highlightAuto(code).value;
  },
  gfm: true,      // GitHub Flavored Markdown
  breaks: false,  // 不強制換行（保留 Markdown 標準）
});

export function renderMarkdown(content) {
  const rawHtml = marked.parse(content);
  return DOMPurify.sanitize(rawHtml);   // 清理 XSS
}

export function renderText(content) {
  // 純文字：escaping + 保留空白換行
  const escaped = content
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return `<pre class="txt-view">${escaped}</pre>`;
}
```

---

### theme.js — 主題切換

```javascript
const THEMES = ['system', 'light', 'dark'];

export function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  localStorage.setItem('theme', theme);
}

export function initTheme() {
  const saved = localStorage.getItem('theme') || 'system';
  applyTheme(saved);
}
```

```css
/* style.css — CSS 變數主題系統 */
:root {
  --bg: #ffffff;
  --text: #1a1a1a;
  --sidebar-bg: #f5f5f5;
  --border: #e0e0e0;
  --accent: #2563eb;
}

[data-theme="dark"],
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #1e1e1e;
    --text: #e8e8e8;
    --sidebar-bg: #252526;
    --border: #3a3a3a;
    --accent: #60a5fa;
  }
}
```

---

## 8.6 瀏覽器相容性處理

| 功能 | Chrome/Edge 86+ | Firefox | Safari |
|------|----------------|---------|--------|
| `showOpenFilePicker` | ✅ | ❌ | ❌ (iOS/macOS 部分支援) |
| `showDirectoryPicker` | ✅ | ❌ | ❌ |
| `<input type="file">` | ✅ | ✅ | ✅ |
| Drag & Drop | ✅ | ✅ | ✅ |

**降級策略：**
```javascript
const hasFileSystemAPI = 'showOpenFilePicker' in window;

if (!hasFileSystemAPI) {
  // 降級：使用傳統 <input type="file"> + webkitdirectory
  // 資料夾模式仍可用，但路徑資訊受限
  showFallbackUI();
}
```

---

## 8.7 UI 佈局草圖

```
┌─────────────────────────────────────────────────────────┐
│  📄 MD Reader          [System ▾]  [開啟資料夾] [開啟檔案] │
├──────────────┬──────────────────────────────────────────┤
│ 📁 notes/    │  # 標題一                                 │
│  ├ 📄 a.md   │                                           │
│  ├ 📄 b.txt  │  內文段落內容，支援 **粗體**、_斜體_...   │
│  └ 📁 sub/   │                                           │
│    └ 📄 c.md │  ## 標題二                                │
│              │  - 清單項目                               │
│              │  - 清單項目                               │
│              │                                           │
│              │  ```python                                │
│              │  print("Hello")                           │
│              │  ```                                      │
└──────────────┴──────────────────────────────────────────┘
```

---

# 九、開發與部署流程（Dev & Deploy）

## 9.1 本地開發

### 方案 A：無建置工具（最簡單）
```bash
# 僅需一個本機靜態伺服器（避免 CORS / ES Module 問題）
npx serve .
# 或
python -m http.server 8080
```

### 方案 B：Vite 開發環境
```bash
npm create vite@latest md-reader -- --template vanilla
cd md-reader
npm install marked highlight.js dompurify
npm run dev       # HMR 開發
npm run build     # 輸出至 /dist
```

---

## 9.2 GitHub Pages 部署

### 方案 A：直接推送（無 build 步驟）
```
Repository 設定 → Pages → Source: main branch / root
→ 網址：https://<username>.github.io/md-reader/
```

### 方案 B：GitHub Actions 自動部署（使用 Vite）
```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci && npm run build
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

---

# 十、實作分階段計畫（Milestones）

| 階段 | 目標 | 狀態 |
|------|------|------|
| **Phase 1** | 單檔模式 + Markdown 渲染 + 基本樣式 | ✅ 完成 |
| **Phase 2** | 資料夾模式 + 樹狀結構 UI | ✅ 完成 |
| **Phase 3** | 主題切換 + 拖放支援 + 瀏覽器降級 | ✅ 完成 |
| **Phase 4** | UI 精修（字體 Noto Sans TC、配色、間距）+ 部署 | ✅ 完成 |
| **Phase 4+** | 最近開啟（IndexedDB）+ 程式碼複製按鈕 | ✅ 完成 |
| **Phase 5**（選填） | 全文搜尋、TOC、閱讀位置記錄 | 待實作 |

---

# 十一、已知風險與對策（Risks）

| 風險 | 影響 | 對策 |
|------|------|------|
| Firefox / Safari 不支援 `showDirectoryPicker` | 資料夾模式失效 | 偵測後降級為 `<input webkitdirectory>` |
| 超大 `.md` 檔案（> 5MB） | 渲染卡頓 | 加入檔案大小警告 + 延遲渲染 |
| Markdown 中含惡意 HTML | XSS 攻擊 | DOMPurify 過濾，預設關閉 raw HTML |
| CDN 無法存取 | 套件載入失敗 | 提供 fallback 本地複製版本 |

---

# 十二、使用者價值（User Value）

* **零誤修改風險** — 設計層面消除
* **專注閱讀體驗** — 無多餘功能干擾
* **快速使用（免安裝）** — 瀏覽器直接存取
* **隱私保護（本地處理）** — 資料不離機器

---

# 十三、成功標準（Success Criteria）

1. 能快速開啟並瀏覽檔案
2. 使用過程完全無修改風險
3. 閱讀體驗清晰穩定
4. 可取代為閱讀而開啟編輯器

---

# 十四、未來擴展（非當前範圍）

* 全文搜尋（Ctrl+F 跨檔案）
* 文章目錄（TOC 側欄）
* ~~最近開啟紀錄（IndexedDB）~~ ✅ 已實作
* 閱讀位置記錄
* 列印 / 匯出 PDF

---

# 十五、總結

本工具定義為：

> **「部署於 GitHub Pages 的本機 Markdown / TXT 唯讀瀏覽器」**

**技術核心：**
* 純前端 Vanilla JS + marked.js + DOMPurify
* File System Access API（含降級方案）
* 靜態部署，無後端，免費可用

**實作起點建議：**
> 從 **Phase 1（單檔模式）** 開始，以最短時間驗證渲染效果與使用體驗，再逐步加入資料夾模式與主題切換。
