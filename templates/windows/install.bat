@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
  color 04
  echo Failure: Current permissions inadequate. Please run this file as admin.
  pause
  exit
)

:CHECK_PHPSTORM
tasklist /FI "IMAGENAME eq phpstorm64.exe" 2>NUL | find /I /N "phpstorm64.exe">NUL
if "%ERRORLEVEL%"=="0" (
  color 06
  echo PHPStorm is running. Please close PHPStorm and press key.
  color
  pause
  goto CHECK_PHPSTORM
)

tasklist /FI "IMAGENAME eq phpstorm.exe" 2>NUL | find /I /N "phpstorm.exe">NUL
if "%ERRORLEVEL%"=="0" (
  color 06
  echo PHPStorm is running. Please close PHPStorm and press key.
  color
  pause
  goto CHECK_PHPSTORM
)

echo Creating Symlinks...
@setlocal enableextensions
@cd /d "%~dp0"

mklink /d .\wl.trunk\core ..\checkout\core\trunk
mklink /d .\wl.trunk\namespace.Core ..\checkout\namespace\Core\trunk
mklink /d .\wl.trunk\namespace.Social ..\checkout\namespace\Social\trunk
mklink /d .\wl.trunk\namespace.Wl ..\checkout\namespace\Wl\trunk
mklink /d .\wl.trunk\project ..\checkout\reservationspot.com\trunk\

mklink /d .\wl.stable\core ..\checkout\core\servers\stable.wellnessliving.com
mklink /d .\wl.stable\namespace.Core ..\checkout\namespace\Core\servers\wl-stable
mklink /d .\wl.stable\namespace.Social ..\checkout\namespace\Social\servers\wl-stable
mklink /d .\wl.stable\namespace.Wl ..\checkout\namespace\Wl\servers\stable
mklink /d .\wl.stable\project ..\checkout\reservationspot.com\servers\stable

echo Modifying hosts...
set NEWLINE=^& echo.
set HOST_TRUNK={host_trunk}
set HOST_STABLE={host_stable}

echo %NEWLINE%>>%WINDIR%\System32\drivers\etc\hosts
@find /C /I "%HOST_TRUNK%" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% neq 0 (
  echo Host %HOST_TRUNK% add.
  @echo %NEWLINE%^127.0.0.1 %HOST_TRUNK%>>%WINDIR%\System32\drivers\etc\hosts
)

@find /C /I "%HOST_STABLE%" %WINDIR%\system32\drivers\etc\hosts
if %ERRORLEVEL% neq 0 (
  echo Host %HOST_STABLE% add.
  @echo %NEWLINE%^127.0.0.1 %HOST_STABLE%>>%WINDIR%\System32\drivers\etc\hosts
)

mkdir "%AppData%/Subversion"
xcopy /E /Y Subversion "%AppData%"
rd /S /Q Subversion

:SUBVERSION
start /wait checkout/reservationspot.com/install/templates/windows/Setup-Subversion-1.7.9.msi
if %ERRORLEVEL% equ 1063 (
  echo Subversion already installed
) else (
  if %ERRORLEVEL% neq 0 (
    color 06
    echo Subversion installed with code %ERRORLEVEL%
    color
    goto SUBVERSION
  ) else (
     echo Subversion successfully installed
  )
)

:PUTTY
start /wait checkout/reservationspot.com/install/templates/windows/putty-64bit-0.70-installer.msi
if %ERRORLEVEL% neq 0 (
  if %ERRORLEVEL% equ 1602 (
    color 06
    echo Canceled install Putty. If Putty already installed then select 'Repair' in setup Putty.
  ) else (
    color 04
    echo "Putty installed with code %ERRORLEVEL%"
  )
  color
  goto PUTTY
) else (
  echo Putty successfully installed
)

color 02
echo Symlinks created.

pause
del "%~f0"
