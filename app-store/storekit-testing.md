# StoreKit 本機測試

- 暫時跳過：macOS 26.5.2（25F84）＋ Xcode 26.6（17F113）這個組合的 3 個整合測試。
- 已重現：`Product.purchase()` 回傳 verified 成功交易，但 `Transaction.currentEntitlements`、`Transaction.all` 都是空的。
- 排查結果：直接呼叫 Apple API、改用 Apple 範例商品設定仍能重現；系統紀錄缺少 `original-transaction-id`。目前證據指向本機 StoreKit 測試環境，尚未證實確切根因。
- 其他人的類似回報：[購買後有效交易沒有更新](https://developer.apple.com/forums/thread/820813)、[相同 macOS／Xcode 版本的 SKTestSession 異常](https://developer.apple.com/forums/thread/836842)。回報不等於本專案問題已獲 Apple 確認。
- `verify_subscription.sh` 仍執行訂閱單元、元件與 PKG 流程測試。跳過整合測試時明確顯示警告；其他測試失敗仍回傳失敗。
- macOS 或 Xcode 版本／build 改變後自動恢復執行。手動重試：`Scripts/Tests/test_storekit.sh --force`。
- 正式簽章與後台商品就緒後，使用實際 TestFlight 版本驗證購買、試用、續訂、到期、退款與恢復購買；未完成前不能標記訂閱驗收完成。
