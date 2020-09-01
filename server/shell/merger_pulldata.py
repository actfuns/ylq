#coding:utf-8
import subprocess
import os
import sys
import time


slave_db_addr = {
    "cs" : "172.18.123.208:27018",
    "gs20001" : "172.18.123.210:27017",
    "gs20002" : "172.18.14.122:27020",
}

merger_info = {
    1 : ["gs20002", "gs20001"],
}

form_db_addr = "127.0.0.1:27019"
to_db_addr = "127.0.0.1:27017"

def get_db_addr(server):
    return slave_db_addr[server]

def start_pull_data(merger_cnt, timestamp=""):
    from_server = merger_info[merger_cnt][0]
    to_server = merger_info[merger_cnt][1]
    if timestamp == "":
        timestamp = time.strftime("%Y-%m-%d")
        dump_all_game(from_server, to_server, timestamp)
    drop_all_db()
    load_all_game(from_server, to_server, timestamp)

def dump_all_game(from_server, to_server, timestamp):
    dump_game(from_server, timestamp)
    dump_game(to_server, timestamp)
    dump_game("cs", timestamp)

def load_all_game(from_server, to_server, timestamp):
    load_game(from_server, timestamp, form_db_addr)
    load_game(to_server, timestamp, to_db_addr)
    load_game("cs", timestamp, to_db_addr)

def drop_all_db():
    drop_db(form_db_addr)
    drop_db(to_db_addr)

def dump_game(server, timestamp):
    print(server, timestamp, "dump start")
    addr = get_db_addr(server)
    cmd = """mongodump -h %s --gzip -u root -p YXTxsaj22WSJ7wTG --authenticationDatabase admin -d game --archive=/home/cilu/waifu_db/%s-%s.gz &>/home/cilu/waifu_db/%s-%s.log""" % (addr, server, timestamp, server, timestamp)
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    outdata, errdata = p.communicate()
    if errdata:
        print(server, timestamp, "dump ret fail", errdata)
    else:
        print(server, timestamp, "dump ret success")

def drop_db(addr):
    print(addr, "drop db start")
    p = subprocess.Popen("./shell/drop_all_db.sh %s dropall" % addr, shell=True, stdout=subprocess.PIPE)
    outdata, errdata = p.communicate()
    if errdata:
        print(addr, "drop db ret fail", errdata)
    else:
        print(addr, "drop db ret success")

def load_game(server, timestamp, db_addr):
    print("load", server, timestamp, "start")
    cmd = """mongorestore -h %s --gzip -u root -p YXTxsaj22WSJ7wTG --authenticationDatabase admin --archive=/home/cilu/waifu_db/%s-%s.gz""" % (db_addr, server, timestamp)
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    outdata, errdata = p.communicate()
    if errdata:
        print("load", server, timestamp, "fail", errdata)
    else:
        print("load", server, timestamp, "success")


if __name__ == "__main__":
    #param python getplayer dumplayer server pid
    if len(sys.argv) < 2:
        os._exit(1)
    merger_cnt = int(sys.argv[1])
    timestamp = ""
    if len(sys.argv) > 2:
        timestamp = sys.argv[2]
    start_pull_data(merger_cnt, timestamp)
