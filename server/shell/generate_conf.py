#!/usr/bin/python
#coding:utf-8

import os, sys
import re


p1 = re.compile("(?P<cluster>[a-zA-Z0-9]+)_(?P<server_type>[a-zA-Z]+)(?P<server_id>\d*)")

def gen_config(server_key):
    group_result = p1.match(server_key)
    if not group_result:
        return
    cluster = group_result.group("cluster").strip()
    server_type = group_result.group("server_type").strip()
    if server_type == "cs":
        gen_cs_config(server_key)
    elif server_type == "gs":
        gen_gs_config(server_key)
    elif server_type == "bs":
        gen_bs_config(server_key)
    elif server_type == "ks":
        gen_ks_config(server_key)

def gen_ks_config(server_key):
    with open("./config/template/ks_config.lua", "rb") as fp:
        content = fp.read()
    content = content.replace("T_SERVER_KEY", '"%s"'%server_key)
    with open("./config/ks_config.lua", "wb") as fp:
        fp.write(content)

def gen_bs_config(server_key):
    with open("./config/template/bs_config.lua", "rb") as fp:
        content = fp.read()
    content = content.replace("T_SERVER_KEY", '"%s"'%server_key)
    with open("./config/bs_config.lua", "wb") as fp:
        fp.write(content)

def gen_cs_config(server_key):
    with open("./config/template/cs_config.lua", "rb") as fp:
        content = fp.read()
    content = content.replace("T_SERVER_KEY", '"%s"'%server_key)
    with open("./config/cs_config.lua", "wb") as fp:
        fp.write(content)

def gen_gs_config(server_key):
    with open("./config/template/gs_config.lua", "rb") as fp:
        content = fp.read()
    content = content.replace("T_SERVER_KEY", '"%s"'%server_key)
    with open("./config/gs_config.lua", "wb") as fp:
        fp.write(content)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print "%s no args" % sys.argv[0]
        os._exit(1)

    server_key = sys.argv[1]
    gen_config(server_key)
