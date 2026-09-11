# App Store Implementation Plan

## 已完成

- [x] Review 現有程式與發佈流程。
- [x] 所有 `.app` 與 DMG Build 啟用 App Sandbox。
- [x] 完成輔助使用與螢幕錄製權限引導。
- [x] 新增權限重設腳本，供每次人工測試前使用。
- [x] 完成 StoreKit 年訂閱、權限判斷、購買、恢復購買與管理訂閱。
- [x] 將功能驗證與訂閱驗證拆成 `verify_features.sh`、`verify_subscription.sh`。
- [x] 完成無訂閱功能的測試 DMG 流程。
- [x] 完成 App Store `.app` 與 PKG 建置流程。
- [x] 註冊 Bundle ID `com.lillard.BoundlessTranslator` 並建立 App Store Connect App。
- [x] 建立 App Store `.app` 憑證、PKG 憑證與 Provisioning Profile。
- [x] 建立訂閱群組 `Boundless Translator Subscription`。
- [x] 建立年訂閱商品 `com.lillard.boundless.annual`。
- [x] 設定一年期、所有銷售地區與台灣 NT$199 價格。
- [x] 新增英文、繁體中文與簡體中文訂閱名稱及說明。
- [x] 設定一個月免費試用。
- [x] 發佈英文、繁體中文與簡體中文的 Privacy Policy 和 Support 網頁。
- [x] 在 App Store Connect 填入 Privacy Policy URL 與 Support URL。
- [x] 發佈 App Privacy：`Data Not Collected`。
- [x] 本機產生並驗證 App Store 版 `1.0 (1)`：arm64、Sandbox、簽章、Provisioning Profile 與 PKG 均正確。
- [x] 完成 `Scripts/verify.sh`，包含 Swift、GUI、DMG、訂閱與 App Store 建置測試。

## 接下來

- [ ] 等 Apple 更新開發者地址後，完成 Paid Apps Agreement、銀行與稅務資料並確認狀態為 Active。
- [ ] 完成 App Store 商品頁資料：分類、年齡分級、內容權利、供應地區、介紹、關鍵字與版權。
- [ ] 建立 App Store Connect API Key，將 `.p8` 私鑰保存在 repo 外。
- [ ] 上傳 `Build/AppStore/BoundlessTranslator-1.0-1.pkg`。
- [ ] 在 TestFlight 驗證權限、選字翻譯、截圖翻譯、免費試用、購買、取消、到期與恢復購買。
- [ ] 擷取 App Store 商品頁截圖與訂閱 Review Screenshot。
- [ ] 在 `1.0` 版本選擇 Build `1`，加入第一個訂閱商品並完成 Export Compliance。
- [ ] 填寫 App Review 聯絡資料與測試說明。
- [ ] 最後檢查後送審。
