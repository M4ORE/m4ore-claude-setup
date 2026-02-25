#!/usr/bin/env bash
set -euo pipefail

# ─── Resolve paths ───────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$REPO_DIR/lib/common.sh"

CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/setup-$(date +%Y%m%d-%H%M%S)"

# ─── Detect OS ───────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Darwin) info "Detected: macOS" ;;
  Linux)  info "Detected: Linux" ;;
  *)      error "Unsupported OS: $OS"; exit 1 ;;
esac

# ─── Prerequisite checks ────────────────────────────────────────────────────
info "Checking prerequisites..."
MISSING=0
for cmd in node npm claude; do
  if ! require_cmd "$cmd"; then
    MISSING=1
  fi
done
if [ "$MISSING" -eq 1 ]; then
  error "Please install missing prerequisites and re-run."
  exit 1
fi
success "All prerequisites found"
echo ""

# ─── Create ~/.claude if needed ──────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR"

# ─── Symlinks ────────────────────────────────────────────────────────────────
info "Setting up symlinks..."
echo ""

# settings.json
create_symlink "$REPO_DIR/config/settings.json" "$CLAUDE_DIR/settings.json" "$BACKUP_DIR"

# skills/ (entire directory)
create_symlink "$REPO_DIR/skills" "$CLAUDE_DIR/skills" "$BACKUP_DIR"

# CLAUDE.md
create_symlink "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "$BACKUP_DIR"

# mcp.json - explicitly skipped
echo ""
info "Skipped: mcp.json (manual per-machine)"
echo ""

# ─── npm global packages ────────────────────────────────────────────────────
NPM_PACKAGES=("typescript" "typescript-language-server" "@anthropic-ai/claude-code" "@tobilu/qmd")

info "Checking npm global packages..."
for pkg in "${NPM_PACKAGES[@]}"; do
  if check_npm_global "$pkg"; then
    success "Already installed: $pkg"
  else
    info "Installing: $pkg"
    npm install -g "$pkg"
    success "Installed: $pkg"
  fi
done
echo ""

# ─── Verification ────────────────────────────────────────────────────────────
info "Verifying setup..."
ERRORS=0

# Verify symlinks
for link in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/skills" "$CLAUDE_DIR/CLAUDE.md"; do
  if [ -L "$link" ]; then
    success "Symlink OK: $link"
  else
    error "Not a symlink: $link"
    ERRORS=$((ERRORS + 1))
  fi
done

# Verify npm packages
for cmd_check in "tsc:typescript" "typescript-language-server:typescript-language-server" "qmd:@tobilu/qmd"; do
  cmd="${cmd_check%%:*}"
  pkg="${cmd_check##*:}"
  if command -v "$cmd" &>/dev/null; then
    success "$pkg: $($cmd --version 2>/dev/null || echo 'installed')"
  else
    warn "$pkg: command '$cmd' not in PATH (may still work via npx)"
  fi
done

echo ""

# ─── Summary ─────────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [ "$ERRORS" -eq 0 ]; then
  success "Setup complete! All symlinks verified."
else
  warn "Setup completed with $ERRORS error(s). Check above."
fi
echo ""
echo "  Symlinks:"
echo "    ~/.claude/settings.json  -> $REPO_DIR/config/settings.json"
echo "    ~/.claude/skills/        -> $REPO_DIR/skills/"
echo "    ~/.claude/CLAUDE.md      -> $REPO_DIR/CLAUDE.md"
echo ""
if [ -d "$BACKUP_DIR" ]; then
  echo "  Backups: $BACKUP_DIR"
  echo ""
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "Next Steps:"
echo "  1. Run 'claude' to verify everything works"
echo "  2. (Optional) Configure mcp.json manually if needed"
echo "  3. (Optional) cp config/settings.local.example.json ~/.claude/settings.local.json"
echo ""
