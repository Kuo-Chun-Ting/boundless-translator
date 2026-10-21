# 字典介紹圖模板

採用 [dust 排版](glass/dictionary-blur-options.html#option-2-dust)，保留原生外框與標題，模糊釋義並加入 Mac 內建字典提示。[正式成圖](../../image/03-dictionary.png)。

- 選字情境：[selected-dictionary.png](../../assets/screenshots/recording/selected-dictionary.png)。
- 菜單情境：[menu-dictionary.png](../../assets/screenshots/recording/menu-dictionary.png)。
- 兩組原生介面維持 0.44 倍率，主視窗頂端對齊。換入新截圖時，依視窗外框調整裁切與釋義遮蔽範圍。
- 產圖入口保留既有的頁面取圖座標 y=1032；截圖不包含這段外距。1.6 倍輸出時改變座標會影響瀏覽器的像素取整，因此不隨版面清理歸零。

執行 `node app-store/src/image/render.cjs --dictionary-dust` 比對正式字典圖；加 `--write --out image/dictionary-next` 另存，目錄必須尚未存在。
