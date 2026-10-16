@echo off
title Biblionet - Flutter + Node.js + PostgreSQL
color 0B
echo ====================================================================
echo    BIBLIONET - Instituto Superior Universitario Japon
echo    Flutter (Windows, web y Android) + API Node.js + PostgreSQL
echo    Estudiante: Siomey Elizabeth Romero Tituana
echo    Docente: MSc. Luis Calo
echo ====================================================================
cd /d "%~dp0backend"
if not exist node_modules call npm install
start "Biblionet API" cmd /k "cd /d "%~dp0backend" && npm start"
cd /d "%~dp0app"
flutter pub get
flutter run -d windows
pause
