# 專案規則

## 工作流

- 完成程式碼修改後，執行 `Scripts/verify.sh`；通過後交付使用者 code review。
- 使用者確認 code review 並要求發布後，依指定版號執行 `Scripts/release_dmg.sh <version>`。

不得存放或提交簽章私鑰。

## Spec

- `spec.md` 是目前產品行為與架構的唯一規格文件。
- 修改產品行為或架構後，若 `spec.md` 的描述受到影響，完成開發前同步更新。
- 使用 Superpowers 產生設計時，將核准內容整合至 `spec.md`；不要在 repo 保留日期型或歷史 spec。

## App icon

- 修改來源 PNG 後，執行 `Scripts/Tools/generate_brand_icons.swift .` 產生 ICNS。
- 切換 App icon 時，執行 `Scripts/Tools/replace_app_icon.sh <icns-path>` 更新 `Resources/AppIcon.icns`。
- 完成後執行 `Scripts/verify.sh`。
