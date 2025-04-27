@echo off
REM Use UTF-8 without BOM encoding for this file
setlocal enabledelayedexpansion

echo ====== Flutter Windows App Portable Packaging Tool (7-Zip SFX) ======
echo This script will package your Flutter Windows app as a self-extracting executable
echo Make sure you have run 'flutter build windows' command successfully before using this tool.

REM Get current directory as project root
set "PROJECT_ROOT=%cd%"
set "BUILD_DIR=%PROJECT_ROOT%\build\windows\runner\Release"
if not exist "%BUILD_DIR%" (
    set "BUILD_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"
)

REM Check if Build directory exists
if not exist "%BUILD_DIR%" (
    echo Error: Build directory does not exist. Please run 'flutter build windows' first.
    goto :end
)

REM Get app name from .exe file in BUILD_DIR
for %%f in ("%BUILD_DIR%\*.exe") do (
    set "APP_NAME=%%~nf"
    goto :found_app
)
:found_app
if "%APP_NAME%"=="" (
    echo Error: No .exe file found in %BUILD_DIR%
    goto :end
)

echo Found application: %APP_NAME%
echo.

REM Ask for 7-Zip path
set "SEVENZIP_PATH=D:\AppOccupied\7-Zip\7z.exe"
set /p SEVENZIP_PATH=Enter 7-Zip executable path (e.g. C:\Program Files\7-Zip\7z.exe): 
if "%SEVENZIP_PATH%"=="" set "SEVENZIP_PATH=D:\AppOccupied\7-Zip\7z.exe"

if not exist "%SEVENZIP_PATH%" (
    echo Error: Cannot find 7-Zip. Please download and install it from:
    echo https://www.7-zip.org/download.html
    goto :end
)

REM Extract 7-Zip directory from path
for %%i in ("%SEVENZIP_PATH%") do set "SEVENZIP_DIR=%%~dpi"
set "SEVENZIP_DIR=%SEVENZIP_DIR:~0,-1%"
echo 7-Zip directory: %SEVENZIP_DIR%

REM Create output directory
set "OUTPUT_DIR=%PROJECT_ROOT%\portable"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Create temporary directory
set "TEMP_DIR=%PROJECT_ROOT%\temp\%APP_NAME%_portable"
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

REM Copy necessary files
echo Copying application files...
xcopy "%BUILD_DIR%\%APP_NAME%.exe" "%TEMP_DIR%\" /y
xcopy "%BUILD_DIR%\*.dll" "%TEMP_DIR%\" /y
xcopy "%BUILD_DIR%\data" "%TEMP_DIR%\data\" /s /e /y

REM Check and copy required runtime files
if exist "C:\Windows\System32\msvcp140.dll" (
    copy "C:\Windows\System32\msvcp140.dll" "%TEMP_DIR%\" /y
) else if exist "C:\Windows\SysWOW64\msvcp140.dll" (
    copy "C:\Windows\SysWOW64\msvcp140.dll" "%TEMP_DIR%\" /y
)

if exist "C:\Windows\System32\vcruntime140.dll" (
    copy "C:\Windows\System32\vcruntime140.dll" "%TEMP_DIR%\" /y
) else if exist "C:\Windows\SysWOW64\vcruntime140.dll" (
    copy "C:\Windows\SysWOW64\vcruntime140.dll" "%TEMP_DIR%\" /y
)

if exist "C:\Windows\System32\vcruntime140_1.dll" (
    copy "C:\Windows\System32\vcruntime140_1.dll" "%TEMP_DIR%\" /y
) else if exist "C:\Windows\SysWOW64\vcruntime140_1.dll" (
    copy "C:\Windows\SysWOW64\vcruntime140_1.dll" "%TEMP_DIR%\" /y
)

REM Create config file
set "CONFIG_FILE=%PROJECT_ROOT%\temp\%APP_NAME%_sfx_config.txt"
(
    echo ;!@Install@!UTF-8!
    echo Title="%APP_NAME% Portable Installation"
    echo BeginPrompt="Do you want to extract %APP_NAME% Portable?"
    echo RunProgram="%APP_NAME%.exe"
    echo ;!@InstallEnd@!
) > "%CONFIG_FILE%"

REM Set output file path to project root directory
set "OUTPUT_FILE=%OUTPUT_DIR%\%APP_NAME%_Portable.exe"

REM Execute packaging
echo Creating self-extracting archive...

REM Create temporary archive
set "TEMP_ARCHIVE=%PROJECT_ROOT%\temp\%APP_NAME%.7z"
"%SEVENZIP_PATH%" a -t7z "%TEMP_ARCHIVE%" "%TEMP_DIR%\*" -mx=9 -r

REM Confirm 7z file was created
if not exist "%TEMP_ARCHIVE%" (
    echo Archive creation failed!
    goto :cleanup
)

REM Find 7z SFX module - check multiple potential locations
set "SFX_MODULE=%SEVENZIP_DIR%\7z.sfx"
if not exist "%SFX_MODULE%" set "SFX_MODULE=%SEVENZIP_DIR%\7zCon.sfx"
if not exist "%SFX_MODULE%" set "SFX_MODULE=%ProgramFiles%\7-Zip\7z.sfx"
if not exist "%SFX_MODULE%" set "SFX_MODULE=%ProgramFiles(x86)%\7-Zip\7z.sfx"
if not exist "%SFX_MODULE%" set "SFX_MODULE=%ProgramFiles%\7-Zip\7zCon.sfx"
if not exist "%SFX_MODULE%" set "SFX_MODULE=%ProgramFiles(x86)%\7-Zip\7zCon.sfx"

REM If SFX module still not found, look in common locations
if not exist "%SFX_MODULE%" (
    echo SFX module not found in standard locations. Searching additional paths...
    for %%d in (D: C:) do (
        for %%p in ("\Program Files\7-Zip" "\Program Files (x86)\7-Zip" "\7-Zip" "\Apps\7-Zip") do (
            if exist "%%d%%p\7z.sfx" (
                set "SFX_MODULE=%%d%%p\7z.sfx"
                goto :sfx_found
            )
            if exist "%%d%%p\7zCon.sfx" (
                set "SFX_MODULE=%%d%%p\7zCon.sfx"
                goto :sfx_found
            )
        )
    )
)

:sfx_found
if not exist "%SFX_MODULE%" (
    echo ERROR: 7z.sfx module not found. Please download the complete 7-Zip package from:
    echo https://www.7-zip.org/download.html
    echo.
    echo Alternative: Copy 7z.sfx or 7zCon.sfx to the same directory as 7z.exe
    goto :cleanup
)

echo Using SFX module: %SFX_MODULE%

REM Create final executable
echo Creating self-extracting executable...
copy /b "%SFX_MODULE%" + "%CONFIG_FILE%" + "%TEMP_ARCHIVE%" "%OUTPUT_FILE%"

if exist "%OUTPUT_FILE%" (
    echo.
    echo Success! Portable executable created: %OUTPUT_FILE%
    echo File size: 
    for %%A in ("%OUTPUT_FILE%") do echo %%~zA bytes
) else (
    echo Failed! Please check permissions and path settings.
)

:cleanup
REM Clean up temporary files
echo Cleaning up temporary files...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
if exist "%TEMP_ARCHIVE%" del "%TEMP_ARCHIVE%"
if exist "%CONFIG_FILE%" del "%CONFIG_FILE%"

:end
pause 