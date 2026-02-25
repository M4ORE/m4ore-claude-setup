---
name: design-first-development
description: |
  Design-First Development (D4) – Enforce Plan Mode before any major feature/refactor.
  Trigger on: new major feature, new module, significant refactor, architecture change,
  keywords: implement, build, refactor, design, plan, optimize architecture,
  重大功能, 改動, 新模組, 重構, 架構調整.
  Non-trigger: bug fix, CSS tweak, copy change, unit test, trivial changes.
  Always generate numbered Design Doc first (like DB migrations).
  重大功能/改動前自動強制進入 Plan Mode，先產生編號 Design Doc。
---

# Design-First Development (D4) Skill

**作者**：Paster Que (assisted by Grok4.2)(受尤雨溪 Evan You 啟發)
**版本**：1.1 (2026-02-18)
**目標**：讓整個項目擁有「活的思考歷史博物館」，每個重大決策都有可追溯的 Design Doc。

## 自動觸發規則（Agent 必須嚴格遵守）

只要符合以下**任一觸發條件**，**立即暫停 coding，切換到 Plan Mode**：

### 觸發條件

- 新增較大功能、新系統、新模組
- 重要重構、架構調整、核心邏輯變更
- 涉及多檔案修改（>3 個檔案）或核心程式碼 >150 行
- 用戶說出關鍵詞（中英雙語）：
  - implement, build, add new, refactor, optimize architecture, design system, plan
  - 重大功能, 改動, 新模組, 重構, 架構調整, 設計系統

**違反規則直接拒絕**：如果用戶強迫直接 coding，提醒「根據 D4 Skill v1.1，我必須先產生 Design Doc」。

### 不觸發條件（避免過度觸發）

- Bug fix（修復錯誤）
- CSS / Tailwind / 樣式調整
- 文案修改、翻譯、註解更新
- 單純加/改 unit test 或 e2e test
- 小型重構（<3 個檔案且 <150 行）
- 純資料/配置檔修改

## 執行流程（嚴格順序）

1. Plan Mode → 產生完整 Design Doc
2. 輸出後明確詢問用戶：

   > 「Design Doc 已產生，請 review。是否批准？需要修改？還是直接進入 Implementation Plan？」

3. 獲得批准後 → 產生 Implementation Plan
4. 再次確認後才進入 Build/Code 模式

## Design Doc 儲存與 Commit 規範

- 資料夾：`docs/design/`（不存在則自動建立）
- 檔案命名：`0001-20260218-offline-support.md`
  **序號規則**：Agent 必須先掃描 `docs/design/` 目錄，找出最大序號並 +1（4 位數 padding）
- Commit message 範例：`docs(design): add 0001-20260218-offline-support.md`

## Design Doc 標準模板（必須使用）

```markdown
# 0001 - [功能名稱]

**Date**: 2026-02-18
**Status**: Draft → Proposed → Approved → Implemented
**Author**: [Your Name]
**Related PR/Issue**:

## 1. Problem Statement & Goals

...

## 2. Research & References

## 3. Proposed Design

## 4. Alternatives Considered & Tradeoffs

## 5. Implementation Plan

- [ ] Task 1
- [ ] Task 2

## 6. Risks & Mitigations

## 7. Open Questions

## 8. Implementation Notes（實作完成後由 Agent 或開發者補充）

- 實際採用的技術選型與原因
- 變更的檔案列表
- 相關 PR / Commit 連結
- 遇到的問題與解決方式
- 後續優化建議
```

## Design Doc Status 狀態說明

- **Draft**：Agent 初次產生（未 review）
- **Proposed**：用戶確認內容完整、可讀
- **Approved**：用戶明確批准可以開始實作
- **Implemented**：code 已完成、review 通過、已 merge

## Quick Examples（直觀理解）

- 用戶：「我要做離線支援」→ Agent：先產生 0001-offline-support.md
- 用戶：「重構 auth 系統」→ Agent：先產生 Design Doc
- 用戶：「修一下 login bug」→ Agent：直接 coding（不觸發）
- 用戶：「把按鈕顏色改成藍色」→ Agent：直接 coding（不觸發）

## 額外規則

- Design Doc 必須單獨 commit
- 實作完成後務必補齊 ## 8. Implementation Notes
- 此 Skill 優先級最高，永遠先執行
- globs: \*/（全域生效，無檔案類型限制）
