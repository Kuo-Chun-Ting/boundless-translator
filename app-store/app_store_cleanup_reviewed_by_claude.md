# App Store 檔案整理方案 review

對象：`app_store_cleanup_responsed_by_codex.md`。

結論：刪除清單不會影響重製。但母帶改名的理由不成立，影片的整理後驗證照現在寫的做不到，這兩項要先修正再執行。

## 已核對

- 刪除的成品都不是製作輸入：
  - 圖片模板（`src/image/` 的 HTML、JS）沒有引用 `image/` 底下的成品；只有 `src/image/render.cjs` 把它們當輸出與比對目標。
  - 影片只讀 `public/` 的代理檔、品牌圖、配樂和音效，不讀任何成品 MP4。
- 刪除 `video/credit-review/`、`src/video/credit-review.tsx` 不會遺失採用的署名：`src/video/src/components/Brand.tsx` 的片尾署名跟 `one-line-claude.png` 的規格一致（21 px、`colors.sub`、不透明度 0.85、距底 34 px、同樣的文字與分隔點）。
- 刪除所有 woo 成品後，仍可以重製 woo：`Root.tsx` 的 `PreviewWoo` 和 `public/sfx/kenney/card-woo.wav` 都保留。

## 必改

1. 母帶改名沒有作用（方案第 13、32 行）。
   - `src/video/render-previews.sh:24-27` 會先檢查輸出檔；檔案已存在就直接拒絕，`--encode-only` 根本執行不到。所以只要 `video/preview.mp4` 還在，`--encode-only preview.mp4` 一定被拒絕。
   - 換一個新檔名時，腳本找的是 `out/<新檔名>-master.mov`（第 29 行），不會讀到改名後的 `preview-master.mov`。
   - `out/` 已被 `.gitignore` 排除，只是渲染暫存。建議：舊母帶全部刪除，不另外保留正式母帶，把第 13 行和第 32 行拿掉。如果真的要支援「用既有母帶重新編碼成新檔名」，要另外讓 `--encode-only` 可以指定母帶，這屬於新功能，不建議在整理時一起做。
2. 整理後的影片驗證照現在寫的做不到（方案第 40-41 行）。
   - `render-previews.sh:22` 的輸出目錄固定是 `../../video`，不能輸出到暫存位置。
   - 改用 `npx remotion render PreviewShoo <暫存路徑>/check.mov --codec=h264 --crf=10 --audio-codec=pcm-16`，或用 `npx remotion still` 抽格，跟整理前用同樣方式產生的結果比對。
3. 更新 `TODO.md` 時（方案第 33 行），只新增這次整理的紀錄，不改已勾選項目裡的舊路徑。上次搬遷時，已完成的紀錄被一起換成新路徑，變成不實的歷史（例如 `TODO.md:320`）。

## 建議

4. 固定檔名可以照用（方案第 11-12 行）。正式成品進 git，舊版從 git 歷史找回，不需要在檔名標版本。使用者確認的流程是：
   - 新版先另存成其他檔名給使用者看，不覆蓋正式檔。
   - 使用者確認後，明確請 agent 覆蓋時，才用新版取代 `video/preview.mp4` 或 `image/glass/` 的四張，然後 commit。
   - `HANDOFF.md`「工作方式與交付」裡「每個新版本另存新檔，不覆蓋舊版」要補上這個例外，`video/README.md`、`image/README.md` 寫明正式檔的位置。
5. `src/image/package.json:6` 的 `check` 目前會跑三組。整理後，舊版和 `--recording --space-gray` 的比對目標都不存在了。方案已經提到要調整，建議寫明：`check` 只比對 `image/glass/` 的四張，舊版和太空灰只保留 `--out` 另存的用法。

## 可保留

- 圖片保留模板與太空灰的製作能力，只刪成品。
- 刪除已結束的搬遷 review 檔，結論已寫進 `HANDOFF.md` 和 README。
- 刪除 `app-store/` 內的 `.DS_Store` 和整理後留下的空目錄。

## 待確認

- `HANDOFF.md:7`、`:85`、`:111` 仍寫著截圖翻譯功能圖的副標「待確認」，方案卻寫使用者已選定 Glass 四張。要先確認副標已經定案，還是之後 02 還會重製。

## 第二輪：核對整理結果

沒有問題，本 review 結束。三項必改都已處理。

- 正式四張圖 `image/0[1-4]-*.png` 的 MD5 跟 HEAD 的 `image/glass-review/` 相同；`npm run check` 四張都是 0 像素差異。
- `video/preview.mp4`：1920 × 1080、30 fps、897 格、29.9 秒、AAC 48 kHz，可完整解碼；片尾是採用的單行署名，右緣沒有白條。影片 lint 通過，`PreviewShoo`、`PreviewWoo` 都在。
- `src/video/out/` 的母帶已全部清除。
- `TODO.md` 跟 HEAD 比沒有刪改任何一行，只有新增。
- `HANDOFF.md:93` 已寫明「新版先另存，使用者明確要求後才取代正式檔」。
- 防覆蓋：`render.cjs --write --out image` 和只加 `--write` 都會拒絕執行。
- 舊路徑與舊檔名在 `app-store/` 和根目錄 README 都沒有殘留。連結檢查只剩 VS Code、General 兩套參考模板引用的 8 張圖，搬遷前就不存在，不是這次造成的。
