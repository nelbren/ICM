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

REM Enable all traffic
echo netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound
netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound

REM Remove ICMd traffic-only rule
echo netsh advfirewall firewall delete rule name="Allow Local Gateway"
netsh advfirewall firewall delete rule name="Allow Local Gateway"

REM powershell -ExecutionPolicy Bypass -File "fw4instructure.ps1" delete

REM PAUSE

exit