@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem 変数のロード
CALL Setting.bat

rem サーバ名取得
set /P svname="構築するサーバ名を入力してください: "
echo 重複確認...
FOR /F %%i in ('%VBOX_MNG% list vms') do (
    set svr=%%i
	if !svr! == "%svname%" (
		echo サーバ名：!svr:~1,-1! はすでに存在しています。処理を終了します。
		exit /B 0
	)
)
echo  →OK

echo 空きSSHポート捜索
set portnum=%SSH_PORTNUM%
:portsearch
	
	set /a portnum+=1

	rem Forward設定済ポートの存在確認
	set text=
	for /F %%i in ('%VBOX_MNG% list vms') do (
		for /f "tokens=* delims=" %%x in ('"%VBOX_MNG% showvminfo %%i | findstr -i NIC | findstr -i Rule | findstr -i %portnum%"') do (set text=!text!%%x^
		)
	)

	rem 見つからない場合は、再度ポートチェック
	if not "!text:~0,1!" == "~0,1" (
		goto:portsearch
	)
echo  →OK

echo 以下の情報でVMを構築します。よろしいでしょうか
echo   VM名称                    :%svname%
echo   SSHポート                 :%portnum%
echo   テンプレートVM            :%TEMPLATE_VM%
echo   VM作成先                  :%VM_DEST%
echo   共有フォルダ              :%SF_DEST%

SET /P ans="（Y/N）？"
if /i not "%ans%"=="Y" (
	echo 終了します
	exit /B 0
)

echo VMインポート
%VBOX_MNG% import %TEMPLATE_VM% --vsys 0 --vmname %svname% --settingsfile %VM_DEST%\%svname%\%svname%.vbox --unit 13 --disk %VM_DEST%\%svname%\%svname%.vdi
call :cmdcheck

echo 共有フォルダ作成
mkdir %SF_DEST%\%svname%
call :cmdcheck

echo 共有フォルダ設定
%VBOX_MNG% sharedfolder add %svname% --name %svname% --hostpath "%SF_DEST%\%svname%" --automount --auto-mount-point "/sf"
call :cmdcheck

echo NAT透過モード設定
%VBOX_MNG% modifyvm %svname% --nataliasmode1 proxyonly
call :cmdcheck

echo VM起動
%VBOX_MNG% startvm %svname% --type headless
call :cmdcheck

echo SSHポートフォワード設定
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
