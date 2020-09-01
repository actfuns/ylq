#!/bin/bash
python ./shell/format_proto.py
protoc -I cs_common/proto -ocs_common/proto/proto.pb `find -L cs_common/proto  -name "*.proto"`
echo "make proto done"
