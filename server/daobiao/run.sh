export PYTHONPATH=./tools/py/lib/python2.7/site-packages:$PYTHONPATH
rm -Rf luadata/**
mkdir -p luadata
./tools/py/bin/python2.7 xls2lua.py
rm -Rf gamedata/server/data.lua
./tools/lua/lua ./lua2game_scripts/server/init.lua luadata gamedata/server

echo "服务端导表成功"

./tools/lua/lua ./client/convert/_run.lua

echo "客户端导表成功"
