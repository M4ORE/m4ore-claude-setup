[繁體中文](./README.zh-TW.md) | **English**

# m4ore-claude-setup

Cross-platform one-command setup for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — sync configuration, skills, and global instructions across all your machines.

## Quick Start

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

> PowerShell alternative: `.\setup.ps1`

## What It Does

The setup script creates **symlinks** from `~/.claude/` to this repo, so edits here take effect immediately across all projects.

| Target | Source | Strategy |
|--------|--------|----------|
| `~/.claude/settings.json` | `config/settings.json` | Symlink |
| `~/.claude/skills/` | `skills/` | Symlink (entire dir) |
| `~/.claude/CLAUDE.md` | `CLAUDE.md` | Symlink |
| `~/.claude/mcp.json` | *(not managed)* | Manual per-machine |
| `~/.claude/settings.local.json` | *(not managed)* | Manual per-machine |

It also installs these npm global packages (if not already present):

- `typescript` / `typescript-language-server` — JS/TS language support
- `@anthropic-ai/claude-code` — Claude Code CLI
- `@tobilu/qmd` — QMD tool

## Included Skills

### Design-First Development (D4)

Automatically enforces **Plan Mode** before any major feature or refactor. Generates numbered Design Docs in `docs/design/` with a standardized template. See [`skills/design-first-development/SKILL.md`](./skills/design-first-development/SKILL.md) for details.

## Windows Symlink Note

Windows requires **Developer Mode** to create symlinks without admin privileges.

> Settings > Update & Security > For developers > Developer Mode

If symlinks aren't available, `setup.bat` / `setup.ps1` automatically falls back to **Copy mode**. In Copy mode, you must re-run the setup script after every `git pull`.

## Updating

| Mode | After `git pull` |
|------|-----------------|
| Symlink (Linux/macOS/Win+DevMode) | Changes take effect immediately |
| Copy (Win without DevMode) | Re-run `setup.bat` or `.\setup.ps1` |

## Repo Structure

```
m4ore-claude-setup/
├── README.md                              # English README
├── README.zh-TW.md                        # 繁體中文 README
├── .gitignore
├── CLAUDE.md                              # Global Claude instructions
├── setup.sh                               # Linux/macOS setup
├── setup.bat                              # Windows setup (CMD)
├── setup.ps1                              # Windows setup (PowerShell)
├── config/
│   ├── settings.json                      # Shared Claude settings
│   └── settings.local.example.json        # Local settings template
├── skills/
│   └── design-first-development/
│       └── SKILL.md                       # D4 Skill
├── lib/
│   └── common.sh                          # Bash helper functions
└── docs/
    ├── plan-v1.md
    └── design/                            # D4 Design Docs directory
```

## Local Settings

Copy the template and customize per machine:

```bash
cp config/settings.local.example.json ~/.claude/settings.local.json
```

This file is gitignored and never committed.

## License

MIT
