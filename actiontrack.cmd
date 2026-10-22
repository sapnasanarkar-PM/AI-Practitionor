@echo off
rem Runs actiontrack.ps1 without changing the computer's script policy (Bypass applies to this run only).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0actiontrack.ps1" %*
