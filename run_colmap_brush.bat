@echo off
setlocal enabledelayedexpansion

REM ============================
REM Drag & Drop image folder
REM ============================
set IMAGES_DIR=%~1
if "%IMAGES_DIR%"=="" (
    echo Please drag an images folder onto this BAT file.
    pause
    exit /b 1
)

REM ============================
REM Parent project folder
REM ============================
for %%i in ("%IMAGES_DIR%\..") do set PROJECT_DIR=%%~fi

set DATABASE=%PROJECT_DIR%\database.db
set SPARSE=%PROJECT_DIR%\sparse
set DENSE=%PROJECT_DIR%\dense

mkdir "%SPARSE%" 2>nul
mkdir "%DENSE%" 2>nul

REM ============================
REM Set paths for COLMAP & Qt plugins
REM ============================
set COLMAP_PATH=E:\Semester_8th\Summer_2026\IIPP\Professor_Cheng-Hsin_Volumetric_Video_GS\GS\colmap-x64-windows-nocuda
set PATH=%COLMAP_PATH%\bin;%PATH%
set QT_QPA_PLATFORM_PLUGIN_PATH=%COLMAP_PATH%\plugins\platforms

REM ============================
REM Check if COLMAP folder exists
REM ============================
if not exist "%COLMAP_PATH%\bin\colmap.exe" (
    echo ERROR: colmap.exe not found in "%COLMAP_PATH%\bin"
    pause
    exit /b 1
)

REM ============================
REM Check if Qt plugin folder exists
REM ============================
if not exist "%QT_QPA_PLATFORM_PLUGIN_PATH%" (
    echo ERROR: Qt platform plugin folder not found in "%QT_QPA_PLATFORM_PLUGIN_PATH%"
    pause
    exit /b 1
)

REM ============================
REM COLMAP: Feature Extraction (CPU)
REM ============================
echo ============================
echo COLMAP: Feature Extraction (CPU)
echo ============================
colmap.exe feature_extractor ^
 --database_path "%DATABASE%" ^
 --image_path "%IMAGES_DIR%" ^
 --SiftExtraction.use_gpu 0

REM ============================
REM COLMAP: Feature Matching (CPU)
REM ============================
echo ============================
echo COLMAP: Matching (CPU)
echo ============================
colmap.exe exhaustive_matcher ^
 --database_path "%DATABASE%" ^
 --SiftMatching.use_gpu 0

REM ============================
REM COLMAP: Sparse Mapping
REM ============================
echo ============================
echo COLMAP: Sparse Mapping
echo ============================
colmap.exe mapper ^
 --database_path "%DATABASE%" ^
 --image_path "%IMAGES_DIR%" ^
 --output_path "%SPARSE%"

REM ============================
REM COLMAP: Dense Preparation
REM ============================
echo ============================
echo COLMAP: Dense Prep
echo ============================
colmap.exe image_undistorter ^
 --image_path "%IMAGES_DIR%" ^
 --input_path "%SPARSE%\0" ^
 --output_path "%DENSE%" ^
 --output_type COLMAP ^
 --max_image_size 2000

REM ============================
REM Export PLY
REM ============================
echo ============================
echo Export PLY
echo ============================
colmap.exe model_converter ^
 --input_path "%SPARSE%\0" ^
 --output_path "%SPARSE%\model.ply" ^
 --output_type PLY

REM ============================
REM Brush Gaussian Splat (Optional)
REM ============================
echo ============================
echo Start Brush Gaussian Splat
echo ============================
brush_app "%PROJECT_DIR%" ^
 --total-steps 10000 ^
 --max-resolution 1920 ^
 --export-every 5000 ^
 --export-path "%PROJECT_DIR%"

echo.
echo Brush Gaussian Splat finished successfully!
pause