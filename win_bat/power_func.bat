@echo off
call :power 2 4
echo %result%
rem Prints 16, determined as 2 * 2 * 2 * 2
goto :eof

rem __Function power______________________
rem Arguments: %1 and %2
:power
setlocal
set counter=%2
set interim_product=%1
:power_loop
if %counter% gtr 1 (
  set /a interim_product=interim_product * %1
  set /a counter=counter - 1
  goto :power_loop
)
endlocal & set result=%interim_product%
goto :eof