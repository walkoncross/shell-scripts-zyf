set var1=Abc_123
set var2=%var1:*_=%
echo %var2%

set endings=%var1:*_=%
call set var3=%%var1:%endings%=%%
echo %var3%