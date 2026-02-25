# m4ore-claude-setup

Cross-platform one-command setup for Claude Code configuration, skills, and global instructions.

## Quick Start

### Linux / macOS

```bash
git clone <your-repo-url> ~/m4ore-claude-setup
cd ~/m4ore-claude-setup
chmod +x setup.sh && ./setup.sh
```

### Windows (CMD)

```cmd
git clone <your-repo-url> %USERPROFILE%\m4ore-claude-setup
cd %USERPROFILE%\m4ore-claude-setup
setup.bat
```

> PowerShell 也可以用：`.\setup.ps1`

## What It Does

The setup script creates symlinks from `~/.claude/` to this repo, so edits here take effect immediately.

| Target | Source | Strategy |
|--------|--------|----------|
| `~/.claude/settings.json` | `config/settings.json` | Symlink |
| `~/.claude/skills/` | `skills/` | Symlink (entire dir) |
| `~/.claude/CLAUDE.md` | `CLAUDE.md` | Symlink |
| `~/.claude/mcp.json` | *(not managed)* | Manual per-machine |
| `~/.claude/settings.local.json` | *(not managed)* | Manual per-machine |

The scripts also install these npm global packages (if not already installed):

- `typescript`
- `typescript-language-server`
- `@anthropic-ai/claude-code`
- `@tobilu/qmd`

## Windows Symlink Note

Windows requires **Developer Mode** enabled to create symlinks without admin.

- **Settings > Update & Security > For developers > Developer Mode**

If symlinks aren't available, `setup.bat` / `setup.ps1` automatically falls back to **Copy mode**. In Copy mode, after `git pull` you must re-run the setup script to sync changes.

## Updating

After pulling new changes:

- **Symlink mode** (Linux/macOS/Windows with Developer Mode): Changes take effect immediately.
- **Copy mode** (Windows without Developer Mode): Re-run `setup.bat` or `.\setup.ps1`.

## Repo Structure

```
m4ore-claude-setup/
├── README.md
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
    ├── plan-v1.md                         # Planning document
    └── design/                            # D4 Design Docs directory
```

## Local Settings

Copy the template and customize for each machine:

```bash
cp config/settings.local.example.json ~/.claude/settings.local.json
# Edit ~/.claude/settings.local.json with your API key, etc.
```

This file is gitignored and never committed.
