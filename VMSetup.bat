@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem �ϐ��̃��[�h
CALL Setting.bat

rem �T�[�o���擾
set /P svname="�\�z����T�[�o������͂��Ă�������: "
echo �d���m�F...
FOR /F %%i in ('%VBOX_MNG% list vms') do (
    set svr=%%i
	if !svr! == "%svname%" (
		echo �T�[�o���F!svr:~1,-1! �͂��łɑ��݂��Ă��܂��B�������I�����܂��B
		exit /B 0
	)
)
echo  ��OK

echo ��SSH�|�[�g�{��
set portnum=%SSH_PORTNUM%
:portsearch
	
	set /a portnum+=1

	rem Forward�ݒ�σ|�[�g�̑��݊m�F
	set text=
	for /F %%i in ('%VBOX_MNG% list vms') do (
		for /f "tokens=* delims=" %%x in ('"%VBOX_MNG% showvminfo %%i | findstr -i NIC | findstr -i Rule | findstr -i %portnum%"') do (set text=!text!%%x^
		)
	)

	rem ������Ȃ��ꍇ�́A�ēx�|�[�g�`�F�b�N
	if not "!text:~0,1!" == "~0,1" (
		goto:portsearch
	)
echo  ��OK

echo �ȉ��̏���VM���\�z���܂��B��낵���ł��傤��
echo   VM����                    :%svname%
echo   SSH�|�[�g                 :%portnum%
echo   �e���v���[�gVM            :%TEMPLATE_VM%
echo   VM�쐬��                  :%VM_DEST%
echo   ���L�t�H���_              :%SF_DEST%

SET /P ans="�iY/N�j�H"
if /i not "%ans%"=="Y" (
	echo �I�����܂�
	exit /B 0
)

echo VM�C���|�[�g
%VBOX_MNG% import %TEMPLATE_VM% --vsys 0 --vmname %svname% --settingsfile %VM_DEST%\%svname%\%svname%.vbox --unit 13 --disk %VM_DEST%\%svname%\%svname%.vdi
call :cmdcheck

echo ���L�t�H���_�쐬
mkdir %SF_DEST%\%svname%
call :cmdcheck

echo ���L�t�H���_�ݒ�
%VBOX_MNG% sharedfolder add %svname% --name %svname% --hostpath "%SF_DEST%\%svname%" --automount --auto-mount-point "/sf"
call :cmdcheck

echo NAT���߃��[�h�ݒ�
%VBOX_MNG% modifyvm %svname% --nataliasmode1 proxyonly
call :cmdcheck

echo VM�N��
%VBOX_MNG% startvm %svname% --type headless
call :cmdcheck

echo SSH�|�[�g�t�H���[�h�ݒ�
%VBOX_MNG% controlvm %svname% natpf1 "SSH Port,tcp,,%portnum%,,22"
call :cmdcheck

echo ssh_config setting
call ReloadSSHConfig.bat

echo hostname setting (waiting 30sec for starting sshd...)
timeout 30
ssh %svname% "hostnamectl set-hostname %svname%"
call :cmdcheck

SET /P TASK_END="Environment setup is complete. Please 'ssh %svname%' to login Server."
exit /b
:cmdcheck
if %errorlevel% neq 0 (
  set /P ERROR="ERROR : errorlevel:%errorlevel%. Please check log and enter something to continue."
)
echo Done.
exit /b
