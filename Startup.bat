@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem �ϐ��̃��[�h
CALL Setting.bat

rem Virtualbox���VM�ꎮ���擾
FOR /F %%i in ('%VBOX_MNG% list vms') do (
	set svr=%%i

    rem VM�N��
	%VBOX_MNG% startvm !svr:~1,-1! --type headless
)

rem WSL2Ubuntu�N����Asshd���N��
wsl -u root service ssh start

rem �N������IP�ς��̂ŁA�����[�h
CALL ReloadSSHConfig.bat

rem WindowsServer�́A���Ƃ��Ă���
%VBOX_MNG% controlvm WindowsSunabaServer poweroff


SET /P TASK_END="Instance startup processing is complete."