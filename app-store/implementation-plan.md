# App Store Implementation Plan

- [x] 建立 App Store Connect App 與 Bundle ID，並在 Xcode 登入 Developer 帳號供 Automatic Signing 管理簽章憑證與 Provisioning Profile。
- [x] 建立年訂閱商品，設定台灣 NT$199、一個月免費試用、銷售地區與英文、繁體中文、簡體中文名稱及說明。
- [x] 發佈 Privacy Policy 與 Support 網頁，完成 App Privacy 設定。
- [x] 完成開發者地址更新。
- [x] 修正建置產物夾帶 `com.apple.quarantine` 的問題。
- [x] 建置並上傳 App Store Build `1.0 (2)`。
- [x] 2026-09-17 已透過 Xcode Automatic Signing 在本機產出 App Store Build `1.0 (4)` 的 `.xcarchive` 與已簽章 `.pkg`；已確認最終 PKG 內的 App 使用 App Store 發行簽章、正確 Team ID、App Sandbox 與網路權限，尚未上傳 App Store Connect。
- [ ] 完成 App Information：主要分類與年齡分級；確認 App 價格、Tax Category 及銷售地區。
- [ ] 更新英文商品描述與 App Review Notes，使其符合 `Command-Shift-1` 翻譯及 `Command-Shift-2` 截圖的現行流程。
- [ ] 新增繁體中文、簡體中文商品頁，並上傳 App 商品頁截圖。
- [ ] 新增訂閱群組顯示名稱並上傳訂閱審核截圖，使訂閱商品離開 `MISSING_METADATA` 狀態。
- [x] 完成 Business 資料。2026-09-16 已確認 Paid Apps Agreement、銀行帳戶與三張稅表均為 Active。
- [ ] 將 Build 與訂閱商品加入送審版本。Build 1.0 (2) 已完成處理及 Export Compliance，已加入內部群組並透過 TestFlight 安裝。
- [x] Apple Sandbox 商品已完成同步。Build `1.0 (2)` 的 TestFlight App 已能顯示年訂閱、台灣價格、一個月免費試用與不會收費的測試購買確認畫面。
- [ ] 透過 TestFlight 驗證權限、跨 App 選字翻譯、截圖翻譯、試用、購買、訂閱失效與恢復購買。
- [ ] 調整訂閱畫面的 Check Again：目前只更新訂閱權限，未重新載入商品。
- [ ] 檢查全部送審資料並提交 App 與訂閱商品審核。
- [ ] 審核通過後手動發佈。
