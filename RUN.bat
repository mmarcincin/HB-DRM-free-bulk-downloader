@echo off
set curDir=%~d0%~p0
if not exist "%curDir%links.txt" type nul>links.txt
notepad %curDir%links.txt
start powershell.exe -nologo -command  "& ""%curDir%HB-DRM-Free_download.ps1"""