# 專案規則

## 工作流

- 直接修改目前分支；只有使用者要求時才建立或使用 worktree。
- 供使用者執行的 Shell 入口放在 `Scripts/` 第一層，共用工具放在 `Scripts/Shared/`；`Tests/` 僅 `Tests/Scripts/` 放 Shell 測試。
- 兩個測試 App 交換的檔案放在專案 `Build/` 共用目錄。
- 修改程式碼或測試後，交付前跑 `Scripts/run_unit_tests.sh` 和 `Scripts/run_component_tests.sh`；其他層級預設不跑。
- 修改 GUI／E2E 測試時，加跑改過的案例；修改共用測試工具時，跑受影響的群組；修改腳本時，跑對應的 `Tests/Scripts/` 測試。
- 只改文件時，檢查內容、引用與一致性，不跑 App 測試或產生 DMG。
- 使用者指定驗證層級時，跑該入口；未指定案例則跑該層全部。入口與參數見 `Tests/README.md`。
- 完整驗證或正式發布前跑 `Scripts/verify.sh`；除下列 StoreKit 例外，失敗、跳過或環境不足均不算通過。
- 目前 StoreKit 沿用既有環境跳過規則；其餘項目全數通過即視為 Verify 通過，可依使用者授權 commit 或發布。即使腳本因此回傳非零，仍按此例外判定，並在報告註明 StoreKit 未驗證。
- 只有使用者要求可安裝版本或發布驗證時才產生 DMG。建置與公證用 `Scripts/release_dmg.sh`；發布包與安裝後啟動驗證用 `Scripts/run_release_tests.sh`。
- 使用者要求實際 UI 驗證時，操作修改後的 App 並附截圖；未驗證的畫面或操作要明確標示。
- Codex 跑測試入口時，第一次就使用 `exec_command` 的 `sandbox_permissions: "require_escalated"`；讀檔與改檔使用預設沙盒。
- 只有使用者要求時才重設權限。首次權限流程用 `Scripts/run_e2e_tests.sh --from-permission-setup`，僅重設 E2E 權限；一般 E2E 與 Verify 不重設。
- 交付前更新 `TODO.md`，只勾選已完成項目。交付時列出驗證結果、未完成範圍及本次產生的 DMG 路徑。

不得存放或提交簽章私鑰。

## Spec

- `spec.md` 是產品行為與架構的唯一規格；改動影響規格時，同步更新。
- Superpowers 核准的設計整合至 `spec.md`，不保留日期型或歷史 spec。

## App icon

- 修改來源 PNG 後，執行 `Scripts/Assets/generate_brand_icons.swift .` 產生 ICNS。
- 切換圖示時，執行 `Scripts/Assets/replace_app_icon.sh <icns-path>` 更新 `Resources/AppIcon.icns`；依工作流驗證，不自動跑完整 Verify。
