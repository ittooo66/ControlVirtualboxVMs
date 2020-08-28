@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem 変数のロード
CALL Setting.bat

rem Master TCVolのマウント（R）
"C:\Program Files\TrueCrypt\TrueCrypt.exe" /q /v \Device\Harddisk1\Partition0 /lr
call :cmdcheck

rem Slave TCVolのマウント（S）
"C:\Program Files\TrueCrypt\TrueCrypt.exe" /q /v \Device\Harddisk3\Partition0 /ls
call :cmdcheck

rem Master TCV(R:)が詰まっていることを確認
dir R:\master /s /a:-d | wsl tail -n 2 | wsl head -n 1
echo The number of files to be backed up is as above (R:) . 
echo And this Procedure involves shutting down the VMs. 
set /P ans="Please enter something to continue."

rem 1世代前領域(old)にVMを退避
move /Y %BACKUP_DEST%\* %BACKUP_DEST%\old
call :cmdcheck

rem バックアップ実施
FOR /F %%i in ('%VBOX_MNG% list vms') do (
  set svr=%%i

  rem VMの停止
  %VBOX_MNG% controlvm !svr:~1,-1! poweroff

  rem VMのバックアップ
  %VBOX_MNG% export !svr:~1,-1! -o %BACKUP_DEST%\!svr:~1,-1!.ova

  rem VMの起動
  %VBOX_MNG% startvm !svr:~1,-1! --type headless

)

rem 【転送先削除無し】C:の鍵をR:に移送
robocopy /E C:\Users\%WIN10_USER%\.ssh R:\master\key

rem 【転送先削除無し】C:のOneDriveをR:に移送
robocopy /E C:\Users\%WIN10_USER%\OneDrive R:\master\OneDrive

rem 【転送先削除有り】R:とS:をミラー
robocopy /MIR R:\master S:\slave

rem ディスク異常確認
SET /P TASK_END="Backup procedure is complete. And check disk info."
"C:\Users\%WIN10_USER%\OneDrive\home\img\winapp\Utility Applications\CrystalDiskInfo8_4_2\DiskInfo64.exe"

exit /b

:cmdcheck
if %errorlevel% neq 0 (
  set /P ERROR="ERROR : errorlevel:%errorlevel%. Please check log and enter something to continue."
)
echo Done.

exit /b