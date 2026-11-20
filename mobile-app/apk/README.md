# Android 發佈封裝

此資料夾只保留目前需要發佈的兩種 Android 產物：

- `parchment-v版本-google-play.aab`：Google Play Console 上架
- `parchment-v版本-android-universal.apk`：所有支援架構的 Android 手機直接安裝

Universal APK 同時包含 ARM32、ARM64 與 x86_64；最低支援 Android 7.0（API 24）。

請勿把 Flutter 的完整 `build/` 目錄複製到這裡。Release 檔案必須使用 `android/keystore/` 的 Upload Key 簽署；金鑰與 `android/key.properties` 不可提交到 Git，且必須另外安全備份。
