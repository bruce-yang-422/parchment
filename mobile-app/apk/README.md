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
| `parchment-v1.1.1-android-universal.apk` | 63.2 MB | `C2392CD6A45B6AD357600F916D241ED3FA6C03AD30D6A0A353EDC17CD00572A9` |
| `parchment-v1.1.1-google-play.aab` | 60.3 MB | `AE2F565FC8721BE61C2D25EBCED32E5B1BA51837EC27AEFF610EB96250D7F2FC` |

本次封裝包含：Frontmatter／Callouts／註腳等語法修正、向量圖表燈箱與高解析 PNG 另存、TODO 勾選存回、資料夾模式（檔案樹、搜尋、標籤、雙向連結、最近資料夾）、Android 單檔文字類型過濾、從 LINE 等 App「開啟方式」進入、文件資訊面板、可搜尋與收合的開源授權頁、App 隱私政策入口、新版 App 圖示、精簡歡迎畫面與表格自動排版。

> [!IMPORTANT]
> 同一個 versionCode 不能重複上傳到 Google Play。若 1.1.1（versionCode 1）已經上傳過，請先把 `pubspec.yaml` 改為 `1.1.2+2`（並同步 `lib/app/app_info.dart`）再重新封裝。

## 驗證

```powershell
apksigner verify --print-certs parchment-v1.1.1-android-universal.apk
Get-FileHash parchment-v1.1.1-*.* -Algorithm SHA256
```

請勿把 Flutter 的完整 `build/` 目錄複製到這裡。Release 檔案必須使用 `android/keystore/` 的 Upload Key 簽署；金鑰與 `android/key.properties` 不可提交到 Git，且必須另外安全備份。
