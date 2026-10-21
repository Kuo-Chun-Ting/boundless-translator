# 預覽影片製作

已確認成品是 [v24-claude-shoo](../../video/boundless-translator-glass-v24-claude-shoo.mp4)，29.9 秒。目前來源輸出 [v25-claude-shoo](../../video/boundless-translator-glass-v25-claude-shoo.mp4)：只修正背景飄移時右側露出的白條，待確認。`PreviewWoo` 僅字卡音效不同。來源維護一份，成品每版另存。

## 執行

在本目錄執行，需要 Node（版本見 package.json）與 FFmpeg：

```sh
npm ci
./prepare-media.sh
npm run lint
npx remotion compositions src/index.ts
npm run render -- my-preview.mp4
```

- `prepare-media.sh` 將 `../../assets/recording/` 轉成 `public/media/` 的 30 fps 代理檔；檔案已更新則跳過。
- `npm run render -- my-preview.mp4 woo` 使用另一款音效；加 `--encode-only` 只重新編碼同名母帶。
- 成品寫到 `../../video/`，檔案已存在即拒絕覆蓋。母帶放 `out/<成品名稱>-master.mov`。
- `prepare-sfx.sh`、`prepare-card-sfx.sh` 從 `sfx-source/` 重製音效。操作音效在 `public/sfx/ui/`，字卡音效在 `public/sfx/kenney/`，配樂在 `public/audio/`。
- 單格檢查：`npx remotion still PreviewShoo /tmp/preview.png --frame=140`。

## 修改位置

以下路徑相對本目錄：

| 檔案 | 用途 |
| --- | --- |
| `src/scenes/Preview.tsx` | 段落順序、片尾標語、配樂 |
| `src/scenes/SelectedTextDemo.tsx` | 選字翻譯時間軸、鏡頭、提示與字典遮蔽 |
| `src/scenes/ScreenshotDemo.tsx` | 截圖翻譯時間軸、鏡頭、提示、hover 框、字卡音效與字典遮蔽 |
| `src/Root.tsx` | 選擇字卡音效及提前格數，註冊兩個版本 |
| `src/components/` | 對話框、字典遮罩、功能標題、品牌、背景、音樂 |
| `src/timeline/` | 片段、定格、鏡頭與閱讀時間計算 |
| `src/theme.ts` | 1920 × 1080、30 fps、色彩與動態曲線 |

改提示文字後，閱讀時間會依字數重算，仍需確認影片不超過 30 秒。更換錄影時，依新代理檔重新量測時間軸、鏡頭、游標與字典遮蔽；若解析度變更，同步調整 `theme.ts` 的 `SOURCE`。格數指 30 fps 代理檔，不是原始 MOV 的影格編號。

目錄或程式整理前後，用相同環境輸出相同格數的 PNG 比對；不要把 PNG 與有損母帶作逐像素比對。檢查聲音起點與動作時間，已有 MP4 用雜湊確認未變。

[製作需求](../../HANDOFF.md) · [音訊授權](licenses/README.md) · [素材權利紀錄](licenses/rights-review.md)
