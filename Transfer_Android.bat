set UIT=%HIER%GTKW_144.P

rem Telefoon via USB aangesloten (USB-foutopsporing aan)? Dan meteen installeren en starten.
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
if not exist "%ADB%" goto handmatig
"%ADB%" devices | findstr /E "unauthorized" >nul && (
  echo Telefoon gevonden, maar nog niet toegestaan: tik op de telefoon op Toestaan en start dit opnieuw.
  goto einde
)
"%ADB%" devices | findstr /E "device" >nul || goto handmatig
echo Telefoon gevonden, installeren...
"%ADB%" install -r "%UIT%\GTKW_144.P.apk"
if errorlevel 1 (
  echo Installeren is mislukt. Zie de meldingen hierboven.
  goto einde
)
"%ADB%" shell monkey -p org.gtkw144p.game -c android.intent.category.LAUNCHER 1 >nul
echo Geinstalleerd en gestart op de telefoon.
goto einde

:handmatig
echo Geen telefoon aangesloten. Sluit hem aan met USB-foutopsporing aan en start dit opnieuw,
echo of zet het bestand zelf op je telefoon en open het (installeren uit onbekende bronnen toestaan).

:einde
pause
