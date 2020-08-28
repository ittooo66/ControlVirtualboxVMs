@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem �ϐ��̃��[�h
CALL Setting.bat

rem �T�[�o�ꗗ
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

rem �T�[�o�����擾�ł��Ȃ��ꍇ�A�I��
if %svname% == "" (
	echo The server number is invalid. To finish.
	exit /B 0
)

rem �ŏI�m�F
set /P finalcheck="You want to DELETE %svname% ? Re-enter the server name you want to delete:"
if %svname% neq %finalcheck% (
  echo The server name is different. To finish.
  exit /B 0
)

rem VM�폜
%VBOX_MNG% controlvm %svname% poweroff
%VBOX_MNG% unregistervm %svname% --delete
if %errorlevel% neq 0 (
  set /P ERROR="ERROR : errorlevel=%errorlevel%. Please check log and enter something to continue."
)
echo Done.

rem .ssh/config�X�V
CALL ReloadSSHConfig.bat

rem ���L�t�H���_�ޔ�
move %SF_DEST%\%svname% %SF_DEST%\_old

SET /P TASK_END="Server deletion process is complete."
