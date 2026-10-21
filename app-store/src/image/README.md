# 功能介紹圖與影片模板

模板保留排版與動畫；替換畫面素材不需要刪掉模板。新製作依 [交接文件](../../HANDOFF.md)。

| 製作內容 | 沿用來源 | 要替換的部分 |
| --- | --- | --- |
| Preview 選字介紹圖 | [共用排版](glass/recording.html#selection) | 新操作截圖 |
| 菜單截圖介紹圖 | [共用排版](glass/recording.html#screenshot)、[光束元件](components/beams.js) | 原圖、截圖視窗、譯文及光束座標 |
| 字典介紹圖 | [模板與尺寸](dictionary.md) | 新錄影中的原始字典畫面 |
| Settings 介紹圖 | [Glass](glass/04-settings.html)、[Space Gray](space-gray/04-settings.html) | 沿用目前畫面 |
| 原創菜單素材 | [菜單排版](original-kit/menu.html)、[產圖程式](original-kit/render.cjs) | 依需求調整網頁文案 |
| 預覽影片 | [影片場景](../video/src/scenes/Preview.tsx)，元件說明見 [影片來源](../video/README.md) | 錄影片段、時間軸、提示文字與位置 |

另保留 VS Code 選字與 General 截圖的兩套 HTML，供比較構圖；其舊圖片已刪，未列入目前產圖清單。新版不增加這兩個場景，也不恢復 General 的原圖與成圖。

## 新錄影版

[Glass 排版](glass/recording.html)使用新錄影擷取的畫面，產出[四張正式圖](../../image/index.html)，Settings 沿用。舊版模板保留，舊成圖已清除。

### Glass 設計原則

沿用原有構圖：冷色玻璃背景承托操作畫面，金色箭頭、框選與光束引導視線。精靈使用既有圖檔。

品牌、標題與說明維持原有字體、位置和層級。文字只說明功能，不新增裝飾性標籤。

選字頁將原文與結果放在同一組 Preview 畫面；截圖頁維持左側原圖、右側上下兩張結果。仔細校準裁切、邊距與光束落點，保留完整譯文。

字典頁沿用左右兩個情境，原生介面使用相同縮放比例、主視窗頂端對齊；保留真實卡片位置與外框，釋義依交接文件遮蔽。完成後逐張核對文字、邊緣與效果，避免框線或光束遮住結果。

執行 `node app-store/src/image/render.cjs` 可逐像素比對現有成圖。另存新版的指令見下方。來源時間點見[擷取紀錄](../../assets/screenshots/recording/README.md)。

## 目前採用版本

正式採用選字、截圖、字典與設定四張 [Glass 圖片](../../image/index.html)。太空灰保留製作能力，不保存比較成品。

字典採用 Claude 的金色光塵（dust）樣式，提示為「See definitions in your Mac’s built-in dictionary.」。來源是 `glass/dictionary-blur-options.html` 的 `#option-2-dust`，成圖為 `03-dictionary.png`。原始截圖與既有模板保留；其他字典比較成圖已刪除。

```sh
node app-store/src/image/render.cjs --write --out image/next
node app-store/src/image/render.cjs --space-gray --write --out image/space-gray-next
```

只重製字典時，加上 `--dictionary-dust`。太空灰沿用既有主題，與 Glass 共用新版構圖。

## 截圖構圖

正式 `02-screenshot.png` 採用 1:1：原圖面積與右側兩張結果的總顯示面積相等。結果均寬 450 px，原圖約寬 681 px。沿用 Glass 完整視窗與配色，右側上下對齊；精靈疊在原圖右下角，可覆蓋價格，但避開框選內容。光束落在兩張翻譯字卡左緣。不加主題參數時重製 Glass；加 `--space-gray` 可另存太空灰版。

## 安裝與檢查

在本目錄執行 `npm ci`，首次使用執行 `npx playwright install chromium`。`npm run check` 只比對正式 Glass 四張，不覆寫成品。

另存成品必須同時提供 `--write --out <新目錄>`。相對路徑以 `app-store/` 為基準，也可指定絕對路徑。目錄已存在即拒絕寫入；不提供 `--out` 也不會覆蓋舊圖。新版單一主題直接輸出四張 PNG；加 `--legacy` 可重製舊版兩種主題，分別放在新目錄下的 `glass/`、`space-gray/`，避免同名。`--legacy` 與 `--space-gray` 只支援另存，不比對已刪成品。原 `--recording` 仍可使用，效果與預設相同。若渲染失敗留下不完整目錄，檢查後清理或另選新目錄重跑。原創菜單用 `node original-kit/render.cjs` 重製，會更新 `../../assets/original-kit/` 的菜單圖片與預覽。
