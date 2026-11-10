@echo off

C:\Windows\System32\Robocopy "\\Atm-naranjo\E\Store01" "D:\Backup\Store01" /E /COPY:DAT /DCOPY:T /MT:4 /R:1 /W:1 /XJ /XD "System Volume Information" "$RECYCLE.BIN"

C:\Windows\System32\Robocopy "\\Atm-naranjo\F\Store02" "D:\Backup\Store02" /E /COPY:DAT /DCOPY:T /MT:4 /R:1 /W:1 /XJ /XD "System Volume Information" "$RECYCLE.BIN"

pause
