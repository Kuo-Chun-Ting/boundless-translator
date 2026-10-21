# 字典介紹圖模板

新版採用 [dust 排版](glass/dictionary-blur-options.html)，保留原生外框與標題，模糊釋義並加入 Mac 內建字典提示。[正式 Glass 成圖](../../image/03-dictionary.png)。太空灰可由製作入口另存。以下保留舊版排版供參考。

| 舊版主題 | 模板 |
| --- | --- |
| Glass | [HTML](glass/dictionary.html) |
| Space Gray | [HTML](space-gray/dictionary.html) |

兩個模板只負責排版。釋義位於引用的 [選字截圖](../../assets/screenshots/dictionary/dictionary_selected_text.jpg)和 [截圖翻譯截圖](../../assets/screenshots/dictionary/dictionary_screenshot.jpg)，作為舊構圖參考保留。

兩組畫面維持 0.44 倍率。主視窗左緣分別為 x=156、850，頂端 y=380.6；小標題位於 y=306。換入新截圖時，依新視窗外框調整裁切，保留字體、背景與兩欄關係。

執行 `node app-store/src/image/render.cjs --dictionary-dust` 比對正式字典圖；加 `--write --out image/dictionary-next` 另存（目錄必須尚未存在）。舊版參考圖可用 `--legacy --write --out image/legacy-next` 重製。介紹圖模板與遮蔽釋義的獨立卡片草稿是不同素材。
