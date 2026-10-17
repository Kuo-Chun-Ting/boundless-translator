# 功能介紹素材

正式成圖在 [Glass](output/glass/README.md) 與 [Space Gray](output/space-gray/README.md)，各 6 張，共 12 張。重製時直接讀取 HTML 排版、原始素材及光束元件，不保留舊底圖、半成品或重複成圖。

| 內容 | Glass | 太空灰 |
| --- | --- | --- |
| 選字翻譯：VS Code | [PNG](output/glass/01-selection-1-vscode.png) | [PNG](output/space-gray/01-selection-1-vscode.png) |
| 選字翻譯：Preview | [PNG](output/glass/01-selection-2-preview.png) | [PNG](output/space-gray/01-selection-2-preview.png) |
| Can’t select it：完整光束 | [PNG](output/glass/02-screenshot-1-cant-select.png) | [PNG](output/space-gray/02-screenshot-1-cant-select.png) |
| General：完整光束 | [PNG](output/glass/02-screenshot-2-general.png) | [PNG](output/space-gray/02-screenshot-2-general.png) |
| 字典 | [PNG](output/glass/03-dictionary.png) | [PNG](output/space-gray/03-dictionary.png) |
| Settings | [PNG](output/glass/04-settings.png) | [PNG](output/space-gray/04-settings.png) |

## 目錄分類

- `assets/`：原始截圖、精靈、框線及示範文件。
- `layouts/`：HTML 排版、共用光束元件與產圖程式。
- `output/`：Glass／太空灰最終成圖與預覽索引。

## 可編輯來源

| 要修改的內容 | 位置 |
| --- | --- |
| 選字翻譯、Settings | `layouts/glass/`、`layouts/space-gray/` 中的對應 HTML |
| 截圖翻譯排版與背景 | `layouts/glass/`、`layouts/space-gray/` 中的 `screenshot-*.html` |
| 選字翻譯窄光束箭頭 | `layouts/components/selected-text-arrow.js` |
| 完整光束、字卡保護範圍 | `layouts/components/beams.js` |
| 字典排版與來源截圖 | [字典來源](layouts/dictionary.md) |
| 選字翻譯、Settings 原始截圖 | `assets/screenshots/` |
| Can’t select it／General 原始截圖 | `assets/screenshots/lettering/`、`assets/screenshots/general/` |
| 精靈與截圖框元件 | [精靈與框線](assets/components/README.md) |
| 重新截圖用的文件 | [PDF](assets/demos/boundless-selected-text-demo.pdf)、[VS Code README](assets/demos/vscode/README.md)、[文字圖](assets/demos/text-only/README.md) |

## 重製

使用 Node.js、Playwright Chromium、pngjs。在專案根目錄執行：

```sh
node docs/feature-showcase/layouts/render.cjs
node docs/feature-showcase/layouts/render.cjs --write
```

第一個指令只比對，不寫入；第二個會重製並覆蓋`output/glass/` 與 `output/space-gray/`的 12 張成圖。若套件安裝在共用 runtime，將其 `node_modules` 路徑設為 `NODE_PATH`。

正式 HTML、共用光束元件與最新素材可重製全部 12 張成圖，已驗證逐像素一致。

截圖翻譯最新版：小標題為 Take a screenshot、Hover over a word、Select a sentence，統一灰色與對應圖片的間距；下方標題離上一張圖至少 32 px、離下一張圖 12 px。Can’t select it 原圖補述為「We’ll make the text selectable.」。截圖翻譯統一使用完整光束，短光束成圖與產圖邏輯已移除。

## 正式素材與排版

截圖素材保存在 `assets/screenshots/`，HTML 直接引用這些檔案；根目錄不另留重複截圖。裁切僅移除視窗外桌面，保留真實視窗的工具列、文字與字典卡。Settings 來源為 918 × 748 JPEG，放大後清晰度受原始尺寸限制。

字典兩組使用相同 0.44 倍率；小標題與主視窗沿用確認的位置，描述標示 macOS 內建字典。詳細尺寸見 [字典排版說明](layouts/dictionary.md)。Settings 為上方標題與描述、下方置中截圖。

Settings 已從原始素材等比例縮小 10%；截圖翻譯小標題使用「Hover over a word」。正式圖均不含 Alpha 通道。截圖翻譯按展示順序命名：`02-screenshot-1-cant-select.png` 為 Can’t select it，`02-screenshot-2-general.png` 為 General。比較版本已整合回正式圖與 HTML，不另留 Update 檔案。
