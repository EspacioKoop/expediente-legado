@echo off
setlocal EnableExtensions
title SIGA-98 - Actualizador de playtest

if /I "%~1"=="--help" goto :help
if /I "%~1"=="/?" goto :help

set "UPDATER=%~dp0Actualizar-SIGA98.ps1"
if not exist "%UPDATER%" (
  echo.
  echo ERROR: falta Actualizar-SIGA98.ps1 junto a este archivo.
  echo Extrae completos los archivos del paquete de actualizacion.
  echo.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%UPDATER%" %*
set "EXITCODE=%ERRORLEVEL%"

if not "%EXITCODE%"=="0" (
  echo.
  echo La actualizacion no pudo completarse. Revisa el mensaje anterior.
  pause
)
exit /b %EXITCODE%

:help
echo SIGA-98 - actualizador de playtest para Windows
echo.
echo Doble clic:
echo   comprueba la ultima alpha, descarga solo si cambia, verifica SHA-256 y abre el juego.
echo.
echo Opciones:
echo   Actualizar-SIGA98.cmd -NoRun
echo   Actualizar-SIGA98.cmd -Force
echo   Actualizar-SIGA98.cmd -InstallDir "C:\Ruta"
exit /b 0
