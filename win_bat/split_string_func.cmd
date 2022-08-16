@echo off

call :%~1 %~2 %~3 %~4 %~5
exit /b

:split_string
setlocal
set _input=%1
set _delimiter=%2
call set _suffix=%%_input:*%_delimiter%=%%
@REM echo %_suffix%
call set _prefix=%%_input:%_delimiter%%_suffix%=%%
@REM echo %_prefix%
endlocal & set %3=%_prefix% & set %4=%_suffix%
exit /b