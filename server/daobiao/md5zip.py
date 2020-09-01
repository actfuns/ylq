#!/usr/bin/python
#coding:utf-8

import os
import sys
import hashlib
import zipfile

if len(sys.argv) < 3:
    print "%s no src or dst" % sys.argv[0]
    os._exit(1)

src_path = sys.argv[1].replace(os.sep, "/").rstrip("/")
dst_path = sys.argv[2].replace(os.sep, "/").rstrip("/")

result_name = "client-daobiao"
if len(sys.argv) > 3:
    result_name = sys.argv[3]

if __name__ == '__main__':
    namelist = []
    if os.path.isfile(src_path):
        namelist.append(src_path)
    elif os.path.isdir(src_path):
        for dirpath, _, filenames in os.walk(src_path):
            for filename in filenames:
                filepath = "/".join([dirpath.replace(os.sep, "/"), filename.replace(os.sep, "/")])
                if filepath.endswith(".lua"):
                    namelist.append(filepath)
    else:
        print "zip error path type"
        os._exit(1)

    zipname = "%s/%s.package"%(dst_path, result_name)

    contentlist = []
    namelist.sort()
    for n in namelist:
        tf = open(n, "rb")
        ts = tf.read()
        tf.close()
        contentlist.append(ts)
    filestream = "".join(contentlist)
    newmd5 = hashlib.md5(filestream).hexdigest()

    flag = False
    if not os.path.exists(zipname):
        try:
            os.makedirs(dst_path)
        except OSError, e:
            pass
        flag = True
    else:
        zf = open(zipname, "rb")
        zs = zf.read()
        zf.close()
        oldmd5 = zs[:32]

        if newmd5 == oldmd5:
            flag = False
        else:
            flag = True

    if flag:
        if os.path.exists(zipname):
            os.remove(zipname)

        z = zipfile.ZipFile(zipname, "w", zipfile.ZIP_DEFLATED)
        for i, cs in enumerate(contentlist):
            name = namelist[i]
            z.writestr(name, cs)
        z.close()

        zf = open(zipname, "rb")
        zs = zf.read()
        zf.close()

        finalstr = "%s%s"%(newmd5, zs)
        zf = open(zipname, "wb")
        zf.write(finalstr)
        zf.close()
