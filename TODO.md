# TODO

- [x] 新增 `Scripts/reset_all_dmg.sh` 與 `Scripts/reset_all_app_store.sh`，依核准順序串接對應版本的 App data、權限、Lookup 重設；沿用既有腳本，不加額外錯誤處理。入口順序測試已先失敗再通過，ResetEntryPoints／ResetAppData／ResetPermissions／ResetLookupDictionary 四組 Shell 測試及 zsh 語法檢查通過，獨立 review 無待修正問題。測試使用替身，未重設實際資料或權限；未改 App 程式碼、未產生 DMG、未 commit。

- [x] 提示 GUI 測試改為分層定位：先以提示卡 ID 找到卡片，再查詢卡片內的 Close／checkbox；移除額外的控制項 ID。多語系排版只查卡片內唯一控制項，不依賴順序或英文標籤。保留關閉目標提示不影響語言提示、另一種提示仍可顯示及啟動後 app.activate() 的檢查。Unit 246 項、Component 202 項、Hint GUI 4 項通過（Build/GUI/Results.Af6nGk/Local.xcresult），獨立 review 無待修正問題。未產生 DMG、未 commit。

- [ ] 完成晃動效果的使用者實測確認：隔離診斷使用正式 Settings presenter，首次開啟、已開啟與關閉後重開均測到兩個選單約 9–9.5 pt 往返位移，介面語言選單不動，Reduce Motion 為 false。2026-10-16 23:30 的 Build App 程序於 23:30:27 啟動，但當次執行檔於 23:30:34 才建好；同時仍執行 Applications 正式版。需結束舊程序後只開最新 Build App 再確認兩個快捷鍵。暫時診斷測試已移除，本次未改 production code、未產生 DMG。

- [x] 未設定完整翻譯語言時，選字翻譯與截圖快捷鍵共用 Settings 提醒入口，只讓來源／目標選單短暫晃動；標籤、底色及提示不動。一般開啟不晃動，重按快捷鍵可再次提醒，遵守 Reduce Motion。Settings 增高 6 pt 以容納分開標籤的原生欄位。通知測試已確認先失敗再通過，完整 Unit 246 項、Component 202 項通過，獨立 review 無待修正問題。選單位移另以單獨 Component 診斷確認；該診斷與大量排版測試並行時會錯過動畫，未納入正式套件。未做實際快捷鍵 GUI／冷啟動驗證，未產生 DMG、未 commit。

- [x] 精簡必填語言提示：固定在 Settings 右側，移除自動換邊與螢幕邊界調整；問號提示獨立顯示，保留原本關閉規則。語言提示沿用精靈、不可關閉，設定完成才消失；48 個語系改為「先設定翻譯語言，再透過快捷鍵翻譯」。保留不支援的已存語言改回「請選擇」的行為，方法更名為 `resetUnsupportedSourceLanguage`／`resetUnsupportedTargetLanguage`，語言比對降至共用 private 方法，同步呼叫端、測試與 spec。兩項提示回歸測試已確認先失敗再通過；完整 Unit 246 項、Component 201 項及 48 份 strings 格式檢查通過，獨立 review 無待修正問題。未做實際 GUI 視覺驗證或母語者校閱，未產生 DMG、未 commit。

- [ ] 全面盤點 App 的錯誤處理架構：檢查各操作入口、非同步工作與 API 呼叫是否有未接住的錯誤，評估如何讓各流程接住錯誤後，統一交由共用處理顯示訊息與記錄 log。釐清 try-catch 能涵蓋的範圍及無法捕捉的崩潰，不假設單一最外層 try-catch 能攔住所有錯誤。定義未知錯誤的通用提示，以及可追蹤、可診斷的紀錄內容（時間、操作、原始錯誤類型與代碼、相關識別資訊），並確認使用者回報問題時如何附上紀錄；避免記錄原文、譯文等敏感內容。先完成盤點與方案討論，再決定實作範圍。

- [x] 翻譯語言首次使用改為來源、目標各自「請選擇」，保留儲存值及明確選過的自動偵測；移除英翻中預設與不支援語言的自動替代。快捷鍵依各自權限→語言設定→功能的順序執行，截圖與截圖內選字不要求 Accessibility；未完成設定顯示 Settings，完成後需重新按快捷鍵。新增不含關閉控制的必填語言提示，與既有提示共用外觀、分開管理狀態。同步 48 個語系、spec 與 Xcode 註冊。完整 Unit 246 項、Component 199 項通過，48 份 strings 格式與新鍵完整性、Xcode 註冊檢查通過；新預設、必填提示與未設定前不讀取選字皆驗證先失敗再通過。獨立 reviewer 複查無待修正問題。未做實際 GUI 操作與母語者校閱、未產生 DMG、未 commit。

- [x] 全部 48 個語系的共用語言提示標題改為「語言設定」（英文 Language settings），提示內文不變。48 份 strings 格式檢查通過，確認每份僅更新標題；未重跑 App 測試、未做畫面與母語者校閱、未產生 DMG。

- [x] 精簡共用語言提示的 48 份語系文案：明確指向「上方的語言設定」，說明其只適用於目前視窗，預設值到偏好設定調整；沿用各語系的選單名稱。48 份 strings 格式檢查通過；本次僅更新文案，未重跑 App 測試、未做畫面與母語者校閱、未產生 DMG。

- [ ] 隔離 Component 的原生選單測試與桌面事件：`test_show_when_appleReturnsDetectedSource_then_displaysItAndAllowsExplicitRetranslation` 在整組重跑時曾因視窗消失而出現 6 個錯誤；程序內注入視窗外點擊可重現相同錯誤，單跑與另兩次整組重跑通過。測試會啟動 AppKit 事件迴圈，且翻譯視窗仍監聽真實滑鼠事件；需改善測試隔離，不改產品正常的視窗外點擊關閉規則。原 Verify 的 Component 明細未保留，無法確認是否同一案例。GUI 原先失敗的焦點／字卡按鈕兩例在停止桌面操作後皆通過（`Build/GUI/Results.fI3Xyb/ImageText.xcresult`）；未重新跑完整 Verify，未產生新 DMG。

- [x] 翻譯與截圖視窗共用一則提示，說明當前視窗的語言變更不會保存為預設，須到偏好設定調整。沿用多 hint 元件及共用永久關閉紀錄，補齊 48 份語系資源與 Xcode 註冊。Unit 240 項、Component 198 項通過；提示缺失測試已驗證先失敗後通過，獨立 code review 無待修正問題。未做實際 GUI 視覺驗證、未做母語者文案校閱、未產生 DMG。既有 Swift concurrency 警告與 Component 桌面事件隔離待辦不在本次範圍。

- [x] 截圖翻譯語言切換採第一版「標籤在上」：兩個選單靠左成組、方向箭頭置中，Hint 在下方；直接共用翻譯視窗的 `TranslationLanguagePicker`，標籤沿用 Settings localization。已清除討論用的三版暫時設計稿。Unit 239 項、Component 197 項、相關 GUI 2 項通過；已檢查一般寬度與 420 pt 窄視窗的實際截圖。深色模式驗證涵蓋翻譯字卡，未檢查整條工具列的深色畫面；GUI 使用模擬翻譯，未驗證 Apple 真實翻譯與語言下載，未產生 DMG。

- [ ] 研究截圖翻譯行為是否能取得著作權保護：針對「截圖後保留原圖，可反覆 hover 單字或選取句子查看翻譯」的流程，查明互動行為、介面設計與程式碼各自可受保護的範圍、是否需要申請或登記，以及是否應另評估專利；以預計上架地區的官方資料為依據，整理既有類似產品與需向智慧財產權專業人士確認的問題。

- [x] 截圖視窗加入與翻譯視窗共用的來源／目標語言選單：放在品牌標題列下、Hint 上方，不加朗讀按鈕；當張截圖獨立設定，切換重翻目前字卡，後續 hover、選字及快捷鍵沿用，新截圖恢復 Settings。完整 Unit 239 項、Component 197 項及新增的 GUI 操作案例通過；GUI 使用模擬翻譯結果，未驗證 Apple 真實翻譯與語言下載流程。

- [x] StoreKit 本機測試暫時一律跳過，移除 macOS／Xcode 版本判斷；保留 `--force` 手動診斷。StoreKit 入口與 Verify 流程的腳本測試通過，未執行真正 StoreKit 測試。

- [x] 統一翻譯、截圖、Settings、權限引導與訂閱視窗的品牌標題列：共用 18 pt 圖示與「Boundless Translator」，移除功能名稱；同步測試的視窗識別。
  - 已整理 `WindowBranding` 降層。Unit 236 項、五種品牌標題列案例及修改的 GUI 案例通過；Component 185／191 項通過。移除品牌修改後，六個 Component 測項仍同樣失敗，截圖 E2E 仍在等待辨識完成時逾時；失敗與品牌修改無關，後續操作尚未驗證。
- [x] 修正六個語言選單 Component 測項：沿用 identifier 與系統公開的值、位置找選單，不再限定 `NSPopUpButton`；保留內容、排列、文字容納與重新翻譯檢查。測試環境由 AppKit 管理原生選單事件，避免程序提早結束。
  - macOS 27.0.1：Component 191 項全數通過，約 53 秒。Production code 未修改；未跑其他測試層級、未產生 DMG。
- [x] 分開驗證翻譯、OCR 與介面語言：OCR 只依 Vision 支援篩選，補芬蘭文、印地文、馬來文圖片；移除缺素材即失敗的測試，介面語言沿用 Unit 並補實際載入檢查。
  - macOS 27.0.1：48 個翻譯方向、25 張 OCR 圖片及 Unit 237 項通過；尚無範例的語言列於測試紀錄。Production code 未修改。
- [ ] 調整截圖 E2E 的辨識等待：三個案例共用的前置流程只等 10 秒；診斷時約 25 秒才完成辨識，之後完整截圖流程通過，同包 App 再次啟動也通過。維持原本功能預期，釐清初始化耗時並訂定合理逾時；正式修正尚未進行。

- [x] 補齊 `docs/ocr-samples/`：依目前 Vision accurate API 回傳的 33 個語言選項，各保留一份 Markdown 與單頁 PDF；新增 26 組，原有七組未覆寫。新增 README 語言代碼對照。新 PDF 已檢查完整排版、缺字與文字擷取；本次未執行 OCR 效能／正確率測試，未改 App、未產生 DMG。

- [x] 33 語言全量 OCR 耗時實測：清除隔離測試 App 的 E5 快取後，以正式 ImageTextRecognizer／Document／Layout 程式依範例清單順序辨識固定 2× PDF 圖片。首輪 3/33 次超過 3 秒：英文 28.141 秒、阿拉伯文 15.775 秒、印地文 13.493 秒；皆有 E5／ANE 編譯採樣，合計產生五組快取。重開測試程序但不清快取，第二輪 0/33 次超過 3 秒，最慢 0.616 秒，未新增快取。0.5 秒門檻首輪 8 次、第二輪 5 次。66 次皆完成且兩輪像素雜湊一致；只驗證非空結果與耗時，未驗證全文正確率。報告：`/private/tmp/boundless-ocr-causal/all-33-results.md`。未操作 GUI 截圖、未清真實 App 資料／權限、未修改 App、未產生 DMG。

- [x] 五組 OCR 快取覆蓋實驗：清隔離測試 App 快取，英文／阿拉伯文／印地文分別 27.938／15.637／13.490 秒並產生五組 E5 快取，三次皆採樣到 E5／ANE 編譯。再跑 33 個語言選項、字級／尺寸／旋轉／深底等 280 張固定圖片，重開程序反序重跑，共 560 次全部低於 0.682 秒；五組快取所有十個檔案的雜湊、大小與修改時間均未變，逐張像素配對一致。支持五組快取覆蓋本批測資，不證明所有未來輸入不會再編譯；未測跨 OS／硬體及快取失效。馬拉地文短段落兩輪皆回傳空文字，故非辨識正確率通過。報告：`/private/tmp/boundless-ocr-five-cache-probe/README.md`。未改 App 或提示文案、未清真實資料／權限、未產生 DMG。

- [x] 改善截圖 OCR 等待體驗：辨識超過 0.5 秒才在圖片區中央顯示系統轉圈圈與「正在準備辨識模型…」，完成、失敗、換圖或關窗即移除。沿用系統 glass／material，不變動語言工具列、提示列、原圖及 OCR 演算法；不做啟動預熱，也不宣稱只有首次會慢。後續 Preview／VisionKit 對照調查結果如下。
  - 交付確認：使用者已核准提交，範圍包含等待提示與 48 語系、測試專案引用、Component 測試、33 組 OCR samples、獨立 reset OCR 腳本與文件；暫時計時 log 已清除。Unit 246／Component 207／GUI 15／E2E 4 項皆有通過紀錄；Component 曾有一項語言選單案例首輪失敗，單獨及完整重跑皆通過，原因仍未確認。最後清理僅重跑 Unit、Component 與 reset OCR Shell 測試；未產生新 DMG。Build 49 測試說明以 Build 48 為基準，只列使用者可驗證的等待提示行為。
  - [x] 移除調查用 OCRTiming log、計時變數、logID 參數與 OSLog import；ImageTextRecognizer 已恢復至 HEAD 的原始辨識實作。依 Coding Principle 檢查等待提示、視窗生命週期、reset 腳本與測試專案引用，未發現需增加抽象或重構的問題。Unit 246 項、reset OCR Shell 測試通過；Component 首輪有一個語言選單案例失敗，單獨重跑及完整重跑 207 項皆通過，首輪失敗原因尚未確認。紀錄：`/private/tmp/boundless-ocr-cleanup-{unit,component,component-retry,component-confirm}.log`。未重跑 GUI／E2E、未重設資料或權限、未產生 DMG、未 commit。
  - [x] 依確認結論更新等待文案與全部 48 個語系，沿用 0.5 秒顯示條件；這是等待文案，不是新增編譯狀態偵測。Strings 格式、Unit 246 項、Component 207 項及 diff 檢查通過。未執行實際 App 畫面驗證、未產生 DMG；等待使用者測試 review，再連同 OCR samples、reset OCR 腳本提交，目前未 commit。
  - [x] 修正 GUI／E2E 測試建置遺漏：CursorTestHost 使用 ImageTextView，卻未把 ImageRecognitionProgressView 加入 Sources，兩層原先皆在編譯階段失敗、0 個案例執行。補上測試專案引用後，GUI 15/15 通過（`Build/GUI/Results.1Uu46p/`）；E2E 3/4 通過（`Build/E2E/Results/Features.xcresult`）。本輪未改 production code、未重設權限、未產生 DMG、未 commit。
  - [x] 使用者表示已授權 E2E Runner 後，重跑完整 E2E，4/4 通過；外部編輯器的 Accessibility 取字與複製取字兩種流程皆通過。上輪附件確認曾停在「允許輔助使用」，本輪未再出現；尚未確認 macOS 對 Runner 與 App 的授權歸屬，不能據此斷言必須另外授權 E2E App。紀錄：`/private/tmp/boundless-e2e-after-permission.log`；報告：`Build/E2E/Results/Features.xcresult`。本輪未改程式或測試、未重設權限、未產生 DMG、未 commit。
  - [x] 唯讀核對 DMG App 現有五組 E5 快取：引用系統 TextRecognition 的 orientation、td、latincyrillic、arabic、devanagari 模型。模型名稱與系統來源路徑已確認；個別功能依名稱推斷，完整字元涵蓋與內部選模規則仍未確認。五組快取不代表全套 OCR 只有五個模型，也沒有證據支持隨使用者辨識字集擴大而重新訓練模型。 進一步列舉目前系統 TextRecognition Resources：共有 27 個頂層 mlmodelc 模型套件，其中名稱帶 _e5 的正好五個，與 App 五組快取相符；另有 cj、korean、thai 等非 E5 命名套件。這是該目錄的完整盤點，不代表整個系統或所有執行路徑的模型全集，也不保證五組快取足以消除所有後續延遲。
  - [x] 完成 Vision／VisionKit 最小程式對照，共 84 次、七篇文章、逐張像素雜湊一致。Vision 清獨立快取兩輪皆重現日文與越文約 13～22 秒等待及 E5／ANE 編譯；VisionKit 同機三輪均低於 0.8 秒，實際透過 `mediaanalysisd` 執行。Preview 既有紀錄與匯入符號也確認使用 VisionKitCore／同一系統服務。未清除系統服務快取，不能宣稱 VisionKit 全新系統首次也不會慢。公開 ImageAnalysis 缺少目前自訂 hover／選字所需的文字座標，不能直接替換並保留完整操作；尚未實作替代方案。原始碼、紀錄與驗證：`/private/tmp/boundless-ocr-api-comparison/README.md`。本輪未改 production code、未清真實資料／權限、未產生 DMG。
  - [x] 完成獨立 OCR 因果調查：兩輪清除隔離快取後，先辨識英文與一般繁中，再處理兩張大字繁中圖片，皆新增阿拉伯／天城文字命名的模型並等待約 13～15 秒；同圖立即重跑低於 0.3 秒。採樣確認等待在 E5／ANE 編譯；相同像素明確指定繁中後為 0.231／0.143 秒且未新增模型。使用者既有十次慢速紀錄皆有超過 99% 時間在 Vision 並與 ANE 編譯重疊。最小 Apple API、新 API、CPU／GPU 等對照未排除初始編譯；未找到造成此延遲的明確 API 誤用，內部選模規則仍未知。證據與重現驗證：`/private/tmp/boundless-ocr-causal/README.md`。本輪未改 production code、未重設真實資料／權限、未產生 DMG。
  - [ ] 另行評估 OCR 取消傳遞：實際 ImageTextView 暫時 Component 實驗通過；快速換圖並取消後，八個 detached OCR 工作仍全部執行，最後結果等待 2.568 秒。此問題與沒有重疊請求的模型編譯延遲分開處理；本輪僅記錄，未修正。
  - 2026-10-17：補齊 48 個語系、Xcode source 註冊與規格；新增 5 個 Component 測試，涵蓋快速完成、慢速完成／失敗、換圖與提示出現前後關窗。先驗證未實作時失敗，再驗證實作後通過。完整 Component 首輪 4 個新增案例因 3 秒測試等待上限遇到主執行緒排程延遲而逾時；只將測試上限調成 120 秒，產品門檻仍是 0.5 秒。最終 Unit 246 項、Component 207 項通過，獨立 agent review 無待修問題。未跑 GUI／E2E、未驗證正式 App 的實際玻璃外觀、未產生 DMG。
  - [x] 2026-10-17 重新核對 Apple OCR 官方用法並做正反順序對照：未找到 `VNRecognizeTextRequest`／同步 `perform`／accurate＋自動判斷語言的明確誤用。沿用 production 辨識程式、固定 PDF 圖片及隔離快取，日→韓→繁中→越→法→英與反序各清快取兩輪，共 48 次。日文優先為日文 13.963／14.255 秒、越文 13.050／12.840 秒；英文優先只有英文 26.566／26.584 秒，其餘皆低於 0.6 秒；不清快取重跑亦皆低於 0.6 秒。慢次數與新增快取對應，不能以每種語言首次使用解釋；本批圖片未重現使用者的繁中慢或阿拉伯／天城文字路由。原始資料：`/private/tmp/boundless-ocr-order-check/`。未修改 production code、未重設真實資料或權限、未產生 DMG。
  - [x] 2026-10-17 自動化控制實驗：以現有辨識程式及獨立暫存 home／模型快取重跑，未操作桌面、重設權限或修改正式辨識流程。兩輪「清快取→同圖辨識兩次」日文為 15.656／0.542、15.391／0.526 秒；僅刪拉丁模型，英文為 14.460／0.183 秒；僅刪方向模型，日文為 14.354／0.539 秒；僅刪天城文字模型，固定印地文為 13.690／0.047 秒。模型分別按需編譯，並非整個 OCR 只初始化一次；新程序可沿用已準備的快取。
  - 同尺寸日文→韓文→繁中皆快，接越文新增拉丁模型而等待約 14 秒；改成英文先辨識則首次 29.372 秒，後續日／韓／越文皆快。韓文字級加倍未變慢；只增加畫布空白曾新增天城文字模型並等待 14.211 秒，但下一輪未再次觸發，不能宣稱已找出 Apple 模型選擇的確切規則。使用者 07:07 的 Build App 紀錄也分別建立方向／文字偵測、拉丁／天城文字模型，與兩次慢速時間相符。實驗與原始紀錄暫存於 `/private/tmp/boundless-ocr-investigation/`；當輪尚未實作提示 UI，也未產生 DMG；後續採中央延遲提示，未採預熱。
  - [x] 暫時在 `ImageTextRecognizer.swift` 直接加入 `[OCRTiming]` 系統 log：每次辨識用 UUID 對應開始、準備、Vision、座標整理、選字資料建立、結束及總耗時，只記尺寸與數量，不記原文。已撤掉計時元件、專用測試、Xcode 設定與視窗流程改動。Unit 246 項、Component 202 項通過，已從系統 log 回查完整紀錄；尚待使用者多語言實測。計時僅涵蓋辨識函式，不含背景排程、畫面套用或翻譯，也不新增取消行為。查詢：`/usr/bin/log show --last 30m --style compact --predicate 'eventMessage BEGINSWITH "[OCRTiming]"'`。未 reset 真實資料、未產生 DMG。
  - [x] 新增 `docs/ocr-samples/` 測試文章：英文、繁中、日文、韓文、法文、越文、泰文各自一份單頁 PDF 及 Markdown 原文，移除合併檔。每篇約 1,000～2,000 字元，統一 A4 尺寸與內文 12.5 pt，供手動比較不同語言的辨識等待。七頁已逐頁檢查排版、文字提取及完整容納，拆檔後確認每份僅一頁且文字與原頁相同，尚未用這批素材測量 OCR 耗時。使用者另觀察到慢速不固定發生在首次，後續提示不能宣稱只有第一次會慢。
  - 已將 [TRex 與 MindClip 的官方更新紀錄](docs/product-support.md#macos-27-圖片文字辨識問題)合併至上線用支援文件，能佐證相似症狀；尚未找到 Apple 官方確認，不能宣稱已證明 Boundless 的故障原因。
  - macOS 27.0.1／Xcode 26.6：OCR 元件 7 組圖片通過；GUI 首次等待辨識逾時。診斷視窗辨識耗時 28.43 秒，採樣顯示 Apple 正在編譯辨識模型；完成後重開，同圖辨識 0.18 秒，hover、拖曳選字及字卡 GUI 通過。正式 App、朋友案例及 Preview 是否同因尚未確認；暫時診斷程式已移除。結果：`Build/GUI/Results.sVI5Sl/`。
  - 2026-10-17：未執行 reset，將現有 `ImageTextRecognizer`、`ImageTextDocument`、`ImageTextLayout` 編成暫時診斷程式，辨識 `basic-text.png`；第一次 29.265 秒、後兩次 0.095／0.050 秒，重新啟動同一程式後 0.171／0.049／0.049 秒，六次文字與詞框檢查均通過。04:03:33–04:04:00 的系統紀錄顯示 ANECompilerService 編譯模型，結束後取得辨識結果；已重現首次延遲，未重現永久無文字。
  - reset 稽核：`Scripts/Reset/reset_app_data.sh` 刪除指定 bundle 的整個 container Data，包含 Apple 在 App 內建立的 `Library/Caches/<bundle>/com.apple.e5rt.e5bundlecache`；權限重設指定 bundle 的 Accessibility／ScreenCapture；Lookup reset 停止共用 `LookupViewService` 並刪除 `FTE/Lookup*` 首次使用紀錄。
  - E2E 實測：固定同一個已建置的 App、同一張 `SCREENSHOT SAMPLE`，六組皆正確取得文字。重設前兩次 4.372／4.276 秒；完整重設第一輪 30.401／4.183 秒、第二輪 30.259／4.194 秒；單獨 Lookup 重設 4.300／4.273 秒；單獨 App data 重設 29.285／4.284 秒；只刪除上述模型快取、保留設定及權限，37.337／4.193 秒。時間包含截圖操作與 XCTest 輪詢，不是純 OCR API 時間。已確認「正常 → reset → 變慢 → 恢復 → 再 reset → 再變慢」，不是僅觀察第一次慢。
  - 原因：完整 Data 清除連帶移除 App 的 Apple 辨識模型快取。首次截圖時 `VNRecognizeTextRequest` 等待模型重新編譯；重設後程序採樣包含 `TextRecognition → Espresso E5CompilerImpl::CompileInternal`。完成前 `ImageTextView` 的 document 為空，因此暫時不能選字；本次測到的是延遲後成功，不是辨識回傳錯誤或永久失敗。尚未更改 reset 的清除範圍、辨識策略或等待中的 UI。
  - 證據保留在 `Build/OCRReset/`：六組 `boundless-ocr-*.log` 與 `boundless-ocr-reset1-sample.txt`；當時使用暫時 E2E 診斷案例，全部跑完後移除，既有測試及 production code 未修改。未產生 DMG。
  - [x] 新增獨立 OCR 模型快取清除入口 `Scripts/reset_ocr_cache_dmg.sh`、`Scripts/reset_ocr_cache_app_store.sh`；共用核心 `Scripts/Shared/reset_ocr_cache.sh` 也支援 `e2e`。僅關閉對應 App 並刪除其 `com.apple.e5rt.e5bundlecache`，保留設定、權限及 Lookup；原本完整 reset 不變。ResetOCRCache、ResetEntryPoints、ResetAppData 三組 Shell 測試通過，使用替身未清除真實資料；未修改 App 程式碼、未產生 DMG。載入提示與啟動預熱尚未實作。
- [ ] 依官方文件整理 macOS 支援清單與功能限制，同步 README、Support 與 App Store 說明；實測結果另記，不混入官方支援判斷。
  - 已核對建置設定與 API：最低 macOS 15、僅支援 M 系列晶片；已建立並部署 `macos-compatibility` skill。對外說明尚未更新。
  - 已整理 [上線用系統與語言支援資料](docs/product-support.md)：介面列 34 組語言（含地區版本共 48 個語系），圖片辨識收進截圖翻譯說明；翻譯與辨識依使用者的 Mac 提供。附 macOS 27 回報及 Vision 新舊介面說明；換新版不列為上線前必改。對外文件同步尚未完成。

- [x] E2E 分成四個獨立案例：選字翻譯、截圖翻譯、切換 App、重新開啟 Settings；兩種外部編輯器共用一次啟動，截圖流程止於快捷鍵開啟翻譯視窗。修正第二次選字前未切回編輯器 App 的測試操作；production code 未修改。
  - 四個 E2E 全數通過，案例共約 64 秒；E2E／GUI 入口腳本測試、Xcode 專案檢查及另一個 agent 審閱通過。同步測試工作流：production code 跑 Unit、Component，只改測試則跑修改的層級。未跑完整 Verify、未產生 DMG。
- [x] 截圖 hover E2E 改用單次 XCUITest `hover()`，移除手動滑鼠事件；單一案例通過並經另一個 agent 審閱。App 程式碼未修改，單筆 CGEvent 失敗的原因尚未確認。
- [x] Unit、Component 各跑一輪並共用建置結果；刪除訂閱編譯設定的 Unit 測試，改由 App Store 建置腳本檢查，未啟用訂閱限制時停止建置。其他 Verify 階段不變。
  - Unit 236 項、Component 190 項、兩個受影響的腳本測試群組與 Xcode 專案檢查通過；實際 App Store 設定查詢及另一個 agent 審閱通過。未執行 App Store archive、完整 Verify 或產生 DMG。
- [x] 精簡重複測試：App 切換由三輪改成一輪，合併 E2E 首次拖曳選字與翻譯檢查；GUI 保留兩組外觀，刪除重複的 12 組截圖案例及跳過設定。Production code 未修改。
  - Unit 237 項、Component 188 項（各兩種模式）、GUI 入口腳本測試與修改的 E2E 通過。游標案例補上焦點前置條件，在另一個 App 取得焦點後執行通過；移除診斷後的最後一次 GUI 驗證已中止，未完成全組驗證。
- [x] 整理測試名稱與位置：字典重設測試改名、7 個測試搬到對應模組、GUI 共用 App 目錄改名，移除 E2E 的 DMG 層；同步引用並跑完整 Verify。
- [x] 新增 `Scripts/reset_lookup_dictionary.sh`：直接清除首次提示紀錄，保留其他設定，不備份；已在測試 Runner 外執行並重現首次提示。
- [x] 將 Build App 入口移至 `Scripts/build_dmg_app.sh`，同步更新發布、E2E、文件路徑及 `BuildDmgAppTests.sh` 測試入口；建置行為不變。
- [ ] 調整截圖翻譯與選字翻譯的字典定位：以書本圖示為定位依據，優先在上方顯示並保留圖示可見；先實測 Apple API 的定位限制。
- [x] 查字典期間保留選字翻譯的書本按鈕：更新按鈕前沿用 `WindowPresentationState`，附屬視窗開啟時暫停自動顯示更新，關閉後恢復原有焦點、選取與捲動規則。新增 Component 測試覆蓋保留與恢復；Unit 237 項通過，Component 初跑另有一個翻譯視窗案例失敗，單獨及整組重跑皆通過（192 項）。未執行原生字典 GUI 驗證、未產生 DMG。
- [ ] 全盤檢查 UI 事件處理：找出滑鼠追蹤、游標、焦點與視窗關閉中，用額外判斷、旗標或 override 補救自訂行為的地方，包含本次截圖字卡修正。逐項確認能否沿用系統或既有元件的行為，列出應移除、修正或保留的做法及理由。
- [x] 修正首次查字典按「繼續」後翻譯視窗消失：翻譯視窗與截圖字卡共用 AppKit 附屬視窗狀態，暫停自動關閉與字卡替換，結束後恢復原本行為；移除手動旗標。
  - Unit 237 項、Component 190 項（各兩種模式）、2 個 Lookup GUI 案例與 Xcode 專案檢查通過。兩個 GUI 案例各自重設字典後驗證首次提示，並確認關閉字典後恢復操作；實測截圖存於 `Build/LookupReview/`。其他 Apple 提示未做實際操作驗證；未重建 Build App、未產生 DMG。
- [x] 修正截圖翻譯中，hover 單字或選取文字後，滑鼠向上移至字卡時觸發下層文字事件，導致字卡消失的問題。 改由字卡面板接收自身事件，移除截圖多餘的滑鼠事件註冊與跨視窗判斷。

- [x] 功能介紹素材集中至 `docs/feature-showcase/`：還原暫存內容，移入示範 PDF、來源截圖與背景參考圖，更新目錄說明及引用。
- [x] 使用者確認 Settings、選字翻譯與字典功能介紹排版，最新成圖已整合至正式 output。
- [x] 審查 Glass／Space Gray 共十二張正式成圖的文案、畫面與上傳格式：皆為 2560 × 1600；截圖翻譯圖的 Alpha 通道及「Hover a word」用語問題已修正。
- [x] 產出六張 `-Update` 比較圖及對應 HTML：兩種主題的 Settings 從原始截圖等比例縮小 10%，四張截圖翻譯改為「Hover over a word」；Update PNG 均無 Alpha 通道、重製零像素差異。十二張原圖已恢復並逐位元組確認與修改前相同。
- [x] 將使用者確認的六張 Update 圖及對應 HTML 升為正式版，移除比較檔與專用入口；簡化兩種主題的成圖檔名，選字與截圖翻譯均保留編號及情境名稱：截圖使用 `02-screenshot-1-cant-select.png`、`02-screenshot-2-general.png`，同步產圖程式、文件與預覽引用。十二張正式圖重製零像素差異、無 Alpha 通道，檔案引用檢查通過。
- [x] 字典功能介紹採石墨灰情境標籤與柔和底色，使用 `dictionary_selected_text.jpg` 與 `dictionary_screenshot.jpg`；保留書本 icon、完整查詢文字及字典視窗，選字翻譯視窗左緣對齊小標題。可編輯來源在 `docs/feature-showcase/layouts/`。
- [x] 截圖功能介紹採暖金框、圖外 Take a screenshot 灰色小標題、中央精靈與石墨灰情境標籤；Can’t select it 第一頁、General 第二頁。已確定使用完整光束。
- [x] 截圖功能介紹確定使用完整光束；刪除 Glass／太空灰共四張短光束成圖與專用產圖邏輯，同步預覽索引及文件。
- [x] 選字翻譯採 VS Code 第一頁、Preview 第二頁的同尺寸自然構圖，不放精靈，暖黃短斜直箭頭由左上指向右下。保留 Mac 選單列、App 工具列及完整翻譯視窗。
- [x] 準備 VS Code 截圖用 README：`docs/feature-showcase/assets/demos/vscode/README.md`，沿用 PDF 的兩句文案。
- [x] 清理功能介紹歷次試稿與根目錄重複截圖；只保留最新成圖、必要原始素材、可編輯排版與共用產圖腳本。目前直接以石墨灰 HTML 排版產圖。
- [x] 更新選字翻譯示範 PDF：`docs/feature-showcase/assets/demos/boundless-selected-text-demo.pdf`，採用確認的兩句文案、12 pt 同字級，維持 960 × 540 pt 頁面、縮短上方留白及句距；已替換舊版並檢查排版與文字。

- [x] 完成截圖翻譯收尾：更新 GUI 舊文案、三語 Support、README、示範文件與規格；同步 StoreKit 驗證例外。移除 hint 多餘的快捷鍵參數與顯示條件，保留截圖選字後按快捷鍵翻譯；Help 字典圖示改用共用來源。
  - 文件經另一個 agent 審閱。Unit 237 項、Component 188 項（各兩種模式）與 Hint GUI 4 項皆通過。未重建 Build App、未產生 DMG、未發布 Support。

- [x] 同步 48 個語系的 Help 截圖翻譯說明：保留截圖快捷鍵，沿用新版 hint，移除選字快捷鍵與圖示操作說明；刪除多餘的格式化參數並更新既有測試。經另一個 agent 審閱，尚無母語者校閱。48 份語言資源格式及與 hint 一致性檢查、Unit 237 項與 Component 188 項（兩種模式）皆通過；未做實際 UI 驗證、未重建 Build App、未產生 DMG、未 commit。

- [x] 縮短 48 個語系的截圖翻譯 hint：明確說明滑鼠停在單字上或選取文字查看翻譯，簡述朗讀原文與字典功能，移除快捷鍵及圖示操作說明。全部語系經另一個 agent 依 concise-writing、humanizer-zh-tw、no-ai-slop 審閱並複查套用內容；尚無母語者校閱。同步更新既有文案測試與規格。48 份語言資源格式檢查、Unit 237 項與 Component 188 項（兩種模式）皆通過；未重建 Build App、未產生 DMG、未 commit。

- [x] 2026-10-07 發布字體調整版本：`54389fd` 已提交；App Store 1.0（Build 41）封存、驗證與上傳成功，Apple 後續處理及正式上架尚未確認。DMG 已完成公證與安裝後啟動驗證：`Build/Boundless Translator DMG Test.dmg`。StoreKit 依專案例外未驗證，其餘 Verify 項目全數通過。

- [x] 同步 AGENTS.md／CLAUDE.md：Verify 除 StoreKit 外，其餘項目全部成功即視為通過。

- [x] 翻譯視窗的原文與譯文改用系統介面字體，保留原有預設大小與一般粗細；截圖字卡不變。
  - 驗證：Unit 237 項、Component 188 項，兩種模式皆通過。既有第五行字典測試因新字體行高而超出可見範圍，僅調高該案例的測試視窗後通過，未修改字典功能。
  - 2026-10-07 完整 Verify：Unit、Component、Scripts、GUI（13 項）、E2E（6 項）、Languages、Release 通過；StoreKit 因既有環境規則跳過，整體為 7 通過、0 失敗、1 跳過，回傳非零。另以 `--force` 跑 StoreKit，5 項皆在 Apple `SKTestSession.buyProduct` 回傳 `unknown`；系統記錄購買成功但未回傳預期的交易 JWS，尚未釐清環境故障根因。驗證期間未修改程式碼或測試。使用者已確認 StoreKit 為目前驗證例外；其餘 7 項通過，本次 Verify 視為通過。
  - 本次 DMG 已完成公證、安裝後啟動驗證：`Build/Boundless Translator DMG Test.dmg`。Build 根目錄的獨立 App 未重建；未另做字型視覺驗收。

- [x] 玻璃浮條改版：移除紙頁版與樣式切換；單一原生玻璃形狀包含指向原文的尖角，調整譯文比例、間距及淡色染色。
  - 驗證：尖角空間回歸測試先失敗、修改後通過；Unit 237 項、Component 188 項，兩種模式皆通過；單獨執行截圖 GUI 群組 9 項通過，已檢查深淺外觀 × 白／黑／彩色背景 × 長短文共 12 張實際 UI 截圖。先前與 Component 同跑的 GUI 因游標失敗而中止，分開重跑全組通過。已重建 `Build/Boundless Translator DMG Test.app`；macOS 15 備援材質未實測，未跑完整 Verify、未產生 DMG、未 commit。

- [x] 截圖字卡雙樣式比較：玻璃浮條、紙頁註解，共用翻譯與按鈕行為；開發版字卡空白處右鍵選單即時切換並記住選擇。修正切換容器的排版模式，以及進入字卡後仍執行先前 hover 的問題。
  - 驗證：Unit 237 項、Component 185 項，兩種模式皆通過；截圖 GUI 群組中 8 項通過，樣式切換失敗修正後單獨重跑通過，再重跑 4 個受影響操作案例通過。已檢查兩版 × 深淺 × 長短文的 8 張測試 App 截圖。已重建 `Build/Boundless Translator DMG Test.app`；第三版未實作，未跑完整 Verify、未產生 DMG、未 commit。

- [x] 截圖字卡外觀：短詞縮窄、上方譯文區高於功能區、通欄細線、文字對齊圖示左緣；保留 17／16 pt 圖示與 28 × 28 pt 點擊範圍，淡化按鈕底。
  - 驗證：Unit 237 項、Component 182 項，兩種模式皆通過；朗讀與字典操作的 2 個 GUI 案例通過。已檢查測試 App 的短詞／長文深淺外觀截圖，臨時拍圖程式已移除。未重建 Build App、未跑完整 Verify、未產生 DMG。

- [x] 修正截圖字卡游標：按鈕顯示手指、譯文顯示 I-beam，移到空白處恢復箭頭。補上連續切換的 Component 回歸測試及實際滑鼠 GUI 測試。
  - 驗證：修正前回歸測試失敗、修正後通過；Unit 237 項、Component 183 項，兩種模式皆通過；游標切換與按鈕操作 2 個 GUI 案例通過。未重建 Build App、未跑完整 Verify、未產生 DMG。

- [x] 調整截圖翻譯字卡：譯文在上、細線分隔功能區，等大按鈕靠左並與文字對齊；hover 單字加灰色底，選字保留原底色。同步更新截圖 hint、問號說明及既有語系。
  - 驗證：Unit 237 項、Component 182 項，兩種模式皆通過；4 個相關 GUI 案例通過，最後調整按鈕後重跑字卡操作通過。已檢查實際字卡與 hint 截圖；修正 GUI 長文查詢及字典按鈕高度。未跑完整 Verify、未產生 DMG。

- [x] 截圖內 hover 單字與選取文字共用快速翻譯字卡：左側圓形按鈕朗讀原文，右側共用書本圖示開啟 Apple 字典。保留雙擊、拖曳、複製與快捷鍵；文字上為 I-beam、空白處為箭頭。字卡優先放上方，長文可捲動，沿用分段翻譯、取消與重試。原翻譯視窗不變。
  - 驗證：Unit 237 項、Component 180 項，兩種模式皆通過；7 個相關 GUI、4 個截圖 E2E 及 Xcode 專案檢查通過。E2E 曾因截圖前置操作未完成失敗，保留錄影並單獨重跑通過。已檢查深淺外觀、短字、長文與捲動截圖；拍圖用的暫時測試已移除。未實測 macOS 15、Apple 原生選語言與下載視窗；未跑完整 Verify，未產生 DMG。

- [ ] 補齊 macOS App 選單、精靈選單與「關於」視窗（先確認設計，再實作）：
  - 左側：App 在前景時，在 Apple 選單右邊顯示 Boundless Translator 選單，沿用系統的「關於、設定、服務、隱藏、隱藏其他、顯示全部、結束」項目與順序；操作說明及 Support 放在「輔助說明」選單。
  - 右側精靈：作為使用其他 App 時的快捷操作，保留設定、訂閱（適用版本）與結束，補上關於及 Support；評估加入截圖翻譯。Apple 沒有要求固定清單，不照搬 Xnip 的評分、網站等項目；重要功能不能只能從右側開啟，因為圖示可能被系統隱藏。
  - 關於視窗：顯示 App 圖示、名稱、版本與 Build、版權，以及 Support／隱私權連結；左右選單開啟同一個視窗，版本沿用 App bundle 資料。
  - 目前 App 使用 `LSUIElement` 與 `MenuBarExtra`；實作前確認顯示左側選單對 Dock、前景切換及翻譯視窗焦點的影響。參考 [Apple 選單列規範](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)。

- [x] 清理 Build 中現行流程不再使用的 121 項舊產物（約 17.6 GiB）：120 項刪除，含系統收據的 StoreKitVerification 移至垃圾桶。保留現行 DMG／App、GUI／E2E 產物與 App Store 發布紀錄；已確認舊路徑移除，未執行測試或重新建置。

- [x] 問號操作說明右下角以次要灰色顯示可複製的 `Version 1.0 (40)`，版本與 Build 編號從 App bundle 讀取；三語 Support 頁補上查詢位置。Unit 234 項、Component 161 項，兩種編譯模式皆通過；未做實際 UI 驗證，未產生 DMG，Support 尚未發布。

- [x] 更新英文、繁中、簡中 Support 頁：移除過時的原況文字操作，補上預設快捷鍵、自動偵測、語言資源與截圖辨識限制，保留權限、訂閱及聯絡方式。已核對三語內容與既有連結；尚未發布。

- [x] 2026-10-06 執行 App Store 發布入口：1.0（Build 40）封存、驗證與上傳成功；Apple 後續處理及正式上架尚未確認。

- [x] Apple 回傳使用者取消時，關閉本次翻譯視窗，不再保留待命提示；區分一般工作取消，忽略舊請求的取消結果。使用者實測確認正常。
  - 2026-10-06 驗證：Unit（234 項 × 2）、Component（160 項 × 2）、Scripts、GUI（8 項）、E2E（5 項）、DMG 公證與安裝後啟動驗證通過。啟用 Apple Intelligence 並等模型準備完成後，重跑語言測試，44 個翻譯方向、22 項 OCR 及測資完整性檢查全部通過；驗證期間未修改程式碼。StoreKit 仍依既有環境限制跳過，不算完整 Verify 全數通過。DMG：`Build/Boundless Translator DMG Test.dmg`。

- [x] 翻譯視窗的附屬面板開啟時，暫停外部點擊與切換 App 的自動關閉；面板結束後恢復原有行為。Unit 234 項、Component 157 項，兩種編譯模式皆通過。使用修改後的視窗元件實測 Apple 原生面板：`chat` 選英文後顯示「聊天」，視窗保留。尚未實測語言下載面板、獨立系統視窗與 macOS 15；未產生 DMG。

- [x] Verify 結尾列出各層 PASS／FAIL／SKIPPED 及總數；已用腳本測試驗證全部通過、失敗及跳過情況，維持失敗或跳過時回傳非零。

- [x] 完成截圖語言限制 Hint、空結果 Alert 與多 Hint 排版：截圖照常開啟，辨識成功但沒有文字時顯示一次原生 Alert；來源設定不支援時，限制 Hint 排在教學 Hint 上方。各 Hint 統一使用既有精靈圖示。各自管理關閉紀錄，關閉不改變圖片尺寸與選取。行為已整合至 `spec.md`，移除暫存清單。
  - 驗證：Unit 238 項、Component 153 項，兩種編譯模式皆通過。本次未跑 GUI／E2E，也未產生 DMG。

- [ ] 【待討論】統一翻譯與截圖視窗的操作：目前翻譯視窗點擊外部會消失，截圖視窗則會保留。評估兩者是否都採用「未釘選時點外部隱藏、釘選後保留」，讓操作更一致、方便；並討論是否共用視窗 layout／框架及圖釘控制。先確認使用體驗，再決定實作。

- [ ] 【目前】釐清各功能的語言支援範圍：選字翻譯與截圖辨識依使用者 Mac 當下的 API 能力，App 介面依內含語系；區分翻譯來源、目標與 OCR 限制，不要求三者一致，也不維護逐版 macOS 語言表。核對 App Store 與功能介紹的宣稱，產出支援表及付費前查詢支援範圍的呈現建議。本階段先釐清範圍，不實作新的介紹或購買介面。
  - 呈現方式已記於 [語言支援說明](docs/language-support.md#user-facing-language-lists-planned)；對外文件與 App Store 宣稱尚待同步。

- [x] 完成這次語言支援實測：macOS 26.5.2 啟用 Apple Intelligence 並補齊傳統語言包後，44 個翻譯方向、22 種 OCR 固定圖片及測資完整性檢查全部通過。完整範圍、模型條件與驗證界線記於 [語言支援資源表](docs/language-support.md)。

- [x] 建立可獨立執行的語言支援測試與固定資料，放在 `Tests/LanguageSupport`；由獨立入口與完整 Verify 執行。已用錯誤預期文字確認 OCR 測試會失敗，並還原資料。

- [ ] 修正語言測試未就緒時的提示：區分個別語言包與 Apple Intelligence 準備條件，不再對所有 supported 但未安裝的語言一律要求下載語言包。

- [ ] 【之後再處理】研究 OCR 精準選取單一字母／字元的做法：涵蓋 App 支援的所有語言，考慮組合字元、閱讀方向與混合語言。評估字元定位精度、辨識品質、效能及維護成本，先驗證可行性，再決定是否調整或替換辨識引擎。

- [ ] 改善截圖 OCR 將介面圖示當成文字的情況：先檢查箭頭、勾選等圖示實際回傳的字串與信心分數，再制定過濾規則。過濾孤立且無翻譯用途的圖示結果，保留各語言文字、數字、標點及文句中的有意義符號；不能直接刪除所有符號或只保留英文字母。選取、複製與翻譯使用同一份過濾結果，過濾後沒有文字時沿用現有 Alert。補上純圖示、圖示混文字及多語言內容的測試，確認不誤刪有效內容。

- [x] 修正拉動翻譯視窗外側邊緣時被誤判為點擊外部、清空內容的問題，字典提示隨原文欄位變寬；同一個真實縮放測試已先失敗再通過。

- [x] 翻譯視窗經使用者縮放後，後續譯文與提示更新維持使用者尺寸；快速測試驗證原文與譯文重排、保留選取，GUI 測試驗證連續拉寬、拉高及提示關閉後仍可操作。

- [x] 修正 OCR 將段落的畫面折行直接傳給翻譯：合併相鄰對齊的段落行，保留段落間隔與分散標籤的換行，並驗證文字選取與中英文連接。

- [ ] 調查重新開啟 App 時，未關閉的截圖視窗跟著 Settings 移到目前桌面的問題：保留截圖視窗，切到另一個桌面／全螢幕空間後重新開啟 Boundless，會把 Settings 與截圖視窗一起帶過來。使用者記得先前已修過，需確認是否復發及預期的視窗行為。

- [x] 修正截圖翻譯一次、切換 App 再回來後，第一次拖曳無法選字、選字後翻譯只發出警告音的問題；E2E 保留首次拖曳選字、已選文字的快捷鍵翻譯，以及重新開啟 Settings 後立即取得鍵盤焦點的檢查。

- [x] 完成截圖選字元件整合：以 Apple Vision 辨識文字，由 Boundless 管理選取、游標與焦點，保留圖片原貌並支援空白起拖。只有整詞座標時，拖曳局部也選取完整單字。已通過 Verify 的可執行檢查、44 項 GUI／E2E 測試及 DMG 公證驗證；5 項 StoreKit 測試仍依既有環境限制跳過。

- [x] 完成本次測試精簡：GUI 由 48 個縮減為 8 個；截圖相關保留 4 個 GUI 與 3 個 E2E，其餘選取／排列／OCR 與元件狀態由 Unit／Component 覆蓋。GUI 執行時間由約 9 分 22 秒降至 3 分 26 秒，不含建置。
  - 本輪 Verify：Unit（233 項 × 2）、Component（142 項 × 2）、17 份腳本測試、8 項 GUI、5 項 E2E、語言與發布驗證全部通過。StoreKit 依使用者要求沿用既有環境跳過；Verify 僅因此回傳 1。紀錄：`Build/verify-refactor-complete.log`。

- [ ] 改善快捷鍵衝突提示：以簡短文字說明快捷鍵目前無法使用、可能與其他 App 衝突，並引導點擊快捷鍵更換按鍵組合；各自顯示於對應快捷鍵下方，縮減提示佔用的空間，避免大片紅字讓使用者誤以為 App 壞掉。錯誤碼保留於除錯紀錄，不顯示在一般使用畫面。

- [x] 核對 Apple 原生自動辨識與 Boundless 的責任範圍（macOS 26.5.2／Xcode 26.6）：`source: nil` 可由 Apple 辨識；`Chat`、`test`、`Bonjour` 實測仍會出現原生選語言 sheet，選定後接續翻譯。不能宣稱移除自訂 60% 門檻就能消除這些提示。`pain` 與英／日／韓完整句子可直接翻譯；`Chat` 指定日文仍翻成「聊天」，回傳來源仍是日文，預設與 lowLatency 設定皆重現。未選語言就按原生 sheet 的 Done，回傳 `NSCocoaErrorDomain` 3072，應視為使用者取消。下載提示依官方文件由 `.translationTask` 處理，本次未移除模型測試下載，也未實測 macOS 15。
- [x] 改用 Apple 原生自動辨識及選語言提示，刪除自訂門檻、提示畫面及過時測試。翻譯錯誤使用右欄灰階元件，沿用各語系文案；取消不顯示錯誤。Unit、Component 兩種編譯模式皆通過；實測原生選語言、取消、語言組合錯誤與深淺外觀。

- [ ] 將輔助使用與螢幕錄製的權限引導整合為同一個視窗，參考 ChatGPT 的呈現方式；由選字翻譯或截圖快捷鍵觸發時，都顯示兩項權限的用途與授權狀態，並清楚標示這次操作需要設定哪一項。

- [x] 整理腳本目錄：`Scripts/` 第一層集中操作與測試入口，重設核心放在 `Scripts/Reset/`，共用測試工具放在 `Scripts/Shared/`，`Tests/` 僅 `Tests/Scripts/` 保留 Shell 測試；移除一次性翻譯診斷工具，同步呼叫路徑、測試與文件。

- [x] 統一 DMG 命名：建置設定與 scheme 使用 DMG，DMG Test、E2E 安裝包各自與 App 同名，同步腳本、測試和文件。

- [x] 第二階段整理 GUI 測試的狀態讀取：查字典游標改由 Component 完整覆蓋後刪除該 GUI 案例；其餘必要案例改由 XCUITest 直接讀取狀態，移除共享 JSON。
  - 已移除共享 JSON 與前置視窗拖曳。Unit（232 項 × 2）、Component（127 項 × 2）、17 份腳本測試、47 項 GUI、5 項 E2E、語言與發布驗證通過。Verify 因既有環境限制下的 5 項 StoreKit 未執行而回傳失敗；使用者已確認提交。
- [x] 完成 Shell 精簡及驗證：移除重複存在性檢查、工具查找與公證後的重複驗證；保留必要的測試結果／發布包驗證。腳本測試、DMG 公證與安裝後啟動驗證通過；`check_xcode_test_results.sh` 保留，用來拒絕零測試、失敗或跳過，StoreKit 也共用它。

- [ ] 修正 GUI 測試結束後 Cursor Test Host 程序殘留：清理時先停止本次建置的測試 App，再刪除暫存檔，並補上程序退出的測試。

- [x] 更新工作流程：平常修改跑 Unit 與 Component；其他測試各自有入口，依使用者要求或測試本身的改動執行；完整 Verify 跑全部，DMG 不再每次自動產生。

- [x] 重設資料與權限使用共用核心，提供 DMG、App Store／TestFlight 的無參數入口；E2E 明確指定自己的版本。

- [x] 分離一般 DMG、E2E 與 App Store 的 App 身分：DMG Test 安裝名稱與 Bundle ID、重設腳本及建置設定；保留共用介面文字。
- [x] 選單列改用與 Hint、Settings 共用的去背精靈，避免完整 App 圖示的底色出現在選單列。

- [ ] 全面檢查精靈圖示的使用位置與圖片來源，確認哪些仍帶背景，並統一去背顯示；留待下一個 commit 處理。

- [x] 加入暫時的翻譯效能時間紀錄，已確認可寫入；記錄翻譯編號、文字大小、讀字、開窗、取消呼叫與翻譯返回時間，不記原文或譯文。
- [x] 分析使用者重做測試的紀錄：取消呼叫立即返回，大段呼叫約 204 秒後返回取消錯誤；後續短句等待約 46 秒，最後短句恢復約 0.14 秒。
- [x] 診斷完成後移除 App 內暫時的效能紀錄程式；獨立診斷工具也已於目錄整理時移除。
- [x] 建立可獨立執行的 Apple 翻譯比較腳本並實測：正常短句約 0.06 秒，大段取消後短句約 93.36 秒；大段呼叫約 211.68 秒後仍返回譯文。已驗證 log、編譯與逾時退出；單次結果尚不足以判定 Apple 內部原因。
- [x] 用取消方式、主執行緒心跳、跨程序、小段依序處理的對照與 Apple 背景服務取樣，確認延遲發生在 Apple 服務側，已送出的大段未被立即中斷；採用的長文分段方案已整合至 `spec.md`，一次性診斷工具與文件已移除。

- [x] 修正兩個視窗定位 Component test，移除對 `NSScreen.main` 的依賴。
- [x] 整理 `Tests` 目錄下的檔案結構與命名。
- [x] 改用 Settings 右側提示卡引導新使用者開啟問號說明，支援暫時關閉與不再顯示；使用說明先區分可選字／不可選字，再顯示目前快捷鍵與操作步驟。沿用既有權限引導，加入位置、多語系換行、明暗底色及關閉行為測試。
- [x] 使用說明改用共用「字典」標題與「朗讀」，明確指示選取原文單字或片語再點書本；各功能維持一致間距，同步各語言並驗證中英文明暗畫面。
- [x] 精簡朗讀說明；截圖翻譯明確指示擷取想翻譯的區域，移除辨識文字的補充段落，同步各語言並檢查畫面。
- [x] 在原文下方加入單字／片語字典提示，以 TipKit 管理顯示紀錄；提示預留空間，關閉後釋出空間，與截圖提示共用精靈圖示、內嵌排版與隨明暗模式調整的系統底色；截圖提示標題為「選字翻譯」。按叉暫時關閉，勾選「不再顯示」後再按叉才永久隱藏；支援多語系與明暗模式。
- [x] 截圖提示改為圖片上方整列，增加視窗高度並保留圖片大小；已驗證提示不覆蓋圖片、圖片可選字，以及關閉後尺寸與選取內容。字典提示維持左欄原文下方。
- [x] 依 Apple UI 與 Liquid Glass 原則統一各畫面的控制項與對齊。
- [x] 整理設定視窗標題、介面語言分組與底部按鈕，修正各語系排版。
- [x] 長文以 10,000 字元為分段目標，優先保留段落，超長段落依完整句子切分，單句超標仍保持完整。逐段送出與顯示，未完成時保留「Translating…／翻譯中…」；取消後不再送剩餘段落、忽略舊結果，新 session 直接開始，不等待取消通知。已驗證完整測資無遺漏、依序更新、失敗保留部分譯文及取消後的新結果保護；每段耗時仍取決於內容與裝置。
- [x] 移除開窗前的精靈載入提示、取消按鈕與專用測試。保留背景讀字、語言辨識及分段，以及視窗高度的有限排版測量。視窗內保留轉圈圈在「Translating…／翻譯中…」前方、垂直置中；保留逐段結果與關窗取消。
- [x] 接上關窗與新翻譯時的取消呼叫，忽略舊結果；尚未證實底層工作立即停止或下一筆翻譯恢復正常速度。
- [x] 核對原測資為 100,000 個英文單字、653,352 個字元，改名為「100K_words.txt」，新增「10K_characters.txt」，同步診斷腳本與文件路徑。
- [x] 保護 copy 取字流程的剪貼簿：觸發複製前備份所有項目與格式，取字後立即還原；失敗或取消時清理已觀察到的複製結果，保留後續 Copy。剪貼簿保護與路徑判斷由單元及元件測試驗證，E2E 保留原本三個基本流程。

- [x] 將 App Store Archive、Validate、Distribute 三支獨立 shell 放在 `Scripts/AppStore/`，由第一層 `Scripts/release_app_store.sh` 依序執行；使用固定路徑、Xcode 自動簽章與 Build Number 管理。

- [x] App Store 三支腳本分別顯示 Archive、Validate、Distribute 的開始與成功訊息；失敗時不顯示成功。

- [x] 清理 Glass／Space Gray：各保留最新 6 張成圖及可編輯來源，更新索引與引用；截圖翻譯僅保留完整光束，舊生成底圖已由直接產圖流程取代。

- [x] 功能介紹產圖改為直接讀取 HTML、原始截圖及共用光束元件，移除舊底圖、重複成圖與階段性產圖程式；14 張重製逐像素一致，16 張交付成圖原檔均未更改。
- [x] Settings 已換入確認後的新截圖與正式排版，HTML 重製結果與正式 PNG 逐像素一致。

- [x] 功能介紹目錄統一為 `docs/feature-showcase/`，分成 `assets/`、`layouts/`、`output/`；成圖放在 `output/glass/` 與 `output/space-gray/`，移除 updated 命名，同步排版與產圖路徑。
- [x] 選定 A「窄光束」，套用 VS Code／Preview 的 Glass 與太空灰共四張選字翻譯成圖；逐像素比對確認僅箭頭附近改變，其餘十二張成圖未變。



- [x] 將八張截圖翻譯最新版（完整／尾端光束、Glass／太空灰）及四份 HTML 整合回正式位置，同步共用光束座標；移除 screenshot-subtitles 暫存目錄與專用產圖程式；正式來源重製八張均逐像素一致。

- [x] 移除已採用或淘汰的兩組比較稿、舊 Screenshot 字樣 CSS 與專用字型，共 9 個檔案；同步文字樣式及 Output 說明，正式成圖保留。
- [ ] 另開獨立 commit 整理字典按鈕與共用附屬視窗判斷的命名；不與本次字典顯示修正混在一起。
- [x] 在 Can't select 原始圖片素材下方加入「We’ll make the text selectable.」，供重新截圖使用；註明換入新截圖時需移除排版中的重複補述。

- [x] 將使用者確認的八張功能介紹圖升為正式版；六張新截圖取代 assets 舊素材，最新排版整合回八份正式 HTML 與共用光束元件。保留兩種主題各六張成圖，刪除比較頁、Update 專用程式、重複素材與根目錄六張截圖。十二張正式圖重製逐像素一致。
