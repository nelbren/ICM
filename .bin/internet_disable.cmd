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

Set IP=%1%

REM Block all traffic
echo netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound

REM Allow traffic only to the ICMd
REM echo netsh advfirewall firewall add rule name="Allow Local Gateway" dir=out action=allow remoteip=%IP% protocol=TCP remoteport=8080 enable=yes
REM netsh advfirewall firewall add rule name="Allow Local Gateway" dir=out action=allow remoteip=%IP% protocol=TCP remoteport=8080 enable=yes
echo netsh advfirewall firewall add rule name="Allow Local Gateway" dir=out action=allow remoteip=%IP% enable=yes
netsh advfirewall firewall add rule name="Allow Local Gateway" dir=out action=allow remoteip=%IP% enable=yes

REM powershell -ExecutionPolicy Bypass -File "fw4instructure.ps1" add

REM PAUSE

exit