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

echo === Running in elevated session:
echo Script file: %~f0
echo Arguments  : %*

echo route delete -p 0.0.0.0
route delete -p 0.0.0.0
echo route add 0.0.0.0 mask 0.0.0.0 %*
route add 0.0.0.0 mask 0.0.0.0 %*

exit

REM echo Working dir: %cd%
