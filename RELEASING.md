# GitHub Releases 發布規範

Parchment 在同一個儲存庫裡維護多個產品，每個產品各自發版、各自編號。這份文件規定 GitHub Releases 的標籤、標題、安裝檔與發行說明怎麼寫，讓使用者一眼就能找到自己要的版本。

## 1. 產品對照表

| 項目 | Browser Extension | Android App | iOS App（預留） |
| --- | --- | --- | --- |
| 產品名稱 | Parchment Browser Extension | Parchment Android | Parchment iOS |
| 標籤前綴 | `extension-v` | `android-v` | `ios-v` |
| 版本來源 | 根目錄 `package.json` 的 `version` | `mobile-app/pubspec.yaml` 的 `version`（`+` 前的部分） | `mobile-app/pubspec.yaml` 的 `version`（`+` 前的部分） |
| GitHub 安裝檔 | ZIP | APK | 不附安裝檔（見 [5.3](#53-ios-app)） |
| 安裝檔命名 | `parchment-extension-<版本>.zip` | `parchment-android-<版本>.apk` | — |
| 主要通路 | Chrome Web Store（上架後） | Google Play | App Store / TestFlight |

目前版本：

| 產品 | 版本 | Git 標籤 | Release 標題 | 安裝檔 |
| --- | --- | --- | --- | --- |
| Browser Extension | 1.1.1 | `extension-v1.1.1` | Parchment Browser Extension v1.1.1 | `parchment-extension-1.1.1.zip` |
| Android | 1.1.4 | `android-v1.1.4` | Parchment Android v1.1.4 | `parchment-android-1.1.4.apk` |

新增產品時，在上表加一欄，並依同樣格式決定前綴與安裝檔名稱。

## 2. 版本號

採用「科學化情感版本號」（Scientific Pride Versioning）：三段式 `主版號.次版號.修訂號`，數字依技術規則判定，Pride／Default／Shame 只是對應層級的別名。完整規則見 `D:\Projects\版本號命名規則.md`，以下是 Parchment 適用的重點。

| 層級 | 別名 | 什麼時候升 | 版本變化 | Parchment 例子 |
| --- | --- | --- | --- | --- |
| Major | Pride | 不相容的變更：移除既有功能、設定或資料格式改變導致舊的無法沿用、主要操作流程重新設計 | `1.7.9 → 2.0.0` | 改變待辦勾選存回檔案的寫法，舊筆記需要轉換 |
| Minor | Default | 新增使用者看得到的功能，舊的用法不受影響 | `1.4.8 → 1.5.0` | 新增配色、新增支援的 Markdown 語法、連結可以直接開啟 |
| Patch | Shame | 只修正既有功能：錯誤、閃退、排版、錯字、效能小幅改善 | `1.4.8 → 1.4.9` | 修正圖片不顯示、捲動跳動 |

判定方式：

1. 依序找出這次的不相容變更、新功能、修正。
2. 取**最高層級**：Major > Minor > Patch。同時有新功能和修正，就是 Minor。
3. 算出新版本號，再附上別名。不可以先決定「這版值得驕傲」再反推數字。
4. 修改的檔案多寡不決定層級。大量內部重構但行為不變，仍是 Patch，甚至不必升版。

發行文件的欄位表要寫上判定結果，例如 `Patch / Shame`。

其他規則：

- 各產品的版本號**彼此獨立**。Android 到 1.1.4，不代表外掛也要跟著跳到 1.1.4。
- Android 與 iOS 共用同一份 `pubspec.yaml`。同一個 commit 同時發兩個平台時，版本號相同，但仍要分開建立兩個 Release。
- Android 的 `versionCode`（`pubspec.yaml` 裡 `+` 後面的數字）不出現在標籤裡，但要寫進發行說明。每次上傳 Google Play 都必須遞增，已上傳過的號碼不可重複使用。
- 已經公開的版本號不可重複使用。發布後才發現問題，就遞增修訂號重新發布，不要改動舊的 Release。

## 3. Git 標籤

格式：`<前綴><版本>`

```text
extension-v1.1.1
android-v1.1.4
ios-v1.2.0
android-v1.2.0-beta.1      ← 測試版
```

規則：

1. 標籤一律使用**附註標籤**（annotated tag），訊息使用 Release 標題。
2. 標籤指向**實際建置出安裝檔的那個 commit**，而且這個 commit 已經推送到 `main`。
3. 標籤推送後不可移動或刪除後重建。打錯就作廢該版本號，用下一個修訂號重新發布。
4. 不要使用不帶前綴的 `v1.2.3` 標籤，否則無法分辨屬於哪個產品。

```bash
git tag -a android-v1.1.4 -m "Parchment Android v1.1.4"
git push origin android-v1.1.4
```

> 本機目前有 `v1.1.0`、`v1.1.1` 兩個舊格式標籤，沒有推送到 GitHub。外掛 1.1.1 正式發布時改用 `extension-v1.1.1`。舊標籤保持不推送即可，也可以用 `git tag -d v1.1.0 v1.1.1` 刪除。

## 4. Release 欄位

| GitHub 欄位 | 填寫規則 | 範例 |
| --- | --- | --- |
| Tag | 依第 3 節建立 | `android-v1.1.4` |
| Target | `main`（標籤已存在時自動對應該 commit） | `main` |
| Release title | `<產品名稱> v<版本>` | `Parchment Android v1.1.4` |
| 版本類型 | 依第 2 節判定，只寫在發行文件草稿，不必貼到 GitHub | `Patch / Shame` |
| Description | 依第 6 節範本，繁體中文在前、英文在後 | — |
| Assets | 安裝檔 | `parchment-android-1.1.4.apk` |
| Set as a pre-release | 標籤含 `-beta`、`-rc` 等後綴時勾選 | — |
| Set as the latest release | 見下方說明 | — |

### 「Latest」標記

GitHub 一個儲存庫只能有一個「Latest」，多產品時無法代表每個產品各自的最新版。因此：

- 正式版發布時勾選 **Set as the latest release**，讓它代表「整個專案最近一次正式發布」。
- 測試版（pre-release）不可設為 Latest。
- README、網站、商店頁面等**一律連結到指定標籤**的下載網址，不要使用 `/releases/latest`，否則可能把外掛使用者帶到 Android 的頁面：

```text
https://github.com/bruce-yang-422/parchment/releases/download/<標籤>/<安裝檔名>
https://github.com/bruce-yang-422/parchment/releases/tag/<標籤>
```

- 要列出某個產品的所有版本，可使用篩選連結，例如：`https://github.com/bruce-yang-422/parchment/releases?q=android-v&expanded=true`

## 5. 各平台的安裝檔

GitHub 會自動為每個上傳的安裝檔顯示 SHA-256 檢查碼，不需要另外附檢查碼檔，發行說明也不用寫「驗證檔案」段落。

### 5.1 Browser Extension

- 建置：在根目錄執行 `npm run extension`，輸出 `browser-extension/release/parchment-extension-<版本>.zip`。
- 上傳前確認 ZIP 內的 `manifest.json` 版本與標籤一致。
- 這個 ZIP 是手動安裝用的套件。發行說明要提醒使用者需要開啟開發人員模式；Chrome Web Store 上架後，要把商店連結放在發行說明最前面。

### 5.2 Android App

- 只附**通用 APK**（universal APK），並重新命名為 `parchment-android-<版本>.apk`。本機打包時的檔名（例如 `parchment-v1.1.4-android-universal.apk`）不直接上傳。
- **不附 AAB**。AAB 只能上傳到 Google Play，使用者無法直接安裝。
- APK 必須是 release 版並且已簽署，上傳前自行確認：

  ```bash
  apksigner verify --print-certs parchment-android-1.1.4.apk
  ```

- **簽署差異要寫進發行說明**：Google Play 使用 Play 應用程式簽署金鑰重新簽署，GitHub 上的 APK 使用上傳金鑰簽署，兩者簽章不同。從 Play 安裝的 App 不能直接用 GitHub 的 APK 覆蓋更新，反過來也一樣；要換安裝來源，必須先解除安裝（手機上的閱讀設定會被清除，文件檔案本身不受影響）。
- GitHub 上的 APK 與同版本的 Google Play 版本，必須來自同一個 commit，`versionCode` 也要相同。

### 5.3 iOS App

- iOS 一般使用者無法安裝 GitHub 上的 `.ipa`，所以 **iOS Release 不附安裝檔**，只放 App Store 或 TestFlight 連結，以及 GitHub 自動產生的原始碼壓縮檔。
- 標題、標籤與發行說明格式和其他平台相同，例如 `ios-v1.2.0`、`Parchment iOS v1.2.0`。
- 發行說明要寫上 App Store 審核通過的建置版本號（Build），方便對照。

## 6. 發行說明範本

延續既有格式：繁體中文在前，英文在後，中間用 `---` 分隔。用一般使用者看得懂的話描述變更，不要直接貼 commit 訊息或技術名詞。

某個產品在 GitHub 的**首發**，發行說明用「主要功能」介紹 App，不寫「變更內容」，也不提和先前版本的差異。之後的版本才用下方範本列出變更。

在發行文件草稿裡，整段發行說明要用 ` ````markdown ` 程式碼區塊包起來，方便一次複製貼到 GitHub 的說明欄。用四個反引號，是為了內容裡有程式碼區塊時不會提早結束。

```markdown
Parchment Android v1.1.4 修正網路圖片無法顯示、往上捲動時畫面跳動等問題，並在開啟外部連結前先詢問。

### 變更內容

- 修正：……
- 改善：……
- 新增：……

### 安裝方式

- **建議**：從 [Google Play](<商店連結>) 安裝，之後會自動更新。
- **手動安裝**：下載下方的 `parchment-android-1.1.4.apk`，在手機上開啟並允許安裝。

> 從 Google Play 安裝的版本不能直接用這個 APK 更新，反過來也一樣。要換安裝來源，請先解除安裝。

### 版本資訊

| 項目 | 內容 |
| --- | --- |
| 版本 | 1.1.4（versionCode 4） |
| 系統需求 | Android 〈最低版本〉以上 |

---

Parchment Android v1.1.4 fixes web images that did not load and the page jumping while scrolling up, and asks before opening external links.

### Changes

- Fixed: …
- Improved: …
- Added: …

### Installation

- **Recommended**: install from [Google Play](<store link>) to receive automatic updates.
- **Manual**: download `parchment-android-1.1.4.apk` below, open it on your phone, and allow the installation.

> The Google Play build cannot be updated with this APK, and vice versa. Uninstall first to switch sources.

### Version details

| Item | Value |
| --- | --- |
| Version | 1.1.4 (versionCode 4) |
| Requirements | Android 〈minimum〉 or later |
```

外掛的「版本資訊」改為列出相容的瀏覽器（Chrome / Edge 110 以上等）；iOS 則列出最低 iOS 版本與 App Store 建置版本號。

發行說明的草稿放在各產品的打包資料夾，檔名為 `GITHUB_RELEASE_<標籤>.md`，例如 `mobile-app/apk/GITHUB_RELEASE_android-v1.1.4.md`。`browser-extension/release/` 整個資料夾不進 Git；`mobile-app/apk/` 只排除安裝檔，`.md` 會進 Git。正式內容以 GitHub Release 頁面為準。

## 7. 發布檢查清單

發布前：

- [ ] 版本號已更新（`package.json` 或 `pubspec.yaml`、App 內的版本資訊、README）。
- [ ] 測試全部通過，並在實機或模擬器上試過主要功能。
- [ ] 變更已提交並推送到 `main`。
- [ ] 安裝檔從該 commit 建置，檔名符合第 1 節的規則。
- [ ] Android：已用 `apksigner` 確認是 release 簽署；`versionCode` 與 Google Play 上傳的版本相同。

發布：

- [ ] 建立並推送附註標籤（第 3 節）。
- [ ] 在 GitHub 建立 Release：選擇標籤、填標題、貼上發行說明、上傳安裝檔。
- [ ] 測試版勾選 pre-release；正式版勾選 Latest。

發布後：

- [ ] 從 Release 頁面重新下載安裝檔，確認 GitHub 顯示的 SHA-256 與本機檔案相同，且可以正常安裝。
- [ ] 更新 README 與網站上的下載連結（指向指定標籤，不要用 `/latest`）。
- [ ] 外掛：README 的「目前版本」連結改成新標籤。
