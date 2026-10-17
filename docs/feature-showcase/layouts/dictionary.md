# 字典功能介紹來源

只保留目前石墨灰版的兩份可編輯排版及 `dictionary_selected_text.jpg`、`dictionary_screenshot.jpg` 原始截圖。柔和模糊底色、字體與視窗位置都寫在 HTML 裡，不需要先產生舊配色版。

| 主題 | 排版 | 最終成圖 |
| --- | --- | --- |
| Glass | [HTML](glass/dictionary.html) | [PNG](../output/glass/03-dictionary.png) |
| 太空灰 | [HTML](space-gray/dictionary.html) | [PNG](../output/space-gray/03-dictionary.png) |

原始截圖在 `../assets/screenshots/dictionary/`。共用產圖入口為 [render.cjs](render.cjs)，直接輸出到 `output/glass/`／`output/space-gray/`，不另存中間圖片。

選字翻譯使用保留書本 icon、字典結果靠右的新截圖；翻譯視窗左緣對齊 Selected Text Translation 小標題。按視窗外緣裁切多餘空白，兩側字典視窗維持相同縮放比例，兩側主視窗頂端對齊。

## 正式排版

右側使用使用者縮小 General 內容後重截的 `assets/screenshots/dictionary/dictionary_screenshot.jpg`（1270 × 1402）。直接由兩份正式 HTML 排版，只沿主視窗與字典卡外緣去除白色背景；不裁切、拼接或移動視窗內內容。

兩側使用相同 0.44 縮放。主視窗寬度約 494／496 CSS px，兩張字典卡寬約 344。較高的右側整組底端約 y=949，距畫布底部約 51。

兩側小標題與主視窗恢復原版對齊位置：左側 x=156、右側 x=850，小標題 y=306、主視窗頂端 y=380.6。兩組之間約 200 CSS px，標題至視窗間距均為 30.6。右側主視窗仍比左側高，保留實際畫面比例，不拉伸或重組。

描述使用「Look up words with the built-in macOS dictionary.」，交代原生字典介面的來源；選字翻譯頁不增加翻譯 API 品牌敘述。

成圖、排版與原始截圖均為目前確認版。共用產圖入口直接重製正式 PNG，不需要比較版套用程式。

### 本版設計原則：雙景並置

依 Canvas Design 的構圖與留白原則，兩個情境共用主視窗頂端與標題間距，讓字典結果成為比較重點。以描述、小標題、主視窗的左緣建立閱讀順序，再依兩組實際尺寸安排中間與外側留白。

依 Theme Factory 的一致性原則，延續 Glass／Space Gray 配色、石墨灰小標題與既有字體，不新增主題或裝飾。

依 Algorithmic Art 的參數與可重現原則，以相同縮放倍率與明確遮罩座標控制比例，保留既有漸層及模糊底色；這次不新增粒子或生成圖案。

檢查範圍涵蓋整組主視窗與字典卡、外緣、標題間距及兩欄比例；不能因兩張字典卡等大，就認定整體構圖已經平衡。
