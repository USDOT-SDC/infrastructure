@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: pr-summary.cmd
:: 
:: Collects comprehensive git diff information for PR summary generation.
:: Output files are written to scripts/pr-summary-data/ with timestamps.
::
:: Usage:
::   pr-summary.cmd <source-branch> <target-branch>
::   pr-summary.cmd test stage
::
:: Author: Jeff Ussing
:: ============================================================================

if "%~1"=="" (
    echo Error: Source branch required
    echo Usage: pr-summary.cmd ^<source-branch^> ^<target-branch^>
    echo Example: pr-summary.cmd test stage
    exit /b 1
)

if "%~2"=="" (
    echo Error: Target branch required
    echo Usage: pr-summary.cmd ^<source-branch^> ^<target-branch^>
    echo Example: pr-summary.cmd test stage
    exit /b 1
)

set SOURCE_BRANCH=%~1
set TARGET_BRANCH=%~2

:: Check for uncommitted changes
echo Checking for uncommitted changes...
git diff --quiet
if errorlevel 1 (
    echo.
    echo ============================================================================
    echo ERROR: UNCOMMITTED CHANGES DETECTED
    echo ============================================================================
    echo.
    echo You have uncommitted changes in your working directory.
    echo This script needs to switch branches and requires a clean working tree.
    echo.
    echo Please commit or stash your changes before running this script:
    echo   git add .
    echo   git commit -m "your message"
    echo.
    echo Or to stash temporarily:
    echo   git stash
    echo   [run this script]
    echo   git stash pop
    echo.
    echo ============================================================================
    exit /b 1
)

git diff --cached --quiet
if errorlevel 1 (
    echo.
    echo ============================================================================
    echo ERROR: STAGED BUT UNCOMMITTED CHANGES DETECTED
    echo ============================================================================
    echo.
    echo You have staged changes that are not committed.
    echo Please commit them before running this script:
    echo   git commit -m "your message"
    echo.
    echo ============================================================================
    exit /b 1
)

echo Working directory is clean.
echo.

:: Generate timestamp for output files (YYYYMMDD-HHMMSS)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set TIMESTAMP=%datetime:~0,8%-%datetime:~8,6%

:: Get script directory and repo root
set SCRIPT_DIR=%~dp0
set REPO_ROOT=%SCRIPT_DIR%..

:: Create output directory if it doesn't exist
set OUTPUT_DIR=%SCRIPT_DIR%pr-summary-data
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

:: Create timestamped subdirectory
set OUTPUT_SUBDIR=%OUTPUT_DIR%\%SOURCE_BRANCH%-to-%TARGET_BRANCH%-%TIMESTAMP%
mkdir "%OUTPUT_SUBDIR%"

echo ============================================================================
echo Generating PR Summary Data
echo ============================================================================
echo Source Branch: %SOURCE_BRANCH%
echo Target Branch: %TARGET_BRANCH%
echo Output Directory: %OUTPUT_SUBDIR%
echo ============================================================================
echo.
echo IMPORTANT: Ensure both branches are up-to-date with origin:
echo   git checkout %TARGET_BRANCH% ^&^& git pull origin %TARGET_BRANCH%
echo   git checkout %SOURCE_BRANCH% ^&^& git pull origin %SOURCE_BRANCH%
echo.
echo Press Ctrl+C to abort, or any key to continue...
pause > nul
echo.

:: Check if branches are behind origin
echo Checking branch sync status...
git fetch origin > nul 2>&1

for %%B in (%SOURCE_BRANCH% %TARGET_BRANCH%) do (
    git rev-list %%B..origin/%%B --count > "%TEMP%\behind-%%B.txt" 2>nul
    set /p BEHIND_COUNT=<"%TEMP%\behind-%%B.txt"
    
    if defined BEHIND_COUNT (
        if !BEHIND_COUNT! GTR 0 (
            echo WARNING: Local branch %%B is !BEHIND_COUNT! commit^(s^) behind origin/%%B
            echo Run: git pull origin %%B
        )
    )
    
    del "%TEMP%\behind-%%B.txt" 2>nul
)
echo.

:: ============================================================================
:: 1. Branch Information
:: ============================================================================
echo [1/13] Collecting branch information...
(
    echo ============================================================================
    echo BRANCH INFORMATION
    echo ============================================================================
    echo.
    echo SOURCE BRANCH: %SOURCE_BRANCH%
    echo TARGET BRANCH: %TARGET_BRANCH%
    echo TIMESTAMP: %TIMESTAMP%
    echo.
    echo --- Current Branch ---
    git branch --show-current
    echo.
    echo --- All Local Branches ---
    git branch -v
    echo.
    echo --- Remote Branches ---
    git branch -r
    echo.
) > "%OUTPUT_SUBDIR%\01-branch-info.txt"

:: ============================================================================
:: 2. Version Analysis
:: ============================================================================
echo [2/13] Analyzing version tags...
(
    echo ============================================================================
    echo VERSION ANALYSIS
    echo ============================================================================
    echo.
    
    :: Get tag on HEAD of target branch
    git describe --exact-match --tags %TARGET_BRANCH% > "%OUTPUT_SUBDIR%\temp-tag.txt" 2>nul
    
    if exist "%OUTPUT_SUBDIR%\temp-tag.txt" (
        set /p CURRENT_TAG=<"%OUTPUT_SUBDIR%\temp-tag.txt"
        
        if defined CURRENT_TAG (
            echo Current Version on %TARGET_BRANCH%: !CURRENT_TAG!
            echo.
            
            :: Get change statistics for version suggestion
            git rev-list --count %TARGET_BRANCH%..%SOURCE_BRANCH% > "%OUTPUT_SUBDIR%\temp-commit-count.txt"
            set /p COMMIT_COUNT=<"%OUTPUT_SUBDIR%\temp-commit-count.txt"
            
            git diff %TARGET_BRANCH%...%SOURCE_BRANCH% --shortstat > "%OUTPUT_SUBDIR%\temp-shortstat.txt"
            set /p CHANGE_STAT=<"%OUTPUT_SUBDIR%\temp-shortstat.txt"
            
            echo Commits to be merged: !COMMIT_COUNT!
            echo Changes: !CHANGE_STAT!
            echo.
            echo --- Next Version Suggestion ---
            echo.
            echo Merging %SOURCE_BRANCH% into %TARGET_BRANCH%
            echo Changes include:
            echo - !COMMIT_COUNT! commit^(s^)
            echo - !CHANGE_STAT!
            echo.
            
            :: Simple heuristic for suggestion narrative
            if !COMMIT_COUNT! GTR 20 (
                echo This is a substantial merge with many commits. Consider a MINOR version bump
                echo if this introduces new features or significant functionality. If it's primarily
                echo bug fixes and incremental improvements, a PATCH bump may be appropriate.
            ) else if !COMMIT_COUNT! GTR 5 (
                echo This is a moderate-sized merge. Review the commit messages and file changes to
                echo determine if new features warrant a MINOR bump, or if it's primarily fixes and
                echo improvements suitable for a PATCH bump.
            ) else (
                echo This is a small merge. Unless it introduces breaking changes or significant new
                echo features, a PATCH bump is likely appropriate.
            )
            echo.
            
            del "%OUTPUT_SUBDIR%\temp-commit-count.txt" 2>nul
            del "%OUTPUT_SUBDIR%\temp-shortstat.txt" 2>nul
        ) else (
            echo No version tag found on HEAD of %TARGET_BRANCH%
        )
        
        del "%OUTPUT_SUBDIR%\temp-tag.txt" 2>nul
    ) else (
        echo No version tag found on HEAD of %TARGET_BRANCH%
    )
    echo.
) > "%OUTPUT_SUBDIR%\02-version-analysis.txt"

:: ============================================================================
:: 3. Commit Log (One-line)
:: ============================================================================
echo [3/13] Collecting commit history (one-line)...
git log %TARGET_BRANCH%..%SOURCE_BRANCH% --oneline > "%OUTPUT_SUBDIR%\03-commits-oneline.txt"

:: ============================================================================
:: 4. Commit Log (Detailed)
:: ============================================================================
echo [4/13] Collecting commit history (detailed)...
git log %TARGET_BRANCH%..%SOURCE_BRANCH% --pretty=format:"%%h - %%an, %%ar : %%s%%n%%b%%n" > "%OUTPUT_SUBDIR%\04-commits-detailed.txt"

:: ============================================================================
:: 5. File Statistics
:: ============================================================================
echo [5/13] Collecting file change statistics...
git diff %TARGET_BRANCH%...%SOURCE_BRANCH% --stat > "%OUTPUT_SUBDIR%\05-file-stats.txt"

:: ============================================================================
:: 6. File Name Status (A/M/D/R)
:: ============================================================================
echo [6/13] Collecting file name status...
git diff %TARGET_BRANCH%...%SOURCE_BRANCH% --name-status > "%OUTPUT_SUBDIR%\06-file-name-status.txt"

:: ============================================================================
:: 7. File Names Only (Changed)
:: ============================================================================
echo [7/13] Collecting changed file names...
git diff %TARGET_BRANCH%...%SOURCE_BRANCH% --name-only > "%OUTPUT_SUBDIR%\07-file-names-only.txt"

:: ============================================================================
:: 8. Summary Statistics
:: ============================================================================
echo [8/13] Generating summary statistics...
(
    echo ============================================================================
    echo SUMMARY STATISTICS
    echo ============================================================================
    echo.
    echo --- Commit Count ---
    git rev-list --count %TARGET_BRANCH%..%SOURCE_BRANCH%
    echo.
    echo --- Files Changed Summary ---
    git diff %TARGET_BRANCH%...%SOURCE_BRANCH% --shortstat
    echo.
) > "%OUTPUT_SUBDIR%\08-summary-stats.txt"

:: Get authors separately using temp file
git log %TARGET_BRANCH%..%SOURCE_BRANCH% --format="%%an" > "%OUTPUT_SUBDIR%\temp-authors.txt"
(
    echo --- Authors ---
    sort "%OUTPUT_SUBDIR%\temp-authors.txt"
    echo.
) >> "%OUTPUT_SUBDIR%\08-summary-stats.txt"
del "%OUTPUT_SUBDIR%\temp-authors.txt"

:: ============================================================================
:: 9. Terraform-Specific Changes
:: ============================================================================
echo [9/13] Collecting Terraform-specific changes...
git diff %TARGET_BRANCH%...%SOURCE_BRANCH% --name-status > "%OUTPUT_SUBDIR%\temp-all-files.txt"
(
    echo ============================================================================
    echo TERRAFORM FILES CHANGED
    echo ============================================================================
    echo.
    findstr "\.tf$" "%OUTPUT_SUBDIR%\temp-all-files.txt"
    echo.
) > "%OUTPUT_SUBDIR%\09-terraform-changes.txt"

git diff %TARGET_BRANCH%...%SOURCE_BRANCH% --stat > "%OUTPUT_SUBDIR%\temp-stat.txt"
(
    echo --- Terraform File Stats ---
    findstr "\.tf " "%OUTPUT_SUBDIR%\temp-stat.txt"
    echo.
) >> "%OUTPUT_SUBDIR%\09-terraform-changes.txt"
del "%OUTPUT_SUBDIR%\temp-all-files.txt"
del "%OUTPUT_SUBDIR%\temp-stat.txt"

:: ============================================================================
:: 10. Lambda-Specific Changes
:: ============================================================================
echo [10/13] Collecting Lambda-specific changes...
git diff %TARGET_BRANCH%...%SOURCE_BRANCH% --name-status > "%OUTPUT_SUBDIR%\temp-lambda.txt"
(
    echo ============================================================================
    echo LAMBDA FILES CHANGED
    echo ============================================================================
    echo.
    findstr "lambda" "%OUTPUT_SUBDIR%\temp-lambda.txt"
    echo.
    echo --- Python Files ---
    findstr "lambda.*\.py$" "%OUTPUT_SUBDIR%\temp-lambda.txt"
    echo.
) > "%OUTPUT_SUBDIR%\10-lambda-changes.txt"
del "%OUTPUT_SUBDIR%\temp-lambda.txt"

:: ============================================================================
:: 11. Added/Deleted Files
:: ============================================================================
echo [11/13] Collecting added and deleted files...
git diff %TARGET_BRANCH%...%SOURCE_BRANCH% --name-status > "%OUTPUT_SUBDIR%\temp-files.txt"
(
    echo ============================================================================
    echo ADDED FILES
    echo ============================================================================
    findstr "^A" "%OUTPUT_SUBDIR%\temp-files.txt"
    echo.
    echo ============================================================================
    echo DELETED FILES
    echo ============================================================================
    findstr "^D" "%OUTPUT_SUBDIR%\temp-files.txt"
    echo.
    echo ============================================================================
    echo RENAMED FILES
    echo ============================================================================
    findstr "^R" "%OUTPUT_SUBDIR%\temp-files.txt"
    echo.
) > "%OUTPUT_SUBDIR%\11-added-deleted-renamed.txt"
del "%OUTPUT_SUBDIR%\temp-files.txt"

:: ============================================================================
:: 12. Pull Request Template
:: ============================================================================
echo [12/13] Copying PR template...
if exist "%REPO_ROOT%\pull_request_template.md" (
    copy "%REPO_ROOT%\pull_request_template.md" "%OUTPUT_SUBDIR%\12-pr-template.md" > nul
) else (
    echo PR template not found > "%OUTPUT_SUBDIR%\12-pr-template.md"
)

:: ============================================================================
:: 13. README for AI
:: ============================================================================
echo [13/13] Generating README for AI...
(
    echo.
    echo ============================================================================
    echo README FOR AI
    echo ============================================================================
    echo.
    echo This directory contains comprehensive git diff data for generating a Pull Request summary.
    echo.
    echo Source Branch: %SOURCE_BRANCH%
    echo Target Branch: %TARGET_BRANCH%
    echo Generated: %TIMESTAMP%
    echo.
    echo ============================================================================
    echo FILE DESCRIPTIONS
    echo ============================================================================
    echo.
    echo 01-branch-info.txt          - Current branch state and remote tracking
    echo 02-version-analysis.txt     - Version tag analysis and bump suggestions
    echo 03-commits-oneline.txt      - One-line commit history
    echo 04-commits-detailed.txt     - Detailed commit messages with bodies
    echo 05-file-stats.txt           - File change statistics (insertions/deletions)
    echo 06-file-name-status.txt     - Files with status (Added/Modified/Deleted/Renamed)
    echo 07-file-names-only.txt      - Simple list of changed files
    echo 08-summary-stats.txt        - High-level statistics and authors
    echo 09-terraform-changes.txt    - Terraform-specific file changes
    echo 10-lambda-changes.txt       - Lambda-specific file changes
    echo 11-added-deleted-renamed.txt - Categorized file changes
    echo 12-pr-template.md           - Repository PR template
    echo 13-README.txt               - This file
    echo.
    echo ============================================================================
    echo HOW TO USE WITH AI
    echo ============================================================================
    echo.
    echo 1. Upload all .txt files to AI
    echo 2. Ask: "Based on these git diff files, write a comprehensive GitHub PR summary"
    echo 3. AI will analyze:
    echo    - What changed (from file stats and commit messages)
    echo    - Why it changed (from detailed commit messages)
    echo    - Impact of changes (from file types and statistics)
    echo    - Testing completed (from commit messages)
    echo    - Version recommendations (from version analysis)
    echo.
    echo 4. AI will generate:
    echo    - Executive summary
    echo    - Key changes by category
    echo    - Architecture changes (if applicable)
    echo    - Testing notes
    echo    - Deployment instructions
    echo    - Related tickets/issues
    echo    - Version bump recommendation
    echo.
    echo ============================================================================
    echo QUICK STATS
    echo ============================================================================
    echo.
    type "%OUTPUT_SUBDIR%\08-summary-stats.txt"
    echo.
) > "%OUTPUT_SUBDIR%\13-README.txt"

:: ============================================================================
:: Summary Report
:: ============================================================================
echo.
echo ============================================================================
echo GENERATION COMPLETE
echo ============================================================================
echo.
echo Output directory: %OUTPUT_SUBDIR%
echo.
echo Files generated:
dir /b "%OUTPUT_SUBDIR%"
echo.
echo ============================================================================
echo NEXT STEPS
echo ============================================================================
echo.
echo 1. Review the files in: %OUTPUT_SUBDIR%
echo 2. Upload all .txt files to AI
echo 3. Ask AI to write the PR summary
echo.
echo Quick preview of changes:
echo.
type "%OUTPUT_SUBDIR%\05-file-stats.txt"
echo.
echo ============================================================================

endlocal
