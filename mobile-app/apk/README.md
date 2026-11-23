# Android 發佈封裝

此資料夾提供兩種 Android 發佈封裝：

- `parchment-v版本-google-play.aab`：Google Play Console 上架
- `parchment-v版本-android-universal.apk`：所有支援架構的 Android 手機直接安裝

Universal APK 同時包含 ARM32、ARM64 與 x86_64；最低支援 Android 7.0（API 24）。

## Google Play 上傳

在 Google Play Console 上傳 [parchment-v1.1.2-google-play.aab](parchment-v1.1.2-google-play.aab)。這份封裝的版本為 `1.1.2`（`versionCode 2`）。先前的 `versionCode 1` 已在上傳時被 Google Play 記錄，當時尚未發布。目錄內的 `v1.1.1` 封裝留作備份。

下次上傳新的 AAB 前，請提高 `pubspec.yaml` 中 `version` 的組建編號（`+` 後的數字），同步更新 `lib/app/app_info.dart` 再重新封裝。[Android 版本設定說明](https://developer.android.com/studio/publish/versioning)

## 目前版本

封裝日期：2026-11-23

| 項目 | 內容 |
| --- | --- |
| App ID | `com.stackbase.parchment` |
| 版本 | 1.1.2（versionCode 2） |
| 最低／目標 Android | API 24（7.0）／API 36（16） |
| 架構 | `arm64-v8a`、`armeabi-v7a`、`x86_64` |
| 簽署憑證 | `CN=Parchment, OU=Mobile, O=StackBase, L=Taipei, ST=Taiwan, C=TW` |
| 憑證 SHA-256 | `9e1ec1d201fa10593f768202a25cf7953fb38515014119d91ac72fe4108e247e` |

| 檔案 | 大小 | SHA-256 |
| --- | --- | --- |
| `parchment-v1.1.2-android-universal.apk` | 93.0 MiB（97,513,847 bytes） | `E7C846F90F31498697AEDF1D43573F8CB394246CC75A8DB345A4FF88EE21AACE` |
| `parchment-v1.1.2-google-play.aab` | 90.0 MiB（94,377,925 bytes） | `C146CE2F1CFAD16686E432B0E767A6EE2937EEBF71C0176631358D011FBD73CE` |

Google Play AAB 與 Universal APK 均包含文末註腳返回修正。即使長文中的對應引用還未出現在畫面上，點擊返回箭頭也能定位到該引用。

本次封裝包含：

- 閱讀：Frontmatter、Callouts、註腳（中文名稱註腳也能點開；文末返回鍵為自繪向量圖示；註腳面板固定 96% 寬）、HTML 白名單（`<kbd>`、`<details>` 等）、SVG／GIF／點陣圖片、向量圖表燈箱與高解析 PNG、表格自動排版（隨字級放大）、回到頂端按鈕；缺圖會顯示無法存取或不存在的原因。
- 程式碼：寬內容固定顯示水平捲動軸；可選擇顯示行號（預設關閉），行號與空白行、多語文字及斜體內容維持對齊。
- 配色：羊皮紙、紫晶（Obsidian）、墨白（Notion）、湖藍（Windows 11）、鋁銀（iOS）各自的版面、提示框圖示與按鈕樣式。
- 字型：內建台北黑體、jf 粉圓、芫荽、內海、源柔哥德體、LINE Seed JP、Pretendard；Google Fonts 選了才下載；清單依介面語言、附範例文字。
- 介面：8 種語言（繁中、簡中、英、日、韓、法、德、西）全部翻譯；閱讀設定會記住。
- 檔案：資料夾模式、從 LINE 等 App 開啟、TODO 勾選存回、文件資訊（SHA-256、完整路徑）、中文資料夾名稱修正。
- 穩定性：修正切換文件時畫面凍結（灰色遮罩）的問題；正式版補上網路權限；從檔案管理員「選擇開啟工具」開檔時交給同一個 Parchment，不再另開一份或卡在讀取中；選檔結果、讀檔與文件資訊改由背景工作處理，外部開檔啟動時不再同步查詢慢速文件提供者；背景資訊取得後會以正式顯示名稱或實際路徑檔名取代 MediaStore 數字 ID；文件只在內容、配色、字型、字級或寬度改變時才重新排版；修正單獨 HTML 圖片造成遞迴溢位；關閉 Flutter 深層連結，外部開檔不再觸發路由錯誤。

內建字型在 APK 中約佔 28.5 MB（壓縮後）。

## 驗證

```powershell
apksigner verify --print-certs parchment-v1.1.2-android-universal.apk
jarsigner '-J-Duser.language=en' '-J-Duser.country=US' -verify parchment-v1.1.2-google-play.aab
keytool '-J-Duser.language=en' '-J-Duser.country=US' -printcert -jarfile parchment-v1.1.2-google-play.aab
Get-FileHash parchment-v1.1.2-*.* -Algorithm SHA256
```

請勿把 Flutter 的完整 `build/` 目錄複製到這裡。Release 檔案必須使用 `android/keystore/` 的 Upload Key 簽署；金鑰與 `android/key.properties` 不可提交到 Git，且必須另外安全備份。
