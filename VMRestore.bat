@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem �ϐ��̃��[�h
CALL Setting.bat

rem ova�ꗗ�\��
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
rem �T�[�o�����擾�ł��Ȃ��ꍇ�A�I��
if %ovaname% == "" (
	echo Ova name is invalid. The process will end.
	exit /B 0
)

rem �ŏI�m�F
SET /P ans="Restore %ovaname% . Is it OK? [Y/N]"
if /i not "%ans%"=="Y" (
	echo The process will end.
	exit /B 0
)

rem ���X�g�A�Ώ�VM�F�d���`�F�b�N
FOR /F %%i in ('%VBOX_MNG% list vms') do (
    set svr=%%i
	if !svr! == "%ovaname:~0,-4%" (
		echo Server name: !svr:~1,-1! already exists. The process will end.
		exit /B 0
	)
)

rem VM���X�g�A
%VBOX_MNG% import %BACKUP_DEST%\%ovaname%
call :cmdcheck

rem VM�N��
%VBOX_MNG% startvm %ovaname:~0,-4% --type headless
call :cmdcheck

rem .ssh/config�X�V
call ReloadSSHConfig.bat

SET /P TASK_END="Server Restore process is complete."

exit /b

:cmdcheck
if %errorlevel% neq 0 (
  set /P ERROR="ERROR : errorlevel:%errorlevel%. Please check log and enter something to continue."
)
echo Done.

exit /b
