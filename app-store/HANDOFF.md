# 預覽影片與功能介紹圖交接

這份是影片與功能介紹圖唯一的需求和交接文件，記錄目前採用版本與後續製作規則。

## 待辦

- 截圖翻譯功能圖副標之後再處理，目前保留原文。
- 不上傳或 push，commit 依使用者指示。

## 目標與素材

讓觀眾看懂三件事：選取的文字可以翻譯，圖片裡的文字也可以翻譯，翻譯後可以接著查字典。影片和功能介紹圖使用同一批操作素材。

- 選字翻譯：用 Preview 開啟 [PDF](assets/original-kit/boundless-selected-text-demo.pdf)，選取句子 → ⌘⇧1 翻譯 → 顯示譯文 → 查「shortcut」。
- 截圖翻譯：用 Safari 開啟 [あかり食堂菜單網頁](assets/original-kit/screenshot-menu.html)（插畫為 [menu.png](assets/original-kit/menu.png)），⌘⇧2 框選菜單 → hover 單字 → 選取整段說明看譯文 → 查字典。
- 錄影在 `assets/recording/`：`selected-text-translation.mov`、`screenshot-translation.mov`。功能介紹圖從錄影擷取畫面。
- Safari 可以選取菜單圖片裡的文字，所以不演出「選不到字」。

## 影片

### 結構

- 單支影片，總長 30 秒內。
- 不放開頭品牌卡，只在結尾放品牌卡。
- 選字翻譯、截圖翻譯兩段，每段開頭有獨立的功能名稱畫面，之後才出現第一個動作提示。
- 功能名稱用 `Selected Text Translation`、`Screenshot Translation`，跟功能介紹圖的標題相同。
- 功能名稱不是動作，不用對話框樣式：
  - 在錄影出現前直接放在 Glass 背景上，用深藍大字，字級和字重跟結尾品牌卡相同。
  - 標題完全淡出後錄影視窗才浮入，視窗定位後才出現第一個提示。標題和錄影不重疊。
  - 停留時間比任何動作提示都長。

### 動作提示

- 文案由使用者決定，不自行改寫。現行順序：
  - 選字：Select text to translate（⌘⇧1）→ Open dictionary
  - 截圖：Take a screenshot to translate（⌘⇧2）→ Hover to translate → Select to translate → Open dictionary
  - 字典上的說明：See definitions in your Mac's built-in dictionary.
- 不寫「Can't select…」、「Text in an image?」這類宣稱圖片選不到字的句子。截圖翻譯的用途由功能名稱和操作呈現。
- 不另加拖曳、選單字或 Look up 的提示。畫面已經說清楚的動作不重複解說。
- 選字和按快捷鍵共用一個提示，按下時按鍵填色並發出聲音。兩段的 Open dictionary 都涵蓋找到單字和點書本。截圖段在查字典前保留 hover 出現翻譯卡的操作。
- 樣式：
  - 漫畫對話框：白底、金色細框、金色光暈。
  - 小三角尖角從平直的邊伸出，指向即將變化的位置。不畫彎曲、拉長或夾在兩個圓角之間的尖角。
  - 所有對話框用同一種文字：石墨黑 #2c2c2e，字級和字重都相同。卡片和標籤的差別只在卡片多一排按鍵。
  - 不用深藍或彩色底，也不加星星、光掃這類裝飾。
- 位置：放在游標即將操作的地方旁邊，不蓋住游標路徑和操作結果。例如選句提示放在拖曳起點上方，不放在句尾。
- 金色圓圈：每次點擊或拖曳起點之前，在按下的位置顯示，從提示出現持續到按下那一格。hover 改用 hover 外框，按快捷鍵不加圓圈。
- hover 虛線金框標出翻譯卡所屬的字：從那個字的翻譯卡出現（或開始顯示 Translating…）那一格開始，游標移往下一個字或下一個動作開始時收掉。不提早出現當作預告。
- 點擊後的結果會蓋到按下的位置時（例如字典彈窗），該位置的提示卡、金色圓圈和點擊擴散圈要在結果出現前收掉。
- 金色標記（圓圈、hover 框、截圖框）外加白邊，在奶油色菜單上也看得清楚。

### 節奏

- 提示的閱讀時間依字數計算：完全淡入後到動作開始前的時間 = 基礎值 + 每字固定時間。按鍵列算一個字。
- 中文譯文依字元數保留閱讀時間。
- 只為了閱讀而定格。游標已經在移動、提示又短的時候不加定格，例如框選前。
- 現行參數在 `src/video/src/timeline/read.ts`：2 字 0.63 秒、3 字 0.83 秒、4 字 1.03 秒，譯文每字約 0.073 秒，功能名稱完全顯示 1.33 秒。

### 鏡頭

- 不要放大到看不出操作在畫面哪裡。保留操作所在的整個視窗，結果要跟來源同框。例如翻譯視窗要和原句同框，字典要和翻譯視窗同框。
- 鏡頭避開 macOS 選單列和 Safari 網址列，兩者會露出其他 App 的圖示和本機路徑。

### 字典

- 查詢詞依實際錄影：Preview 查 shortcut，菜單查「香ばしく」。
- 釋義模糊處理，加上金色微塵和說明文字，跟功能介紹圖 [03-dictionary.png](image/03-dictionary.png) 相同。
- 字典名稱、詞條、Open in Dictionary 保持清楚。
- 釋義在任何一格都不能看清楚。彈窗從放大動畫的第一格就要蓋住。放大期間釋義還不在最終位置，所以要蓋住整個彈窗，直到彈窗停定。開始放大和停定的格數要查 `public/media/` 的 30 fps 代理檔確認，不用原始 MOV 的影格編號。

### 聲音

- 不使用 macOS 內建音效。配樂和音效只用授權允許廣告使用的來源，需要付費時先詢問使用者。授權記錄在 `src/video/licenses/`。
- 音效只有按鍵、截圖、點擊，以及截圖翻譯字卡出現時的「咻」。拖曳（選字、框選）和 hover 動作本身不加音效。
- 音效要和畫面在同一格：按鍵音對齊按鍵亮起，點擊音對齊金色點擊圈。`click.wav` 從第一個取樣就有聲音，不要裁切開頭。

## 功能介紹圖

- 依序四張：Preview 選字翻譯、菜單截圖翻譯、字典、Settings。前三張從那兩段錄影擷取，Settings 沿用既有截圖。
- 截圖翻譯那張用菜單網頁，不用「Can't select」純文字圖。新版不放 VS Code 和 General。
- 選字圖保留原文反白和譯文。
- 截圖圖同時顯示背景原圖、較小的截圖視窗和翻譯字卡，讓人能對照內容。
- 字典圖保留原始外框和標題，釋義用金色光塵模糊，提示為「See definitions in your Mac's built-in dictionary.」。選字情境用錄影截圖；菜單情境用使用者補拍的 [menu-dictionary.png](assets/screenshots/recording/menu-dictionary.png)，查詢「カレー」。
- 沿用 Glass 風格，構圖和動畫由製作者決定。Space Gray 版由 `src/image/render.cjs` 從同一份來源產生。
- 截圖翻譯那張的副標要改成「選不到字就用截圖翻譯」的意思，文案還沒定。Claude 提議的版本：Can't select the text? Use a shortcut to capture and translate it.

## 工作方式與交付

- 改樣式、版面或文案前，先跟使用者確認做法。樣式要先給靜態參考圖確認，再改影片。
- 答案顯而易見時直接做，不要問。例如功能名稱要停留比較久。
- 設計影片時用 `remotion-create`、`remotion-markup`、`remotion-render`、`motion-design`，文案用 `concise-writing`、`humanizer-zh-tw`。
- 只用 CLI 或無介面渲染，不操控使用者的桌面。
- 每個新版本先另存供 review，不覆蓋正式版；使用者明確要求取代後，才更新 `video/preview.mp4` 或 `image/`。交付可編輯的來源、MP4 和 PNG。影片規格為 1920 × 1080、30 fps、H.264、小於 500 MB。
- 交付前自己驗證，並回報沒驗證到的部分：
  - 逐格確認每個提示在動作前完整顯示，動作在預期的那一格開始，提示不遮擋操作。
  - 量測音效起點，對照畫面格數。
  - 確認總長在 30 秒內，並檢查輸出規格。
- 驗證完請另一個 agent 對照本文件 review。
- 進度回報和回覆一律用繁體中文。
- 素材清單見 [assets/original-kit/README.md](assets/original-kit/README.md)，重製來源見 [模板總覽](src/image/README.md)，授權查核見 [rights-review.md](src/video/licenses/rights-review.md)。

## 目前狀態

- 正式影片：[preview.mp4](video/preview.mp4)，29.9 秒，保留背景白條修正，使用 shoo 字卡音效與底部單行署名。署名為 21 px、距底 34 px、灰藍色、不加粗；授權說明見 `src/video/licenses/README.md`。
- 正式圖片：[Glass 四張圖](image/index.html)。截圖頁維持 1:1 構圖，副標之後再處理。太空灰與舊版成圖已清除，模板與來源仍保留。
- 來源在 `src/video/src/scenes/`。要改哪個檔案、共用元件在哪裡，見 [影片來源 README](src/video/README.md)。
- 截圖翻譯的四張字卡（hover 野菜、カレー、香ばしく，以及選整段的譯文）在翻譯出現那一格播字卡音效。「咻」提前 3 格播，讓卡牌落下的聲音落在字卡上。
- 待使用者決定：
  - 結尾標語「Translate in any app or website.」要不要保留。「any app」是否成立還沒驗證。
  - 截圖翻譯功能介紹圖的副標文案。

## 目錄與維護

全部集中於 `app-store/`：`src/image/` 是功能圖程式，`src/video/` 是 React 影片專案，`image/`、`video/` 放正式成品與尚待 review 的新版，`assets/` 放素材。入口見 [README](README.md)。上架版本由各成品 README 註明，不另設定案目錄。

- 程式只維護一份，歷史交給 Git；成品每版另存；影片拒絕覆蓋既有檔案，功能圖用 `--write --out <新目錄>` 另存，目錄已存在即拒絕寫入。只有已 commit 的檔案才能從 Git 還原。
- Node 套件、lockfile 與設定留在各子專案。`node_modules/`、影片 `out/`、`public/media/` 不納入 Git；原始素材、可編輯來源、音訊授權與成品保留。
- 影片 Shell 腳本只供 agent 製作，留在 `src/video/`。若改成使用者入口，依專案規則放到根目錄 `Scripts/`。
- 腳本從自身位置解析路徑；HTML 使用相對連結，可直接開啟。不要新增伺服器或路徑框架。
- 影片來源按 `scenes/`、`components/`、`timeline/` 分工，共用 `theme.ts`；字典遮罩及提示文字集中在 `components/DictionaryVeil.tsx`。修改位置與指令見 [影片 README](src/video/README.md)。
- 功能圖有自己的依賴與 lockfile；重製方式見 [圖片 README](src/image/README.md)。

### 素材保留原則

- 模板可以沿用，不能因舊畫面被替換而刪除模板。保留 Preview／自有 PDF、原創菜單、Settings、字典來源與舊構圖參考。
- 舊聊天、VS Code、NBA、日本咖啡店網站與 General 不在目前製作範圍；不因搬目錄恢復舊素材，也不順便刪除仍保留的檔案。
- 原創菜單來源是 `src/image/original-kit/menu.html`；先前刪除的原創草稿不能因此認定侵權。獨立字典卡 PNG 草稿保留，但其未追蹤 HTML 和舊 `prepare-review-kit.py` 沒有可還原版本，現行製作不依賴它們。
- 素材瀏覽頁在 `assets/index.html`。既有權利查核與授權紀錄保留於 `src/video/licenses/`。

### 驗證

- 只改製作子專案時，不跑 Swift App 測試、不產生 DMG。
- 影片跑 `npm run lint`、`npx remotion compositions src/index.ts`；目錄整理前後用同一環境渲染相同格數 PNG 比對，另核對時序與聲音。已有 MP4 不重製，用雜湊確認未變。
- 功能圖跑 `npm run check`，只比對正式 Glass 四張；太空灰與舊模板用 `--write --out <新目錄>` 驗證另存能力；比對時不加 `--write`。
- 每次改動畫面或聲音，仍按上方「工作方式與交付」檢查及請另一個 agent review。
