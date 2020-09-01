#!/bin/bash

rm -Rf check_proto.out

Protos=`find . -name "*.proto"`
if [ "${Protos}" != "" ]; then
	for i in ${Protos}
	do
		./build/lua ./shell/check_proto.lua ${i} check_proto.out
	done
fi
