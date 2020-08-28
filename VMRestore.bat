@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem 変数のロード
CALL Setting.bat

rem ova一覧表示
set index=0
FOR /F %%i in ('dir %BACKUP_DEST% /b') do (
	set /a index=index+1
	set ovaname=%%i
	echo   !index!:!ovaname!
)

set /P svnum="Enter the ova ID to restore:"
set ovaname=""
set index=0
FOR /F %%i in ('dir %BACKUP_DEST% /b') do (
	set /a index=index+1
	if !index! == %svnum% (
		set ovaname=%%i
	)
)
rem サーバ名を取得できない場合、終了
if %ovaname% == "" (
	echo Ova name is invalid. The process will end.
	exit /B 0
)

rem 最終確認
SET /P ans="Restore %ovaname% . Is it OK? [Y/N]"
if /i not "%ans%"=="Y" (
	echo The process will end.
	exit /B 0
)

rem リストア対象VM：重複チェック
FOR /F %%i in ('%VBOX_MNG% list vms') do (
    set svr=%%i
	if !svr! == "%ovaname:~0,-4%" (
		echo Server name: !svr:~1,-1! already exists. The process will end.
		exit /B 0
	)
)

rem VMリストア
%VBOX_MNG% import %BACKUP_DEST%\%ovaname%
call :cmdcheck

rem VM起動
%VBOX_MNG% startvm %ovaname:~0,-4% --type headless
call :cmdcheck

rem .ssh/config更新
call ReloadSSHConfig.bat

SET /P TASK_END="Server Restore process is complete."

exit /b

:cmdcheck
if %errorlevel% neq 0 (
  set /P ERROR="ERROR : errorlevel:%errorlevel%. Please check log and enter something to continue."
)
echo Done.

exit /b
