@echo off
Setlocal enabledelayedexpansion

Set "Find=knightfall"
Set "Replace=syndicate"

For %%# in ("%cd%\*") Do (
Set "File=%%~nx#"
Ren "%%#" "!File:%Find%=%Replace%!"
)