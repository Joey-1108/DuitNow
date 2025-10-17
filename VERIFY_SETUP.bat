@echo off
echo ====================================
echo  DuitNow Setup Verification
echo ====================================
echo.

echo [1/5] Checking Node.js...
node --version
if %errorlevel% neq 0 (
    echo ❌ Node.js not found! Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)
echo ✅ Node.js is installed
echo.

echo [2/5] Checking npm...
npm --version
if %errorlevel% neq 0 (
    echo ❌ npm not found!
    pause
    exit /b 1
)
echo ✅ npm is installed
echo.

echo [3/5] Checking Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo ⚠️ Flutter not found! Install from https://flutter.dev/
    echo    (You can still test with the web interface)
) else (
    echo ✅ Flutter is installed
)
echo.

echo [4/5] Checking Node modules...
if exist node_modules\ (
    echo ✅ node_modules folder exists
) else (
    echo ⚠️ node_modules not found. Installing dependencies...
    npm install
    if %errorlevel% neq 0 (
        echo ❌ npm install failed!
        pause
        exit /b 1
    )
    echo ✅ Dependencies installed
)
echo.

echo [5/5] Checking Flutter dependencies...
cd frontend
if exist pubspec.yaml (
    echo ✅ pubspec.yaml found
    flutter pub get
    if %errorlevel% neq 0 (
        echo ⚠️ Flutter pub get failed (you can still test with web interface)
    ) else (
        echo ✅ Flutter dependencies ready
    )
) else (
    echo ⚠️ pubspec.yaml not found in frontend folder
)
cd ..
echo.

echo ====================================
echo  Verification Complete!
echo ====================================
echo.
echo Next Steps:
echo   1. Run START_BACKEND.bat to start the server
echo   2. Open backend\test-page.html in your browser
echo      OR
echo      Run START_FLUTTER.bat for the mobile app
echo.
pause

