@echo off
setlocal EnableDelayedExpansion

REM === Resolve paths ===
set "REPO_DIR=%~dp0"
if "!REPO_DIR:~-1!"=="\" set "REPO_DIR=!REPO_DIR:~0,-1!"
set "CLAUDE_DIR=%USERPROFILE%\.claude"

REM Timestamp for backups (locale-safe via PowerShell)
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "TIMESTAMP=%%i"
set "BACKUP_DIR=!CLAUDE_DIR!\backups\setup-!TIMESTAMP!"

chcp 65001 >nul 2>&1

echo.
echo   m4ore-claude-setup
echo   ========================================
echo.

REM === Detect symlink capability ===
set "CAN_SYMLINK=0"
set "TEST_TARGET=%TEMP%\claude-test-target-%RANDOM%"
set "TEST_LINK=%TEMP%\claude-test-link-%RANDOM%"

echo.> "!TEST_TARGET!"
mklink "!TEST_LINK!" "!TEST_TARGET!" >nul 2>&1
if !errorlevel! equ 0 set "CAN_SYMLINK=1"
del "!TEST_LINK!" >nul 2>&1
del "!TEST_TARGET!" >nul 2>&1

if "!CAN_SYMLINK!"=="1" (
    echo [OK] Symlink support detected
    set "MODE=symlink"
) else (
    echo [WARN] Cannot create symlinks - falling back to Copy mode
    echo [WARN] Enable Developer Mode to use symlinks
    set "MODE=copy"
)
echo.

REM === Prerequisite checks ===
echo [INFO] Checking prerequisites...
set "MISSING=0"

where node >nul 2>&1
if !errorlevel! equ 0 (echo [OK] Found: node) else (echo [ERROR] Not found: node & set "MISSING=1")

where npm >nul 2>&1
if !errorlevel! equ 0 (echo [OK] Found: npm) else (echo [ERROR] Not found: npm & set "MISSING=1")

where claude >nul 2>&1
if !errorlevel! equ 0 (echo [OK] Found: claude) else (echo [ERROR] Not found: claude & set "MISSING=1")

if "!MISSING!"=="1" (
    echo [ERROR] Please install missing prerequisites and re-run.
    goto :end
)
echo.

REM === Create ~/.claude if needed ===
if not exist "!CLAUDE_DIR!" mkdir "!CLAUDE_DIR!"

REM === Setup symlinks / copies ===
echo [INFO] Setting up !MODE!...
echo.
set "ERRORS=0"

set "_SRC=!REPO_DIR!\config\settings.json"
set "_TGT=!CLAUDE_DIR!\settings.json"
set "_TYPE=file"
call :DoLink

set "_SRC=!REPO_DIR!\skills"
set "_TGT=!CLAUDE_DIR!\skills"
set "_TYPE=dir"
call :DoLink

set "_SRC=!REPO_DIR!\CLAUDE.md"
set "_TGT=!CLAUDE_DIR!\CLAUDE.md"
set "_TYPE=file"
call :DoLink

echo.
echo [INFO] Skipped: mcp.json ^(manual per-machine^)
echo.

REM === npm global packages ===
echo [INFO] Checking npm global packages...

call :NpmEnsure typescript
call :NpmEnsure typescript-language-server
call :NpmEnsure @anthropic-ai/claude-code
call :NpmEnsure @tobilu/qmd

echo.

REM === Verification ===
echo [INFO] Verifying setup...

for %%F in ("!CLAUDE_DIR!\settings.json" "!CLAUDE_DIR!\skills" "!CLAUDE_DIR!\CLAUDE.md") do (
    if exist %%F (
        echo [OK] Exists: %%~F
    ) else (
        echo [ERROR] Missing: %%~F
        set /a ERRORS+=1
    )
)

where tsc >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%v in ('tsc --version 2^>nul') do echo [OK] typescript: %%v
) else (
    echo [WARN] typescript: tsc not in PATH
)

where typescript-language-server >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%v in ('typescript-language-server --version 2^>nul') do echo [OK] typescript-language-server: %%v
) else (
    echo [WARN] typescript-language-server: not in PATH
)

where qmd >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%v in ('qmd --version 2^>nul') do echo [OK] qmd: %%v
) else (
    echo [WARN] qmd: not in PATH
)

echo.

REM === Summary ===
echo ========================================================
echo.
if "!ERRORS!"=="0" (
    echo [OK] Setup complete! All targets verified.
) else (
    echo [WARN] Setup completed with !ERRORS! error^(s^).
)
echo.
echo   Mode: !MODE!
echo   Targets:
echo     %USERPROFILE%\.claude\settings.json  --^> config\settings.json
echo     %USERPROFILE%\.claude\skills\        --^> skills\
echo     %USERPROFILE%\.claude\CLAUDE.md      --^> CLAUDE.md
echo.
if exist "!BACKUP_DIR!" echo   Backups: !BACKUP_DIR!
if "!CAN_SYMLINK!"=="0" (
    echo [WARN] COPY mode: after git pull, re-run setup.bat to sync.
)
echo.
echo ========================================================
echo.
echo [INFO] Next Steps:
echo   1. copy config\settings.local.example.json %USERPROFILE%\.claude\settings.local.json
echo   2. Configure mcp.json manually if needed
echo   3. Run 'claude' to verify everything works
echo.
goto :end

REM ================================================================
REM  DoLink - uses _SRC, _TGT, _TYPE variables set by caller
REM ================================================================
:DoLink
if not exist "!_TGT!" goto :DoLink_Create

REM Target exists - back it up first
if not exist "!BACKUP_DIR!" mkdir "!BACKUP_DIR!"
echo [WARN] Backing up: !_TGT!
if "!_TYPE!"=="dir" (
    xcopy "!_TGT!" "!BACKUP_DIR!\skills\" /E /I /Q /Y >nul 2>&1
    rmdir /S /Q "!_TGT!" >nul 2>&1
) else (
    copy /Y "!_TGT!" "!BACKUP_DIR!\" >nul 2>&1
    del /F "!_TGT!" >nul 2>&1
)

:DoLink_Create
if "!CAN_SYMLINK!"=="0" goto :DoLink_Copy

REM Symlink mode
if "!_TYPE!"=="dir" (
    mklink /D "!_TGT!" "!_SRC!" >nul 2>&1
) else (
    mklink "!_TGT!" "!_SRC!" >nul 2>&1
)
if !errorlevel! equ 0 (
    echo [OK] Linked: !_TGT!
) else (
    echo [ERROR] Failed to link: !_TGT!
    set /a ERRORS+=1
)
goto :eof

:DoLink_Copy
if "!_TYPE!"=="dir" (
    xcopy "!_SRC!" "!_TGT!" /E /I /Q /Y >nul 2>&1
) else (
    copy /Y "!_SRC!" "!_TGT!" >nul 2>&1
)
if !errorlevel! equ 0 (
    echo [OK] Copied: !_TGT!
) else (
    echo [ERROR] Failed to copy: !_TGT!
    set /a ERRORS+=1
)
goto :eof

REM ================================================================
REM  NpmEnsure - install npm package if not present
REM ================================================================
:NpmEnsure
set "_PKG=%~1"
<nul set /p="       Checking: !_PKG! ... "
npm list -g --depth=0 --offline "!_PKG!" >nul 2>&1
if !errorlevel! equ 0 (
    echo already installed
    goto :eof
)
echo not found, installing...
npm install -g "!_PKG!"
if !errorlevel! equ 0 (
    echo [OK] Installed: !_PKG!
) else (
    echo [ERROR] Failed to install: !_PKG!
)
goto :eof

:end
endlocal
