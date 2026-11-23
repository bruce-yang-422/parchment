# Parchment Android v1.1.4－GitHub 發行文件 / GitHub Release

## 發布欄位 / Release fields

| GitHub 欄位 / Field | 填寫內容 / Value |
| --- | --- |
| Tag | `android-v1.1.4`（建立新標籤 / Create a new tag） |
| Target | `main` |
| Release title | `Parchment Android v1.1.4` |
| Release label | `Latest` |
| 版本類型 / Version type | `Patch / Shame`（自 1.1.3 起以修正為主 / mostly fixes since 1.1.3） |
| Binary | [`parchment-android-1.1.4.apk`](https://github.com/bruce-yang-422/parchment/releases/download/android-v1.1.4/parchment-android-1.1.4.apk) |

上傳的 APK 是 `parchment-v1.1.4-android-universal.apk` 改名後的檔案，內容相同。檔案已在這個資料夾準備好，命名規則見 [RELEASING.md](../../RELEASING.md)。

The uploaded APK is `parchment-v1.1.4-android-universal.apk` renamed; the content is identical. The file is ready in this folder.

## 發行說明 / Release notes

整段複製，貼到 GitHub Release 的說明欄。

Copy the whole block into the GitHub release description.

````markdown
Parchment Android v1.1.4 是第一個在 GitHub 發布的 Android 版本，可以在手機上離線閱讀 Markdown 筆記，文件不會上傳到任何地方。這個版本修正往上捲動時畫面來回跳動的問題，文件內的跳轉連結與底線式標題的目錄也都能正常使用；點選網址或 E-mail 連結時，會先顯示完整網址，確認後再開啟。

### 變更內容

- 修正往上捲動經過圖表或網路圖片時，畫面會來回跳動、要等一陣子才能繼續捲動的問題。
- 修正部分網路圖片無法顯示的問題，維基百科等圖庫的圖片也能正常載入。
- 文件內的跳轉連結（例如「回到表格段落」）不需要開啟整個筆記資料夾也能使用。
- 目錄會列出以 `===`、`---` 底線標示的標題，也能點選跳轉。
- 點選網址或 E-mail 連結時，先顯示完整網址，可以選擇「開啟」、「複製網址」或「取消」。
- 長文章中，按下文末註腳的返回箭頭，就能回到對應的引用位置。

### 主要功能

- 開啟單一 `.md`、`.txt` 檔，或整個筆記資料夾；可以從 LINE、檔案管理員等 App 直接開啟。
- 支援提示框（Callouts）、註腳、數學公式、Mermaid／Graphviz 圖表、表格、程式碼、待辦清單勾選存回等語法。
- 五種配色、多款內建中日韓字型，可調整字級與版面寬度。
- 介面支援繁中、簡中、英、日、韓、法、德、西 8 種語言。

### 安裝方式

1. 在手機上[下載 `parchment-android-1.1.4.apk`](https://github.com/bruce-yang-422/parchment/releases/download/android-v1.1.4/parchment-android-1.1.4.apk)。
2. 開啟下載的檔案；如果出現提示，請允許瀏覽器或檔案管理員「安裝不明應用程式」。
3. 依畫面指示完成安裝。

> 已經從 Google Play 安裝 Parchment 的使用者，不能直接用這個 APK 更新，反過來也一樣。要換安裝來源，請先解除安裝；手機上的閱讀設定會被清除，筆記檔案本身不受影響。

### 相容性

- Android 7.0（API 24）或更新版本
- 支援 ARM64、ARM32 與 x86_64 裝置
- 版本 1.1.4（versionCode 4）

---

Parchment Android v1.1.4 is the first Android release on GitHub. It lets you read Markdown notes offline on your phone; documents are never uploaded. This release fixes the page jumping back and forth while scrolling up, makes in-document links and the outline of underlined headings work, and shows the full address before opening a web or e-mail link.

### Changes

- Fixed the page jumping back and forth, and briefly getting stuck, while scrolling up past diagrams or web images.
- Fixed some web images that did not load, including images from Wikipedia and similar media libraries.
- In-document links (for example "back to the Tables section") now work without opening a whole notes folder.
- The outline now lists headings underlined with `===` or `---`, and tapping them jumps to the heading.
- Tapping a web or e-mail link first shows the full address, with **Open**, **Copy address** and **Cancel**.
- The back arrow on an endnote now returns to its reference, even in long documents.

### Highlights

- Open a single `.md` or `.txt` file, or a whole notes folder, including files shared from LINE or a file manager.
- Callouts, footnotes, math, Mermaid and Graphviz diagrams, tables, code, and task lists whose checkboxes are saved back to the file.
- Five color themes, bundled CJK fonts, and adjustable text size and page width.
- Interface in 8 languages: Traditional Chinese, Simplified Chinese, English, Japanese, Korean, French, German and Spanish.

### Installation

1. [Download `parchment-android-1.1.4.apk`](https://github.com/bruce-yang-422/parchment/releases/download/android-v1.1.4/parchment-android-1.1.4.apk) on your phone.
2. Open the downloaded file. If prompted, allow your browser or file manager to install unknown apps.
3. Follow the on-screen steps to finish installing.

> If you installed Parchment from Google Play, you cannot update it with this APK, and vice versa. Uninstall first to switch sources; your reading settings on the phone are cleared, but your note files are not affected.

### Compatibility

- Android 7.0 (API 24) or later
- ARM64, ARM32 and x86_64 devices
- Version 1.1.4 (versionCode 4)
````
