@echo off

set input=%1
set delimiter=%2
set prefix=%3
set suffix=%4

call :split_string %%input%% %%delimiter%% %%prefix%% %%suffix%%
@REM call echo %%prefix%%
@REM call echo %%suffix%%

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