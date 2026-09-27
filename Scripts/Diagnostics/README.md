# Apple 翻譯取消效能診斷

需要 macOS 26 以上、Xcode，以及已下載的來源與目標翻譯語言。這個腳本只使用 Apple Translation framework，不啟動或連結 Boundless Translator。

在專案目錄執行：

```sh
Scripts/diagnose_apple_translation.sh
```

腳本先執行 baseline，再用另一個程序執行 cancel：

- baseline：先翻短句暖機，再測同一短句的耗時。
- cancel：先翻同一短句暖機，送出十萬個英文單字，約 2.7 秒後呼叫取消，立即用另一個 TranslationSession 翻短句。短句返回後繼續等大段呼叫返回，最多等到整組六分鐘逾時。

預設短句是 `THE CITY THAT LEARNS`，語言是英文 → 繁體中文。測試期間不要使用其他翻譯功能。重開測試程序不代表 Apple 背景服務也已重設；單次差異不足以證明原因，應重複比較。

每次執行都會印出 log 位置：`Build/TranslationDiagnostics/run-日期時間.隨機字串/`。`build.log` 記錄編譯；`baseline.log` 和 `cancel.log` 記錄事件時間、文字位元組數、回傳耗時、錯誤類型。原文和譯文不寫入 log。`cancel_call_returned` 只表示取消函式返回，不代表內部工作已停止。逾時或按 Control-C 會結束測試程序，也不能據此認定 Apple 背景工作已停止。

可單獨執行或比較取消方式：

```sh
Scripts/diagnose_apple_translation.sh baseline
Scripts/diagnose_apple_translation.sh cancel
Scripts/diagnose_apple_translation.sh concurrent
Scripts/diagnose_apple_translation.sh task-cancel
Scripts/diagnose_apple_translation.sh cancel-both
Scripts/diagnose_apple_translation.sh chunked
```

- `concurrent` 不取消大段，直接送短句。
- `task-cancel` 只取消 Swift 工作；`cancel-both` 同時取消 session 與 Swift 工作。
- `chunked` 每次送 1,000 個 Swift 字元，收到結果才送下一段；取消後停止送出剩餘段落。這是效能實驗，會直接切斷句子，不能當成產品的分段演算法。
- `short-only` 不暖機，直接翻短句，供獨立程序對照使用。

非 baseline 模式會定期記錄主執行緒仍能執行，以及舊工作結束後的短句耗時。呼叫 session 取消後，再確認同一個 session 拒絕新請求；這只證明取消狀態已設定，並不證明正在執行的工作停止。

需要變更測試條件時，用環境變數：

```sh
APPLE_TRANSLATION_TARGET=zh-Hans Scripts/diagnose_apple_translation.sh
APPLE_TRANSLATION_CANCEL_DELAY=3 APPLE_TRANSLATION_TIMEOUT=420 Scripts/diagnose_apple_translation.sh
```

也可指定 `APPLE_TRANSLATION_SOURCE`、`APPLE_TRANSLATION_SHORT_TEXT` 或 `APPLE_TRANSLATION_FIXTURE`。`APPLE_TRANSLATION_CHARACTER_LIMIT` 只取測資前 N 個 Swift 字元，保留原始換行；未設定時使用完整測資。

短句的效能目標預設為一秒，可用 `APPLE_TRANSLATION_SHORT_LATENCY_LIMIT` 更改。這是本專案的診斷標準，不是 Apple 的效能承諾。退出代碼：0 表示短句成功且符合目標；1 表示翻譯或讀檔失敗；2 表示條件無效；3 表示短句成功但超過目標；124 表示整組逾時。舊工作仍會等到返回或逾時，保留完整紀錄。

快速重現延遲，約兩秒完成：

```sh
APPLE_TRANSLATION_CHARACTER_LIMIT=5000 APPLE_TRANSLATION_CANCEL_DELAY=0.1 Scripts/diagnose_apple_translation.sh cancel-both
```

對照小段依序送出的方式：

```sh
APPLE_TRANSLATION_CHARACTER_LIMIT=65000 APPLE_TRANSLATION_CANCEL_DELAY=0.1 Scripts/diagnose_apple_translation.sh chunked
```

研究結果與處理建議見 [ROOT_CAUSE.md](ROOT_CAUSE.md)。

## 手動測試用文字

測資位於 `Tests/Fixtures/Translation/`：

- `100K_words.txt`：原檔完整保留，依空白分隔共 100,000 個英文單字、653,352 個字元。
- `10K_characters.txt`：原檔前 10,000 個字元，包含空白、標點與換行，供測量一次分段的耗時；截取點可能位於單字中間。

可用文字編輯器開啟 `10K_characters.txt`，全選後按 Boundless 的翻譯快捷鍵測試。這裡的一萬指字元，不是一萬個英文單字。診斷腳本預設仍使用完整的十萬英文單字檔。
