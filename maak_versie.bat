@echo off
rem Maakt een speelbare versie van GTKW 144.P: GTKW_144.P\GTKW_144.P.exe naast dit bestand.
setlocal
set GODOT=C:\Godot\Godot_console.exe
set HIER=%~dp0
set UIT=%HIER%GTKW_144.P

if not exist "%GODOT%" (
  echo Godot niet gevonden: %GODOT%
  pause
  exit /b 1
)
if not exist "%UIT%" mkdir "%UIT%"

"%GODOT%" --headless --path "%HIER%Game" --export-release "Windows Desktop" "%UIT%\GTKW_144.P.exe"
if errorlevel 1 (
  echo.
  echo Maken van de versie is mislukt. Zie de meldingen hierboven.
  pause
  exit /b 1
)

echo.
echo Klaar: %UIT%\GTKW_144.P.exe
pause
