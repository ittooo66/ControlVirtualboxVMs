@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem 変数のロード
CALL Setting.bat

rem Virtualbox上のVM一式を取得
FOR /F %%i in ('%VBOX_MNG% list vms') do (
	set svr=%%i

    rem VM起動
	%VBOX_MNG% startvm !svr:~1,-1! --type headless
)

rem WSL2Ubuntu起動後、sshdを起動
wsl -u root service ssh start

rem 起動時にIP変わるので、リロード
CALL ReloadSSHConfig.bat

rem WindowsServerは、落としておく
%VBOX_MNG% controlvm WindowsSunabaServer poweroff


SET /P TASK_END="Instance startup processing is complete."