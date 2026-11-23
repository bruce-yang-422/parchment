# Parchment Android v1.1.4－GitHub 發行文件 / GitHub Release

## 發布欄位 / Release fields

| GitHub 欄位 / Field | 填寫內容 / Value |
| --- | --- |
| Tag | `android-v1.1.4`（建立新標籤 / Create a new tag） |
| Target | `main` |
| Release title | `Parchment Android v1.1.4` |
| Release label | `Latest` |
| 版本類型 / Version type | GitHub 首發，版本號沿用 Google Play 測試版 / First GitHub release; version number continues from the Google Play test builds |
| Binary | [`parchment-android-1.1.4.apk`](https://github.com/bruce-yang-422/parchment/releases/download/android-v1.1.4/parchment-android-1.1.4.apk) |

上傳的 APK 是 `parchment-v1.1.4-android-universal.apk` 改名後的檔案，內容相同。檔案已在這個資料夾準備好，命名規則見 [RELEASING.md](../../RELEASING.md)。

The uploaded APK is `parchment-v1.1.4-android-universal.apk` renamed; the content is identical. The file is ready in this folder.

## 發行說明 / Release notes

這是 Android 在 GitHub 的首發，說明只介紹功能，不寫與先前版本的差異。整段複製，貼到 GitHub Release 的說明欄。

This is the first Android release on GitHub, so the notes introduce the app rather than list changes. Copy the whole block into the GitHub release description.

````markdown
Parchment Android 是一款 Markdown 筆記閱讀器，可以在手機上離線閱讀 `.md` 筆記。文件只在手機上開啟，不會上傳到任何地方。

### 主要功能

- **開啟檔案**：開啟單一 `.md`、`.txt` 檔或整個筆記資料夾，也可以從 LINE、檔案管理員等 App 直接開啟。
- **完整的 Markdown 排版**：標題目錄、表格、程式碼、引用、提示框（Callouts）、註腳、數學公式、Mermaid 與 Graphviz 圖表、定義清單與縮寫說明。
- **圖片**：支援資料夾內的圖片與網路圖片，點一下可以放大檢視；圖片找不到時會說明原因。
- **筆記連結**：支援 `[[筆記]]` 雙括號連結與文件內的段落跳轉；網址與 E-mail 連結會先顯示完整網址，確認後才開啟。
- **待辦清單**：可以直接勾選，並存回原本的檔案。
- **閱讀設定**：五種配色，內建多款中日韓字型，也可以下載 Google Fonts；字級與版面寬度都能調整，設定會自動記住。
- **多國語言**：介面支援繁中、簡中、英、日、韓、法、德、西 8 種語言。
- **隱私**：不需要帳號，不蒐集任何資料；只有在顯示網路圖片或下載字型時才會連網。

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

Parchment Android is a Markdown notes reader for reading `.md` notes offline on your phone. Documents are opened only on your phone and are never uploaded.

### Features

- **Open files**: open a single `.md` or `.txt` file or a whole notes folder, including files shared from LINE or a file manager.
- **Full Markdown layout**: outline, tables, code, quotes, callouts, footnotes, math, Mermaid and Graphviz diagrams, definition lists and abbreviations.
- **Images**: images from the notes folder and from the web; tap to zoom, and a clear message when an image cannot be found.
- **Note links**: `[[note]]` wiki links and in-document links; web and e-mail links show the full address and open only after you confirm.
- **Task lists**: tick tasks directly and save them back to the original file.
- **Reading settings**: five color themes, bundled CJK fonts plus optional Google Fonts, adjustable text size and page width, all remembered.
- **Languages**: interface in Traditional Chinese, Simplified Chinese, English, Japanese, Korean, French, German and Spanish.
- **Privacy**: no account and no data collection; the app goes online only to show web images or download fonts.

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
