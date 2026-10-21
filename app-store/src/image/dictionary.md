# 字典介紹圖模板

新版採用 [dust 排版](glass/dictionary-blur-options.html)，保留原生外框與標題，模糊釋義並加入 Mac 內建字典提示。[Glass 成圖](../../image/glass-review/03-dictionary.png)與[太空灰成圖](../../image/space-gray-review/03-dictionary.png)。以下保留舊版排版供參考。

| 主題 | 模板 | 成圖 |
| --- | --- | --- |
| Glass | [HTML](glass/dictionary.html) | [PNG](../../image/glass/03-dictionary.png) |
| Space Gray | [HTML](space-gray/dictionary.html) | [PNG](../../image/space-gray/03-dictionary.png) |

兩個模板只負責排版。釋義位於引用的 [選字截圖](../../assets/screenshots/dictionary/dictionary_selected_text.jpg)和 [截圖翻譯截圖](../../assets/screenshots/dictionary/dictionary_screenshot.jpg)，作為舊構圖參考保留。

兩組畫面維持 0.44 倍率。主視窗左緣分別為 x=156、850，頂端 y=380.6；小標題位於 y=306。換入新截圖時，依新視窗外框調整裁切，保留字體、背景與兩欄關係。

執行 `node app-store/src/image/render.cjs` 比對保留成圖；加 `--write --out image/dictionary-next` 另存（目錄必須尚未存在）。介紹圖模板與遮蔽釋義的獨立卡片草稿是不同素材。
