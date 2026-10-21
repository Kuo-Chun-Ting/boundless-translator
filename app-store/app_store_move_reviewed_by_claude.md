# 目錄搬遷 review

只檢查兩件事：搬遷後成品有沒有變；之後要細修圖片和影片時，新架構能不能直接處理。

結論：成品沒有變。影片的架構可以直接細修；功能截圖的產圖程式還有一個缺口，重製時會覆蓋現有成品，需要修正。

## 1. 成品沒有變

- 影片：
  - 用原參數重新渲染完整母帶，影像串流 MD5 跟搬遷前的 `out/V24ClaudeShoo-master.mov` 相同，897 格逐位元一致。
  - `PreviewShoo`、`PreviewWoo` 的音軌 MD5，分別跟搬遷前兩支母帶的音軌相同。
  - `video/` 裡的兩支 mp4，修改時間仍是當初輸出的 12:15、12:13，大小不變，搬遷後沒有被重寫。最終版 mp4 的音軌，跟用母帶重新編碼的結果 MD5 相同。影像串流因為 x264 多執行緒編碼不保證逐位元重現，無法用重新編碼比對。
- 功能截圖：`npm run check` 16 張都是 0 個像素差異；舊版 5 張成圖的雜湊跟 HEAD 相同。

## 2. 之後能不能用新架構細修

影片可以：

- 要改的地方集中在 `src/video/src/scenes/`，共用元件在 `components/`、`timeline/`，README 有寫每個檔案負責什麼。
- 改完用 `npx remotion still` 看單格，`npm run render -- 新檔名.mp4` 輸出新版。檔名已存在時會拒絕覆蓋。

### 必改

- 功能截圖重製時會覆蓋現有成品，無法另存新版。
  - `src/image/render.cjs:17-45` 的輸出檔名都是固定的（例如 `image/glass-review/02-screenshot.png`），加 `--write` 會直接覆蓋。
  - 這跟 `HANDOFF.md`「成品每版另存新檔，不覆蓋舊版」的規則衝突，影片端已經做到這一點，圖片端還沒有。
  - 建議：讓 `render.cjs` 接收輸出目錄（例如 `--out image/glass-review-2/`），目錄已存在時拒絕寫入，作法跟影片的 `render-previews.sh` 一致。

### 建議

- 程式註解還在引用已不存在的版本資料夾，細修時會找不到對應的東西：
  - `src/video/src/scenes/Preview.tsx:19,22`：v22、v23-claude
  - `src/video/src/components/Cues.tsx:7`：v8
  - `src/video/src/components/Brand.tsx:11`：v8
  - `src/video/src/components/DictionaryVeil.tsx:13`：v11
  - 改成直接描述行為，不寫版本號。
- `src/video/public/sfx/v3/` 仍以版本命名，跟這次依用途命名的原則不一致。可以改成 `public/sfx/ui/`，同時修改 `prepare-sfx.sh` 和兩個場景的 `staticFile()`。

## 第二輪：核對 Codex 的修正

三項都已解決，沒有新問題，本 review 結束。

- 圖片另存：
  - 只加 `--write`、只加 `--out`、`--out` 沒給值、指定既有的 `image/glass-review`，四種情況都在渲染前拒絕執行。
  - 新版 Glass 四張輸出到新目錄，MD5 跟 `image/glass-review/` 的現有成圖相同；對同一個目錄再跑一次會拒絕執行。
- 版本註解：`src/video/src/` 裡已沒有引用舊版本資料夾的註解。
- 操作音效改到 `public/sfx/ui/`：兩個場景和 `prepare-sfx.sh` 都已同步；lint 通過；重新渲染的 `PreviewShoo` 音軌 MD5 跟搬遷前的母帶相同。
