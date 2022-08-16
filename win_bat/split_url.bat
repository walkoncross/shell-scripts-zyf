@REM call split_string.cmd split_string abc_123 _ var1 var2


call :get_prefix "https://www.bilibili.com/video/BV1Fs411v7kF/\?spm_id_from\=333.788.recommend_more_video.-1" ? var1

@echo off
echo %var1%


:get_prefix
setlocal
set _input=%1
set _delimiter=%2
call set _suffix=%%_input:*%_delimiter%=%%
@REM echo %_suffix%
call set _prefix=%%_input:%_delimiter%%_suffix%=%%
@REM echo %_prefix%
endlocal & set %3=%_prefix%
exit /b