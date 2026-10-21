# 目前保留的素材

| 素材 | 入口 | 狀態 |
| --- | --- | --- |
| Preview PDF | [PDF](boundless-selected-text-demo.pdf) · [實拍](../screenshots/selected-text-preview.jpg) | 新版選字翻譯使用 |
| あかり食堂菜單 | [網頁](screenshot-menu.html) · [預覽](screenshot-menu-preview.png) · [菜單圖片](menu.png) | Claude 原創 SVG 插畫菜單；英文提示放在影片金色字卡，網頁不加標題 |
| 字典後製草稿 | [獨立卡片](dictionary-card.png) · [來源](dictionary-source-notes.md) | 僅作參考；成品使用金色光塵遮蔽釋義 |

素材目錄：`/Users/lillard/side-project/boundless-translator/app-store/assets/original-kit/`。

可編輯來源在 `../../src/image/original-kit/`。圖片來源見 [manifest.json](manifest.json)，整組可看 [預覽頁](index.html)。

聊天、籃球、TextEdit 範例、自編字典與舊字典合成圖已清除。新版依 [製作需求](../../HANDOFF.md)；兩支操作錄影在 `../recording/`。

使用已安裝 Playwright 的 Node 執行 `node app-store/src/image/original-kit/render.cjs` 可重製菜單與網頁預覽（字典只留 PNG 草稿），不操作桌面瀏覽器。

舊生成餐點照片 `images/curry-photo.png` 已不使用，僅保留來源紀錄。
