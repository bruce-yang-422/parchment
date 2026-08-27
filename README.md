# 🟤 Parchment

> 本機 Markdown & TXT 唯讀瀏覽器，看得到、改不了。
> A calm, local-first, read-only viewer for Markdown & TXT files — open them straight in your browser, safely.

---

## 🚀 線上使用 Live Demo

👉 **[https://bruce-yang-422.github.io/parchment](https://bruce-yang-422.github.io/parchment)**

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
- 🌙 **三種主題** — 淺色 / 深色 / 跟隨系統
- 🔒 **完全唯讀** — 無任何寫入或儲存行為，從設計上消除誤修改風險
- 🏠 **本地處理** — 所有檔案在瀏覽器本機讀取，不上傳、不儲存、不同步
- 📦 **免安裝且可離線** — 純靜態網頁，所有執行期套件與字型皆已隨專案提供
- 📲 **PWA 應用程式** — 可安裝到桌面／主畫面，安裝後可離線啟動

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

### 支援格式

| 格式 | 顯示方式 |
|------|--------|
| `.md` | Markdown 格式化渲染（含語法高亮） |
| `.txt` | 純文字原樣顯示 |

> 本機相對圖片與跨文件連結需要資料夾讀取權限，因此請使用「開啟資料夾」。瀏覽器的單檔選擇器不會提供父資料夾權限。

### 擴充 Markdown 語法

支援 GFM、語法高亮、工作清單、註腳、Emoji（例如 `:rocket:`）、上下標、插入與標記、縮寫、定義清單、GitHub Alert、KaTeX，以及 `mermaid`、`dot`／`graphviz` fenced code block。

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
2. 支援的瀏覽器會在標題列顯示「安裝應用程式」；也可使用瀏覽器網址列或選單中的安裝功能。
3. 首次載入完成後，應用程式介面、Markdown 引擎、圖表引擎與 KaTeX 字型皆可離線使用。

安裝後的 Chromium 桌面版也可將 Parchment 登錄為 `.md`、`.txt` 的開啟方式；實際可用性依作業系統與瀏覽器支援而定。

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

若升級第三方套件，重新產生已提交的離線資產並跑測試：

```bash
npm ci
npm run vendor
npm test
```

`npm run vendor` 會連帶更新 PWA 快取；若只修改 HTML、CSS、JavaScript 或圖示，可單獨執行 `npm run pwa`。它會依目前執行期資產內容產生帶雜湊版本的 `service-worker.js`。

---

## 📦 部署 Deployment

### GitHub Pages（推薦）

1. Fork 或 clone 此 repository
2. 前往 `Settings → Pages`
3. Source 設為 `main` branch、`/ (root)`
4. 儲存後稍等片刻，即可透過以下網址存取：

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
| PWA | Web App Manifest + Service Worker 預快取 |
| 部署 | GitHub Pages |

---

## 🔒 隱私聲明 Privacy

- ✅ 所有檔案讀取皆在**使用者瀏覽器本機**執行
- ✅ 不上傳任何檔案至伺服器
- ✅ 不收集任何使用者資料
- ✅ 無任何後端服務
- ✅ IndexedDB 僅儲存檔案名稱與系統 handle，不儲存任何檔案內容

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
