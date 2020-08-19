@echo off
@setlocal enabledelayedexpansion

rem VM変数のロード
CALL VMSetting.bat

echo "以下のVM一覧をバックアップします"
echo "バックアップ先：%BACKUP_DEST%"

FOR /F %%i in ('%VBOX_MNG% list vms') do (
	set SVNAME=%%i
	echo     !SVNAME:~1,-1!
)

SET /P ANSWER="よろしいですか？ [Y/N]"
if /i not "%ANSWER%"=="Y" (
	echo 終了します
	exit /B 0
)

rem VM一式の退避
set DATE=%date:~0,4%%date:~5,2%%date:~8,2%
mkdir %BACKUP_DEST%\%DATE%
move %BACKUP_DEST%\* %BACKUP_DEST%\%DATE%
echo バックアップ先確保のため、旧ovaファイル一式を以下に退避しました。
echo %BACKUP_DEST%\%DATE%

FOR /F %%i in ('%VBOX_MNG% list vms') do (
  set svr=%%i

  rem VMの停止
  %VBOX_MNG% controlvm !svr:~1,-1! poweroff

  rem VMのバックアップ
  %VBOX_MNG% export !svr:~1,-1! -o %BACKUP_DEST%\!svr:~1,-1!.ova

  rem VMの起動
  %VBOX_MNG% startvm !svr:~1,-1! --type headless

)

echo バックアップが終了しました

