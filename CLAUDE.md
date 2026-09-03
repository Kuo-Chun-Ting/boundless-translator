# 專案規則

## 驗證

完成所有程式碼修改後：

- 執行完整 `swift test`。
- 修改 UI component 時，確認相關 component test 涵蓋變更行為。
- 修改 Build、簽章、部署或 DMG 流程時，執行相關 deployment integration test。
- 建立最新 App 與 DMG，確認 App 簽章、最低 macOS 版本、system framework 與 DMG 安裝版面。
- 執行下列腳本時，必須使用可存取 macOS 系統資源的執行環境；需要授權時，以腳本路徑建立可重複使用的授權規則：
  - `Scripts/build_app.sh`
  - `Scripts/package_dmg.sh`
  - `Scripts/verify_app.sh`
  - `Scripts/deploy_app.sh`
  - `Scripts/build_and_deploy_app.sh`
  - `Scripts/test_gui.sh`
  - `Tests/Deployment/PackageDmgTests.sh`
  - `Tests/Deployment/VerifyAppTests.sh`

所有驗證通過後才算完成。

不得存放或提交簽章私鑰。

## App icon

- 修改來源 PNG 後，執行 `Scripts/generate_brand_icons.swift .` 產生 ICNS。
- 切換 App icon 時，執行 `Scripts/replace_app_icon.sh <icns-path>` 更新 `Resources/AppIcon.icns`。
- 完成後建立並驗證最新 App 與 DMG。
