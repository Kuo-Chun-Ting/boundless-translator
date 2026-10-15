# 字典功能介紹來源

只保留目前石墨灰版的兩份可編輯排版及 `dictionary_selected_text.jpg`、`dictionary_screenshot.jpg` 原始截圖。柔和模糊底色、字體與視窗位置都寫在 HTML 裡，不需要先產生舊配色版。

| 主題 | 排版 | 最終成圖 |
| --- | --- | --- |
| Glass | [HTML](glass/dictionary.html) | [PNG](../output/glass/03-dictionary-graphite.png) |
| 太空灰 | [HTML](space-gray/dictionary.html) | [PNG](../output/space-gray/03-dictionary-graphite.png) |

原始截圖在 `../assets/screenshots/dictionary/`。共用產圖入口為 [render.cjs](render.cjs)，直接輸出到 `output/glass/`／`output/space-gray/`，不另存中間圖片。

選字翻譯使用保留書本 icon、字典結果靠右的新截圖；翻譯視窗左緣對齊 Selected Text Translation 小標題。按視窗外緣裁切多餘空白，兩側字典視窗維持相同縮放比例，兩側主視窗頂端對齊。
