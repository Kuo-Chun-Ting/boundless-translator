# 上線用系統與語言支援資料

供 App Store、官網、Support 與功能介紹引用。整理日期：2026-10-11。

## 支援範圍

| 項目 | 對外說明 |
|---|---|
| macOS | 需要 macOS 15 或更新版本，目前包含 macOS 15、26、27。macOS 14 或更早版本不支援。 |
| 晶片 | 需要 Apple M 系列晶片（M1 或更新）。Intel Mac 不支援。 |
| 介面語言 | 提供 34 組介面語言，含地區版本共 48 個語系。同一版 App 在各支援的 macOS 上提供相同清單。 |
| 翻譯語言 | 使用 Apple 翻譯功能，支援語言由使用者的 Mac 提供，App 會自動讀取。可在 Settings 的來源與目標語言選單查看。 |
| 截圖翻譯 | 使用 Apple 的圖片文字辨識與翻譯功能，支援語言由使用者的 Mac 提供，App 會自動查詢。圖片中的原文須同時支援辨識與翻譯；目標語言沿用翻譯語言清單。來源語言不支援圖片辨識時，截圖視窗會顯示提示。 |

翻譯與 OCR 不宣稱固定語言數量，也不列每個 macOS 版本的語言表。支援範圍可能隨系統更新改變。首次翻譯可能需要下載語言資源，部分語言需要啟用 Apple Intelligence 並完成模型下載。

## 介面語言清單

提供以下 34 組介面語言，含地區版本共 48 個語系：

阿拉伯文、加泰隆尼亞文、簡體中文、繁體中文、克羅埃西亞文、捷克文、丹麥文、荷蘭文、英文、芬蘭文、法文、德文、希臘文、希伯來文、印地文、匈牙利文、印尼文、義大利文、日文、韓文、馬來文、挪威文、波蘭文、葡萄牙文、羅馬尼亞文、俄文、斯洛伐克文、斯洛維尼亞文、西班牙文、瑞典文、泰文、土耳其文、烏克蘭文、越南文。

## macOS 27 圖片文字辨識問題

可對外使用的說明：

> 其他 App 開發者也回報 macOS 27 上圖片文字辨識停住或找不到文字的情況。Boundless 使用 Apple 的圖片文字辨識功能，目前尚未找到 Apple 官方確認這項故障的文件。

| 可靠來源 | 記錄內容 |
|---|---|
| [TRex 官方更新紀錄](https://github.com/amebalabs/TRex/blob/main/CHANGELOG.md)，2026-09-27，v2.0.1-beta.2「Fixes」 | macOS 27 上 OCR 失敗或停住；改用新版 Apple Vision API，並增加失敗時的替代處理。 |
| [MindClip 官方更新說明](https://www.mindclip.pro/)，2026-09-29，v3.13.3「Extract Text, back up to speed」 | macOS 27 上辨識接近一分鐘，或圖片有文字卻回報沒有文字；改用 Live Text。 |

這些是開發者第一手回報，能佐證相似問題，尚不足以證明 Boundless 每次辨識失敗的原因。不要寫成「Apple 已確認此 bug」。

### Vision 新舊介面（內部參考）

Apple Vision 是 Apple 提供的影像分析功能。我們將截圖交給它，取得文字及位置，再由 App 處理選字與翻譯。

目前使用較早的 [`VNRecognizeTextRequest`](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)。新版介面叫 [`RecognizeTextRequest`](https://developer.apple.com/documentation/vision/recognizetextrequest)，同樣屬於 Vision。

TRex 同時更換介面並加入其他處理，不能據此認定只換新版就能解決問題。新版可留待評估，尚未證明能改善 Boundless 的偶發故障，不列為上線前必改項目。比較時需確認辨識與選字功能沒有退步；若新舊版都未重現故障，不能宣稱問題已修好。

## 資料依據與發布時需同步的內容

- 系統與晶片：專案設定為 `MACOSX_DEPLOYMENT_TARGET = 15.0`、`ARCHS = arm64`。Apple 的 [macOS 15 更新說明](https://developer.apple.com/documentation/macos-release-notes/macos-15-release-notes)記載 App 使用的 Translation 功能。
- 介面：`Sources/BoundlessTranslator/Resources/` 內的 48 個語系，由 `InterfaceLanguageCatalog` 讀取。
- 翻譯：Apple [LanguageAvailability](https://developer.apple.com/documentation/translation/languageavailability)提供當下支援的語言，也能查詢指定來源與目標的支援、安裝狀態。
- OCR：Apple [VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)提供辨識語言清單。App 使用 accurate 模式、自動偵測語言與語言校正。
- 實測紀錄見 [語言支援資料](language-support.md)，不作為所有 Mac 的固定支援清單。
- 本文尚未套用至對外頁面。同步時移除 README「介面語言與 macOS 相同」與三語 Support「印地文不支援截圖辨識」的固定宣稱；後者已不符合 macOS 27.0.1 的實測結果。
