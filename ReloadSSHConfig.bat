@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem �ϐ��̃��[�h
CALL Setting.bat

rem WSL2_IP�̃��[�h
for /f "usebackq" %%A in (`wsl ip a ^| wsl grep eth0 ^| wsl tail -n 1 ^| wsl awk '{print $2}' ^| wsl cut -f 1 -d /`) do set WSL2_IP=%%A

rem EC2�ݒ�
echo Writing EC2 Config...
echo Host EC2 > %SSH_CONFIG%
echo     HostName %EC2_IP% >> %SSH_CONFIG%
echo     User ec2-user >> %SSH_CONFIG%
echo     IdentityFile %EC2_KEY% >> %SSH_CONFIG%
echo     Port 22 >> %SSH_CONFIG%
echo Done.

rem WSL2�ݒ�
echo Writing WSL2 Config...
echo Host WSL2 >> %SSH_CONFIG%
echo     HostName %WSL2_IP% >> %SSH_CONFIG%
echo     User %WSL2_USER% >> %SSH_CONFIG%
echo     IdentityFile %VBOX_KEY% >> %SSH_CONFIG%
echo     Port 22 >> %SSH_CONFIG%
echo     StrictHostKeyChecking no >> %SSH_CONFIG%
echo Done.

rem VirtualboxVM�ݒ�
echo Writing Virtualbox VMs Config...
FOR /F %%i in ('%VBOX_MNG% list vms') do (
	set svr=%%i
	echo Host !svr:~1,-1! >> %SSH_CONFIG%

    for /f "tokens=18" %%A in ('"%VBOX_MNG% showvminfo %%i | findstr -i NIC | findstr -i Rule | findstr -i SSH"') do (
		set port=%%A
		echo     HostName %NAUTILUS_IP% >> %SSH_CONFIG%
		echo     User root >> %SSH_CONFIG%
		echo     IdentityFile %VBOX_KEY% >> %SSH_CONFIG%
		echo     Port !port:~0,-1! >> %SSH_CONFIG%
		echo     StrictHostKeyChecking no >> %SSH_CONFIG%
	)
)
echo Done.

rem ManagementServer�ւ�config�]��
echo Reloading ManagementServer Config...
scp -r %SSH_CONFIG% ManagementServer:~/.ssh/config
ssh ManagementServer "sh /sf/scripts/reloadAnsibleSSHConfig.sh"
echo Done.