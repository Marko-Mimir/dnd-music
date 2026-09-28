@echo off
setlocal enabledelayedexpansion

set "OWNER=marko-mimir"
set "REPO=dnd-music"
set "FILE_EXTENSION=.exe"
set "API_URL=https://api.github.com/repos/%OWNER%/%REPO%/releases/latest"

echo Fetching latest release...

for /f "tokens=2 delims=^"" %%F in (
    'curl -s "%API_URL%" ^| findstr /i "browser_download_url" ^| findstr /i "%FILE_EXTENSION%"'
) do (
    set "DOWNLOAD_URL=%%F"
    goto :download
)

echo Error: No %FILE_EXTENSION% asset found.
exit /b 1

:download
echo Found:
echo %DOWNLOAD_URL%
echo.
echo Downloading...

curl -L -O "%DOWNLOAD_URL%"

if errorlevel 1 (
    echo Download failed.
    exit /b 1
)

echo.
echo Download completed successfully!
exit /b 0