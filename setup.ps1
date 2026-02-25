#Requires -Version 5.1
<#
.SYNOPSIS
  Cross-platform Claude Code setup script for Windows.
.DESCRIPTION
  Sets up symlinks (or copies as fallback) for Claude Code configuration,
  installs required npm global packages, and verifies the setup.
#>

$ErrorActionPreference = "Stop"

# ─── Resolve paths ───────────────────────────────────────────────────────────
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupDir = Join-Path $ClaudeDir "backups\setup-$Timestamp"

# ─── Helper functions ────────────────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Blue }
function Write-Success { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

# ─── Detect symlink capability ───────────────────────────────────────────────
$CanSymlink = $false
$TestLink = Join-Path $env:TEMP "claude-setup-symlink-test-$(Get-Random)"
$TestTarget = Join-Path $env:TEMP "claude-setup-symlink-target-$(Get-Random)"

try {
    New-Item -ItemType File -Path $TestTarget -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path $TestLink -Target $TestTarget -ErrorAction Stop | Out-Null
    $CanSymlink = $true
    Remove-Item $TestLink -Force -ErrorAction SilentlyContinue
} catch {
    $CanSymlink = $false
} finally {
    Remove-Item $TestTarget -Force -ErrorAction SilentlyContinue
    Remove-Item $TestLink -Force -ErrorAction SilentlyContinue
}

if ($CanSymlink) {
    Write-Success "Symlink support detected"
} else {
    Write-Warn "Cannot create symlinks. Falling back to Copy mode."
    Write-Warn "To enable symlinks: Settings > Update & Security > For developers > Developer Mode"
    Write-Host ""
}

$Mode = if ($CanSymlink) { "symlink" } else { "copy" }

# ─── Prerequisite checks ────────────────────────────────────────────────────
Write-Info "Checking prerequisites..."
$Missing = @()
foreach ($cmd in @("node", "npm", "claude")) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Success "Found: $cmd"
    } else {
        Write-Err "Not found: $cmd"
        $Missing += $cmd
    }
}

if ($Missing.Count -gt 0) {
    Write-Err "Please install missing prerequisites: $($Missing -join ', ')"
    exit 1
}
Write-Host ""

# ─── Create ~/.claude if needed ──────────────────────────────────────────────
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

# ─── Link or Copy function ──────────────────────────────────────────────────
function Set-LinkOrCopy {
    param(
        [string]$Source,
        [string]$Target,
        [switch]$IsDirectory
    )

    # Check if target already correctly linked
    if ($CanSymlink -and (Test-Path $Target)) {
        $item = Get-Item $Target -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            $currentTarget = $item.Target
            if ($currentTarget -eq $Source) {
                Write-Success "Already linked: $Target -> $Source"
                return
            }
            Write-Info "Removing old symlink: $Target"
            Remove-Item $Target -Force -Recurse -ErrorAction SilentlyContinue
        } else {
            # Existing real file/directory - back it up
            Write-Warn "Backing up existing: $Target -> $BackupDir\"
            if (-not (Test-Path $BackupDir)) {
                New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
            }
            $backupName = Split-Path $Target -Leaf
            Move-Item $Target (Join-Path $BackupDir $backupName) -Force
        }
    } elseif (Test-Path $Target) {
        # Copy mode - remove old copy
        Write-Info "Removing old copy: $Target"
        Remove-Item $Target -Force -Recurse -ErrorAction SilentlyContinue
    }

    # Ensure parent directory exists
    $parentDir = Split-Path $Target -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if ($CanSymlink) {
        if ($IsDirectory) {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
        } else {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
        }
        Write-Success "Linked: $Target -> $Source"
    } else {
        if ($IsDirectory) {
            Copy-Item -Path $Source -Destination $Target -Recurse -Force
        } else {
            Copy-Item -Path $Source -Destination $Target -Force
        }
        Write-Success "Copied: $Source -> $Target"
    }
}

# ─── Symlinks / Copies ──────────────────────────────────────────────────────
Write-Info "Setting up $Mode..."
Write-Host ""

# settings.json
Set-LinkOrCopy -Source (Join-Path $RepoDir "config\settings.json") `
               -Target (Join-Path $ClaudeDir "settings.json")

# skills/ (entire directory)
Set-LinkOrCopy -Source (Join-Path $RepoDir "skills") `
               -Target (Join-Path $ClaudeDir "skills") `
               -IsDirectory

# CLAUDE.md
Set-LinkOrCopy -Source (Join-Path $RepoDir "CLAUDE.md") `
               -Target (Join-Path $ClaudeDir "CLAUDE.md")

Write-Host ""
Write-Info "Skipped: mcp.json (manual per-machine)"
Write-Host ""

# ─── npm global packages ────────────────────────────────────────────────────
$NpmPackages = @("typescript", "typescript-language-server", "@anthropic-ai/claude-code", "@tobilu/qmd")

Write-Info "Checking npm global packages..."
foreach ($pkg in $NpmPackages) {
    $installed = npm list -g --depth=0 $pkg 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Already installed: $pkg"
    } else {
        Write-Info "Installing: $pkg"
        npm install -g $pkg
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Installed: $pkg"
        } else {
            Write-Err "Failed to install: $pkg"
        }
    }
}
Write-Host ""

# ─── Verification ────────────────────────────────────────────────────────────
Write-Info "Verifying setup..."
$Errors = 0

# Verify links/copies
$targets = @(
    (Join-Path $ClaudeDir "settings.json"),
    (Join-Path $ClaudeDir "skills"),
    (Join-Path $ClaudeDir "CLAUDE.md")
)

foreach ($target in $targets) {
    if (Test-Path $target) {
        if ($CanSymlink) {
            $item = Get-Item $target -Force
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Write-Success "Symlink OK: $target"
            } else {
                Write-Warn "Exists but not a symlink: $target"
            }
        } else {
            Write-Success "Copy OK: $target"
        }
    } else {
        Write-Err "Missing: $target"
        $Errors++
    }
}

# Verify npm packages
$cmdChecks = @(
    @{ Cmd = "tsc";                        Pkg = "typescript" },
    @{ Cmd = "typescript-language-server";  Pkg = "typescript-language-server" },
    @{ Cmd = "qmd";                        Pkg = "@tobilu/qmd" }
)

foreach ($check in $cmdChecks) {
    $found = Get-Command $check.Cmd -ErrorAction SilentlyContinue
    if ($found) {
        try {
            $version = & $check.Cmd --version 2>$null
            Write-Success "$($check.Pkg): $version"
        } catch {
            Write-Success "$($check.Pkg): installed"
        }
    } else {
        Write-Warn "$($check.Pkg): command '$($check.Cmd)' not in PATH (may still work via npx)"
    }
}

Write-Host ""

# ─── Summary ─────────────────────────────────────────────────────────────────
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

if ($Errors -eq 0) {
    Write-Success "Setup complete! All targets verified."
} else {
    Write-Warn "Setup completed with $Errors error(s). Check above."
}

Write-Host ""
Write-Host "  Mode: $Mode"
Write-Host "  Targets:"
Write-Host "    ~/.claude/settings.json  -> $RepoDir\config\settings.json"
Write-Host "    ~/.claude/skills/        -> $RepoDir\skills\"
Write-Host "    ~/.claude/CLAUDE.md      -> $RepoDir\CLAUDE.md"
Write-Host ""

if (Test-Path $BackupDir) {
    Write-Host "  Backups: $BackupDir"
    Write-Host ""
}

if (-not $CanSymlink) {
    Write-Host ""
    Write-Warn "Running in COPY mode. After 'git pull', re-run setup.ps1 to sync changes."
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Info "Next Steps:"
Write-Host "  1. Copy config\settings.local.example.json to ~/.claude/settings.local.json"
Write-Host "  2. Configure mcp.json manually if needed"
Write-Host "  3. Run 'claude' to verify everything works"
Write-Host ""
