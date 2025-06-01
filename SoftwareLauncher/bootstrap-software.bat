@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& \"%~dp0scripts\Launcher.ps1\" %*}"
