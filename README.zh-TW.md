**繁體中文** | [English](./README.md)

# m4ore-claude-setup

跨平台一鍵部署 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 設定檔、Skills、全域指令 — 在任何新機器上 `git clone` + 跑一個腳本就搞定。

## 快速開始

### Linux / macOS

```bash
git clone https://github.com/m4ore/m4ore-claude-setup.git ~/m4ore-claude-setup
cd ~/m4ore-claude-setup
chmod +x setup.sh && ./setup.sh
```

### Windows (CMD)

```cmd
git clone https://github.com/m4ore/m4ore-claude-setup.git %USERPROFILE%\m4ore-claude-setup
cd %USERPROFILE%\m4ore-claude-setup
setup.bat
```

> 也可以用 PowerShell：`.\setup.ps1`

## 功能說明

Setup 腳本會從 `~/.claude/` 建立 **Symlink** 指向本 repo，修改 repo 內的檔案即可立即在所有專案中生效。

| 目標 | 來源 | 同步策略 |
|------|------|----------|
| `~/.claude/settings.json` | `config/settings.json` | Symlink |
| `~/.claude/skills/` | `skills/` | Symlink（整個目錄） |
| `~/.claude/CLAUDE.md` | `CLAUDE.md` | Symlink |
| `~/.claude/mcp.json` | *（不同步）* | 各台手動設定 |
| `~/.claude/settings.local.json` | *（不同步）* | 各台手動設定 |

腳本同時會安裝以下 npm 全域套件（已安裝則跳過）：

- `typescript` / `typescript-language-server` — JS/TS 語言支援
- `@anthropic-ai/claude-code` — Claude Code CLI
- `@tobilu/qmd` — QMD 工具

## 內建 Skills

### Design-First Development (D4)

重大功能或重構前自動強制進入 **Plan Mode**，在 `docs/design/` 產生編號 Design Doc，使用標準化模板。詳見 [`skills/design-first-development/SKILL.md`](./skills/design-first-development/SKILL.md)。

## Windows Symlink 注意事項

Windows 需要開啟 **開發人員模式** 才能在不需系統管理員的情況下建立 Symlink。

> 設定 > 更新與安全性 > 開發人員專用 > 開發人員模式

如果無法建立 Symlink，`setup.bat` / `setup.ps1` 會自動 **退回到複製模式（Copy mode）**。在複製模式下，`git pull` 之後需要重新執行 setup 腳本才能同步更新。

## 更新方式

| 模式 | `git pull` 之後 |
|------|----------------|
| Symlink（Linux/macOS/Win+開發者模式） | 自動生效，不需額外操作 |
| Copy（Win 未開啟開發者模式） | 需重新執行 `setup.bat` 或 `.\setup.ps1` |

## Repo 結構

```
m4ore-claude-setup/
├── README.md                              # English README
├── README.zh-TW.md                        # 繁體中文 README
├── .gitignore
├── CLAUDE.md                              # 全域 Claude 指令
├── setup.sh                               # Linux/macOS 設定腳本
├── setup.bat                              # Windows 設定腳本 (CMD)
├── setup.ps1                              # Windows 設定腳本 (PowerShell)
├── config/
│   ├── settings.json                      # 共用 Claude 設定
│   └── settings.local.example.json        # 本地設定模板
├── skills/
│   └── design-first-development/
│       └── SKILL.md                       # D4 Skill
├── lib/
│   └── common.sh                          # Bash 共用 helper
└── docs/
    ├── plan-v1.md
    └── design/                            # D4 Design Doc 目錄
```

## 本地設定

將模板複製到各台機器並自行填入：

```bash
cp config/settings.local.example.json ~/.claude/settings.local.json
```

此檔案已加入 `.gitignore`，不會被 commit。

## 授權

MIT
