@echo off
title Biblionet Web
cd /d "%~dp0backend"
if not exist node_modules call npm install
start "Biblionet API" cmd /k "cd /d "%~dp0backend" && npm start"
cd /d "%~dp0app"
flutter pub get
flutter run -d chrome
pause
