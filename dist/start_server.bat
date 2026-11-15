@echo off
rem Avvia il server dei livelli (UDP 9100). Serve Python 3. Chiudere la finestra per fermarlo.
cd /d "%~dp0"
python levelserver.py
pause
