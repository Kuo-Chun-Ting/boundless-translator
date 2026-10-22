# 上架待辦

後台查核日期：2026-10-22。版本 1.0 已選擇 Build 1.0（49）並儲存，仍為 Prepare for Submission。App Review 尚無送審項目。

本文件集中記錄剩餘工作、目的、入口與完成條件。已完成的項目不重做；歷來欄位操作說明見 [submission-guide.md](submission-guide.md)。

## 素材與語言

三語商品頁不代表必須製作三套圖片。這次先沿用已定稿的英文圖片與影片；繁中、簡中圖片屬於另外的在地化工作，不列為本次上架必做項目。上傳後確認三個語言頁都有素材可顯示；若頁面未沿用主要語言素材，再指定或上傳相同檔案。

- 圖片依序為 [選字翻譯](image/01-selection.png)、[截圖翻譯](image/02-screenshot.png)、[字典](image/03-dictionary.png)、[設定](image/04-settings.png)。
- 影片為 [preview.mp4](video/preview.mp4)。
- 商品圖片給下載前的使用者看；訂閱審核截圖給 Apple 看實際購買畫面，兩者不同。

[Apple 商品頁在地化說明](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information)

## 待辦順序

由 agent 負責資料整理、上傳、檢查與測試；只有帳號驗證、接受合約、系統交易確認或最後送審／發布決定需要使用者介入時，才請使用者處理。這份文件本身不代表已授權送審或發布。

### 1. 上傳商品圖片與影片

目的：讓使用者在 App Store 看到功能及操作方式。英文已上傳四張圖片與一支影片；繁中、簡中顯示 Using Existing Assets，沿用英文素材。

入口：[版本 1.0 商品頁](https://appstoreconnect.apple.com/apps/6810727652/distribution/macos/version/inflight)。

- [x] 英文頁已上傳四張圖片，依選字翻譯、截圖翻譯、字典、設定排序。
- [x] 已上傳 `video/preview.mp4`，後台列出一支影片。
- [x] 後台影片已從開頭播放到 29 秒片尾，未遇播放錯誤；本次未驗證音訊。
- [x] 已檢視現有封面：預設第 5 秒的選字操作畫面，非空白或載入失敗畫面；沒有修改封面。
- [x] 繁中、簡中均沿用同一組英文圖片與影片。
- [x] 三語素材清單與順序已確認；英文影片播放與封面已檢視，中文沿用相同素材。

完成條件：三語商品頁都有預定的四張圖片與一支可播放影片，沒有處理失敗或未儲存的修改。

### 2. 訂閱群組顯示名稱（已完成）

目的：讓使用者在管理訂閱時辨認這個 App。現有內部參考名稱不等於對外顯示名稱。

入口：[訂閱群組](https://appstoreconnect.apple.com/apps/6810727652/distribution/subscription-groups/22374799)。

- [x] 英文群組顯示名稱為 `Boundless Translator`，App 名稱也沿用品牌名稱。
- [x] 依使用者決定維持一份英文群組名稱，不另加中文翻譯。

年訂閱商品本身仍有三語顯示名稱與描述：英文 `Annual Plan`（本次已儲存）、繁中「年繳方案」、簡中「年度订阅」。內部 Reference Name 保持 `Boundless Translator Annual`。

### 3. 驗收準備送審的 App

目的：確認真正交給 Apple 的程式及訂閱流程能使用。後台有 Build 不等於已完成驗收。

入口：[TestFlight](https://appstoreconnect.apple.com/teams/5bb83b1e-176f-4d8c-a7c2-37242cbca6fb/apps/6810727652/testflight)，以及專案根目錄的終端機。

- [x] 核對既有測試紀錄及送審程式版本。目前候選為 Build 49，已核對 `/Applications/Boundless Translator.app` 的版本編號。
- [x] 完成 Verify 各項驗證：2026-10-22 使用者執行時六項通過、Scripts 失敗、StoreKit 略過。修正測試對 `rg` 的依賴後，單獨重跑 Scripts 全部通過（exit 0）；其餘項目沿用本次 Verify 結果，StoreKit 沿用既有例外。未重新執行整套 Verify。
- [x] Build 49 的選字翻譯、截圖內單字與句子翻譯、字典、朗讀、快捷鍵及語言設定保存，使用者回報測試完成、沒有問題。
- [ ] 首次安裝的語言設定及必要權限流程，本輪未驗證，也未重設使用者環境。
- [x] 訂閱價格與重啟後保留 Active 已由 agent 確認；恢復購買、訂閱失效後限制翻譯及再次訂閱後解鎖，由使用者回報清單皆已測完、沒有問題。
- [x] 記錄 Build 編號、測試結果與未測範圍；本機 StoreKit 跳過不當作實際訂閱驗收通過。詳見 [storekit-testing.md](storekit-testing.md)。

Build 49 對應改動已有 Unit 246、Component 207、GUI 15、E2E 4 項通過紀錄，當時引用的三份 `/private/tmp/` log 已不存在。2026-10-22 已補上述手動驗收；使用者回報的項目未由 agent 逐項重測。同日讀取使用者終端機的 Verify 結果：Unit、Component、GUI、E2E、Languages、Release 通過，Scripts 失敗（exit 127），StoreKit 依既有例外略過。原始終端機未保留 Scripts 的失敗細節；後續已重現並修正工具依賴問題，見下方紀錄。Release 包含 DMG 公證、安裝後啟動驗證，產物為 `Build/Boundless Translator DMG Test.dmg`；這不代表 App Store 已送審。

完成條件：送審 Build 的功能與訂閱驗收有紀錄，沒有阻擋上架的問題。若要修改 App 程式或內建文案，先修正並上傳新 Build；只改商品圖片或描述不需要重建 App。既有語言支援文案待決定事項見[驗收說明](submission-guide.md#step-09)，不在本次自行擴大修改。

Scripts 診斷：2026-10-22 單獨執行 `Scripts/run_script_tests.sh`，Codex 環境全部通過；改用不含 Codex 工具的標準 PATH，完整 Scripts 與單一網站預覽測試均在 `Tests/Scripts/PreviewWebsiteTests.sh:80` 回報 `command not found: rg`、exit 127。該行已改用 `grep -Fq` 檢查提示文字，不需安裝其他工具。修正後以相同標準 PATH 重跑完整 Scripts，全部通過（exit 0），輸出保留於 `/private/tmp/boundless-scripts-grep-verification.log`。只修改測試，未改 App、未跑其他測試層級、未產生發布 DMG。

### 4. 訂閱審核截圖（已完成）

目的：讓 Apple 看見 App 內實際購買年訂閱的畫面。Review Information → Screenshot 已有圖片，頁面沒有待儲存變更。

入口：[年訂閱設定](https://appstoreconnect.apple.com/apps/6810727652/distribution/subscriptions/6810730512)。

- [x] 已取得未訂閱畫面的真實截圖，輸出為 `image/subscription.jpg`。
- [x] 後台 Review Information → Screenshot 已上傳並儲存。

本機 Sandbox 首次購買已成功；候選 Build 的完整驗收仍另列第 3 項，不能因截圖上傳完成就勾選通過。

完成條件：Apple 的訂閱審核欄位有實際購買畫面。上方 Image (Optional) 是訂閱宣傳圖片，不是這次要補的欄位。

### 5. 指定送審 Build（已選擇）

目的：告訴 Apple 版本 1.0 要審核哪一份程式。

入口：[版本 1.0 商品頁](https://appstoreconnect.apple.com/apps/6810727652/distribution/macos/version/inflight)。

- [x] 版本頁已選擇 1.0（49）並儲存。
- [x] Build Metadata 顯示 Validated、macOS 15.0、arm64，App Uses Non-Exempt Encryption 為 No。
- [ ] 送審前完成第 3 項驗收；若換版，再更新此處選擇。

完成條件：版本頁已指定驗收過的 Build。

### 6. 將 App、年訂閱與訂閱群組一起送審

目的：讓 Apple 同時審核首次上架的 App 與訂閱。

入口：[版本頁](https://appstoreconnect.apple.com/apps/6810727652/distribution/macos/version/inflight)、[年訂閱](https://appstoreconnect.apple.com/apps/6810727652/distribution/subscriptions/6810730512)、[訂閱群組](https://appstoreconnect.apple.com/apps/6810727652/distribution/subscription-groups/22374799)、[App Review](https://appstoreconnect.apple.com/apps/6810727652/distribution/reviewsubmissions)。

- [ ] 確認前述資料、驗收與下方帳號狀態檢查完成，仍設定手動發布。
- [ ] 在版本頁按 Add for Review，加入送審草稿。
- [ ] 將年訂閱與訂閱群組加入同一份草稿。
- [ ] 在 App Review 核對版本、Build、訂閱及群組，補齊後台實際提示的缺項。
- [ ] 將完整送審內容交給使用者確認，獲准後按 Submit for Review。
- [ ] 確認狀態已進入等待審核或審核中；若 Apple 提問或要求補件，依實際內容處理。

完成條件：正式申請已送出。Add for Review 只是加入草稿，Submit for Review 才是送審。

[App 送審說明](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app) · [首次訂閱送審說明](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)

### 7. 通過後手動發布

目的：由使用者決定正式公開的時間。目前已選 Manually release this version。

入口：[版本 1.0 商品頁](https://appstoreconnect.apple.com/apps/6810727652/distribution/macos/version/inflight)。

- [ ] 等狀態變成 Pending Developer Release。
- [ ] 核對版本、Build 與發布地區，取得使用者發布指示。
- [ ] 按 Release This Version，完成發布確認。
- [ ] 上線後檢查三語商品頁、圖片、影片、下載與訂閱。

完成條件：預定地區可查看商品頁、下載 App 並使用訂閱。

## 帳號與合約狀態（已完成）

2026-10-22 已讀取使用者手動開啟的 Business 頁，最新結果如下。

入口：[Business](https://appstoreconnect.apple.com/business)。

- [x] Free Apps Agreement 為 Active。
- [x] 銀行帳戶與三份稅務文件均為 Active，不需重填。
- [x] Digital Services Act 為 Active，適用 27 個國家／地區，最後更新 2026-10-18。
- [x] 使用者已接受新版 Paid Apps Agreement。重新查核顯示 Active，有效期間為 2026-10-21 至 2027-09-04；新版合約提醒與 View and Agree to Terms 已消失。

本次沒有點選同意或修改任何帳號資料。

## 已確認完成，不重做

2026-10-22 後台查核：

- [x] 主要分類 Productivity、年齡分級 4+ 與內容權利聲明已有設定；此處只記錄已填，不代替權利判斷。
- [x] App Privacy 已發布 Data Not Collected，隱私網址已有設定。
- [x] App 免費下載，175 個國家／地區已設定可用。
- [x] 英文、繁中、簡中的描述、關鍵字與支援網址已填。
- [x] 英文審核備註、聯絡資料已填，未要求 App 帳號登入。
- [x] 年訂閱有三語名稱與描述，台灣年費 NT$199、首月免費已設定。
- [x] Build 49 出現在可送審清單。
- [x] 已設定手動發布。

## 其他頁面查核結果

| 頁面 | 現況與判斷 |
| --- | --- |
| App Information | 三語 App 名稱均為 Boundless Translator；副標空白，維持使用者先前決定。Productivity 與 4+ 已設定；年齡問卷已逐步核對。 |
| App Privacy | Data Not Collected 已發布。繁中、簡中的 Privacy Policy URL 已分別改為 `/zh-tw/privacy/`、`/zh-cn/privacy/` 並儲存；英文維持 `/en/privacy/`。Apple 提示網址變更會隨下一個 App 版本發布。 |
| Pricing and Availability | App 本體在 175 個地區皆為免費，175 個地區可用；Public 發行，稅務分類 App Store software。學校大量購買五折選項已勾選，但適用 App 本體價格，不是年訂閱名額；免費 App 目前沒有折扣金額差異。 |
| Subscriptions | 一個年訂閱群組；多人購買 Not Allowed、Family Sharing 關閉。Billing Grace Period 未啟用，Streamlined Purchasing 啟用；本次未調整。 |
| In-App Purchases | 沒有額外的單次內購商品；年訂閱已在 Subscriptions，不需重建。 |
| App Accessibility | 尚未填寫支援標示。應在實際驗證各項輔助使用功能後再聲明，不列為本次必填。 |
| App Review | 尚無送審項目；未按 Add for Review 或 Submit for Review。 |

三語描述、訂閱說明與審核備註未見需要重寫的空泛宣傳文案。已依使用者授權儲存英文訂閱 Display Name 與兩個中文隱私網址；沒有改 App、執行測試或產生 DMG。

其他已完成紀錄：四張圖片與影片已定稿；支援網站三語發布已於 2026-10-18 驗證。副標題、宣傳文字與 Marketing URL 維持原狀，不新增為本次必填工作。
