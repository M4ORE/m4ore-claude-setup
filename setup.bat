@echo off
setlocal EnableDelayedExpansion

:: ─── Resolve paths ──────────────────────────────────────────────────────────
set "REPO_DIR=%~dp0"
:: Remove trailing backslash
if "%REPO_DIR:~-1%"=="\" set "REPO_DIR=%REPO_DIR:~0,-1%"

set "CLAUDE_DIR=%USERPROFILE%\.claude"

:: Timestamp for backups
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "DT=%%I"
set "TIMESTAMP=%DT:~0,4%%DT:~4,2%%DT:~6,2%-%DT:~8,2%%DT:~10,2%%DT:~12,2%"
set "BACKUP_DIR=%CLAUDE_DIR%\backups\setup-%TIMESTAMP%"

echo.
echo  m4ore-claude-setup
echo  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

:: ─── Detect symlink capability ──────────────────────────────────────────────
set "CAN_SYMLINK=0"
set "TEST_TARGET=%TEMP%\claude-setup-test-target-%RANDOM%"
set "TEST_LINK=%TEMP%\claude-setup-test-link-%RANDOM%"

echo.> "%TEST_TARGET%"
mklink "%TEST_LINK%" "%TEST_TARGET%" >nul 2>&1
if !errorlevel! equ 0 (
    set "CAN_SYMLINK=1"
    del "%TEST_LINK%" >nul 2>&1
)
del "%TEST_TARGET%" >nul 2>&1

if "!CAN_SYMLINK!"=="1" (
    echo [OK] Symlink support detected
    set "MODE=symlink"
) else (
    echo [WARN] Cannot create symlinks. Falling back to Copy mode.
    echo [WARN] To enable: Settings ^> Update ^& Security ^> For developers ^> Developer Mode
    set "MODE=copy"
)
echo.

:: ─── Prerequisite checks ───────────────────────────────────────────────────
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

:: ─── Create ~/.claude if needed ─────────────────────────────────────────────
if not exist "%CLAUDE_DIR%" mkdir "%CLAUDE_DIR%"

:: ─── Setup links/copies ────────────────────────────────────────────────────
echo [INFO] Setting up %MODE%...
echo.

:: --- settings.json ---
call :LinkOrCopy "%REPO_DIR%\config\settings.json" "%CLAUDE_DIR%\settings.json" "file"

:: --- skills/ (entire directory) ---
call :LinkOrCopy "%REPO_DIR%\skills" "%CLAUDE_DIR%\skills" "dir"

:: --- CLAUDE.md ---
call :LinkOrCopy "%REPO_DIR%\CLAUDE.md" "%CLAUDE_DIR%\CLAUDE.md" "file"

echo.
echo [INFO] Skipped: mcp.json (manual per-machine)
echo.

:: ─── npm global packages ────────────────────────────────────────────────────
echo [INFO] Checking npm global packages...

call :NpmEnsure typescript
call :NpmEnsure typescript-language-server
call :NpmEnsure @anthropic-ai/claude-code
call :NpmEnsure @tobilu/qmd

echo.

:: ─── Verification ───────────────────────────────────────────────────────────
echo [INFO] Verifying setup...
set "ERRORS=0"

call :VerifyTarget "%CLAUDE_DIR%\settings.json"
call :VerifyTarget "%CLAUDE_DIR%\skills"
call :VerifyTarget "%CLAUDE_DIR%\CLAUDE.md"

:: Verify npm commands
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

:: ─── Summary ────────────────────────────────────────────────────────────────
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
if "!ERRORS!"=="0" (
    echo [OK] Setup complete! All targets verified.
) else (
    echo [WARN] Setup completed with !ERRORS! error(s). Check above.
)
echo.
echo   Mode: %MODE%
echo   Targets:
echo     ~/.claude/settings.json  -^> %REPO_DIR%\config\settings.json
echo     ~/.claude/skills/        -^> %REPO_DIR%\skills\
echo     ~/.claude/CLAUDE.md      -^> %REPO_DIR%\CLAUDE.md
echo.
if exist "%BACKUP_DIR%" (
    echo   Backups: %BACKUP_DIR%
    echo.
)
if "!CAN_SYMLINK!"=="0" (
    echo [WARN] Running in COPY mode. After 'git pull', re-run setup.bat to sync changes.
    echo.
)
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo [INFO] Next Steps:
echo   1. Copy config\settings.local.example.json to %%USERPROFILE%%\.claude\settings.local.json
echo   2. Configure mcp.json manually if needed
echo   3. Run 'claude' to verify everything works
echo.
goto :end

:: ════════════════════════════════════════════════════════════════════════════
:: Subroutines
:: ════════════════════════════════════════════════════════════════════════════

:LinkOrCopy
:: %1 = source, %2 = target, %3 = "file" or "dir"
set "SRC=%~1"
set "TGT=%~2"
set "TYPE=%~3"

:: Check if target is already a symlink pointing to the right place
:: (fsutil can detect reparse points)
if exist "%TGT%" (
    fsutil reparsepoint query "%TGT%" >nul 2>&1
    if !errorlevel! equ 0 (
        :: It's a reparse point (symlink/junction) — remove and recreate
        if "%TYPE%"=="dir" (
            rmdir "%TGT%" >nul 2>&1
        ) else (
            del "%TGT%" >nul 2>&1
        )
    ) else (
        :: Real file/dir — back it up
        if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
        echo [WARN] Backing up existing: %TGT%
        move "%TGT%" "%BACKUP_DIR%\" >nul 2>&1
    )
)

if "!CAN_SYMLINK!"=="1" (
    if "%TYPE%"=="dir" (
        mklink /D "%TGT%" "%SRC%" >nul 2>&1
    ) else (
        mklink "%TGT%" "%SRC%" >nul 2>&1
    )
    if !errorlevel! equ 0 (
        echo [OK] Linked: %TGT% -^> %SRC%
    ) else (
        echo [ERROR] Failed to create symlink: %TGT%
        set /a ERRORS+=1
    )
) else (
    if "%TYPE%"=="dir" (
        xcopy "%SRC%" "%TGT%" /E /I /Q /Y >nul 2>&1
    ) else (
        copy /Y "%SRC%" "%TGT%" >nul 2>&1
    )
    if !errorlevel! equ 0 (
        echo [OK] Copied: %SRC% -^> %TGT%
    ) else (
        echo [ERROR] Failed to copy: %TGT%
        set /a ERRORS+=1
    )
)
goto :eof

:NpmEnsure
:: %1 = package name
set "PKG=%~1"
npm list -g --depth=0 "%PKG%" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Already installed: %PKG%
) else (
    echo [INFO] Installing: %PKG%
    npm install -g "%PKG%"
    if !errorlevel! equ 0 (
        echo [OK] Installed: %PKG%
    ) else (
        echo [ERROR] Failed to install: %PKG%
    )
)
goto :eof

:VerifyTarget
set "CHECK=%~1"
if exist "%CHECK%" (
    if "!CAN_SYMLINK!"=="1" (
        fsutil reparsepoint query "%CHECK%" >nul 2>&1
        if !errorlevel! equ 0 (
            echo [OK] Symlink OK: %CHECK%
        ) else (
            echo [WARN] Exists but not a symlink: %CHECK%
        )
    ) else (
        echo [OK] Copy OK: %CHECK%
    )
) else (
    echo [ERROR] Missing: %CHECK%
    set /a ERRORS+=1
)
goto :eof

:end
endlocal
