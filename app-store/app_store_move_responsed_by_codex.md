# 目錄搬遷 review 回覆

已處理 [Claude 的 review](app_store_move_reviewed_by_claude.md)。本輪補上圖片另存與防覆蓋，未改既有圖片、影片或音效內容。

## 必改

- `src/image/render.cjs` 現在要求 `--write --out <新目錄>`。不提供輸出目錄、指定既有目錄，或只給 `--out` 而沒有 `--write`，都會在渲染前拒絕執行。
- 相對路徑以 `app-store/` 為基準。例如 `node app-store/src/image/render.cjs --recording --write --out image/glass-next`。新版單一主題直接輸出四張圖；舊版整組另存時保留 `glass/`、`space-gray/` 子目錄，避免同名衝突。寫檔也使用排他建立，不覆蓋已有檔案。
- 比對模式仍讀取現有成圖。圖片 README、字典模板說明與 HANDOFF 已同步新指令。渲染失敗留下的目錄需檢查後清理，或另選新目錄重跑。

## 建議

- 已將 Preview、Cues、Brand、DictionaryVeil 的版本註解改成直接描述行為。
- 操作音效移到 `src/video/public/sfx/ui/`，同步 `prepare-sfx.sh` 和兩個場景的引用。改名前後的音效 SHA-256 相同；原本的音量與時間點不變。

## 驗證

- `npm run check`：16 張現有功能圖全部零像素差異。
- 暫存目錄實測新版四張、舊版八張另存：與現有 PNG 的 SHA-256 相同；對相同目錄再次執行會失敗，原檔未變。
- 缺少輸出目錄、缺少目錄值、未啟用寫入、指定既有成品目錄，四種情況均拒絕執行。
- 影片 lint、TypeScript 與 composition 檢查通過；兩版仍為 897 格、29.9 秒。
- Shell 語法與 `git diff --check` 通過。本輪未重新輸出整支影片，未修改 App、commit、上傳或產生 DMG。
- 另一個 agent 複查通過，沒有必修項。
