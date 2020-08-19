@echo off
@setlocal enabledelayedexpansion

rem VM変数のロード
CALL VMSetting.bat

echo Writing EC2 Config...
echo Host EC2 > %SSH_CONFIG%
echo     HostName %EC2_IP% >> %SSH_CONFIG%
echo     User ec2-user >> %SSH_CONFIG%
echo     IdentityFile %EC2_KEY% >> %SSH_CONFIG%
echo     Port 22 >> %SSH_CONFIG%
echo  →OK

echo TODO:Writing WSL2 Config...
echo TODO:...

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
	)
)
echo  →OK
