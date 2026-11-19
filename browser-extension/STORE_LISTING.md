# Chrome Web Store 上架資料

本文件整理在 [Chrome Web Store 開發人員資訊主頁](https://chrome.google.com/webstore/devconsole) 填寫各欄位時可直接貼上的內容。名稱與簡短描述會自動取自 `src/_locales/*/messages.json`，請保持一致。

## 商店資訊（Store listing）

| 欄位 | 內容 |
| --- | --- |
| 名稱 | 由 `_locales` 提供：`Parchment – 本機 Markdown 閱讀器`／`Parchment – Local Markdown Reader` |
| 簡短描述 | 由 `_locales` 提供（上限 132 字元，建置時會檢查） |
| 類別 | 建議選擇「工具」類別（Productivity → Tools） |
| 語言 | 中文（台灣）、英文 |
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

The app's interface is in Traditional Chinese.

Open source (MIT): https://github.com/bruce-yang-422/parchment
```

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
