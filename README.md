# Parchment

<img src="image/parchment-logo-transparent.png" alt="Parchment 標誌" width="120">

Parchment 是在瀏覽器中運作的本機 Markdown 與純文字閱讀器。使用者可以唯讀開啟 `.md` 和 `.txt` 文件，也可以選取資料夾，以樹狀目錄瀏覽筆記並開啟文件中的相對圖片與連結。

[線上使用 Parchment](https://bruce-yang-422.github.io/parchment/) · [GitHub 專案頁](https://github.com/bruce-yang-422/parchment)

## 功能

- **檔案與資料夾瀏覽**。支援選取及拖放單一檔案。資料夾模式提供預設收合的檔案樹、相對圖片及跨文件連結；檔案樹上方可依檔案名稱（A → Z／Z → A）或編輯時間（新到舊／舊到新）排序，並一鍵全部折疊或展開，排序方式會被記住。左右側欄可拖曳調整寬度。資料夾模式的左下角工作區切換器會列出瀏覽器保存的資料夾授權，可快速切換或開啟其他資料夾。
- **Markdown 閱讀**。支援表格、語法高亮、程式碼複製、註腳、表情符號、提示區塊、KaTeX 公式、Mermaid 與 Graphviz 圖表，以及 `## tags: [標籤一, 標籤二]` 的標籤屬性；在資料夾模式點擊標籤可篩選文件。右側資訊面板可切換文章目錄、標籤、連結筆記與雙向連結；「連結筆記」只顯示目前文件連到的內部筆記，不收錄外部網址。
- **筆記連結與擴充語法**。支援 `[[筆記]]`、`[[筆記#標題|別名]]` 等 Wiki Links，點擊即開啟資料夾內的筆記；`> [!note]`、`> [!tip]-` 等 Callouts（含自訂標題與收合）；YAML Frontmatter 屬性區塊，其中的 `tags` 可用於標籤篩選；`![[圖片.png|300]]` 內嵌圖片與 `![[筆記]]`、`![[筆記#標題]]` 內嵌筆記。Wiki Links 與內嵌依檔名在整個資料夾內尋找，需使用資料夾模式。
- **全文搜尋**。在資料夾模式的左側欄搜尋所有 `.md` 與 `.txt` 的檔名、路徑與內容，可用空白分隔多個關鍵字、以引號搜尋片語；按 `Ctrl+Shift+F` 聚焦搜尋框。開啟結果後會標示關鍵字並捲動到第一個符合處。
- **圖片與圖表檢視**。圖片與 Mermaid 圖表自動縮放至閱讀欄寬（較小的圖片維持原尺寸）。點擊圖片或圖表會以燈箱開啟，可用滾輪、觸控板或雙指縮放，拖曳移動，雙擊切換放大，或使用 `+`、`-`、`0` 鍵與工具列；選擇 **存成 PNG**（或按 `S`）可下載圖片，圖表以 2 倍解析度輸出。
- **閱讀寬度**。內文上方檔名列右側的「滿版／標準寬度」按鈕可在配色預設的閱讀欄寬與滿版之間切換，選擇會被記住。
- **閱讀進度與工作清單**。記住個別文件的捲動位置，並在瀏覽器中保存 Markdown 工作清單的勾選狀態。
- **配色、主題與字型**。右上角的設定提供五套配色：羊皮紙（預設）、紫晶、墨白、湖藍與鋁銀，每套皆有淺色與深色版本，並各有對應的閱讀版面（閱讀欄寬、字級、標題、連結、程式碼、引用、表格與提示區塊的樣式），可搭配跟隨系統、淺色或深色模式；中文字型及英文／數字字型可分別選擇。裝置缺少所選字型時，瀏覽器會使用可用的替代字型。
- **瀏覽器外掛**。提供 Chrome 與 Edge 外掛：點擊工具列圖示即可開啟 Parchment；在瀏覽器中直接開啟本機 `.md` 檔時，會自動以 Parchment 排版顯示。詳見 [瀏覽器外掛](#瀏覽器外掛)。
- **安裝與離線啟動**。右上角提供 **安裝 App** 按鈕（手機版只顯示圖示）；首次完成快取後即可離線啟動。右上角的工具資訊會說明版本、隱私方式及專案網站。安裝、工具資訊與設定固定在標題列，單檔模式隱藏側欄時仍可使用。

## 使用方式

1. 選擇 **開啟檔案**，或將 `.md` 或 `.txt` 檔案拖入頁面。
2. 若文件包含相對圖片或跨文件連結，選擇 **開啟資料夾**，再從左側檔案樹選取文件。
3. 使用右上角的設定按鈕調整配色、明暗模式、中文字型及英文／數字字型；標題列的主題圖示可快速循環切換明暗模式。

Markdown 以格式化版面顯示，TXT 則保留純文字與換行。閱讀內文會依序使用所選的英文／數字與中文字型；Markdown 中的行內程式碼與程式碼區塊固定使用等寬字型。

### 瀏覽器支援

| 功能 | 所需瀏覽器能力 |
| --- | --- |
| 單檔開啟 | 優先使用 `showOpenFilePicker()`，亦可使用一般檔案選擇器。 |
| 資料夾瀏覽 | 優先使用 `showDirectoryPicker()`，亦可使用支援 `webkitdirectory` 的資料夾選擇器建立檔案樹。 |
| 最近開啟、資料夾切換與自動更新 | 透過原生選擇器或作業系統取得檔案控制代碼（`FileSystemHandle`）。首頁最多顯示八筆近期紀錄，資料夾模式的左下角可列出最多十六個曾授權資料夾；重新開啟時會視需要請求讀取授權。 |
| PWA 安裝與離線使用 | 透過 HTTPS 或 `localhost` 使用。安裝介面依瀏覽器而異，離線啟動需要 Service Worker。 |

### 安裝為應用程式

支援原生安裝提示時，右上角會出現 **安裝 App** 按鈕。在 iPhone 或 iPad 上，可從瀏覽器的分享選單選擇 **加入主畫面**。支援 File Handling API 的桌面瀏覽器可將已安裝的 Parchment 設為 `.md` 或 `.txt` 的開啟方式。

## 本機開發

專案包含已編譯的網站資產，可用任何靜態 HTTP 伺服器預覽。先從 [GitHub 專案頁](https://github.com/bruce-yang-422/parchment) 取得原始碼，再進入專案目錄。以下範例使用 Python 3。

```sh
cd parchment
python -m http.server 8080
```

- [開啟本機預覽](http://localhost:8080/)

### 建置與測試

開發與建置使用 Node.js 和 npm，建議採用 Node.js 22。先執行 `npm ci` 安裝鎖定的套件版本。

| 指令 | 用途 |
| --- | --- |
| `npm test` | 檢查 JavaScript 語法，執行相對路徑、標籤、筆記連結、閱讀字型、閱讀寬度、配色與對比度、工作清單狀態、PWA、燈箱縮放、圖片匯出、筆記擴充語法、全文搜尋、檔案樹排序與瀏覽器外掛測試。 |
| `npm run css` | 將 Tailwind CSS 3.4 編譯至 `assets/css/style.css`。 |
| `npm run pwa` | 編譯樣式並產生 `service-worker.js`，依網站資產內容更新離線快取版本。 |
| `npm run vendor` | 重建本機第三方套件，再執行 `npm run pwa`。 |
| `npm run extension` | 建置瀏覽器外掛，輸出 `browser-extension/dist/` 與上架用 zip。 |

啟動本機伺服器後，可使用以下入口驗證 Markdown、筆記擴充語法、圖表引擎和工作清單：

- [開啟渲染測試頁](http://localhost:8080/tests/renderer-smoke.html)

### 專案結構

| 路徑 | 內容 |
| --- | --- |
| `index.html` | 網站入口與 Tailwind 版面類別。 |
| `src/styles/` | 主題、閱讀器及共用元件的樣式原始碼。 |
| `assets/js/` | 以原生 JavaScript 實作的檔案讀取、渲染與閱讀介面。 |
| `assets/vendor/` | 本機提供的 markdown-it、highlight.js、DOMPurify、KaTeX 和圖表引擎。 |
| `manifest.webmanifest` | PWA 安裝資訊與檔案類型宣告。 |
| `browser-extension/` | Chrome／Edge 外掛的原始碼、建置腳本與上架資料。 |
| `scripts/`、`tests/` | 產生網站資產和驗證功能的腳本。 |

架構、瀏覽器 API 與開發規劃詳見 [概念備忘錄](md-reader-concept-memo.md)。

## 瀏覽器外掛

`browser-extension/` 將 Parchment 包裝為 Chrome 與 Edge 外掛（Manifest V3），網站程式碼在建置時從專案根目錄複製。

- 點擊工具列圖示，在新分頁開啟完整的 Parchment，所有功能皆可離線使用。
- 在瀏覽器中直接開啟本機 `.md` 檔時，自動以 Parchment 顯示；需在擴充功能詳細資料中開啟「允許存取檔案網址」。
- 只要求 `storage` 與 `file:///*` 權限，不存取任何網站。

執行 `npm run pwa` 後再執行 `npm run extension` 即可建置。載入測試、上架 Chrome Web Store 與隱私權政策，請參閱 [browser-extension/README.md](browser-extension/README.md)。

## 部署至 GitHub Pages

1. 修改供瀏覽器使用的檔案後，執行 `npm run pwa`。若更新第三方套件，執行 `npm run vendor`。
2. 提交網站變更及產生的 `assets/css/style.css`、`service-worker.js`。若重建了第三方套件，同一批提交也包含 `assets/vendor/` 的變更。
3. 在儲存庫的 **Settings → Pages** 選擇 **Deploy from a branch**，以 `main` 分支的 `/ (root)` 作為發布來源。

## 隱私與資料儲存

- 文件內容在瀏覽器本機讀取與渲染，來源檔案以唯讀方式開啟。
- IndexedDB 保存最近開啟的控制代碼與其名稱、類型及時間。`localStorage` 保存閱讀位置、配色、明暗模式與中英文字型偏好、側欄寬度、安裝提醒時間，以及工作清單的任務指紋與勾選狀態。
- 「存成 PNG」在瀏覽器本機轉換並下載，不會上傳圖片。
- Service Worker 快取網站資產以供離線使用。文件若引用外部圖片等資源，瀏覽器可能向文件指定的網址送出請求。

## 授權

Parchment 採用 [MIT 授權](LICENSE)。隨附套件及授權資訊列於 [第三方套件授權](THIRD_PARTY_LICENSES.md)。
