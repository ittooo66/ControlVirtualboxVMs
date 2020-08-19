@echo off
@setlocal enabledelayedexpansion

rem VM変数のロード
CALL VMSetting.bat

rem Virtualbox上のVM一式を取得
FOR /F %%i in ('%VBOX_MNG% list vms') do (
	set svr=%%i

    rem VM起動
	%VBOX_MNG% startvm !svr:~1,-1! --type headless
)

rem WindowsServerは、落としておくこと
%VBOX_MNG% controlvm WindowsSunabaServer poweroff
