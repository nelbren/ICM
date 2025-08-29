@ECHO OFF

SET IP=%1%

if /I "%2"=="INICIO" call "%HOME%\ICM\.bin\internet_disable.cmd" %IP%
if /I "%2"=="FIN" call "%HOME%\ICM\.bin\internet_enable.cmd"

exit