@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem 変数のロード
CALL Setting.bat

rem サーバ一覧
set index=0
FOR /F %%i in ('%VBOX_MNG% list vms') do (
	set /a index=index+1
	set svname=%%i
	echo   !index!:!svname:~1,-1!
)

set /P svnum="Please select server ID you want to delete : "
set svname=""
set index=0
FOR /F %%i in ('%VBOX_MNG% list vms') do (
	set /a index=index+1
	if !index! == %svnum% (
		set svname=%%i
		set svname=!svname:~1,-1!
	)
)

rem サーバ名を取得できない場合、終了
if %svname% == "" (
	echo The server number is invalid. To finish.
	exit /B 0
)

rem 最終確認
set /P finalcheck="You want to DELETE %svname% ? Re-enter the server name you want to delete:"
if %svname% neq %finalcheck% (
  echo The server name is different. To finish.
  exit /B 0
)

rem VM削除
%VBOX_MNG% controlvm %svname% poweroff
%VBOX_MNG% unregistervm %svname% --delete
if %errorlevel% neq 0 (
  set /P ERROR="ERROR : errorlevel=%errorlevel%. Please check log and enter something to continue."
)
echo Done.

rem .ssh/config更新
CALL ReloadSSHConfig.bat

rem 共有フォルダ退避
move %SF_DEST%\%svname% %SF_DEST%\_old

SET /P TASK_END="Server deletion process is complete."
