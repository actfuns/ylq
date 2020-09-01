SET PYTHONPATH=./tools/Python27/Lib/site-packages
@echo off
color 07
chcp 936
rmdir /S /Q luadata
mkdir luadata
.\tools\Python27\python.exe xls2lua.py
if ERRORLEVEL 1 (
	color 04 
	pause
)

del /a /f gamedata\server\data.lua
.\tools\lua\lua.exe .\lua2game_scripts\server\init.lua luadata gamedata/server
if ERRORLEVEL 1 (
	color 04 
	pause
)
chcp 65001
if ERRORLEVEL 1 (
	color 04 
	pause
)

color 02
echo 服务端导表成功!!!!!!!!!!!!!!!!!!!!!!!!!!

.\tools\lua\lua.exe .\client\convert\_run.lua
if ERRORLEVEL 1 (
    color 04 
    pause
)
chcp 65001
if ERRORLEVEL 1 (
    color 04 
    pause
)

color 02
echo 客户端导表成功!!!!!!!!!!!!!!!!!!!!!!!!!!

pause
