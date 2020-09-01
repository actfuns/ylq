#!/bin/bash

rm -Rf check_lua.out
rm -Rf log/check_lua_result.log
mkdir -p log

Luas=`find . -name "*.lua"`
if [ "$Luas" != "" ]; then
	touch check_lua.out
	touch log/check_lua_result.log
	for i in $Luas
	do
		./build/luac -p -l $i > check_lua.out
		./build/lua ./shell/check_lua.lua $i check_lua.out log/check_lua_result.log
	done
	rm -Rf check_lua.out
fi
