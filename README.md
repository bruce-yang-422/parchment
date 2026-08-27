<p align="center">
  <img src="image/parchment-logo-transparent.png" alt="Parchment logo" width="180">
</p>

# Parchment

> 本機 Markdown & TXT 唯讀瀏覽器，看得到、改不了。
> A calm, local-first, read-only viewer for Markdown & TXT files — open them straight in your browser, safely.

---

## 🚀 線上使用 Live Demo

👉 **[https://bruce-yang-422.github.io/parchment](https://bruce-yang-422.github.io/parchment)**

建議第一次使用時選擇「**開啟資料夾**」，才能完整支援相對圖片、跨文件連結與資料夾樹狀導覽。

---

## ✨ 特色 Features

- 📂 **資料夾模式** — 選擇本機資料夾，以樹狀結構瀏覽所有 `.md` / `.txt` 檔案
- 📄 **單檔模式** — 直接開啟單一檔案，立即顯示內容
- 🖱️ **拖放支援** — 拖曳檔案到頁面即可閱讀
- 🕘 **最近開啟** — 自動記錄最近 8 筆，重新整理後一鍵恢復
- 🎨 **Markdown 渲染** — 支援 GFM（標題、清單、表格、語法高亮程式碼區塊）
- 📋 **一鍵複製** — 程式碼區塊 hover 顯示複製按鈕
- 🧭 **雙側欄導覽** — 左側瀏覽資料夾，右側顯示目前文章目錄並追蹤閱讀章節
- 🔗 **本機相對連結** — 資料夾模式支援相對圖片與 Markdown / TXT 文件跳轉
- 📐 **完整語法** — KaTeX、Mermaid、Graphviz、註腳、Emoji、Alert、上下標、定義清單等
- 🔄 **熱更新** — 本機 Markdown 變更後自動重新渲染並保留閱讀位置
- 🔖 **閱讀進度** — 分別記錄每份文件的捲動位置
- ✅ **唯讀 TODO 檢核** — 可勾選工作清單並在本機保留狀態，不修改 Markdown 原檔
- 🌙 **羊皮紙風格主題** — 現代化暖色介面，支援淺色 / 深色 / 跟隨系統
- 🔒 **來源檔案完全唯讀** — 不寫回 Markdown / TXT，從設計上消除誤修改風險
- 🏠 **本地處理** — 所有檔案在瀏覽器本機讀取，不上傳、不進行雲端儲存或同步
- 📦 **本地依賴且可離線** — 所有執行期套件與字型皆隨專案提供，沒有 CDN 相依
- 📲 **PWA 應用程式** — 首次載入後可安裝到桌面／主畫面，之後可離線啟動

---

## 📖 使用方式 Usage

### 開啟資料夾
1. 點擊「**開啟資料夾**」按鈕
2. 選擇本機資料夾並授權瀏覽器讀取
3. 左欄顯示樹狀結構，點擊檔案即可閱讀

### 開啟單一檔案
1. 點擊「**開啟檔案**」按鈕，或將檔案**拖放**至頁面
2. 內容立即顯示於主閱讀區

### 最近開啟
- 開啟過的檔案與資料夾自動記錄於首頁
- 重新整理後點擊項目，瀏覽器會再次詢問授權，確認後立即恢復

### 已安裝的桌面應用程式

- 在支援 File Handling API 的 Chromium 桌面版中，可將 Parchment 登錄為 `.md`、`.txt` 的開啟方式。
- 從作業系統開啟文件時，Parchment 仍只取得該文件的唯讀 handle；若文件包含相對圖片，請改用「開啟資料夾」授權父資料夾。

### 支援格式

| 格式 | 顯示方式 |
|------|--------|
| `.md` | Markdown 格式化渲染（含語法高亮） |
| `.txt` | 純文字原樣顯示 |

> 本機相對圖片與跨文件連結需要資料夾讀取權限，因此請使用「開啟資料夾」。瀏覽器的單檔選擇器不會提供父資料夾權限。

### 擴充 Markdown 語法

支援 GFM、語法高亮、工作清單、註腳、Emoji（例如 `:rocket:`）、上下標、插入與標記、縮寫、定義清單、GitHub Alert、KaTeX，以及 `mermaid`、`dot`／`graphviz` fenced code block。

工作清單的 checkbox 可以直接勾選；檢核狀態只保存在目前瀏覽器的 `localStorage`，不會將 `- [ ]` 寫回 Markdown。文件熱更新或重新開啟後，會依文件路徑、任務文字指紋與重複項目順序恢復狀態。

---

## 🌐 瀏覽器支援 Browser Support

| 瀏覽器 | 單檔模式 | 資料夾模式 | 最近開啟 |
|--------|---------|----------|---------|
| Chrome 86+ | ✅ | ✅ | ✅ |
| Edge 86+ | ✅ | ✅ | ✅ |
| Firefox | ✅ | ⚠️ 降級為檔案選取 | ⚠️ 僅單檔 |
| Safari | ✅ | ⚠️ 降級為檔案選取 | ⚠️ 僅單檔 |

> 資料夾模式與最近開啟依賴 [File System Access API](https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API)，Firefox / Safari 尚未完整支援，將自動降級。
>
> 檔案熱更新需要持續讀取 FileSystemHandle，目前以 Chrome / Edge 的原生選檔流程支援最完整。

### 安裝為 PWA

1. 使用 HTTPS 的線上版本，或從 `localhost` 開啟本機版本。
2. 支援的瀏覽器會在首頁顯示「安裝 Parchment App」提示卡，標題列也會出現「安裝 App」按鈕；iPhone／iPad 則會提示從分享選單「加入主畫面」。
3. 首次載入完成後，應用程式介面、Markdown 引擎、圖表引擎與 KaTeX 字型皆可離線使用。

提示卡可選擇「稍後安裝」或「不安裝」；前者會在 12 小時後再次提醒，後者則會暫停提醒 60 天。暫停期間仍可使用標題列的「安裝 App」按鈕主動安裝。

安裝後的 Chromium 桌面版也可將 Parchment 登錄為 `.md`、`.txt` 的開啟方式；實際可用性依作業系統與瀏覽器支援而定。

> Service Worker 只預快取應用程式本身，不會複製或快取你開啟的 Markdown／TXT 內容。離線重新開啟本機文件時，仍需瀏覽器保有該 FileSystemHandle 的讀取權限。

---

## 🛠️ 本地開發 Local Development

一般開發與使用不需要 build，直接啟動本機伺服器即可：

```bash
# 方法一：Node.js
npx serve .

# 方法二：Python
python -m http.server 8080
```

開啟瀏覽器前往 `http://localhost:8080`

### 常用指令

```shell
npm ci
npm test

# 修改 HTML、CSS、JavaScript 或 PWA 圖示後
npm run pwa

# 升級第三方套件後，重建 vendor 並連帶更新 PWA 快取
npm run vendor
```

`npm run vendor` 會連帶更新 PWA 快取；若只修改 HTML、CSS、JavaScript 或圖示，可單獨執行 `npm run pwa`。它會依目前執行期資產內容產生帶雜湊版本的 `service-worker.js`。

---

## 📦 部署 Deployment

### GitHub Pages（推薦）

1. Fork 或 clone 此 repository
2. 前往 `Settings → Pages`
3. Source 設為 `main` branch、`/ (root)`
4. 若有修改執行期資產，先執行 `npm run pwa` 並提交產生的 `service-worker.js`
5. 儲存後稍等片刻，即可透過以下網址存取：

```
https://<your-username>.github.io/parchment
```

---

## 🔧 技術棧 Tech Stack

| 項目 | 技術 |
|------|------|
| 核心語言 | HTML5 / CSS3 / Vanilla JavaScript（ES Module） |
| Markdown 渲染 | markdown-it + 語法插件 |
| 語法高亮 | [highlight.js](https://highlightjs.org/) v11 |
| 安全過濾 | [DOMPurify](https://github.com/cure53/DOMPurify) v3 |
| 數學公式 | KaTeX（含本機字型） |
| 圖表 | Mermaid / Graphviz（`@viz-js/viz`） |
| 檔案存取 | File System Access API |
| 最近開啟 | IndexedDB |
| 閱讀位置 | localStorage |
| TODO 檢核狀態 | localStorage（文件識別、任務文字指紋與勾選值） |
| PWA | Web App Manifest + Service Worker 預快取 |
| 部署 | GitHub Pages |

---

## 🗂️ 專案結構 Project Structure

```text
parchment/
├── index.html                 # 應用程式入口
├── manifest.webmanifest       # PWA 名稱、圖示與檔案處理宣告
├── service-worker.js          # 自動產生的離線預快取
├── assets/
│   ├── css/style.css          # 版面與主題
│   ├── js/                    # 閱讀器、檔案、TOC、TODO、PWA 等模組
│   └── vendor/                # 本地化的 Markdown／圖表／安全套件
├── icons/                     # 192px／512px PWA 圖示
├── image/                     # 品牌圖像
├── scripts/                   # vendor 與 PWA 建置腳本
└── tests/                     # 路徑、TODO、渲染與 PWA 測試
```

---

## 🔒 隱私聲明 Privacy

- ✅ 所有檔案讀取皆在**使用者瀏覽器本機**執行
- ✅ 不上傳任何檔案至伺服器
- ✅ 不收集任何使用者資料
- ✅ 無任何後端服務
- ✅ IndexedDB 僅儲存檔案名稱與系統 handle，不儲存任何檔案內容
- ✅ 閱讀位置只儲存在瀏覽器 localStorage
- ✅ TODO 只儲存任務文字指紋與勾選狀態，不儲存任務原文，也不修改來源文件

> 若文件本身引用 `https://` 圖片、字型或其他遠端資源，瀏覽器仍可能向該網址發出請求。需要完全斷網閱讀時，請使用本機相對資源並透過資料夾模式開啟。

---

## 📋 開發路線圖 Roadmap

- [x] 單檔模式
- [x] 資料夾樹狀瀏覽
- [x] Markdown 渲染（GFM + 語法高亮）
- [x] 主題切換（淺色 / 深色 / 系統）
- [x] 拖放支援
- [x] 最近開啟紀錄（IndexedDB）
- [x] 程式碼區塊複製按鈕
- [x] 本機相對圖片與文件連結
- [x] 文章目錄（TOC）
- [x] 閱讀位置記錄
- [x] 唯讀 TODO 檢核與本機狀態保存
- [x] KaTeX / Mermaid / Graphviz / 註腳 / Emoji / Alert
- [x] Markdown 檔案熱更新
- [x] 第三方套件本地化（完全離線）
- [x] PWA 安裝、離線啟動與桌面檔案處理
- [ ] 全文搜尋（跨檔案）

---

## 📄 授權 License

[MIT License](LICENSE). Bundled dependency notices are listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

---

<p align="center">
  Made with ☕ · 看得到、改不了
</p>
