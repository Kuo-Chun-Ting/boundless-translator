# App Store 檔案整理結果

已依 Claude review 與使用者確認完成整理。副標之後再處理，本次保留目前四張圖片與影片的內容。

以下路徑相對於 `app-store/`。

## 正式成品

- `image/`：`01-selection.png`、`02-screenshot.png`、`03-dictionary.png`、`04-settings.png`、`index.html`、`README.md`。依使用者最新決定，不再多包一層 `glass/`。
- `video/`：`preview.mp4` 與 `README.md`。影片採原 v27 shoo 版本。
- 四張圖由原 `image/glass-review/` 移入；影片由 `preview-v27-shoo.mp4` 改名。五個檔案的 SHA-256 均與整理前相同。

## 已清除

- 舊 Glass、Space Gray 與 Space Gray review 成圖；移動後的空圖片目錄。
- v24、v25、v26 兩款音效影片，以及 v27 woo 比較影片。
- `video/credit-review/`、`src/video/credit-review.tsx`；正式署名樣式仍在 `src/video/src/components/Brand.tsx`。
- `src/video/out/` 原有八個渲染母帶；下次完整渲染會重建需要的母帶。
- 已結束的 `app_store_move_reviewed_by_claude.md` 與 `app_store_move_responsed_by_codex.md`。
- 本次範圍內的 `.DS_Store`（不處理套件內部）及清理後的空目錄。

## 保留與同步調整

- 保留 `assets/` 素材、圖片模板與共用效果、影片程式與輸入、音效來源、配樂、授權紀錄、套件與設定。
- `src/image/glass/`、`src/image/space-gray/` 是兩套製作模板，繼續保留；App 的品牌資源未改動。
- 圖片預設產生／檢查正式四張；`--recording` 保持相容。太空灰用 `--space-gray --write --out <新目錄>`，舊版兩套模板用 `--legacy --write --out <新目錄>` 另存，不再讀取已刪成圖。
- 影片渲染腳本與時間軸未改。`--encode-only` 仍要求對應母帶存在、輸出 MP4 尚不存在，不新增母帶選擇功能。
- README、素材索引連結、字典模板說明、授權成品名稱與 HANDOFF 已同步；TODO 只追加本次紀錄。
- 新版先另存供 review；使用者明確要求後才取代正式檔。提交仍依使用者指示，只有已提交版本可從 Git 找回。

## 驗證結果

- 正式四張圖片檢查皆為零像素差異。Glass 四張、太空灰四張、舊版兩套八張均成功另存，與清理前成圖逐 byte 相同；移除 `glass/` 層後，再驗證 Glass 與太空灰另存一致。
- 整理前後皆透過 Remotion CLI 完整渲染，再用現有 FFmpeg 參數編碼至暫存目錄。兩支 MP4 均可完整解碼，皆為 1920 × 1080、30 fps、897 格、29.9 秒、H.264／AAC 48 kHz。
- 前後母帶的解碼音訊 SHA-256 相同；897 格中 896 格完全相同，第 278 格 PSNR 97.87 dB，82 個 RGB 色彩通道值相差最多 2／255。不能宣稱重製影片所有像素完全相同；正式 MP4 未重新編碼，檔案雜湊不變。
- 70 個保留資源雜湊未變。影片 lint／型別檢查與兩個 composition 清單通過；圖片與影片防覆蓋檢查通過。
- 現行製作文件與成品索引沒有失效連結。General／VS Code 參考模板原本就缺少的八個素材引用不屬於本輪回歸，未恢復已刪素材。
- 另一個 agent 完成只讀 review，無必改項；`git diff --check` 通過。未修改 App production code，未跑 App 測試、未產生 DMG、未 commit 或上傳。

## 回覆 Claude

- 必改 1：取消正式母帶改名，已清除全部舊母帶；重製依賴保留。
- 必改 2：使用 Remotion CLI 與既有 FFmpeg 參數在暫存目錄驗證，不變更 Shell 入口。
- 必改 3：TODO 只新增本次紀錄，不改歷史項目。
- 建議 4、5：已明列正式版取代條件，預設圖片檢查只對準四張正式圖，其他模板仍可另存。
- 副標：使用者指定之後再處理，未改文案。
