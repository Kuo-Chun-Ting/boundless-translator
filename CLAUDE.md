# 專案工作流程

## 驗證

修改 App 程式、資源、設定或建置流程後，依序完成以下檢查：

1. 使用位於 `/private/tmp` 的 SwiftPM 與 Clang 快取執行完整 `swift test`，確認所有測試通過且沒有編譯警告。
2. 執行 `zsh -n Scripts/build_app.sh` 與 `plutil -lint Resources/Info.plist`。
3. 執行 `Scripts/build_app.sh`，建立最新的 Release App；不要部署先前留下的 Build。
4. 對 `Build/Boundless Translator.app` 執行：
   - `codesign --verify --deep --strict --verbose=2`
   - `codesign -d --verbose=4`，確認 `Signature` 不是 `adhoc`，且 `Authority` 是本次指定的簽章身分
   - `plutil -lint`
   - `vtool -show-build`，確認最低 macOS 版本仍為 15.0
   - `otool -L`，確認需要的系統 framework 已連結
5. 任一檢查失敗時，先修正並重新完成全部驗證，不得部署。

本機建置預設使用 Keychain 裡 SHA-1 為 `D94FA01C46E10F95D2E20D403C187C470926858C` 的本機開發憑證。需要切換簽章身分時，以 `BOUNDLESS_TRANSLATOR_SIGNING_IDENTITY` 指定；變數只存憑證名稱或 SHA-1，不得存放或提交私鑰。

## 部署

完成驗證後，必須把本次建立的 App 部署到 `/Applications/Boundless Translator.app`：

1. 使用 `pgrep -x BoundlessTranslator` 檢查已安裝的 App 是否仍在執行。
2. 如果正在執行，只終止名稱完全相符的 `BoundlessTranslator` 程序，並等待 `pgrep -x BoundlessTranslator` 確認程序已停止；不得使用模糊程序名稱終止其他 App。
3. 在唯一的暫存目錄中暫存新版並保留舊版備份，再替換 `/Applications/Boundless Translator.app`。部署失敗時恢復舊版，不得留下部分複製的 App。
4. 如果工具要求終止程序或寫入 `/Applications` 的權限，直接發起該次部署所需的權限申請，不得因此跳過部署。
5. 對已安裝的 App 重新執行 `codesign --verify --deep --strict --verbose=2` 與 `plutil -lint`，並確認已安裝的執行檔和 `Build` 版本一致。
6. 部署後保持 App 關閉，讓使用者自行從 Applications 啟動。
