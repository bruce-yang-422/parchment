# Android 發佈封裝

此資料夾只保留目前需要發佈的兩種 Android 產物：

- `parchment-v版本-google-play.aab`：Google Play Console 上架
- `parchment-v版本-samsung-arm64-v8a.apk`：三星 Galaxy A／S 系列手機直接安裝

不封裝 x86_64 模擬器版或舊式 32 位元 APK。

請勿把 Flutter 的完整 `build/` 目錄複製到這裡。Release 檔案必須使用 `android/keystore/` 的 Upload Key 簽署；金鑰與 `android/key.properties` 不可提交到 Git，且必須另外安全備份。
