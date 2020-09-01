#!/bin/bash
./shell/update.sh
make

pack_name="pack_banshu`date +%Y-%m-%d_%H-%M-%S`"
gz_name=$pack_name".tar.gz"
rm -Rf $pack_name
rm -Rf $gz_name
python ./shell/pack.py "./" $pack_name
touch $pack_name/version.out
svn info > $pack_name/version.out
tar zcvf $gz_name $pack_name

ssh -p 932 cilu@120.132.11.112 "
mkdir pack;
"
scp -P 932 -r $gz_name cilu@120.132.11.112:~/pack/
ssh -p 932 cilu@120.132.11.112 "
cd pack;
tar zxvf $gz_name;
"
echo "transfer finish"

rm -Rf $pack_name
rm -Rf $gz_name

echo "publish_banshu finish"
