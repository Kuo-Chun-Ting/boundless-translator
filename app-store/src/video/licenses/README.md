# 聲音來源與授權

## 配樂：Easy Lemon

| 項目 | 內容 |
| --- | --- |
| 曲名 | Easy Lemon（完整版，2:06） |
| 作者 | Kevin MacLeod |
| 來源 | <https://incompetech.com/music/royalty-free/mp3-royaltyfree/Easy%20Lemon.mp3>，曲目資料見 `easy-lemon-catalog-entry.json`（ISRC USUAN1200076） |
| 下載日 | 2026-10-19，SHA-256 `2486b8ecfe4575f9ab31613a2c03c2ee45e6e5280301d05b4dd7237c9e1c2531` |
| 授權 | Creative Commons Attribution 4.0 International（CC BY 4.0），全文 `cc-by-4.0-legalcode.txt` |
| 署名 | 影片收尾畫面已加入：Music: “Easy Lemon” by Kevin MacLeod (incompetech.com), licensed under CC BY 4.0 |

授權依據：

- Incompetech 授權頁（`incompetech-licenses-page-2026-10-19.html`）提供兩種授權。免費的 Creative Commons 授權要求標註音樂來源，網頁產生的署名文字為 `"<曲名>" Kevin MacLeod (incompetech.com) Licensed under Creative Commons: By Attribution 4.0 http://creativecommons.org/licenses/by/4.0/`。
- CC BY 4.0 第 2(a)(1) 節允許以任何目的重製、改作與散布，包括商業用途；唯一條件是第 3(a) 節的署名，須以合理方式呈現。App Store 預覽影片與網站宣傳都在這個範圍內。
- 本片把署名放在收尾畫面。若要在影片以外的平台說明欄也放署名，可沿用同一句話。

注意事項：

- Incompetech 另有付費的 Standard License，用於不想或無法署名的情況。授權頁的程式碼（`incompetech-standard-license-generator-2026-10-19.js`）列出的價格為一首 30 美元、兩首 50 美元，授權範圍包含廣告與推廣，並可在任何媒體使用。本片已附署名，所以不需要購買。
- 如果之後要移除收尾的署名，例如 App Store 審查要求影片內只能出現 App 畫面，就需要改買 Standard License，或換用其他曲目。
- 本次沒有針對 Content ID 或特定平台的音樂比對機制做查證。

## 按鍵、點擊、截圖音效（實錄，CC0）

原始檔保存在 `../sfx-source/`，由 `../prepare-sfx.sh` 剪掉開頭空白並把峰值調到 −1 dBFS。CC0 等同放棄著作權，可商用、不需署名。

| 用途 | 原始檔 | 作者與來源 | 授權 | SHA-256 |
| --- | --- | --- | --- | --- |
| 滑鼠點擊 | `pixeliota-mouse-click.wav` | Pixeliota，“Mouse Click Sound.mp3”，<https://freesound.org/s/678248/>；下載自 Remotion 轉存的 <https://remotion.media/mouse-click.wav> | Creative Commons 0 | `887a9259…6348` |
| 快捷鍵三聲 | `unicae-keypress-004.wav`、`-006.wav`、`-001.wav` | unicaegames，Keyboard Soundpack #1，Cherry KC 1000 鍵盤以 Shure SM7B 收音，<https://opengameart.org/content/keyboard-soundpack-1-typing-and-single-keystrokes> | CC0 1.0；包內說明見 `unicae-keyboard-soundpack-readme.txt`（“Free to use however you like.”） | `29e1aea1…7e`、`419bde00…7eb7`、`7b873548…8bcdaf1` |
| 截圖快門（暫代） | `ristooooo1-dslr-shutter.wav` | ristooooo1，“DSLR Shutter fast 006.wav”，<https://freesound.org/s/539136/>；下載自 Remotion 轉存的 <https://remotion.media/shutter-modern.wav> | Creative Commons 0 | `e9edb887…a1a898` |

下載日：2026-10-19。

截圖聲用上表的 CC0 相機快門聲，不使用 macOS 原生音效：macOS 授權條款沒有明文允許把系統音效檔用在商業影片。

## 截圖翻譯字卡音效（Kenney，CC0）

截圖翻譯的四張字卡出現翻譯時各響一次。原始檔在 `../sfx-source/kenney/`，授權檔是同目錄的 `interface-sounds-License.txt`、`casino-audio-License.txt`。`public/sfx/kenney/` 的 wav 由 `../prepare-card-sfx.sh` 轉成 48 kHz 雙聲道，並把峰值調到約 −13 dB。

| 用途 | 原始檔 | 來源 | 授權 | SHA-256 |
| --- | --- | --- | --- | --- |
| 字卡「woo」（v24-claude-woo） | `maximize_008.ogg` → `public/sfx/kenney/card-woo.wav` | Kenney，Interface Sounds 1.0，<https://kenney.nl/assets/interface-sounds> | CC0 1.0 | `57c074e600e193a303ce781c04c0ccc191c6030f9f106594fd94a65e55435c17` |
| 字卡「咻」（v24-claude-shoo） | `card-slide-4.ogg` → `public/sfx/kenney/card-shoo.wav` | Kenney，Casino Audio 1.1，<https://kenney.nl/assets/casino-audio> | CC0 1.0 | `b9c82bcdbe6b7d00a06e2546bd2683a9ab082ca5fd090a42882f33eddd925b7f` |

下載日：2026-10-21。授權檔原文：“You may use these assets in personal and commercial projects.”（Casino Audio）、“This content is free to use in personal, educational and commercial projects.”（Interface Sounds），署名非必要。

另見 [預覽影片素材權利查核](rights-review.md)（App Store 2.3.9、字典詞條權利）。
