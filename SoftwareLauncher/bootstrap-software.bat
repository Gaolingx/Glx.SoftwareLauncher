@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& \"%~dp0scripts\SoftwareLauncher.ps1\" %*}"
