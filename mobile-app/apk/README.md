# Android 發佈封裝

此資料夾只保留目前需要發佈的兩種 Android 產物：

- `parchment-v版本-google-play.aab`：Google Play Console 上架
- `parchment-v版本-android-universal.apk`：所有支援架構的 Android 手機直接安裝

Universal APK 同時包含 ARM32、ARM64 與 x86_64；最低支援 Android 7.0（API 24）。

## 目前版本

封裝日期：2026-11-21

| 項目 | 內容 |
| --- | --- |
| App ID | `com.stackbase.parchment` |
| 版本 | 1.1.1（versionCode 1） |
| 最低／目標 Android | API 24（7.0）／API 36（16） |
| 架構 | `arm64-v8a`、`armeabi-v7a`、`x86_64` |
| 簽署憑證 | `CN=Parchment, OU=Mobile, O=StackBase, L=Taipei, ST=Taiwan, C=TW` |
| 憑證 SHA-256 | `9e1ec1d201fa10593f768202a25cf7953fb38515014119d91ac72fe4108e247e` |

| 檔案 | 大小 | SHA-256 |
| --- | --- | --- |
| `parchment-v1.1.1-android-universal.apk` | 93.0 MB | `29C3ED7D9135595A7C12AECE43FB360CC734F779CC8F709744F04D16AD8EC799` |
| `parchment-v1.1.1-google-play.aab` | 89.9 MB | `A276106293FAE308277F9B599421A7DF9F95DCE36498D98059C5CE38EEA713FB` |

本次封裝包含：

- 閱讀：Frontmatter、Callouts、註腳（中文名稱註腳也能點開；文末返回鍵為自繪向量圖示；註腳面板固定 96% 寬）、HTML 白名單（`<kbd>`、`<details>` 等）、向量圖表燈箱與高解析 PNG、表格自動排版（隨字級放大）、回到頂端按鈕。
- 配色：羊皮紙、紫晶（Obsidian）、墨白（Notion）、湖藍（Windows 11）、鋁銀（iOS）各自的版面、提示框圖示與按鈕樣式。
- 字型：內建台北黑體、jf 粉圓、芫荽、內海、源柔哥德體、LINE Seed JP、Pretendard；Google Fonts 選了才下載；清單依介面語言、附範例文字。
- 介面：8 種語言（繁中、簡中、英、日、韓、法、德、西）全部翻譯；閱讀設定會記住。
- 檔案：資料夾模式、從 LINE 等 App 開啟、TODO 勾選存回、文件資訊（SHA-256、完整路徑）、中文資料夾名稱修正。
- 穩定性：修正切換文件時畫面凍結（灰色遮罩）的問題；正式版補上網路權限。

內建字型在 APK 中約佔 28.5 MB（壓縮後），所以檔案比 1.1.1 初版大。

> [!IMPORTANT]
> 同一個 versionCode 不能重複上傳到 Google Play。若 1.1.1（versionCode 1）已經上傳過，請先把 `pubspec.yaml` 改為 `1.1.2+2`（並同步 `lib/app/app_info.dart`）再重新封裝。

## 驗證

```powershell
apksigner verify --print-certs parchment-v1.1.1-android-universal.apk
Get-FileHash parchment-v1.1.1-*.* -Algorithm SHA256
```

請勿把 Flutter 的完整 `build/` 目錄複製到這裡。Release 檔案必須使用 `android/keystore/` 的 Upload Key 簽署；金鑰與 `android/key.properties` 不可提交到 Git，且必須另外安全備份。
