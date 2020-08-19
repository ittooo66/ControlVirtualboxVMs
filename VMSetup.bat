@echo off
@setlocal enabledelayedexpansion

rem VM変数のロード
CALL VMSetting.bat

rem ポート番号
set portnum=%SSH_PORTNUM%
rem サーバ名
set /P svname="構築するサーバ名を入力してください: "

echo サーバ名重複確認
FOR /F %%i in ('%VBOX_MNG% list vms') do (
    set svr=%%i
	if !svr! == "%svname%" (
		echo サーバ名：!svr:~1,-1! はすでに存在しています。処理を終了します。
		exit /B 0
	)
)
echo  →OK

echo 空きSSHポート捜索
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
if %errorlevel% neq 0 (
  echo エラー：errorlevel:%errorlevel%
  echo 処理を中断します
  exit /B 0
)
echo  →OK

echo 共有フォルダ作成
mkdir %SF_DEST%\%svname%
echo  →OK

echo 共有フォルダ設定
%VBOX_MNG% sharedfolder add %svname% --name %svname% --hostpath "%SF_DEST%\%svname%" --automount --auto-mount-point "/sf"
if %errorlevel% neq 0 (
  echo エラー：errorlevel:%errorlevel%
  echo 処理を中断します
  exit /B 0
)
echo  →OK

echo NAT透過モード設定
%VBOX_MNG% modifyvm %svname% --nataliasmode1 proxyonly
if %errorlevel% neq 0 (
  echo エラー：errorlevel:%errorlevel%
  echo 処理を中断します
  exit /B 0
)
echo  →OK

echo VM起動
%VBOX_MNG% startvm %svname% --type headless
if %errorlevel% neq 0 (
  echo エラー：errorlevel:%errorlevel%
  echo 処理を中断します
  exit /B 0
)
echo  →OK

echo SSHポートフォワード設定
%VBOX_MNG% controlvm %svname% natpf1 "SSH Port,tcp,,%portnum%,,22"
if %errorlevel% neq 0 (
  echo エラー：errorlevel:%errorlevel%
  echo 処理を中断します
  exit /B 0
)
echo  →OK

echo ssh_config設定
CALL ReloadSSHConfig.bat


echo 環境構築が完了しました。「 ssh %svname% 」でログオン可能です。
