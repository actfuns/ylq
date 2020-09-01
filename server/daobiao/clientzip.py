#!/usr/bin/python
#coding:utf-8

import os
import sys
import zipfile
import time

if len(sys.argv) < 4:
    print "%s no src or dst" % sys.argv[0]
    os._exit(1)

src_path = sys.argv[1].replace(os.sep, "/").rstrip("/")
file = sys.argv[2].replace(os.sep,"/").rstrip("/")
dst_path = sys.argv[3].replace(os.sep, "/").rstrip("/")

if __name__ == '__main__':
    namelist = []
    file_list = file.split(",")
    path2name = {}
    for file_name in file_list:
        filepath = "%s/%s.lua"%(src_path,file_name)
        if os.path.exists(filepath):
            namelist.append(filepath)
            path2name[filepath] = file_name
    namelist.sort()
    for n in namelist:
        tf = open(n, "rb")
        ts = tf.read()
        tf.close()
        file_name = path2name[n]
        zipname = "%s/%s"%(dst_path,file_name)

        if not os.path.exists(zipname):
            try:
                os.makedirs(dst_path)
            except OSError, e:
                pass
        if os.path.exists(zipname):
            os.remove(zipname)

        z = zipfile.ZipFile(zipname, "w", zipfile.ZIP_DEFLATED)
        z.writestr(file_name, ts)
        z.close()

        zf = open(zipname, "rb")
        zs = zf.read()
        zf.close()

        iTime = int(time.time())
        iVersion = iTime
        iFactor = 256*256*256
        lChar = []
        for i in range(1,5):
            sChar = chr(iVersion / iFactor)
            lChar.append(sChar)
            iVersion = iVersion % iFactor
            iFactor = iFactor / 256
        sVersion = "".join(lChar)
        print("----version----",iTime)
        finalstr = "%s%s"%(sVersion,zs)
        zf = open(zipname, "wb")
        zf.write(finalstr)
        zf.close()