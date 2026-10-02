# 專案規則

## 工作流

- 除非使用者明確要求，否則不得建立或使用 Git worktree；直接在目前分支修改。
- 每次修改程式碼後，依序執行 `Scripts/verify.sh`、`Scripts/run_e2e_tests.sh`、`Scripts/release_dmg.sh`。
- 修改 UI 後，啟動修改後的 App，對照確認的設計檢查外觀，並操作受影響的功能。交付時附上實際截圖與檢查結果；無法檢查時，列出未驗證項目與原因。
- Codex 執行 Verify 與 E2E 測試腳本時，第一次就以 `exec_command` 的 `sandbox_permissions: "require_escalated"` 執行；一般讀檔、改檔指令維持預設沙盒。
- 每次交付修改前檢查 `TODO.md`，勾選本次已完成的項目；未完成的項目維持未勾選。
- 只有需要驗證首次權限設定流程時，執行 `Scripts/run_e2e_tests.sh --from-permission-setup`。此模式會自行重設權限，等待使用者完成 macOS 授權，再繼續功能測試。
- 不要在其他流程自動執行 `Scripts/Reset/reset_permissions.sh`；只有使用者要求單獨重設測試權限時才執行。

不得存放或提交簽章私鑰。

## Spec

- `spec.md` 是目前產品行為與架構的唯一規格文件。
- 修改產品行為或架構後，若 `spec.md` 的描述受到影響，完成開發前同步更新。
- 使用 Superpowers 產生設計時，將核准內容整合至 `spec.md`；不要在 repo 保留日期型或歷史 spec。

## App icon

- 修改來源 PNG 後，執行 `Scripts/Assets/generate_brand_icons.swift .` 產生 ICNS。
- 切換 App icon 時，執行 `Scripts/Assets/replace_app_icon.sh <icns-path>` 更新 `Resources/AppIcon.icns`。
- 完成後執行 `Scripts/verify.sh`。
