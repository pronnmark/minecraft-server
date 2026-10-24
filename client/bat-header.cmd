@echo off
title Grisch Minecraft setup
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = (Get-Content -Raw -LiteralPath '%~f0') -split '<#PS#>'; Invoke-Expression $s[-1]"
exit /b
<#PS#>
