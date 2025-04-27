@echo off
REM Use UTF-8 without BOM encoding for this file
setlocal enabledelayedexpansion

echo ====== Flutter Windows App Portable Packaging Tool ======
echo This script will package your Flutter Windows app as a portable single-file executable
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

REM Ask for Enigma Virtual Box path
set "ENIGMA_PATH=D:\DvptTools\Enigma Virtual Box\enigmavbconsole.exe"
set /p ENIGMA_PATH=Enter full path to enigmavbconsole.exe(eg. D:\DvptTools\Enigma Virtual Box\enigmavbconsole.exe): 

if not exist "%ENIGMA_PATH%" (
    echo Error: Cannot find Enigma Virtual Box console. Please enter the correct path.
    goto :end
)

REM Get path to Enigma Virtual Box directory
for %%i in ("%ENIGMA_PATH%") do set "ENIGMA_DIR=%%~dpi"
set "ENIGMA_DIR=%ENIGMA_DIR:~0,-1%"

REM Check for GUI version
set "ENIGMA_GUI=%ENIGMA_DIR%\enigmavb.exe"
if not exist "%ENIGMA_GUI%" (
    set "ENIGMA_GUI=%ENIGMA_DIR%\EnigmaVB.exe"
)
if not exist "%ENIGMA_GUI%" (
    set "ENIGMA_GUI=%ENIGMA_DIR%\Enigma Virtual Box.exe"
)

REM Create output directory
set "OUTPUT_DIR=%PROJECT_ROOT%\portable"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Set output filename
set "OUTPUT_EXE=%OUTPUT_DIR%\%APP_NAME%_Portable.exe"

REM Create temp directory for the project
set "TEMP_DIR=%PROJECT_ROOT%\temp"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

REM ========== STEP 1: Create an EVB project file using GUI format ==========
set "EVB_FILE=%TEMP_DIR%\%APP_NAME%.evb"

echo Creating EVB project file...
(
echo [Project]
echo Version=1
echo OutputFile=%OUTPUT_EXE%
echo InputFile=%BUILD_DIR%\%APP_NAME%.exe
echo.
echo [Options]
echo FileOptions=16385
echo FilesCompressed=0
echo.
echo [Files]
echo Count=1
echo File_0=%BUILD_DIR%\%APP_NAME%.exe
) > "%EVB_FILE%"

REM Add all DLL files
set "FILE_COUNT=1"
for %%f in ("%BUILD_DIR%\*.dll") do (
    echo File_!FILE_COUNT!=%BUILD_DIR%\%%~nxf>> "%EVB_FILE%"
    set /a "FILE_COUNT+=1"
)

REM Update file count
echo Updating file count to !FILE_COUNT!...
type "%EVB_FILE%" > "%TEMP_DIR%\temp.evb"
powershell -Command "(Get-Content '%TEMP_DIR%\temp.evb') -replace 'Count=1', 'Count=!FILE_COUNT!' | Set-Content '%EVB_FILE%'"

echo Project file created at: %EVB_FILE%
echo.

REM ========== STEP 2: Create package template file ==========
set "PACKAGE_TEMPLATE=%TEMP_DIR%\%APP_NAME%_package.evb.template"
echo Creating package template file...
(
echo [Template]
echo Name=%APP_NAME% Portable Package
echo [Files]
echo %BUILD_DIR%\%APP_NAME%.exe
) > "%PACKAGE_TEMPLATE%"

REM Add all DLL files to package template
for %%f in ("%BUILD_DIR%\*.dll") do (
    echo %BUILD_DIR%\%%~nxf>> "%PACKAGE_TEMPLATE%"
)

REM Add data folder reference
echo [Folders]>> "%PACKAGE_TEMPLATE%"
echo %BUILD_DIR%\data>> "%PACKAGE_TEMPLATE%"

REM Create package output file path
set "PACKAGE_DAT=%TEMP_DIR%\%APP_NAME%_package.dat"

REM ========== STEP 3: Create additional project formats ==========
REM Create simplified project file
set "SIMPLE_EVB=%TEMP_DIR%\%APP_NAME%_simple.evb"
(
echo ;Simple project file format
echo [Input]
echo File=%BUILD_DIR%\%APP_NAME%.exe
echo [Output]
echo File=%OUTPUT_EXE%
) > "%SIMPLE_EVB%"

REM Create ultra simplified project file
set "ULTRA_SIMPLE_EVB=%TEMP_DIR%\%APP_NAME%_ultra_simple.txt"
(
echo InputFileName=%BUILD_DIR%\%APP_NAME%.exe
echo OutputFileName=%OUTPUT_EXE%
) > "%ULTRA_SIMPLE_EVB%"

REM ========== STEP 4: Try multiple command line formats ==========
echo Attempting Enigma Virtual Box packaging with multiple methods...
echo.

REM Method 1 - Standard project format
echo Method 1: Standard project file - enigmavbconsole.exe project.evb
echo Running: "%ENIGMA_PATH%" "%EVB_FILE%"
echo.

"%ENIGMA_PATH%" "%EVB_FILE%"
if %ERRORLEVEL% EQU 0 (
    if exist "%OUTPUT_EXE%" (
        echo Method 1 succeeded!
        goto :success
    )
)

echo Method 1 failed, trying Method 2...
echo.

REM Method 2 - Package creation method
echo Method 2: Package creation - enigmavbconsole.exe project.evb package.evb.template output_package.dat
echo Running: "%ENIGMA_PATH%" "%EVB_FILE%" "%PACKAGE_TEMPLATE%" "%PACKAGE_DAT%"
echo.

"%ENIGMA_PATH%" "%EVB_FILE%" "%PACKAGE_TEMPLATE%" "%PACKAGE_DAT%"
if %ERRORLEVEL% EQU 0 (
    if exist "%PACKAGE_DAT%" (
        echo Package file created at: %PACKAGE_DAT%
        echo Now applying package to the executable...
        "%ENIGMA_PATH%" "%EVB_FILE%" -input "%BUILD_DIR%\%APP_NAME%.exe" -output "%OUTPUT_EXE%"
        if exist "%OUTPUT_EXE%" (
            echo Method 2 succeeded!
            goto :success
        )
    )
)

echo Method 2 failed, trying Method 3...
echo.

REM Method 3 - Simplified format
echo Method 3: Simplified project file
echo Running: "%ENIGMA_PATH%" "%SIMPLE_EVB%"
echo.

"%ENIGMA_PATH%" "%SIMPLE_EVB%"
if %ERRORLEVEL% EQU 0 (
    if exist "%OUTPUT_EXE%" (
        echo Method 3 succeeded!
        goto :success
    )
)

echo Method 3 failed, trying Method 4...
echo.

REM Method 4 - Direct input/output parameters
echo Method 4: Direct parameters
echo Running: "%ENIGMA_PATH%" "%EVB_FILE%" -input "%BUILD_DIR%\%APP_NAME%.exe" -output "%OUTPUT_EXE%"
echo.

"%ENIGMA_PATH%" "%EVB_FILE%" -input "%BUILD_DIR%\%APP_NAME%.exe" -output "%OUTPUT_EXE%"
if %ERRORLEVEL% EQU 0 (
    if exist "%OUTPUT_EXE%" (
        echo Method 4 succeeded!
        goto :success
    )
)

echo Method 4 failed, trying Method 5...
echo.

REM Method 5 - Ultra simplified project file
echo Method 5: Ultra simplified project file
echo Running: "%ENIGMA_PATH%" "%ULTRA_SIMPLE_EVB%"
echo.

"%ENIGMA_PATH%" "%ULTRA_SIMPLE_EVB%"
if %ERRORLEVEL% EQU 0 (
    if exist "%OUTPUT_EXE%" (
        echo Method 5 succeeded!
        goto :success
    )
)

echo.
echo All automated methods failed.

REM ========== STEP 5: Create GUI project file and launch GUI ==========
echo.
echo Creating a project file for the GUI and launching Enigma Virtual Box...
set "GUI_EVB=%PROJECT_ROOT%\%APP_NAME%_for_gui.evb"

(
echo [Project]
echo ApplicationName=%APP_NAME%
echo ApplicationVersion=1.0
echo InputFileName=%BUILD_DIR%\%APP_NAME%.exe
echo OutputFileName=%OUTPUT_EXE%
echo.
echo [Files]
) > "%GUI_EVB%"

REM Add all files
echo "%BUILD_DIR%\%APP_NAME%.exe" = "%%DEFAULT FOLDER%%\%APP_NAME%.exe" >> "%GUI_EVB%"
for %%f in ("%BUILD_DIR%\*.dll") do (
    echo "%%f" = "%%DEFAULT FOLDER%%\%%~nxf" >> "%GUI_EVB%"
)

(
echo.
echo [Folders]
echo "%BUILD_DIR%\data" = "%%DEFAULT FOLDER%%\data"
) >> "%GUI_EVB%"

echo.
echo Created GUI project file at: %GUI_EVB%
echo.

if exist "%ENIGMA_GUI%" (
    echo Starting Enigma Virtual Box GUI with the project...
    echo Please click the "Process" button in the GUI to create the portable executable.
    echo.
    start "" "%ENIGMA_GUI%" "%GUI_EVB%"
) else (
    echo Manual instructions:
    echo 1. Open Enigma Virtual Box GUI
    echo 2. Open the project file: %GUI_EVB%
    echo 3. Click "Process" button to create the portable executable
)
echo.
goto :end

:success
echo.
echo Success! Portable executable created: %OUTPUT_EXE%
echo File size:
for %%A in ("%OUTPUT_EXE%") do echo %%~zA bytes
echo.
echo Note: The generated program might be flagged by antivirus software.
echo Add it to exceptions if needed.

:end
pause