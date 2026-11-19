# Parchment 瀏覽器外掛

把 Parchment 包裝成 Chrome 與 Edge 外掛（Manifest V3），並上架 Chrome Web Store。

- **工具列圖示**：在新分頁開啟完整的 Parchment，可開啟檔案、資料夾、全文搜尋等，所有功能都可離線使用。
- **本機 `.md` 檔**：在瀏覽器中直接開啟 `file:///…/筆記.md` 時，自動以 Parchment 排版顯示。

外掛內的網站程式碼在建置時從專案根目錄複製，不另外維護一份；這個資料夾只放外掛專屬的檔案。

## 運作方式

```text
點擊工具列圖示 ──► background.js ──► 新分頁開啟 app/index.html

開啟 file:///D:/notes/a.md
  └─► content/open-markdown.js（僅 *.md 等副檔名，需「允許存取檔案網址」）
        └─► 通知 background.js
              └─► 將分頁導向 app/index.html?file=file:///D:/notes/a.md
                    └─► Parchment 以 XMLHttpRequest 唯讀讀取檔案並顯示
                        （相對圖片與相對 .md 連結以同一資料夾解析）
```

| 檔案 | 用途 |
| --- | --- |
| `src/manifest.json` | Manifest V3 設定；版本號在建置時由根目錄 `package.json` 寫入 |
| `src/background.js` | 工具列按鈕、導向檢視器、首次安裝時開啟設定頁 |
| `src/content/open-markdown.js` | 偵測本機 Markdown 分頁並通知背景；從 Parchment 按「上一頁」時保留原始文字 |
| `src/options/` | 設定頁：自動開啟開關、檔案網址存取狀態 |
| `src/_locales/` | 商店名稱、描述與設定頁文字（英文、繁體中文） |
| `src/icons/` | 16、32、48、128 px 圖示（由 `icons/pwa-icon-512x512.png` 縮製） |
| `scripts/build.mjs` | 組合 `dist/`、檢查商店限制、輸出上架用 zip |
| `STORE_LISTING.md` | 商店頁文案、權限說明與隱私權做法 |
| `PRIVACY.md` | 指向網站隱私權政策頁的說明（政策全文在根目錄 `privacy.html`） |

### 權限

| 權限 | 原因 |
| --- | --- |
| `storage` | 保存「自動以 Parchment 開啟本機 Markdown 檔」設定 |
| `file:///*` | 讀取使用者在瀏覽器中開啟的本機 `.md` 檔及其相對資源 |

外掛不要求任何網站的存取權限。`file:///*` 必須由使用者在擴充功能詳細資料中自行開啟「允許存取檔案網址」才會生效；沒有開啟時，工具列圖示開啟的 Parchment 仍可完整使用。

## 建置

在專案根目錄執行：

```sh
npm run pwa        # 確保網站的 CSS 與資產為最新
npm run extension  # 建置外掛
```

輸出：

- `browser-extension/dist/`：未封裝的外掛，可直接載入瀏覽器測試
- `browser-extension/release/parchment-extension-<版本>.zip`：上傳到商店的檔案

兩者都由建置產生，已列入 `.gitignore`。建置時會檢查以下項目，任何一項不符合就會中止：

- `manifest.json` 為 Manifest V3，引用的檔案都存在
- 各語言的名稱不超過 75 字元，描述不超過 132 字元
- 擴充功能頁面沒有內嵌 `<script>`、內嵌事件屬性或遠端腳本

`npm test` 中的 `tests/extension-test.mjs` 也會檢查 manifest、權限、翻譯鍵與設定頁。

## 在本機測試

### Chrome

1. 開啟 `chrome://extensions`，開啟右上角的 **開發人員模式**。
2. 按 **載入未封裝項目**，選擇 `browser-extension/dist`。
3. 在外掛的 **詳細資料** 中開啟 **允許存取檔案網址**。

### Edge

1. 開啟 `edge://extensions`，開啟左側的 **開發人員模式**。
2. 按 **載入解壓縮**，選擇 `browser-extension/dist`。
3. 在外掛的 **詳細資料** 中開啟 **允許存取檔案 URL**。

修改原始碼後，重新執行 `npm run extension`，再在擴充功能頁按外掛的重新載入按鈕。

### 手動測試清單

- [ ] 點擊工具列圖示，新分頁開啟 Parchment，標誌與樣式正常
- [ ] 開啟檔案、開啟資料夾、全文搜尋、Wiki Links 正常
- [ ] Mermaid、Graphviz、KaTeX 正常渲染（Graphviz 需要 `wasm-unsafe-eval`）
- [ ] 切換配色、明暗模式與閱讀寬度，重新開啟後仍保留
- [ ] 開啟本機 `.md` 檔，自動以 Parchment 顯示；相對圖片與相對 `.md` 連結可用
- [ ] 在檢視器按「上一頁」，回到原始純文字，不會再次跳轉
- [ ] 在設定頁關閉自動開啟後，本機 `.md` 檔維持瀏覽器原本的顯示方式
- [ ] 未開啟「允許存取檔案網址」時，設定頁顯示提示並可開啟詳細資料頁
- [ ] 開發人員工具的主控台沒有 CSP 相關錯誤

## 上架

### Chrome Web Store

1. 註冊 [Chrome Web Store 開發人員帳戶](https://chrome.google.com/webstore/devconsole)（需支付一次性註冊費）。
2. 按 **新增項目**，上傳 `release/parchment-extension-<版本>.zip`。
3. 依 [STORE_LISTING.md](STORE_LISTING.md) 填寫商店資訊、上傳截圖與宣傳圖，並完成隱私權做法。
4. 送出審查。

Edge 使用者也可以直接從 Chrome Web Store 安裝（Edge 會提示允許其他商店的擴充功能）。

### Microsoft Edge 附加元件（選用）

同一個 zip 也可以上傳到 [Microsoft Partner Center](https://partner.microsoft.com/dashboard/microsoftedge/overview) 的 Edge 附加元件商店，商店資訊可沿用 [STORE_LISTING.md](STORE_LISTING.md)。

### 發布新版本

1. 更新根目錄 `package.json` 的 `version`（商店要求每次上傳的版本號都必須更高）。
2. 執行 `npm run pwa` 與 `npm run extension`。
3. 在資訊主頁上傳新的 zip 並送審。

## 已知限制

- 直接開啟本機 `.md` 檔時屬於單檔模式：相對連結可用，但 Wiki Links 無法依檔名在整個資料夾中尋找，也沒有自動更新。需要這些功能時，請從工具列開啟 Parchment，再開啟該資料夾。
- 「允許存取檔案網址」必須由使用者自行開啟，這是瀏覽器的安全限制。
- 介面目前只有繁體中文；商店名稱、描述與外掛設定頁提供英文與繁體中文。
- 外掛內的 Parchment 與網站版的設定、最近開啟紀錄分開保存。
- 目前只支援 Chromium 系瀏覽器；Firefox 的 Manifest V3 實作不同，尚未支援。
