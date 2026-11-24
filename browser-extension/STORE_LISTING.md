# Chrome Web Store 上架資料

本文件整理在 [Chrome Web Store 開發人員資訊主頁](https://chrome.google.com/webstore/devconsole) 填寫各欄位時可直接貼上的內容。名稱與簡短描述會自動取自 `src/_locales/*/messages.json`，請保持一致。

## 商店資訊（Store listing）

| 欄位 | 內容 |
| --- | --- |
| 名稱 | 由 `_locales` 提供：`Parchment – 本機 Markdown 閱讀器`／`Parchment – Local Markdown Reader` |
| 簡短描述 | 由 `_locales` 提供（上限 132 字元，建置時會檢查） |
| 類別 | 建議選擇「工具」類別（Productivity → Tools） |
| 語言 | 中文（台灣）、中文（簡體）、英文、日文、韓文、法文、德文、西班牙文（下次改版建議加入俄文） |
| 官方網址 | <https://parchment.stack-base.com/> |
| 支援網址 | <https://github.com/bruce-yang-422/parchment/issues> |

### 詳細說明（繁體中文）

```text
Parchment 是本機優先的 Markdown 與純文字閱讀器。它以唯讀方式開啟你的檔案，所有處理都在瀏覽器中完成，不需要帳號，也不會上傳任何內容。

【兩種使用方式】
• 點擊工具列圖示，在新分頁開啟完整的 Parchment：開啟單一檔案或整個筆記資料夾。
• 在瀏覽器中直接開啟本機 .md 檔時，自動以 Parchment 排版顯示（需在擴充功能詳細資料中開啟「允許存取檔案網址」）。

【閱讀】
• GitHub 風格 Markdown：表格、工作清單、註腳、程式碼高亮與一鍵複製
• KaTeX 數學公式、Mermaid 與 Graphviz 圖表
• 圖片與圖表可在燈箱中縮放，並可存成 PNG
• 記住每份文件的閱讀位置
• 手機與窄螢幕使用完整寬度閱讀，檔案樹與文件資訊以側邊抽屜開啟
• 長文章捲動兩個畫面後顯示回到頂端按鈕，短文章不占用畫面空間

【筆記】
• Wiki Links：[[筆記]]、[[筆記#標題|別名]]
• 內嵌圖片與筆記：![[圖片.png]]、![[筆記#標題]]
• Callouts 提示區塊、YAML Frontmatter 屬性、標籤篩選與雙向連結
• 資料夾全文搜尋，檔案樹可依名稱或編輯時間排序

【外觀】
• 五套配色，各含淺色與深色版本與專屬閱讀版面
• 中文與英文字型分開設定，閱讀寬度可切換為滿版

【隱私】
不收集任何資料、不含追蹤程式碼，也不連線到任何開發者伺服器。檔案只會為了顯示而在你的瀏覽器中讀取。

開放原始碼（MIT）：https://github.com/bruce-yang-422/parchment
```

### Detailed description (English)

```text
Parchment is a local-first reader for Markdown and plain-text files. It opens your files read-only and does everything inside your browser — no account, no uploads.

TWO WAYS TO USE IT
• Click the toolbar icon to open the full Parchment app in a new tab: open a single file or a whole notes folder.
• Open a local .md file in the browser and Parchment renders it automatically (turn on "Allow access to file URLs" in the extension's details page).

READING
• GitHub-flavored Markdown: tables, task lists, footnotes, syntax highlighting with one-click copy
• KaTeX math, Mermaid and Graphviz diagrams
• Zoom images and diagrams in a lightbox and save them as PNG
• Remembers your reading position in every document
• Full-width reading on phones and narrow screens, with the file tree and document information in side drawers
• A back-to-top shortcut appears after two screenfuls in long documents and stays out of the way in short ones

NOTES
• Wiki Links: [[Note]], [[Note#Heading|Alias]]
• Image and note embeds: ![[image.png]], ![[Note#Heading]]
• Callouts, YAML front matter properties, tag filtering and backlinks
• Full-text search across a folder; sort the file tree by name or modified time

APPEARANCE
• Five color palettes, each with light and dark variants and its own reading layout
• Separate CJK and Latin fonts, and a full-width reading mode

PRIVACY
No data collection, no tracking code, and no connections to any developer server. Files are read in your browser only to display them.

The interface is available in Traditional Chinese, Simplified Chinese, English, Japanese, Korean, French, German and Spanish.

Open source (MIT): https://github.com/bruce-yang-422/parchment
```

### 各語系關鍵字策略與建議文案

Chrome／Edge 外掛商店的主要讀者是開發者與看 GitHub README 的人，搜尋時常用「viewer」「offline」與圖表、公式引擎的名稱。下表的名稱與簡短描述依各地搜尋習慣調整：

- **共通**：名稱或第一句放 **Local Markdown Viewer／Offline**，簡短描述點名 **Mermaid** 與 **KaTeX**。
- **日文**：用「Markdown ビューア」，這是日本使用者最常搜尋的說法。
- **法文、德文**：隱私（Confidentialité／Datenschutz）與離線放在名稱或第一句，這兩地使用者對資料外傳特別在意。
- **俄文**：外掛介面目前沒有俄文，但商店頁可以先加俄文說明，方便俄語區開發者搜尋到。

> 名稱與簡短描述由 `src/_locales/*/messages.json` 提供，修改後需要重新打包外掛並遞增版本號，請在下次外掛改版時一起套用。俄文需新增 `src/_locales/ru/messages.json`。

| 語系 | 建議名稱（≤ 75 字元） | 建議簡短描述（≤ 132 字元） | 主打關鍵字 |
| --- | --- | --- | --- |
| en | Parchment – Local Markdown Viewer (Offline) | Offline Markdown viewer for local .md files: Mermaid diagrams, KaTeX math, Wiki Links and search. Read-only, nothing uploaded. | local markdown viewer, offline, mermaid, katex, md reader |
| zh-TW | Parchment – 本機 Markdown 檢視器（離線） | 離線開啟本機 .md：支援 Mermaid 圖表、KaTeX 數學公式、Wiki Links 與全文搜尋，唯讀顯示，檔案不上傳。 | Markdown 檢視器、md 閱讀器、離線、Mermaid、KaTeX |
| zh-CN | Parchment – 本地 Markdown 查看器（离线） | 离线查看本地 .md：支持 Mermaid 图表、KaTeX 公式、Wiki 链接与全文搜索，只读显示，文件不上传。 | Markdown 查看器、md 阅读器、离线、Mermaid、KaTeX |
| ja | Parchment – ローカル Markdown ビューア | ローカルの .md をオフラインで表示する Markdown ビューア。Mermaid 図・KaTeX 数式・Wiki リンク・全文検索に対応、外部送信なし。 | Markdown ビューア、md 閲覧、オフライン、Mermaid、KaTeX |
| ko | Parchment – 로컬 Markdown 뷰어(오프라인) | 로컬 .md 파일을 오프라인에서 읽기 전용으로 표시합니다. Mermaid 다이어그램, KaTeX 수식, Wiki 링크, 전체 검색 지원. 업로드 없음. | Markdown 뷰어, md 리더, 오프라인, Mermaid, KaTeX |
| fr | Parchment – Lecteur Markdown hors ligne et privé | Confidentialité d’abord : lisez vos .md locaux hors ligne, en lecture seule, avec Mermaid, KaTeX, Wiki Links et recherche. | lecteur markdown, hors ligne, confidentialité, mermaid, katex |
| de | Parchment – Markdown-Viewer offline, Datenschutz | Datenschutz zuerst: lokale .md-Dateien offline und schreibgeschützt lesen – mit Mermaid, KaTeX, Wiki-Links und Suche. | Markdown Viewer, offline, Datenschutz, Mermaid, KaTeX |
| es | Parchment – Visor Markdown local sin conexión | Visor de archivos .md locales sin conexión y en solo lectura: diagramas Mermaid, fórmulas KaTeX, Wiki Links y búsqueda. | visor markdown, sin conexión, lector md, mermaid, katex |
| ru | Parchment – просмотр Markdown офлайн | Офлайн-просмотр локальных .md только для чтения: диаграммы Mermaid, формулы KaTeX, вики-ссылки и поиск. Без загрузки файлов. | просмотр markdown, офлайн, md, mermaid, katex |

### 圖片素材

| 素材 | 尺寸 | 說明 |
| --- | --- | --- |
| 商店圖示 | 128 × 128 PNG | 使用 `src/icons/icon-128.png` |
| 螢幕截圖 | 1280 × 800（或 640 × 400）PNG／JPEG | 至少 1 張、最多 5 張，需由實際畫面擷取 |
| 小型宣傳圖塊 | 440 × 280 PNG／JPEG | 依資訊主頁要求提供 |
| 跑馬燈宣傳圖塊 | 1400 × 560 PNG／JPEG | 選填 |

建議的截圖內容：

1. 資料夾模式：檔案樹、筆記內容與右側目錄
2. 直接開啟本機 `.md` 檔時的排版結果
3. Wiki Links、Callouts 與屬性區塊
4. Mermaid 圖表與燈箱縮放
5. 設定對話框與不同配色的對照
6. 手機版完整寬度閱讀、側邊抽屜與回到頂端按鈕

## 隱私權做法（Privacy practices）

### 單一用途說明（Single purpose）

```text
Parchment displays local Markdown and plain-text files in a read-only, formatted reader, either in its own tab or when the user opens a local .md file in the browser.
```

### 權限說明（Permission justification）

| 權限 | 說明（可直接貼上） |
| --- | --- |
| `storage` | Saves the user's setting for whether local .md files opened in the browser should be shown in Parchment. |
| 主機權限 `file:///*` | When the user opens a local .md file in the browser and has turned on "Allow access to file URLs", Parchment reads that file to display it formatted. It also reads images and linked .md files next to it so relative links keep working. No web sites are accessed. |

### 遠端程式碼（Remote code）

選擇 **No, I am not using remote code**。所有程式碼（含 Markdown、圖表與數學公式引擎）都打包在外掛內，執行時不下載任何程式碼。

### 資料使用（Data usage）

- 不勾選任何收集的資料類型。
- 勾選三項聲明：不出售或轉讓使用者資料、不用於與單一用途無關的目的、不用於判斷信用或放貸。

### 隱私權政策網址

```text
https://parchment.stack-base.com/privacy.html
```

## 送審前檢查

- [ ] `npm test` 全部通過
- [ ] `npm run pwa` 後執行 `npm run extension`，建置檢查無錯誤
- [ ] 以「載入未封裝項目」在 Chrome 與 Edge 各測試一次（見 [README](README.md#手動測試清單)）
- [ ] `package.json` 的版本號高於商店上已發布的版本
- [ ] 上傳 `release/parchment-extension-<版本>.zip`
