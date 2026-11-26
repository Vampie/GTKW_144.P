@echo off
rem Maakt een Android-versie van GTKW 144.P: GTKW_144.P\GTKW_144.P.apk naast dit bestand.
rem Nodig: Godot met Android-exporttemplates, en in Godot (Editor-instellingen, Export, Android)
rem het pad naar de Java SDK (JDK 17) en de Android SDK.
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

"%GODOT%" --headless --path "%HIER%Game" --export-debug "Android" "%UIT%\GTKW_144.P.apk"
if errorlevel 1 (
  echo.
  echo Maken van de versie is mislukt. Zie de meldingen hierboven.
  pause
  exit /b 1
)

echo.
echo Klaar: %UIT%\GTKW_144.P.apk

call Transfer_Android.bat