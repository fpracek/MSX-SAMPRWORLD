@echo off
rem Lancia SamPr World in openMSX (Windows). Uso: run_game.bat [macchina]   (predefinita: Panasonic_FS-A1ST)
rem Mettere run_game.bat, sampr.tcl, editor.rom e unapinet.rom nella stessa cartella.
rem Se openmsx.exe non e' nel PATH, impostare OPENMSX con il percorso completo:  set OPENMSX=C:\openMSX\openmsx.exe
cd /d "%~dp0"
set MACHINE=%1
if "%MACHINE%"=="" set MACHINE=Panasonic_FS-A1ST
if "%OPENMSX%"=="" set OPENMSX=openmsx.exe
"%OPENMSX%" -machine %MACHINE% -ext unapinet -script "%~dp0sampr.tcl"
