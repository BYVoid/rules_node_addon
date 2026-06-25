@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "runfiles_dir=%RUNFILES_DIR%"
set "manifest=%RUNFILES_MANIFEST_FILE%"

if defined runfiles_dir if exist "%runfiles_dir%" goto runfiles_found
if exist "%~f0.runfiles" (
  set "runfiles_dir=%~f0.runfiles"
  goto runfiles_found
)
if defined manifest if exist "%manifest%" goto runfiles_found
if exist "%~f0.runfiles_manifest" (
  set "manifest=%~f0.runfiles_manifest"
  goto runfiles_found
)

echo bun_run_test: unable to locate runfiles for %~f0 1>&2
exit /b 1

:runfiles_found
call :rlocation "{{PACKAGE_JSON_PATH}}" package_json
if errorlevel 1 exit /b 1
for %%I in ("%package_json%") do set "workspace=%%~dpI"
if "%workspace:~-1%"=="\" set "workspace=%workspace:~0,-1%"

call :rlocation "{{BUN_PATH}}" bun
if errorlevel 1 exit /b 1
for %%I in ("%bun%") do set "bun_dir=%%~dpI"
call :rlocation "{{NODE_PATH}}" node
if errorlevel 1 exit /b 1
for %%I in ("%node%") do set "node_dir=%%~dpI"
{{RUNFILES_ENV}}

cd /d "%workspace%"
if errorlevel 1 exit /b 1

set "BUN_INSTALL_NO_TRACK=1"
set "DO_NOT_TRACK=1"
set "NO_COLOR=1"
set "HOME=%TEST_TMPDIR%"
if not defined HOME set "HOME=%TEMP%"
set "XDG_CACHE_HOME=%HOME%\.cache"
set "PATH=%node_dir%;%bun_dir%;%workspace%\node_modules\.bin;%PATH%"

"%bun%" run {{SCRIPT}} {{ARGS}}
exit /b %ERRORLEVEL%

:rlocation
set "runfile_key=%~1"
set "result_var=%~2"
if defined runfiles_dir (
  set "candidate=%runfiles_dir%\%runfile_key:/=\%"
  if exist "!candidate!" (
    set "%result_var%=!candidate!"
    exit /b 0
  )
)
if not defined manifest goto missing_runfile
for /f "usebackq tokens=1,* delims= " %%A in ("%manifest%") do (
  if "%%A"=="%runfile_key%" (
    set "%result_var%=%%B"
    exit /b 0
  )
)
:missing_runfile
echo bun_run_test: missing runfile %runfile_key% 1>&2
exit /b 1
