# 專案工作流程

## App icon

- 修改來源 PNG 後，執行 `Scripts/generate_brand_icons.swift .` 產生 ICNS。
- 切換 App icon 時，執行 `Scripts/replace_app_icon.sh <icns-path>` 覆蓋 `Resources/AppIcon.icns`。
- 修改或替換 App icon 後，完成下列驗證與部署流程。

## 驗證

修改 App 程式、資源、設定或建置流程後，依序完成以下檢查：

1. 使用位於 `/private/tmp` 的 SwiftPM 與 Clang 快取執行完整 `swift test`，確認所有測試通過且沒有編譯警告。
2. 執行 `zsh -n Scripts/build_app.sh Scripts/verify_app.sh Scripts/restore_deployment.sh Scripts/deploy_app.sh` 與 `plutil -lint Resources/Info.plist`。
3. 執行 `Scripts/build_app.sh`，建立最新的 Release App；不要部署先前留下的 Build。
4. 對 `Build/Boundless Translator.app` 執行：
   - `Scripts/verify_app.sh "Build/Boundless Translator.app"`，確認 App 通過嚴格簽章、Bundle ID 與指定 leaf 憑證 SHA-1 驗證
   - `Tests/Deployment/VerifyAppTests.sh`
   - `Tests/Deployment/RestoreDeploymentTests.sh`
   - `codesign -d --verbose=4`
   - `vtool -show-build`，確認最低 macOS 版本仍為 15.0
   - `otool -L`，確認需要的系統 framework 已連結
5. 任一檢查失敗時，先修正並重新完成全部驗證，不得部署。

本機建置與部署只接受 SHA-1 為 `2A650F82E97048C85359EC506D920C5BF684CAEE` 的本機開發憑證。`BOUNDLESS_TRANSLATOR_SIGNING_IDENTITY` 只能指定這張憑證的名稱或 SHA-1；切換憑證時，必須透過 code change 更新建置與驗證設定。不得存放或提交私鑰。

## 部署

完成驗證後，執行 `Scripts/deploy_app.sh`。不得以手動複製或 `Scripts/build_and_deploy_app.sh` 取代正式驗證與部署流程。

`Scripts/deploy_app.sh` 必須符合以下要求：

1. 使用 `pgrep -x BoundlessTranslator` 檢查已安裝的 App 是否仍在執行。
2. 如果正在執行，只終止名稱完全相符的 `BoundlessTranslator` 程序，並等待 `pgrep -x BoundlessTranslator` 確認程序已停止；不得使用模糊程序名稱終止其他 App。
3. 在唯一的暫存目錄中暫存新版並保留舊版備份，再替換 `/Applications/Boundless Translator.app`。部署失敗時恢復舊版；如果恢復也失敗，保留暫存目錄內的復原檔案，不得刪除唯一備份。
4. 如果工具要求終止程序或寫入 `/Applications` 的權限，直接發起該次部署所需的權限申請，不得因此跳過部署。
5. 對已安裝的 App 重新執行 `Scripts/verify_app.sh`，並確認已安裝的執行檔和 `Build` 版本一致。
6. 部署後保持 App 關閉，讓使用者自行從 Applications 啟動。
