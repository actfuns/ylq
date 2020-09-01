服务器安装CentOS 7.2 64位系统
---------------------------------------------------------------------------------------------------------
一，安装宝塔
yum install -y wget && wget -O install.sh http://download.bt.cn/install/install_6.0.sh && sh install.sh

宝塔安装

Nginx 1.16    PHP5.6  PHPMyAdmin 4.4   mongodb

mongodb --软件管理 找到mongodb 点击安装

---------------------------------------------------------------------------------------------------------
开放端口:1:65535

设置mongodb账号密码
mongo
use admin
db.createUser({user:"root",pwd:"123456",roles:[{role:"root",db:"admin"}]})
exit

authorization: enabled
---------------------------------------------------------------------------------------------------------
二，服务端传到home解压

上传pymongo3.5.1.tar.gz到home目录
上传ylq-5.5.1.tar.gz到home目录

给777权限！然后解压出来

pip install DBUtils
cd /home/pymongo-3.5.1
python setup.py install

pip install setuptools

chmod -R 777 /home

---------------------------------------------------------------------------------------------------------
启动游戏
cd /home/ylq
./run.sh

关闭游戏
pkill skynet
---------------------------------------------------------------------------------------------------------
打开改之理反编译修改客户端

修改文件路径\assets\script

用打包解包工具解包script，修改\pack\logic\login\CServerCtrl.lua里面ID111的IP:119.130.207.253

---------------------------------------------------------------------------------------------------------