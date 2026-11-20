# Parchment 手機 App

Parchment 的 Android／iOS 版本，以 Flutter 開發。畫面、文件模型、選檔流程與閱讀邏輯共用同一套 Dart 程式；平台差異集中在 `lib/platform/`、`lib/infrastructure/` 與 Flutter 生成的 `android/`、`ios/` 工程。Android 與 iOS App ID 皆為 `com.stackbase.parchment`。

## 產品定位

- **收到 `.md` 檔的一般人**：IT 或相關人員交付 `.md` 檔時，建議對方安裝本 App 閱讀，通常從 LINE「用其他應用程式開啟」進入。
- **電腦編輯、手機閱讀**：在電腦編輯筆記，將資料夾同步到手機（Syncthing、FolderSync 等），在 App 中開啟整個資料夾。

介面文字一律寫給非 IT 使用者：避免「渲染」「索引」「根目錄」「URI」等技術用語；確實需要的技術資訊（編碼、換行格式、URI、位元組數）放在「資訊」面板最下方的「進階資訊（給技術人員）」。本文件與程式註解不受此限。

## 功能

| 類別 | 內容 | 主要程式 |
| --- | --- | --- |
| 閱讀 | Markdown 與純文字閱讀、文字選取、深淺色、五套配色、字型、文字大小、行距；Windows 換行（CRLF）文件同樣支援 | `lib/ui/reader/reader_screen.dart` |
| Markdown 語法 | 與網頁版一致：YAML Frontmatter 屬性、Callouts（可收合）、註腳（點擊預覽）、縮寫、定義清單、`==螢光==`、`++插入++`、`^上標^`、`~下標~`、Emoji、KaTeX、程式碼高亮與複製、Wiki Links、內嵌、`## tags:` 屬性 | `lib/core/markdown/note_syntax.dart`、`lib/ui/reader/note_markdown.dart` |
| 圖表 | Mermaid 與 Graphviz 在隱藏的本機 WebView 中產生 SVG，以 DOMPurify 清理；點擊開啟向量燈箱，縮放不失真；可另存 4 倍解析度 PNG | `lib/infrastructure/diagram_render_service.dart`、`lib/ui/reader/diagram_view.dart`、`assets/diagram/` |
| 目錄 | 略過程式碼區塊與 Frontmatter；先依比例跳轉，再對齊實際標題 | `extractHeadings`、`_scrollToHeading` |
| 資料夾模式（Android） | 檔案樹（資料夾在前、自然排序、略過隱藏檔）；Wiki Links 跳轉到指定標題；`![[筆記#標題]]`、`![[筆記#^區塊]]` 內嵌（最多兩層）；`![[圖片.png\|寬度]]` 與相對路徑圖片；相對 `.md` 連結。路徑規則與網頁版 `noteSyntax.js` 相同，相對路徑超出資料夾時改依檔名尋找 | `lib/core/markdown/wiki_paths.dart`、`lib/core/models/note_folder.dart`、`lib/ui/reader/folder_tree.dart` |
| 最近的資料夾 | 記住最近 16 個並保留系統授權，重開 App 一點即可切換；授權失效時提示重新選擇，移除時釋放授權 | `lib/core/services/recent_folders.dart`、`lib/infrastructure/preferences_recent_folders.dart` |
| 搜尋、標籤、雙向連結 | 第一次使用時讀取所有筆記並顯示進度（單檔超過 2 MiB 略過）；全文搜尋不分大小寫、標題相符優先、顯示片段並捲到關鍵字段落；點標籤列出相同標籤的筆記；「關聯」面板列出連到本篇的筆記 | `lib/core/notes/note_index.dart`、`lib/ui/reader/notes_sheet.dart` |
| 從其他 App 開啟（Android） | 「開啟方式」與分享選單列出 Parchment，接受 `text/markdown`、`text/x-markdown`、`text/plain` 與 `application/octet-stream`；後者僅在檔名為 `.md`／`.txt` 時開啟 | `AndroidManifest.xml`、`lib/infrastructure/android_document_channel.dart` |
| TODO 勾選寫回 | 勾選視為編輯，底部顯示未儲存數量，可捨棄、存回原檔或另存新檔；離開或開啟其他文件前會詢問。只替換 `[ ]` ↔ `[x]` 字元；掃描到的項目數須與畫面一致；寫入前重新讀取原檔，已被外部修改則拒絕；含非 UTF-8 內容只能另存 | `lib/core/markdown/task_markers.dart`、`lib/infrastructure/platform_document_writer.dart` |
| 文件資訊 | 檔名、可讀位置、資料夾內路徑、大小、修改時間（Android 不提供建立時間）、能否存回；字數、字元、行數、段落、閱讀時間；標題、連結、圖片、程式碼與圖表、附註、待辦進度、標籤；進階資訊；複製檔名、位置、筆記連結與全文 | `lib/core/notes/document_stats.dart`、`lib/core/services/document_inspector.dart`、`lib/ui/reader/document_info_sheet.dart` |
| 關於 | 設定最下方：版本、最後更新、作者、授權、官方網站、隱私權政策、開放原始碼元件授權 | `lib/app/app_info.dart`、`lib/ui/reader/about_section.dart` |

介面採用接近 iOS／macOS 的低干擾設計語言：半圓膠囊操作按鈕、輕量底部 Dock、圓角面板、細分隔線與一致的按壓／滑鼠懸停回饋。所有元件沿用五套配色並支援深色模式。介面語言選擇會立即更新設定與主要導覽文字；文件內容不會被翻譯。

## 平台支援

Android 最低版本為 **Android 7.0（API 24，2016 年）**。Google Play AAB 會依裝置自動提供相符的 ARM32／ARM64 安裝內容；直接下載的三星 Galaxy A／S 系列 APK 僅封裝 ARM64。為維持 Flutter、WebView、Storage Access Framework 與離線圖表的穩定性，不支援 Android 6.0 或更舊版本。

| 功能 | Android | iOS |
| --- | --- | --- |
| 開啟單一檔案、閱讀、圖表 | ✅ | ✅（未在實機驗證） |
| TODO 勾選存回原檔 | ✅ | ❌ 選檔器以副本開啟，只能另存新檔 |
| 資料夾模式 | ✅ | ❌ 需原生 security-scoped 資料夾存取 |
| 從其他 App 開啟 | ✅ | ❌ 尚未宣告文件類型（避免宣告後無法處理） |

## 已知限制

- Android 11 起，系統不允許 App 取得整個「Download」、儲存空間根目錄與 `Android/data`；請選其中的子資料夾，或使用「Documents」。App 內「資料夾」畫面有白話提示。
- Google 雲端硬碟 App 的資料夾無法整個選入（不支援 `ACTION_OPEN_DOCUMENT_TREE`），請改用會同步到手機本機的工具。
- 單檔超過 2 MiB 不開啟（`lib/core/services/large_document_policy.dart`），大型 TXT 分頁閱讀見 [docs/large-document-strategy.md](docs/large-document-strategy.md)。
- Storage Access Framework 不提供建立時間。

## 目錄

```text
mobile-app/
├── apk/                       已封裝的 Android APK 與命名說明
├── lib/
│   ├── app/                  App 組裝與 App 資訊（app_info.dart）
│   ├── core/
│   │   ├── markdown/         語法解析、Frontmatter、Wiki 路徑、TODO 標記
│   │   ├── models/           LocalDocument、NoteFolder
│   │   ├── notes/            筆記索引、文件統計
│   │   └── services/         平台介面（選檔、寫入、資料夾、外部開啟、檔案資訊、最近資料夾）
│   ├── features/reader/      ReaderController（閱讀狀態）
│   ├── infrastructure/       Android 原生通道、選檔、寫入、圖表、圖片匯出、偏好設定
│   ├── platform/             Android／iOS 視覺微調
│   └── ui/                   閱讀畫面、各面板、主題
├── assets/
│   ├── diagram/              圖表渲染頁（renderer.html／js）與 vendor/
│   └── branding/             「關於」使用的 App 圖示
├── android/app/src/main/kotlin/…/MainActivity.kt   原生文件通道
├── test/                     單元與 widget 測試
├── tool/
│   ├── bootstrap.ps1         生成 Android／iOS 原生工程
│   ├── make_icons.py         由網站標誌產生 App 圖示來源
│   └── icons/                圖示來源
└── pubspec.yaml
```

## 原生通道

`MainActivity.kt` 註冊 `com.stackbase.parchment/documents`：

| 方法 | 用途 |
| --- | --- |
| `read`、`write` | 讀寫 SAF 文件（寫入使用 `"wt"` 截斷） |
| `stat` | 檔案大小、修改時間、document ID 與 provider（供「資訊」顯示可讀位置） |
| `listTree` | 列出資料夾樹（最多 20000 筆，略過以 `.` 開頭的項目） |
| `persistedTrees`、`releaseTree` | 查詢與釋放保留的資料夾授權 |
| `takeIncomingDocument`；原生呼叫 `incomingDocument` | 啟動時與執行中收到的外部檔案 |

## 資產同步

- `assets/diagram/vendor/` 內的 `mermaid.min.js`、`graphviz.min.js`、`dompurify.min.js` 由網站根目錄 `assets/vendor/` 複製；網站更新這些套件後需手動同步。
- App 圖示由網站標誌 `image/parchment-logo-transparent.png` 產生（需 Pillow）：

  ```bash
  python tool/make_icons.py          # 產生 tool/icons/ 與 assets/branding/app-icon.png
  dart run flutter_launcher_icons    # 寫入 android/ 與 ios/
  ```

  自適應圖示的前景依標誌最遠像素縮放，確保圓形遮罩下不被裁切；底色 `#F8F1E7`；另產生 Android 13 主題單色圖示與 iOS 不透明圖示。

## 發布前檢查

1. 同步更新 `pubspec.yaml` 的 `version`（例如 `1.1.2+2`，`+` 後的組建編號每次上架都要遞增）與 `lib/app/app_info.dart` 的 `version`、`buildNumber`、`lastUpdated`。`test/app_info_test.dart` 會檢查兩邊一致。
2. 執行 `flutter analyze` 與 `flutter test`。
3. 若網站更新了圖表套件或標誌，依「資產同步」重新產生。

## 建立原生工程

原生工程已建立。從新的 clone 開始且 `android/`、`ios/` 尚不存在時，可在 PowerShell 執行：

```powershell
cd mobile-app
.\tool\bootstrap.ps1
```

腳本會在暫存目錄執行 `flutter create --platforms=android,ios`，只把原生工程與 Flutter metadata 複製回來，不會覆寫現有 Dart 程式，接著下載套件、分析程式碼並執行測試。iOS 最終封裝需要 macOS 與 Xcode。

本機 Flutter SDK 位於 `C:\flutter`。Android Studio 若顯示 SDK 未設定，重新啟動後到 **Settings → Languages & Frameworks → Flutter**，將 Flutter SDK path 設為 `C:\flutter`。

## 開發與封裝

```bash
flutter run                      # 選擇模擬器或實機
flutter test
flutter analyze
flutter build appbundle          # Android Play Store AAB
flutter build apk                # Android 測試 APK
flutter build ipa                # iOS，需 macOS / Xcode
```

### Android Release APK

建立 Google Play AAB 與三星 Galaxy A／S 系列使用的 ARM64 Release APK：

```powershell
cd mobile-app
flutter build appbundle --release
flutter build apk --release --target-platform android-arm64
```

完成後將需要發佈的檔案放入 `apk/`：

- `parchment-v版本-google-play.aab`：Google Play Console 上架
- `parchment-v版本-samsung-arm64-v8a.apk`：三星 Galaxy A／S 系列直接安裝

不產生 x86_64 模擬器版或舊式 32 位元 APK。Release 使用 `android/keystore/` 的 Upload Key；`android/key.properties` 與 keystore 已由 Git 忽略，兩者必須另外安全備份，否則未來可能無法用同一簽章更新 App。
