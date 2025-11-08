@echo off
REM Script para arrancar un emulador de Android desde Windows

set EMULATOR_PATH=C:\Users\ismae\AppData\Local\Android\Sdk\emulator
set AVD_NAME=Pixel_7_Pro_API_VanillaIceCream

cd %EMULATOR_PATH%
emulator.exe -avd %AVD_NAME%
