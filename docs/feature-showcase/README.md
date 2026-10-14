# 功能介紹素材

最新成圖在 [Glass](output/glass/README.md) 與 [Space Gray](output/space-gray/README.md)，各 8 張。重製時直接讀取 HTML 排版、原始素材及光束元件，不保留舊底圖、半成品或重複成圖。

| 內容 | Glass | 太空灰 |
| --- | --- | --- |
| 選字翻譯：VS Code | [PNG](output/glass/01-selected-text-01-vscode-aligned.png) | [PNG](output/space-gray/01-selected-text-01-vscode-aligned.png) |
| 選字翻譯：Preview | [PNG](output/glass/01-selected-text-02-preview-aligned.png) | [PNG](output/space-gray/01-selected-text-02-preview-aligned.png) |
| Can’t select it：後半段光束 | [PNG](output/glass/02-screenshot-02-lettering-wizard-beam-gold-graphite.png) | [PNG](output/space-gray/02-screenshot-02-lettering-wizard-beam-gold-graphite.png) |
| Can’t select it：完整光束 | [PNG](output/glass/02-screenshot-02-lettering-wizard-beam-connected-graphite.png) | [PNG](output/space-gray/02-screenshot-02-lettering-wizard-beam-connected-graphite.png) |
| General：後半段光束 | [PNG](output/glass/02-screenshot-01-general-beam-gold-graphite.png) | [PNG](output/space-gray/02-screenshot-01-general-beam-gold-graphite.png) |
| General：完整光束 | [PNG](output/glass/02-screenshot-01-general-beam-connected-graphite.png) | [PNG](output/space-gray/02-screenshot-01-general-beam-connected-graphite.png) |
| 字典 | [PNG](output/glass/03-dictionary-graphite.png) | [PNG](output/space-gray/03-dictionary-graphite.png) |
| Settings：待最後確認 | [PNG](output/glass/04-settings.png) | [PNG](output/space-gray/04-settings.png) |

## 目錄分類

- `assets/`：原始截圖、精靈、框線及示範文件。
- `layouts/`：HTML 排版、共用光束元件與產圖程式。
- `output/`：Glass／太空灰最終成圖與預覽索引。

## 可編輯來源

| 要修改的內容 | 位置 |
| --- | --- |
| 選字翻譯、Settings | `layouts/glass/`、`layouts/space-gray/` 中的同名 HTML |
| 截圖翻譯排版與背景 | `layouts/glass/`、`layouts/space-gray/` 中的 `screenshot-*.html` |
| 選字翻譯窄光束箭頭 | `layouts/components/selected-text-arrow.js` |
| 完整／後半段光束、字卡保護範圍 | `layouts/components/beams.js` |
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

第一個指令只比對，不寫入；第二個會重製並覆蓋`output/glass/` 與 `output/space-gray/`的 16 張成圖。若套件安裝在共用 runtime，將其 `node_modules` 路徑設為 `NODE_PATH`。

2026-10-14 整理驗證：選字、截圖、字典共 14 張重製後逐像素一致。Settings 原有成圖與現存 HTML 重製結果有細微像素差異，尚未做到逐像素一致；本次保留成圖原檔，沒有覆蓋。

截圖翻譯最新版：小標題為 Take a screenshot、Hover a word、Select a sentence，統一灰色與對應圖片的間距；下方標題離上一張圖至少 32 px、離下一張圖 12 px。Can’t select it 原圖補述為「We’ll make the text selectable.」。完整與尾端光束兩版均已整合回正式 HTML 與成圖。
