# Parchment Android v1.1.5－GitHub 發行文件 / GitHub Release

| GitHub 欄位 / Field | 填寫內容 / Value |
| --- | --- |
| Tag | `android-v1.1.5` |
| Target | 包含 `1.1.5+5` 的建置提交 / Build commit containing `1.1.5+5` |
| Release title | `Parchment Android v1.1.5` |
| Release label | `Latest` |
| Binary | `parchment-android-1.1.5.apk` |

GitHub 用的通用 APK 與同目錄的 `parchment-v1.1.5-android-universal.apk` 內容相同，並與 Google Play AAB 使用相同的版本代碼。請在版本變更提交後，將標籤指向對應的建置提交。

The GitHub APK is byte-for-byte identical to `parchment-v1.1.5-android-universal.apk` and shares the Google Play AAB's version code. Tag the corresponding build commit once the version changes are committed.

## 發行說明 / Release notes

整段複製到 GitHub Release 說明欄。Copy the block into the GitHub release description.

````markdown
### v1.1.5 更新

- **公式**：支援 LaTeX 的行內與區塊分隔符。超出閱讀寬度的區塊公式會顯示水平捲軸。
- **圖表**：Mermaid 與 Graphviz 會依閱讀主題調整預設色彩。深色圓餅圖降低色塊亮度、提高標籤對比，放大按鈕也移到圖表下方。
- **圖片與燈箱**：修正網路圖片下載後仍停在載入中的問題。失敗時可重試，燈箱可查看縮放倍率、一鍵符合螢幕，並儲存為 PNG。
- **圖表匯出**：向量圖表可選 S、M、L 三種 PNG 尺寸，對應長邊 1024、2048、4096 px，保留原圖比例。
- **閱讀排版**：改善中英混排的螢光底色，修正表格標記跨列，並統一註腳返回箭頭方向。

### 安裝

下載下方的 `parchment-android-1.1.5.apk` 並在手機上開啟。適用於 Android 7.0（API 24）以上，支援 ARM64、ARM32 與 x86_64。版本為 1.1.5，版本代碼為 5。

> 若已從 Google Play 安裝，請從原安裝來源取得更新。切換安裝來源可能需要先解除安裝，並會清除 App 內的閱讀設定。

---

### What's new in v1.1.5

- **Math**: Supports LaTeX inline and display delimiters. Display formulas wider than the reading area now show a horizontal scrollbar.
- **Diagrams**: Default Mermaid and Graphviz colors follow the reading theme. Dark-mode pie charts use darker fills and higher-contrast labels, and the zoom control sits below the preview.
- **Images and lightbox**: Fixed web images getting stuck after download, and added retry for failed requests. The image lightbox shows the current zoom level and offers fit-to-screen and PNG saving.
- **Diagram export**: Save vector diagrams as PNG in S, M, or L, with a long edge of 1024, 2048, or 4096 px. The original aspect ratio is preserved.
- **Reading layout**: Improved highlighting for mixed Chinese and Latin text, fixed highlights overlapping adjacent table rows, and aligned the footnote return arrow with the web reader.

### Installation

Download `parchment-android-1.1.5.apk` below and open it on your phone. Requires Android 7.0 (API 24) or later and supports ARM64, ARM32, and x86_64. Version 1.1.5, version code 5.

> If you installed from Google Play, update through the same source. Switching installation sources may require uninstalling the app, which clears its reading settings.
````
