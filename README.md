# 🟤 Parchment

> 本機 Markdown & TXT 唯讀瀏覽器，看得到、改不了。
> A calm, read-only viewer for local Markdown & TXT files. Open files in your browser — safely.

---

## ✨ 特色 Features

- 📂 **資料夾模式** — 選擇本機資料夾，以樹狀結構瀏覽所有 `.md` / `.txt` 檔案
- 📄 **單檔模式** — 直接開啟單一檔案，立即顯示內容
- 🖱️ **拖放支援** — 拖曳檔案到頁面即可閱讀
- 🕘 **最近開啟** — 自動記錄最近 8 筆，重新整理後一鍵恢復
- 🎨 **Markdown 渲染** — 支援 GFM（標題、清單、表格、語法高亮程式碼區塊）
- 📋 **一鍵複製** — 程式碼區塊 hover 顯示複製按鈕
- 🌙 **三種主題** — 淺色 / 深色 / 跟隨系統
- 🔒 **完全唯讀** — 無任何寫入或儲存行為，從設計上消除誤修改風險
- 🏠 **本地處理** — 所有檔案在瀏覽器本機讀取，不上傳、不儲存、不同步
- 🚀 **免安裝** — 純靜態網頁，開啟即用

---

## 🚀 線上使用 Live Demo

👉 [https://bruce-yang-422.github.io/parchment](https://bruce-yang-422.github.io/parchment)

---

## 📖 使用方式 Usage

### 開啟資料夾
1. 點擊「**開啟資料夾**」按鈕
2. 選擇本機資料夾並授權瀏覽器讀取
3. 左欄顯示樹狀結構，點擊檔案即可閱讀

### 開啟單一檔案
1. 點擊「**開啟檔案**」按鈕，或將檔案**拖放**至頁面
2. 內容立即顯示於主閱讀區

### 最近開啟
- 開啟過的檔案與資料夾自動記錄於首頁
- 重新整理後點擊項目，瀏覽器會再次詢問授權，確認後立即恢復

### 支援格式
| 格式 | 顯示方式 |
|------|--------|
| `.md` | Markdown 格式化渲染（含語法高亮） |
| `.txt` | 純文字原樣顯示 |

---

## 🌐 瀏覽器支援 Browser Support

| 瀏覽器 | 單檔模式 | 資料夾模式 | 最近開啟 |
|--------|---------|----------|---------|
| Chrome 86+ | ✅ | ✅ | ✅ |
| Edge 86+ | ✅ | ✅ | ✅ |
| Firefox | ✅ | ⚠️ 降級為檔案選取 | ⚠️ 僅單檔 |
| Safari | ✅ | ⚠️ 降級為檔案選取 | ⚠️ 僅單檔 |

> 資料夾模式與最近開啟依賴 [File System Access API](https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API)，Firefox / Safari 尚未完整支援，將自動降級。

---

## 🛠️ 本地開發 Local Development

不需要任何建置工具，直接啟動本機伺服器即可：

```bash
# 方法一：Node.js
npx serve .

# 方法二：Python
python -m http.server 8080
```

開啟瀏覽器前往 `http://localhost:8080`

---

## 📦 部署 Deployment

### GitHub Pages（推薦）

1. Fork 或 clone 此 repository
2. 前往 `Settings → Pages`
3. Source 設為 `main` branch、`/ (root)`
4. 儲存後稍等片刻，即可透過以下網址存取：

```
https://<your-username>.github.io/parchment
```

---

## 🔧 技術棧 Tech Stack

| 項目 | 技術 |
|------|------|
| 核心語言 | HTML5 / CSS3 / Vanilla JavaScript（ES Module） |
| Markdown 渲染 | [marked.js](https://marked.js.org/) v12 |
| 語法高亮 | [highlight.js](https://highlightjs.org/) v11 |
| 安全過濾 | [DOMPurify](https://github.com/cure53/DOMPurify) v3 |
| 字型 | [Noto Sans TC](https://fonts.google.com/noto/specimen/Noto+Sans+TC)（Google Fonts） |
| 檔案存取 | File System Access API |
| 最近開啟 | IndexedDB |
| 部署 | GitHub Pages |

---

## 🔒 隱私聲明 Privacy

- ✅ 所有檔案讀取皆在**使用者瀏覽器本機**執行
- ✅ 不上傳任何檔案至伺服器
- ✅ 不收集任何使用者資料
- ✅ 無任何後端服務
- ✅ IndexedDB 僅儲存檔案名稱與系統 handle，不儲存任何檔案內容

---

## 📋 開發路線圖 Roadmap

- [x] 單檔模式
- [x] 資料夾樹狀瀏覽
- [x] Markdown 渲染（GFM + 語法高亮）
- [x] 主題切換（淺色 / 深色 / 系統）
- [x] 拖放支援
- [x] 最近開啟紀錄（IndexedDB）
- [x] 程式碼區塊複製按鈕
- [ ] 全文搜尋（跨檔案）
- [ ] 文章目錄（TOC）
- [ ] 閱讀位置記錄

---

## 📄 授權 License

[MIT License](LICENSE)

---

<p align="center">
  Made with ☕ · 看得到、改不了
</p>
