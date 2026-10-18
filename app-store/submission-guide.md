# 上架操作指南

我們現在已經有能讓朋友測試的 App。接下來要把「要交付的程式、商店介紹、訂閱商品」準備好，交給 Apple 檢查；Apple 通過後，再由你按下發布。

本文於 2026-10-18 整理，依據前一天的後台檢查及 Apple 官方操作文件；沒有重新確認今天的後台狀態，也沒有代填或送出資料。勾選進度請回到[上架待辦](implementation-plan.md)。

## 先分清楚這幾個地方

| 地方／名稱 | 它的用途 |
| --- | --- |
| App Store Connect | 管理商品介紹、價格、訂閱和送審的後台。使用者不會看到這個後台，只會看到你發布的商品頁。 |
| TestFlight／Friends Beta | 讓朋友安裝測試版本。朋友能測試，不代表 App 已通過正式上架審核。 |
| Build | 某次建置出來、已上傳的程式。例如版本 1.0 的 Build 48 和 49，是同一版本下的不同程式成品。正式送審時要指定其中一個。 |
| 支援網站 | 使用者點商品頁的 Support URL／Privacy Policy URL 時開啟的網頁。來源在專案 `docs/`，更新檔案後仍要發布網站才會生效。 |
| Apple 審核人員 | Apple 負責檢查 App 和訂閱商品的人。正式審核備註是寫給他們看的，不是給 Friends Beta 的測試說明。 |

上架工作分成四段：**帳號與基本資料（01–04）→ 網站與商品內容（05–08）→ 最後驗收（09–11）→ 送審與發布（12–13）**。

以下 App 相關入口都從 [Boundless Translator](https://appstoreconnect.apple.com/apps/6810727652/distribution) 開始。寬視窗通常用左側導覽；若看不到左側欄，點頁面標題旁的下拉選單，就能切換 App Information、Pricing and Availability、Subscriptions 等頁面。

<a id="step-01"></a>
## 01 接受新版開發者協議

**為什麼：** Apple 更新了開發者協議，後台明確提示未接受前不能提交新的 App。已經有效的付費合約、銀行和稅表，不會自動完成這份新版協議。

**去哪裡：** [Apple Developer 帳號](https://developer.apple.com/account/)；可先從 [Business](https://appstoreconnect.apple.com/business) 查看提示。

1. 使用這個開發者帳號的帳號持有人登入 Apple Developer。
2. 開啟新版協議提示，閱讀內容。
3. 確認接受後，依頁面完成同意程序。
4. 回到 Business，確認沒有仍阻止提交 App 的協議提示。

**完成標準：** 帳號已接受要求的新版協議。這一步需要你本人決定，不由我代為接受。[官方說明](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements)

<a id="step-02"></a>
## 02 申報交易者身分

**為什麼：** Apple 要求開發者申報是否為交易者。即使不在歐盟上架，也要做身分申報；若以交易者身分在歐盟上架，還要驗證會公開顯示的聯絡資料。是否屬於交易者，由你依實際營運情況判斷。[官方說明](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)

**去哪裡：** [Business](https://appstoreconnect.apple.com/business) → Agreements → Digital Services Act／Complete Compliance Requirements。

1. 開啟 Complete Compliance Requirements。
2. 閱讀說明，依實際情況申報交易者身分，不要只為了略過流程選答案。
3. 若要求交易者資料，填入準備公開的聯絡方式，依提示完成電子郵件、電話及文件驗證。
4. 若要在歐盟上架，確認這個 App 的交易者設定也符合你的申報。

**完成標準：** 身分申報完成；適用的聯絡資料驗證已完成。上次後台仍顯示需要處理。

<a id="step-03"></a>
## 03 設定 App 基本資料

**為什麼：** Apple 需要知道 App 屬於什麼類型、適合哪些年齡，以及是否有權使用其中的內容。這是商品與審核資料，不是修改 App 的功能。

**去哪裡：** [App 後台](https://appstoreconnect.apple.com/apps/6810727652/distribution) → App Information。

1. **Category：** 選主要分類。專案目前的分類是 Productivity（生產力），後台應與程式設定一致；若要換別的分類，先一起確認專案設定。次要分類可先不選。
2. **Age Ratings：** 點 Set Up Age Ratings，按 App 實際提供的內容與能力完成每一頁問卷；評級由答案產生，不是直接挑想要的年齡。
3. **Content Rights：** 點 Set Up Content Rights Information，閱讀問題，依 App 使用或存取第三方內容的實際情況完成聲明。這不是申請著作權。
4. 儲存後重新確認這三處都有結果。

**完成標準：** 主要分類已有值、年齡分級已產生、內容權利聲明已完成。上次三項都尚未設定。[分類與權利欄位說明](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/) · [年齡分級步驟](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)

<a id="step-04"></a>
## 04 設定下載價格與上架地區

**為什麼：** 「下載 App 要多少錢」和「年訂閱要多少錢」是兩個設定。年訂閱已設 NT$199，仍不代表 App 已設定免費下載；訂閱選了全部地區，也不代表 App 已在那些地區開放。

**去哪裡：** [App 後台](https://appstoreconnect.apple.com/apps/6810727652/distribution) → Pricing and Availability。

1. 在 Price Schedule 點 Add Pricing。
2. 若維持「免費下載、年訂閱解鎖翻譯」的方式，將 App 下載價格設為免費，依畫面確認並儲存。這不會把年訂閱改成免費。
3. 在 App Availability 點 Set Up Availability，選擇要上架的國家／地區，按畫面完成確認。
4. 確認 App 與年訂閱在預計銷售的地區都可用；需要的身分或地區資料另按提示完成。

**完成標準：** App 已有下載價格及上架地區。Tax Category 已是 App Store software，訂閱沿用 App 的類別，這部分已有設定。[價格步驟](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price) · [地區步驟](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store)

<a id="step-05"></a>
## 05 發布支援網站

**為什麼：** 商店裡的支援網址和隱私權網址已經填好，但它們開啟的是公開網站。本機 README 或 Support 檔案改好了，使用者還不會立即看到。

**去哪裡：** [網站發布設定](https://github.com/Kuo-Chun-Ting/boundless-translator/settings/pages) · [部署紀錄](https://github.com/Kuo-Chun-Ting/boundless-translator/actions) · [公開網站](https://kuo-chun-ting.github.io/boundless-translator/)。

1. 執行 `Scripts/preview_website.sh`，瀏覽器會開啟本機網站；確認首頁、三語 Support／Privacy 的內容、導覽與排版。修改儲存後會自動重建與重新整理，按 Ctrl-C 停止。來源包含 `docs/_layouts/page.html`、`docs/assets/site.css` 和 `docs/_config.yml`；預覽不需要 commit 或 push。
2. GitHub 的 Settings → Pages 已於 2026-10-18 確認使用 Deploy from a branch，來源為 `main` 的 `/docs`；沿用此設定。
3. 將確認後的修改提交並推送到該發布來源；若既有設定使用部署工作流程，依該流程發布。
4. 在 Actions 確認網站部署成功，再開啟公開網站，逐一點英文、繁中、簡中的 Support 和 Privacy Policy。
5. 確認新版說明已出現，頁首只顯示同語言的支援與隱私政策；切換語言後仍停在相同類型的頁面。OCR 測試文章和內部排版文件不應出現在公開網站。

**完成標準：** 公開網頁已是確認後的內容，三語連結可開啟。網站已上線；本次修改須提交、推送到 `main`，並確認部署與公開頁面後，才能勾選完成。[GitHub Pages 發布說明](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)

<a id="step-06"></a>
## 06 更新商品頁文字

**為什麼：** 商品描述是給下載前的使用者看的。現在英文頁仍描述舊版「沒選字就用同一快捷鍵截圖」的流程，跟現有 App 不符。

**去哪裡：** [版本 1.0 商品頁](https://appstoreconnect.apple.com/apps/6810727652/distribution) → Product Page Information。

1. 語言先選 English (U.S.)，修改 Description 和 Keywords。
2. 說清楚選字翻譯與截圖翻譯是兩個操作，預設分別為 Command-Shift-1 和 Command-Shift-2；移除舊的同鍵截圖說明。
3. 說明截圖後能反覆 hover 單字、選字翻譯。不要把目前的辨識元件誤寫成 Live Text，也不必在行銷文字列 API 名稱。
4. 介面語言、可翻譯語言、截圖能辨識的語言是不同清單。不要把 App 的 48 個介面語系說成 48 種翻譯語言；保留年訂閱與試用資格說明。
5. 確認 Support URL、Copyright 等已有內容仍正確，儲存。

**可選的中文商品頁：** 若依原計畫提供繁中、簡中商品頁，從語言選單新增這兩種語言，填入各自的名稱、商品描述、關鍵字、支援網址與需要的截圖，再儲存。不必為 App 內每個語系都建立商店頁。新增語言時，也確認 App Information 裡的名稱資料。

**完成標準：** 商品文字符合實際流程；決定要提供的語言頁都有內容。Subtitle、Promotional Text、Marketing URL 和 App Preview 目前可先不補。[商品頁欄位說明](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) · [商品頁語言步驟](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information)

<a id="step-07"></a>
## 07 上傳六張功能介紹圖

**為什麼：** 圖已存在專案裡，但商店頁目前沒有圖片。把圖做完和把圖上傳到商品頁，是兩件事。

**去哪裡：** [版本 1.0](https://appstoreconnect.apple.com/apps/6810727652/distribution) → App Previews and Screenshots → Mac。

1. 從 [Glass](../docs/feature-showcase/output/glass/README.md) 或 [Space Gray](../docs/feature-showcase/output/space-gray/README.md) 選一套主題。
2. 使用上傳區的 Upload，選擇該目錄的六張 PNG。
3. 排成下列順序；等待處理完成，確認沒有錯誤再儲存。

| 順序 | 檔名／內容 |
| --- | --- |
| 1 | `01-selection-1-vscode.png` |
| 2 | `01-selection-2-preview.png` |
| 3 | `02-screenshot-1-cant-select.png` |
| 4 | `02-screenshot-2-general.png` |
| 5 | `03-dictionary.png` |
| 6 | `04-settings.png` |

**完成標準：** 商品頁顯示正確的六張圖，沒有漏圖或順序錯誤。兩套是樣式選擇，不是要一起放十二張。現有圖片已是 2560 × 1600 且無透明度通道，不需重截。[Apple 圖片規格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

<a id="step-08"></a>
## 08 補齊訂閱審核資料

**為什麼：** App 和訂閱是分開建立、一起供 Apple 檢查的項目。目前年費、試用和商品名稱已有設定，缺的是群組顯示名稱，以及讓 Apple 看見購買畫面的審核截圖。

**先分清楚名稱：**「年訂閱商品」是使用者購買的一年方案；「訂閱群組」是 Apple 將相關方案放在一起管理的分類。即使只有一個年方案，也會有群組。群組的內部參考名稱已存在，不代表使用者看得到的顯示名稱已填。

**去哪裡與步驟：**

1. 開啟[訂閱群組](https://appstoreconnect.apple.com/apps/6810727652/distribution/subscription-groups/22374799)。
2. 在 Display Name and Description 點 Create／Add，選擇語言，填入群組顯示名稱並確認。先完成主要英文；若要提供三語名稱，再補繁中、簡中。這不是重建年訂閱商品。[群組名稱說明](https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions)
3. 開啟 TestFlight 的 Boundless Translator，在 App 的「訂閱」視窗顯示年費與試用資訊，截下實際畫面；這一步不需要按購買。
4. 開啟[年訂閱商品](https://appstoreconnect.apple.com/apps/6810727652/distribution/subscriptions/6810730512)，找到下方 Review Information → Screenshot，選 Choose File 上傳並儲存。
5. 確認審核圖片已出現，群組也有顯示名稱。不要上傳到上方的 Image (Optional)，那是另一種宣傳圖片欄位。

**完成標準：** 群組名稱和訂閱審核截圖都已填妥。商品頁六張圖、訂閱審核截圖用途不同，不能只完成其中一組。這兩項補完後仍要在第 12 項一起加入送審。[訂閱欄位說明](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/auto-renewable-subscription-information)

<a id="step-09"></a>
## 09 完成最終驗收

**為什麼：** 自動測試檢查程式是否符合預期；TestFlight 驗收檢查使用者真正下載到的版本及 Apple 購買流程。兩者都不能只靠「Build 已上傳」判定完成。

**去哪裡：** 專案終端機，以及 [Build 49 的 TestFlight 頁面](https://appstoreconnect.apple.com/teams/5bb83b1e-176f-4d8c-a7c2-37242cbca6fb/apps/6810727652/testflight/macos/b8d68e15-bcd1-4436-afb0-43303c282e60)。朋友仍從 Mac 上的 TestFlight 安裝。

1. 先決定這次 App 是否還要改程式或內建文案。目前 App 內「介面語言與 macOS 相同」是舊說明；要修正就先修改、驗證並上傳新 Build，再以新 Build 驗收。只改網站或商店圖片則不需要重建 App。
2. 若尚無涵蓋最後程式版本的完整驗證，在專案根目錄執行 `Scripts/verify.sh`。它會執行測試，也包含 DMG 發布驗證；請預留時間，讓 GUI／E2E 執行時不受滑鼠鍵盤干擾。
3. StoreKit 本機測試目前有專案已記錄的環境例外。其他層級需全部成功；不要把略過本機 StoreKit 當成訂閱已驗收。細節見[測試紀錄](storekit-testing.md)。
4. 安裝確定要送審的 TestFlight Build，確認首次設定語言、兩種權限、兩組快捷鍵、選字與截圖翻譯、辨識等待、字典都能使用。
5. 依測試帳號狀態，實測免費試用／購買、恢復購買及訂閱失效後的行為，記下用的 Build、結果與未測範圍；只看到購買確認畫面不算完成交易驗收。

**完成標準：** 最後程式版本的 Verify 結果符合專案規則，送審 Build 的實際功能和訂閱驗收也有紀錄。上次後台查核沒有執行這些測試；若你已完成其中一項，先核對紀錄，不必為了文件再重跑。

<a id="step-10"></a>
## 10 選擇正式送審的 Build

**為什麼：** 同一個版本可以上傳很多 Build。Apple 要知道這次正式審核哪一份程式，使用者之後也會下載這一份。

**去哪裡：** [版本 1.0](https://appstoreconnect.apple.com/apps/6810727652/distribution) → Build。

1. 點 Add Build／「+」。
2. 選擇第 09 項實際驗收過的 Build；若沒再改程式，目前候選是 49。
3. 完成選取並儲存。
4. 回到 Build 區塊確認顯示的編號正確。如果要求補加密資料，先閱讀該 Build 的提示；Build 49 先前已申報不使用非豁免加密。

**完成標準：** 版本頁顯示驗收過的 Build 編號，而不是仍顯示 Add Build。[Apple 送審前提](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)

<a id="step-11"></a>
## 11 更新給 Apple 的審核操作說明

**為什麼：** Apple 審核人員需要能實際操作主要功能。現在備註還寫舊快捷鍵 Command-Shift-T，可能讓他按錯或以為功能失效。

**去哪裡：** [版本 1.0](https://appstoreconnect.apple.com/apps/6810727652/distribution) → App Review Information → Notes。

1. 保留正確的審核聯絡資料，並確認 App 不需登入個人帳號；不要誤勾 Sign-in required。
2. 將 Notes 改成目前操作：從選單列開啟 App、訂閱／試用入口、設定來源與目標語言。
3. 接著交代選字用 Command-Shift-1、截圖用 Command-Shift-2，以及各自需要的權限。設定或授權後需再按快捷鍵時，也要寫清楚。
4. 補上截圖內 hover 單字／選字、查看翻譯和開啟字典的方式，儲存。

**完成標準：** 備註能帶審核人員操作最後的 Build，沒有舊的同鍵截圖流程。這份內容不是 TestFlight 的 What to Test；朋友的測試說明不會取代這一欄。[審核資料欄位](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)

<a id="step-12"></a>
## 12 把 App 和訂閱一起送審

**為什麼：** 第一次上架含訂閱的 App，要把 App 版本、首次年訂閱及訂閱群組放進同一份送審資料。各自填好，不代表 Apple 已收到正式審核申請。[Apple 首次訂閱送審規則](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/)

**去哪裡：** [版本 1.0](https://appstoreconnect.apple.com/apps/6810727652/distribution)、[年訂閱](https://appstoreconnect.apple.com/apps/6810727652/distribution/subscriptions/6810730512)、[訂閱群組](https://appstoreconnect.apple.com/apps/6810727652/distribution/subscription-groups/22374799)，以及 App 導覽中的 App Review。

1. 確認前面必填資料與驗收都完成，發布方式仍是 Manually release this version。
2. 在版本頁點 Add for Review，建立草稿提交；若 Apple 提示缺資料，按提示補完再試。
3. 在年訂閱和群組頁，用 Add for Review 加入同一份草稿，不要分成互不相關的提交。
4. 開啟 App Review／Draft Submissions，確認包含版本 1.0、正確 Build、年訂閱及群組。
5. 最後確認內容，再按 Submit for Review。之後在 App Review 查看進度；若 Apple 提問或要求補件，在該處閱讀並回覆。

**完成標準：** 申請已送出，進入等待審核／審核中狀態。**Add for Review 只是加入草稿，Submit for Review 才是正式送出。**這一節是操作說明，本次沒有代為送審。[App 送審步驟](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)

<a id="step-13"></a>
## 13 Apple 通過後手動發布

**為什麼：** 我們已選手動發布，所以 Apple 審核通過後會等你決定上線時間。審核通過和正式開放下載是兩個動作。

**去哪裡：** [版本 1.0](https://appstoreconnect.apple.com/apps/6810727652/distribution)。

1. 等版本狀態變成 Pending Developer Release（等待開發者發布）。
2. 確認這是要上線的版本、Build 與地區。
3. 準備好後按 Release This Version，再確認發布。
4. 等商品頁生效後，開啟公開 App Store 頁面，確認介紹、圖片、價格及下載入口。

**完成標準：** 預定地區的商品頁可見且能下載。Apple 說明發布後可能需要最多 24 小時才出現在商店，不要因為剛按完還沒出現就重做整個送審流程。[手動發布步驟](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/)

## 目前不用重填的資料

2026-10-17 已確認：App Privacy 已發布 Data Not Collected；隱私權網址、英文 Support URL、Copyright 和審核聯絡資料已填；年訂閱有三語商品名稱、台灣年費 NT$199、首月免費及銷售地區；付費合約、銀行、稅表為 Active。保留這些正確資料，只處理仍缺少或已過期的部分。

目前沒有依據把舊的「Check Again」待辦或其他長期改善項目，一律當成這次上架必改功能。若最終驗收發現實際問題，再決定是否修正及產生新 Build。
