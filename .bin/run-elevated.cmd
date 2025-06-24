<!-- : (":" is required)
@echo off & setlocal
net session >NUL 2>&1 && goto :ELEVATED
set ELEVATE_CMDLINE=cd /d "%~dp0" ^& "%~f0" %*
cscript.exe //nologo "%~f0?.wsf" //job:Elevate & exit /b
-->

<job id="Elevate">
  <script language="VBScript">
    Set objShell = CreateObject("Shell.Application")
    Set objWshShell = WScript.CreateObject("WScript.Shell")
    Set objWshProcessEnv = objWshShell.Environment("PROCESS")
    strCommandLine = Trim(objWshProcessEnv("ELEVATE_CMDLINE"))
    objShell.ShellExecute "cmd", "/k " & strCommandLine, "", "runas"
  </script>
</job>

:ELEVATED

REM echo === Running in elevated session:
REM echo Script file: %~f0
REM echo Arguments  : %*
REM echo Argumento 1: %1
REM echo Argumento 2: %2
SET IP=%1%

REM echo route delete -p 0.0.0.0
REM route delete -p 0.0.0.0
REM echo route add 0.0.0.0 mask 0.0.0.0 %IP%
REM route add 0.0.0.0 mask 0.0.0.0 %IP%

if /I "%2"=="INICIO" GOTO HabilitarCortafuegos
if /I "%2"=="FIN" GOTO DeshabilitarCortafuegos

exit

REM echo Working dir: %cd%

:HabilitarCortafuegos
REM Bloquear todo el trafico
echo netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound
REM Permiter solo el trafico al "gateway"
echo netsh advfirewall firewall add rule name="Allow Local Gateway" dir=out action=allow remoteip=%IP% protocol=TCP remoteport=8080 enable=yes
netsh advfirewall firewall add rule name="Allow Local Gateway" dir=out action=allow remoteip=%IP% protocol=TCP remoteport=8080 enable=yes
powershell -ExecutionPolicy Bypass -File "fw4instructure.ps1" add
REM PAUSE
exit
goto :EOF

:DeshabilitarCortafuegos
REM Habilitar todo el trafico
echo netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound
netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound
REM Eliminar regla de solo trafico al "gateway"
echo netsh advfirewall firewall delete rule name="Allow Local Gateway"
netsh advfirewall firewall delete rule name="Allow Local Gateway"
powershell -ExecutionPolicy Bypass -File "fw4instructure.ps1" delete
REM PAUSE
exit
goto :EOF
