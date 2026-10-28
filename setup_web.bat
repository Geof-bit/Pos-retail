@echo off
flutter create --platforms=web,android,ios .
if errorlevel 1 exit /b 1
flutter pub get
if errorlevel 1 exit /b 1
flutter run -d chrome
