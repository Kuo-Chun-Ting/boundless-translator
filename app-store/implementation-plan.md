# 上架待辦

後台狀態依 2026-10-17 的唯讀檢查；以下清單於 2026-10-18 整理，未重新查詢後台。版本為 **1.0**，Build **49** 已供朋友測試，尚未指定為正式送審版本。

2026-10-18 進度核對：Apple Developer 的 Agreements 已記錄新版協議於當日接受；App Store Connect Business 仍顯示新版協議提醒，是否已解除提交阻擋尚待確認。Business 的 Digital Services Act 已顯示 In Review，更新日期為當日，涵蓋 27 個歐盟地區；尚未確認驗證通過。其餘項目維持上次查核紀錄。

2026-10-18 網站與商品頁查核：第 05 項網站發布、第 06 項三語商品文字、第 11 項英文審核備註已完成並儲存。當時商品頁尚未上傳截圖、未選 Build。這次未重新確認交易者身分及 App Information 狀態。

照順序處理即可。原因、入口與步驟見[上架操作指南](submission-guide.md)。

## 接下來要做

- [x] 01 接受新版開發者協議。Apple Developer 記錄 Accepted October 18, 2026；Connect 提醒尚待確認消除。[步驟](submission-guide.md#step-01)
- [ ] 02 完成交易者身分申報；若以交易者身分在歐盟上架，再完成資料驗證。2026-10-18 已提交，狀態 In Review，等待 Apple 驗證結果。[步驟](submission-guide.md#step-02)
- [ ] 03 設定主要分類、年齡分級與內容權利聲明。[步驟](submission-guide.md#step-03)
- [x] 04 設定 App 下載價格與上架地區。2026-10-18 已設定 United States 基準、免費下載及全部 175 個國家／地區；Availability 顯示 Available on App Release。[步驟](submission-guide.md#step-04)
- [x] 05 發布已更新的支援網站。2026-10-18 已確認 `a67b227` 的 Pages 部署成功；正式首頁、三語 Support／Privacy、CSS 與站內連結／錨點均通過檢查，並實際確認三語畫面與語言切換。[步驟](submission-guide.md#step-05)
- [x] 06 更新英文、繁中、簡中商品描述。2026-10-18 已依核准文案儲存三語 Description，對應支援網址已確認；英文關鍵字移除舊 Live Text，簡中填入對應關鍵字。重新載入後逐語讀回與核准稿一致，尚未送審。[步驟](submission-guide.md#step-06)
- [ ] 07 上傳已確認的四張 Glass 功能介紹圖與 `video/preview.mp4`。[步驟](submission-guide.md#step-07)
- [ ] 08 補上訂閱群組顯示名稱與訂閱審核截圖。[步驟](submission-guide.md#step-08)
- [ ] 09 完成最終 Verify 與 TestFlight 功能、訂閱驗收。[步驟](submission-guide.md#step-09)
- [ ] 10 在版本 1.0 選擇驗收過的 Build。[步驟](submission-guide.md#step-10)
- [x] 11 更新給 Apple 的審核操作說明。2026-10-18 已填入使用者核准的英文 Notes 並儲存；重新載入後核對全文一致。[步驟](submission-guide.md#step-11)
- [ ] 12 將 App、年訂閱和訂閱群組一起送審。[步驟](submission-guide.md#step-12)
- [ ] 13 Apple 通過後，手動發布。[步驟](submission-guide.md#step-13)

英文、繁中、簡中商品頁文字已完成。副標題、宣傳文字與 Marketing URL 維持原狀；正式圖片和影片見 [素材入口](README.md)。

## 已有的資料

- [x] Build 49 已上傳並在 TestFlight 測試；最低 macOS 15、僅支援 Apple 晶片。
- [x] App Privacy、隱私權政策網址、英文 Support URL、Copyright 與審核聯絡資料已填。
- [x] 年訂閱已有三語名稱與說明，台灣年費 NT$199、首月免費，已設定銷售地區。
- [x] 付費合約、銀行及稅表為 Active；App 與訂閱的 Tax Category 已有設定。
- [x] 正式功能介紹圖已完成；README、三語 Support 與網站導覽已在本機更新。
- [x] 已選手動發布，Apple 通過後不會立即自動上線。

App 內另有一句舊的語言支援說明待決定是否修改，見[第 09 項](submission-guide.md#step-09)。本清單不將其他長期待辦全部列為上架條件。
