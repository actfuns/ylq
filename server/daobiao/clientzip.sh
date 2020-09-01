export PYTHONPATH=./tools/py/lib/python2.7/site-packages:$PYTHONPATH

mkdir -p logic/data
./tools/lua/lua ./client/convert/_run.lua ./logic/data

./tools/py/bin/python2.7 clientzip.py ./logic/data $1 ./gamedata/server/client-daobiao
rm -Rf logic

echo "生成客户端导表MD5验证包"