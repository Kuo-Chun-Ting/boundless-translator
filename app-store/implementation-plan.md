# App Store Implementation Plan

- [x] 建立 App Store Connect App、Bundle ID、簽章憑證與 Provisioning Profile。
- [x] 建立年訂閱商品，設定台灣 NT$199、一個月免費試用、銷售地區與英文、繁體中文、簡體中文名稱及說明。
- [x] 發佈 Privacy Policy 與 Support 網頁，完成 App Privacy 設定。
- [x] 完成開發者地址更新。
- [x] 修正建置產物夾帶 `com.apple.quarantine` 的問題。
- [x] 建置並上傳 App Store Build `1.0 (2)`。
- [ ] 完成 App Information：主要分類與年齡分級；確認 App 價格、Tax Category 及銷售地區。
- [ ] 更新英文商品描述與 App Review Notes，使其符合 `Command-Shift-1` 翻譯及 `Command-Shift-2` 截圖的現行流程。
- [ ] 新增繁體中文、簡體中文商品頁，並上傳 App 商品頁截圖。
- [ ] 新增訂閱群組顯示名稱並上傳訂閱審核截圖，使訂閱商品離開 `MISSING_METADATA` 狀態。
- [x] 完成 Business 資料。2026-09-16 已確認 Paid Apps Agreement、銀行帳戶與三張稅表均為 Active。
- [ ] 將 Build 與訂閱商品加入送審版本。Build 1.0 (2) 已完成處理及 Export Compliance，已加入內部群組並透過 TestFlight 安裝。
- [ ] 【阻礙訂閱測試】排除 Apple Sandbox 空商品回應。StoreKit 已向台灣 Sandbox 查詢正確的 Bundle ID 與 Product ID，但 Apple 回傳 HTTP 200、`{"data":[]}`。已確認會員有效、最新開發者合約已接受、Paid Apps Agreement、銀行與稅務資料皆為 Active，Build 1.0 (2) 的簽章與 Provisioning Profile 有效，訂閱包含台灣、價格有效且有三個語系。訂閱群組顯示名稱與審核截圖仍缺少，但 Apple 文件指出 Sandbox 測試不需先送審，且沒有群組語系時仍可測試新商品，因此兩項缺件尚不能解釋空回應。Business 剛啟用，等待 Apple 同步後重測；若一小時後仍為空回應，向 Apple 提供 App ID 6810727652、Product ID com.lillard.boundless.annual 與 2026-09-16 22:19:18 的重現紀錄。參考：https://developer.apple.com/documentation/technotes/tn3186-troubleshooting-in-app-purchases-availability-in-the-sandbox
- [ ] 透過 TestFlight 驗證權限、跨 App 選字翻譯、截圖翻譯、試用、購買、訂閱失效與恢復購買。
- [ ] 調整訂閱畫面的 Check Again：目前只更新訂閱權限，未重新載入商品。
- [ ] 檢查全部送審資料並提交 App 與訂閱商品審核。
- [ ] 審核通過後手動發佈。
