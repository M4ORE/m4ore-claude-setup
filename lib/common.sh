#!/usr/bin/env bash
# common.sh - Shared helper functions for setup scripts

# Colors (auto-disabled if not a terminal)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# create_symlink <source> <target>
# Creates a symlink at <target> pointing to <source>.
# If <target> already exists and is not a symlink to <source>, backs it up first.
create_symlink() {
  local source="$1"
  local target="$2"
  local backup_dir="$3"

  if [ -L "$target" ]; then
    local current_target
    current_target="$(readlink "$target")"
    if [ "$current_target" = "$source" ]; then
      success "Already linked: $target -> $source"
      return 0
    fi
    info "Removing old symlink: $target -> $current_target"
    rm -f "$target"
  elif [ -e "$target" ]; then
    warn "Backing up existing: $target -> $backup_dir/"
    mkdir -p "$backup_dir"
    mv "$target" "$backup_dir/"
  fi

  mkdir -p "$(dirname "$target")"
  ln -sf "$source" "$target"
  success "Linked: $target -> $source"
}

# require_cmd <command_name>
# Exits with error if command is not found in PATH.
require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    error "Required command not found: $cmd"
    error "Please install '$cmd' before running this script."
    return 1
  fi
}

# check_npm_global <package_name>
# Returns 0 if the npm global package is installed, 1 otherwise.
check_npm_global() {
  local pkg="$1"
  npm list -g --depth=0 "$pkg" &>/dev/null
}
