# 訂閱測試

## 本機手動購買

在專案根目錄執行：

```sh
Scripts/build_app_store_app.sh
```

成功後產物為 `Build/AppStore/Boundless Translator.app`，由你手動開啟。腳本不開 App、不上傳、不重設資料；失敗時保留上一版，不能把舊檔仍存在當成新建置成功。DMG 建置與發布流程照舊。

這個入口沿用 AppStoreRelease 與正式訂閱商品。2026-10-22 實際建置已確認為 Apple Development 簽章、簽章驗證通過，包含 App Sandbox 與網路權限，未嵌入 provisioning profile。使用者已完成一次 Sandbox 購買，App 顯示 Active。

2026-10-22 已逐張確認使用者提供的五張截圖：未訂閱方案、Sandbox 登入、測試帳號購買確認、購買成功及 App 顯示 Active。目前僅保留[未訂閱方案截圖](image/subscription.jpg)供審核，其餘測試截圖已依使用者要求刪除。使用者清除紀錄後，稍後已實際看到 Subscribe 畫面；無法確定是清除延遲或測試訂閱到期，未再次清除或重新購買。重啟後保留訂閱與恢復購買仍未驗證。

1. 在 Mac 的 App Store → Settings 登入 Sandbox 測試帳號。
2. 結束 TestFlight 或其他版本的 Boundless Translator，再手動開啟上述產物。
3. 從選單列開啟訂閱畫面。此輪不使用翻譯快捷鍵，不授予輔助使用或螢幕錄製權限。
4. 確認未訂閱方案、價格、適用試用資訊及購買按鈕。需要審核截圖時先截圖，不必先購買；用作審核素材前，核對程式來源、訂閱畫面與商品設定符合送審候選版本。
5. 購買確認畫面核對測試帳號及測試環境後再確認購買。檢查訂閱生效、重啟仍有效及手動恢復購買。
6. 重測時先結束 App，到 [Sandbox 測試帳號](https://appstoreconnect.apple.com/access/users/sandbox) 清除該帳號的 Purchase History。等 Apple 處理完成，必要時重新登入，再開啟同一份 App，確認回到未訂閱。若仍有效，先核對執行檔與帳號，不反覆清除本機資料。

本機 App、TestFlight 和正式版都使用 `com.lillard.BoundlessTranslator`，可能共用資料與權限；分開放置不等於隔離。既有 App Store Reset 依此識別碼處理，也可能影響正式版。權限 Reset 預設停止 `/Applications/Boundless Translator.app`，不會自動改找本機產物。這個測試流程不需要執行 Reset；它也不能清除 Apple 的購買紀錄。最後仍以 TestFlight 驗收送審版本。

## 本機自動測試

Apple 的本機 StoreKit 測試使用 `.storekit` 模擬商品與交易，不需要 Sandbox 帳號，也不依賴 Apple 的真實購買服務。Unit／Component 則提供測試狀態，驗證 App 的訂閱判斷。

- 依使用者決定，本次自動測試與 runner 改動已還原，保留原有五項測試；預設略過、回傳 78，僅 `Scripts/run_storekit_tests.sh --force` 強制執行。原 runner 會清理暫存結果，尚未具備失敗保留報告功能。
- 修復列為後續 TODO，不作為這次上架準備的前置條件。Verify 沿用既有 StoreKit 例外，其餘項目仍須通過；正式候選版本仍須 TestFlight 驗收。
- 最近診斷：原五案在 `SKTestSession.buyProduct` 回傳 `unknown`。曾試用 `Product.purchase(confirmIn:)` 建立本機交易，七案中三案通過、四案失敗；該改版已撤回，不能視為目前測試結果或修復完成。
- 後續須釐清本機模擬交易、權益與通知的問題，補足指定交易完成、取消續訂、到期與退款的有效斷言；不用主動刷新冒充通知通過，也不為讓測試通過而改正式訂閱判斷。證據與待 review 項目見[討論文件](sandbox_testing_responsed_by_codex.md)。
