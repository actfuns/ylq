#!/usr/bin/python
#coding:utf-8

import os, sys
if len(sys.argv) != 3:
    print "%s no src or dst" % sys.argv[0]
    os._exit(1)

arg_src_path = sys.argv[1]
arg_dst_path = sys.argv[2]

src_path = arg_src_path
dst_path = arg_dst_path


#二进制编译产物/配置文件/shell脚本/CS公共目录/lualib/service
cp_dirs = ['build', 'config', 'shell', 'cs_common', 'lualib', 'service']
#skynet内的lualib/service
cp_dirs.extend(
        ['skynet/lualib', 'skynet/service']
        )
#服务端所需导表文件
cp_dirs.extend(
        ['daobiao/gamedata']
        )
#服务端所需工具
cp_dirs.extend(
        ['tools/robot']
        )

#将不存在的目录预先建立
for i in cp_dirs:
    dst = os.path.join(dst_path, i)
    try:
        os.makedirs(dst)
    except OSError, e:
        print e
        continue

#把所需全量拷贝
for i in cp_dirs:
    src_dir = os.path.join(src_path, i)
    dst_dir = os.path.join(dst_path, i)
    cmd = "cp -rf %s/** %s"%(src_dir, dst_dir)
    print cmd
    assert(os.system(cmd) == 0)

#将lua编译成luac,并删除lua,这种方式可一定程度增加源码破解门槛,不过还是可被反编译,todo:修改编译器源码
#def recu_compile(dir_name, del_list):
#    for n in os.listdir(dir_name):
#        fn = os.path.join(dir_name, n)
#        if os.path.isfile(fn):
#            fn1, fn2 = os.path.splitext(n)
#            if fn2 == ".lua":
#                del_list.append(fn)
#                cmd = "./build/luac -o %s %s" % (os.path.join(dir_name, fn1+".luac"), fn)
#                print cmd
#                assert(os.system(cmd) == 0)
#        else:
#            recu_compile(fn, del_list)
#    
#del_list = []
#recu_compile(dst_path, del_list)
#for k, v in enumerate(del_list):
#    os.remove(v)

print 'pack finish'
