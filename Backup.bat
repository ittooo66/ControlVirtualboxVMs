@echo off
@setlocal enabledelayedexpansion
cd /d %~dp0

rem �ϐ��̃��[�h
CALL Setting.bat

rem Master TCVol�̃}�E���g�iR�j
"C:\Program Files\TrueCrypt\TrueCrypt.exe" /q /v \Device\Harddisk1\Partition0 /lr
call :cmdcheck

rem Slave TCVol�̃}�E���g�iS�j
"C:\Program Files\TrueCrypt\TrueCrypt.exe" /q /v \Device\Harddisk3\Partition0 /ls
call :cmdcheck

rem Master TCV(R:)���l�܂��Ă��邱�Ƃ��m�F
dir R:\master /s /a:-d | wsl tail -n 2 | wsl head -n 1
echo The number of files to be backed up is as above (R:) . 
echo And this Procedure involves shutting down the VMs. 
set /P ans="Please enter something to continue."

rem 1����O�̈�(old)��VM��ޔ�
move /Y %BACKUP_DEST%\* %BACKUP_DEST%\old
call :cmdcheck

rem �o�b�N�A�b�v���{
FOR /F %%i in ('%VBOX_MNG% list vms') do (
  set svr=%%i

  rem VM�̒�~
  %VBOX_MNG% controlvm !svr:~1,-1! poweroff

  rem VM�̃o�b�N�A�b�v
  %VBOX_MNG% export !svr:~1,-1! -o %BACKUP_DEST%\!svr:~1,-1!.ova

  rem VM�̋N��
  %VBOX_MNG% startvm !svr:~1,-1! --type headless

)

rem �y�]����폜�����zC:�̌���R:�Ɉڑ�
robocopy /E C:\Users\%WIN10_USER%\.ssh R:\master\key

rem �y�]����폜�����zC:��OneDrive��R:�Ɉڑ�
robocopy /E C:\Users\%WIN10_USER%\OneDrive R:\master\OneDrive

rem �y�]����폜�L��zR:��S:���~���[
robocopy /MIR R:\master S:\slave

rem �f�B�X�N�ُ�m�F
SET /P TASK_END="Backup procedure is complete. And check disk info."
"C:\Users\%WIN10_USER%\OneDrive\home\img\winapp\Utility Applications\CrystalDiskInfo8_4_2\DiskInfo64.exe"

exit /b

:cmdcheck
if %errorlevel% neq 0 (
  set /P ERROR="ERROR : errorlevel:%errorlevel%. Please check log and enter something to continue."
)
echo Done.

exit /b