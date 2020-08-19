@echo off
@setlocal enabledelayedexpansion

rem VM変数のロード
CALL VMSetting.bat

rem サーバ一式の表示
set index=0
FOR /F %%i in ('%VBOX_MNG% list vms') do (
	set /a index=index+1
	set svname=%%i
	echo   !index!:!svname:~1,-1!
)

rem サーバ番号の取得
set /P svnum="削除するサーバの番号を入力してください: "
set svname=""
set index=0
FOR /F %%i in ('%VBOX_MNG% list vms') do (
	set /a index=index+1
	if !index! == %svnum% (
		set svname=%%i
		set svname=!svname:~1,-1!
	)
)
rem サーバ名を取得できない場合、終了
if %svname% == "" (
	echo 入力された番号に対応するサーバを取得できません。処理を終了します。
	exit /B 0
)

echo %svname%を削除します。よろしいですか？
set /P finalcheck="よろしければ、削除するサーバ名称を入力してください: "
if %svname% neq %finalcheck% (
  echo サーバ名が異なります。再確認してください。処理を終了します。
  exit /B 0
)

echo VM停止
%VBOX_MNG% controlvm %svname% poweroff
if %errorlevel% neq 0 (
  echo エラー：errorlevel:%errorlevel%
  echo VMの停止に失敗しました。エラー内容を確認してください。処理を中断します。
  exit /B 0
)
echo  →OK

echo VM削除
%VBOX_MNG% unregistervm %svname% --delete
if %errorlevel% neq 0 (
  echo エラー：errorlevel:%errorlevel%
  echo 削除に失敗しました。エラー内容を確認してください。処理を中断します。
  exit /B 0
)
echo  →OK

echo .ssh/config更新
CALL ReloadSSHConfig.bat
echo  →OK

rem 共有フォルダの整理
echo 共有フォルダを退避
move %SF_DEST%\%svname% %SF_DEST%\_old
echo  →OK

echo サーバ削除処理が完了しました。
