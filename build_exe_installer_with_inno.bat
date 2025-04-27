@echo off
REM Use UTF-8 without BOM encoding for this file
setlocal enabledelayedexpansion

echo ====== Flutter Windows App Installer Packaging Tool ======
echo This script will package your Flutter Windows app as an installer.
echo Make sure you have run 'flutter build windows' command successfully before using this tool.

REM Get current directory as project root
set "PROJECT_ROOT=%cd%"
set "BUILD_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release"
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

REM Ask for Inno Setup path
set "INNO_PATH=D:\DvptTools\Inno Setup 6\ISCC.exe"
set /p INNO_PATH=Enter Inno Setup compiler path (e.g. C:\Program Files (x86)\Inno Setup 6\ISCC.exe): 
if "%INNO_PATH%"=="" set "INNO_PATH=D:\DvptTools\Inno Setup 6\ISCC.exe"

if not exist "%INNO_PATH%" (
    echo Error: Cannot find Inno Setup compiler. Please download and install it from:
    echo https://jrsoftware.org/isdl.php
    goto :end
)

REM Set version number - default to 1.0.0 if not provided
set "APP_VERSION=1.0.0"
set /p APP_VERSION=Enter application version (e.g. 1.0.0) [default: 1.0.0]: 
if "%APP_VERSION%"=="" set "APP_VERSION=1.0.0"

REM Ask for publisher info - default to a value if not provided
set "PUBLISHER=swm.com"
set /p PUBLISHER=Enter publisher name [default:swm.com]: 
if "%PUBLISHER%"=="" set "PUBLISHER=swm.com"

REM Create output directory
set "OUTPUT_DIR=%PROJECT_ROOT%\installer"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Create a temp directory to copy required runtime files if they exist
set "TEMP_RUNTIME_DIR=%temp%\%APP_NAME%_runtime"
if exist "%TEMP_RUNTIME_DIR%" rmdir /s /q "%TEMP_RUNTIME_DIR%"
mkdir "%TEMP_RUNTIME_DIR%"

REM Check and copy runtime files if they exist
set "HAS_MSVCP140=0"
set "HAS_VCRUNTIME140=0"
set "HAS_VCRUNTIME140_1=0"

if exist "C:\Windows\System32\msvcp140.dll" (
    copy "C:\Windows\System32\msvcp140.dll" "%TEMP_RUNTIME_DIR%" >nul
    set "HAS_MSVCP140=1"
) else if exist "C:\Windows\SysWOW64\msvcp140.dll" (
    copy "C:\Windows\SysWOW64\msvcp140.dll" "%TEMP_RUNTIME_DIR%" >nul
    set "HAS_MSVCP140=1"
)

if exist "C:\Windows\System32\vcruntime140.dll" (
    copy "C:\Windows\System32\vcruntime140.dll" "%TEMP_RUNTIME_DIR%" >nul
    set "HAS_VCRUNTIME140=1"
) else if exist "C:\Windows\SysWOW64\vcruntime140.dll" (
    copy "C:\Windows\SysWOW64\vcruntime140.dll" "%TEMP_RUNTIME_DIR%" >nul
    set "HAS_VCRUNTIME140=1"
)

if exist "C:\Windows\System32\vcruntime140_1.dll" (
    copy "C:\Windows\System32\vcruntime140_1.dll" "%TEMP_RUNTIME_DIR%" >nul
    set "HAS_VCRUNTIME140_1=1"
) else if exist "C:\Windows\SysWOW64\vcruntime140_1.dll" (
    copy "C:\Windows\SysWOW64\vcruntime140_1.dll" "%TEMP_RUNTIME_DIR%" >nul
    set "HAS_VCRUNTIME140_1=1"
)

REM Temporary script file
set "ISS_FILE=%temp%\%APP_NAME%_installer.iss"

echo Creating Inno Setup script...

REM Generate .iss file
(
    echo #define MyAppName "%APP_NAME%"
    echo #define MyAppVersion "%APP_VERSION%"
    echo #define MyAppPublisher "%PUBLISHER%"
    echo #define MyAppExeName "%APP_NAME%.exe"
    echo.
    echo [Setup]
    echo AppId={{B8F27B67-57AF-4D96-B1E9-!RANDOM!!RANDOM!}}
    echo AppName={#MyAppName}
    echo AppVersion={#MyAppVersion}
    echo AppPublisher={#MyAppPublisher}
    echo DefaultDirName={autopf}\{#MyAppName}
    echo DefaultGroupName={#MyAppName}
    echo OutputDir=%OUTPUT_DIR%
    echo OutputBaseFilename=%APP_NAME%_Setup
    echo Compression=lzma
    echo SolidCompression=yes
    echo WizardStyle=modern
    echo.
    echo [Languages]
    echo Name: "english"; MessagesFile: "compiler:Default.isl"
    echo.
    echo [Tasks]
    echo Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
    echo Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode
    echo.
    echo [Files]
    echo Source: "%BUILD_DIR%\%APP_NAME%.exe"; DestDir: "{app}"; Flags: ignoreversion
    
    REM Add all DLL files
    for %%f in ("%BUILD_DIR%\*.dll") do (
        echo Source: "%BUILD_DIR%\%%~nxf"; DestDir: "{app}"; Flags: ignoreversion
    )
    
    REM Add C++ runtime files if they exist
    if "!HAS_MSVCP140!"=="1" (
        echo Source: "%TEMP_RUNTIME_DIR%\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
    )
    if "!HAS_VCRUNTIME140!"=="1" (
        echo Source: "%TEMP_RUNTIME_DIR%\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
    )
    if "!HAS_VCRUNTIME140_1!"=="1" (
        echo Source: "%TEMP_RUNTIME_DIR%\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
    )

    REM Add data directory (recursive)
    echo Source: "%BUILD_DIR%\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
    echo.
    echo [Icons]
    echo Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
    echo Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
    echo Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
    echo Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon
    echo.
    echo [Run]
    echo Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
) > "%ISS_FILE%"

echo Compiling installer...

REM Show generated file for debugging
echo Debugging: Generated ISS File contents:
type "%ISS_FILE%"
echo.

REM Execute compilation
"%INNO_PATH%" "%ISS_FILE%"

if exist "%OUTPUT_DIR%\%APP_NAME%_Setup.exe" (
    echo Success! Installer created: %OUTPUT_DIR%\%APP_NAME%_Setup.exe
) else (
    echo Failed! Please check:
    echo 1. Make sure all paths are correct
    echo 2. Check if Inno Setup is installed properly
    echo 3. Make sure you have sufficient permissions to write to the target directory
)

REM Clean up temporary files
rmdir /s /q "%TEMP_RUNTIME_DIR%" >nul 2>&1
REM del "%ISS_FILE%" >nul 2>&1

:end
pause 