@echo off
echo ====================================
echo  DuitNow QR Test Flutter App
echo ====================================
echo.
echo Installing dependencies...
cd frontend
call flutter pub get
echo.
echo Starting Flutter app in Chrome...
echo.
call flutter run -d chrome
pause

