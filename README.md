# Parchment

<img src="image/parchment-logo-transparent.png" alt="Parchment 標誌" width="120">

Parchment 是在瀏覽器中運作的本機 Markdown 與純文字閱讀器。使用者可以唯讀開啟 `.md` 和 `.txt` 文件，也可以選取資料夾，以樹狀目錄瀏覽筆記並開啟文件中的相對圖片與連結。

[線上使用 Parchment](https://bruce-yang-422.github.io/parchment/)

## 功能

- **檔案與資料夾瀏覽**。支援選取及拖放單一檔案。資料夾模式提供預設收合的檔案樹、相對圖片及跨文件連結，左右側欄可拖曳調整寬度。
- **Markdown 閱讀**。支援表格、語法高亮、程式碼複製、文章目錄、註腳、表情符號、提示區塊、KaTeX 公式、Mermaid 與 Graphviz 圖表，以及 `## tags: [標籤一, 標籤二]` 的 Obsidian 風格標籤屬性；在資料夾模式點擊標籤可篩選文件。
- **閱讀進度與工作清單**。記住個別文件的捲動位置，並在瀏覽器中保存 Markdown 工作清單的勾選狀態。
- **主題與字型**。以圖示切換跟隨系統、淺色與深色。閱讀字型可選「預設字型」、「微軟正黑體」、「新細明體」和「標楷體」。裝置缺少所選字型時，瀏覽器會使用可用的替代字型。
- **安裝與離線啟動**。在支援的瀏覽器上安裝為 PWA，首次完成快取後即可離線啟動。

## 使用方式

1. 選擇 **開啟檔案**，或將 `.md` 或 `.txt` 檔案拖入頁面。
2. 若文件包含相對圖片或跨文件連結，選擇 **開啟資料夾**，再從左側檔案樹選取文件。
3. 使用標題列的字型選單和主題按鈕調整閱讀外觀。

Markdown 以格式化版面顯示，TXT 則保留純文字與換行。「預設字型」會以系統無襯線字型呈現 Markdown，並以等寬字型呈現 TXT。Markdown 中的程式碼維持等寬字型。

### 瀏覽器支援

| 功能 | 所需瀏覽器能力 |
| --- | --- |
| 單檔開啟 | 優先使用 `showOpenFilePicker()`，亦可使用一般檔案選擇器。 |
| 資料夾瀏覽 | 優先使用 `showDirectoryPicker()`，亦可使用支援 `webkitdirectory` 的資料夾選擇器建立檔案樹。 |
| 最近開啟與自動更新 | 透過原生選擇器或作業系統取得檔案控制代碼（`FileSystemHandle`）。網站最多顯示八筆近期紀錄，重新開啟時會視需要請求讀取授權。 |
| PWA 安裝與離線使用 | 透過 HTTPS 或 `localhost` 使用。安裝介面依瀏覽器而異，離線啟動需要 Service Worker。 |

### 安裝為應用程式

支援原生安裝提示時，可點選標題列的 **安裝 App**。在 iPhone 或 iPad 上，可從瀏覽器的分享選單選擇 **加入主畫面**。支援 File Handling API 的桌面瀏覽器可將已安裝的 Parchment 設為 `.md` 或 `.txt` 的開啟方式。

## 本機開發

專案包含已編譯的網站資產，可用任何靜態 HTTP 伺服器預覽。以下範例使用 Git 和 Python 3。

```sh
git clone https://github.com/bruce-yang-422/parchment.git
cd parchment
python -m http.server 8080
```

在瀏覽器開啟 [本機預覽](http://localhost:8080/)。

### 建置與測試

開發與建置使用 Node.js 和 npm，建議採用 Node.js 22。先執行 `npm ci` 安裝鎖定的套件版本。

| 指令 | 用途 |
| --- | --- |
| `npm test` | 檢查 JavaScript 語法，執行相對路徑、工作清單狀態與 PWA 測試。 |
| `npm run css` | 將 Tailwind CSS 3.4 編譯至 `assets/css/style.css`。 |
| `npm run pwa` | 編譯樣式並產生 `service-worker.js`，依網站資產內容更新離線快取版本。 |
| `npm run vendor` | 重建本機第三方套件，再執行 `npm run pwa`。 |

啟動本機伺服器後，可另外開啟 [渲染測試頁](http://localhost:8080/tests/renderer-smoke.html)，在瀏覽器內驗證 Markdown、圖表引擎和工作清單。

### 專案結構

| 路徑 | 內容 |
| --- | --- |
| `index.html` | 網站入口與 Tailwind 版面類別。 |
| `src/styles/` | 主題、閱讀器及共用元件的樣式原始碼。 |
| `assets/js/` | 以原生 JavaScript 實作的檔案讀取、渲染與閱讀介面。 |
| `assets/vendor/` | 本機提供的 markdown-it、highlight.js、DOMPurify、KaTeX 和圖表引擎。 |
| `manifest.webmanifest` | PWA 安裝資訊與檔案類型宣告。 |
| `scripts/`、`tests/` | 產生網站資產和驗證功能的腳本。 |

架構、瀏覽器 API 與開發規劃詳見 [概念備忘錄](md-reader-concept-memo.md)。

## 部署至 GitHub Pages

1. 修改供瀏覽器使用的檔案後，執行 `npm run pwa`。若更新第三方套件，執行 `npm run vendor`。
2. 提交網站變更及產生的 `assets/css/style.css`、`service-worker.js`。若重建了第三方套件，同一批提交也包含 `assets/vendor/` 的變更。
3. 在儲存庫的 **Settings → Pages** 選擇 **Deploy from a branch**，以 `main` 分支的 `/ (root)` 作為發布來源。

## 隱私與資料儲存

- 文件內容在瀏覽器本機讀取與渲染，來源檔案以唯讀方式開啟。
- IndexedDB 保存最近開啟的控制代碼與其名稱、類型及時間。`localStorage` 保存閱讀位置、偏好、安裝提醒時間與工作清單的任務指紋及勾選狀態。
- Service Worker 快取網站資產以供離線使用。文件若引用外部圖片等資源，瀏覽器可能向文件指定的網址送出請求。

## 授權

Parchment 採用 [MIT 授權](LICENSE)。隨附套件及授權資訊列於 [第三方套件授權](THIRD_PARTY_LICENSES.md)。
