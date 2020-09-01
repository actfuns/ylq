#!/usr/bin/python
#coding:utf-8

import os
import sys
import pyutils.dbdata as db


def key2tag(sServerKey):
    r = sServerKey.split("_", 1)
    if len(r) >= 2:
        return r[1]
    else:
        return r[0]


class Server(object):
    """docstring for Server"""
    def __init__(self, server_type, server_ip, server_port):
        self.conn = db.GetConnection(server_ip, server_port)
        self.server_type = server_type
        self.init_server()
        if server_type == "cs":
            self.chg_roleinfo()
        elif server_type == "gs":
            self.chg_world()
            self.chg_player()
            self.chg_profile()

    def init_server(self):
        if server_type == "cs":
            self.server_tag = "cs"
        elif server_type == "gs":
            data = self.conn['game']["world"].find_one()
            self.server_tag = key2tag(data["server_id"])
        print "init server %s .............." % (self.server_tag)

    def chg_roleinfo(self):
        print "change roleinfo start .............."
        coll = self.conn['game']["roleinfo"]
        server_keys = []
        for r in coll.aggregate([{"$group":{"_id":"$server"}}]):
            server_keys.append(r["_id"])
        for server_key in server_keys:
            server_tag = key2tag(server_key)
            print "roleinfo %s %s start .............." % (server_key, server_tag)
            coll.update_many({"server":server_key}, {"$set":{"server":server_tag, "now_server":server_tag}})
            print "roleinfo %s %s end .............." % (server_key, server_tag)
        print "change roleinfo end .............."

    def chg_world(self):
        print "change world start .............."
        coll = self.conn['game']["world"]
        coll.update_one({}, {"$set":{"server_id":self.server_tag}})
        print "change world end .............."

    def chg_player(self):
        print "change player start .............."
        coll = self.conn['game']["player"]
        coll.update_many({}, {"$set":{"born_server":self.server_tag, "now_server":self.server_tag}})
        print "change player end .............."

    def chg_profile(self):
        print "change profile start .............."
        coll = self.conn['game']["offline"]
        coll.update_many({}, {"$set":{"profile_info.born_server":self.server_tag, "profile_info.now_server":self.server_tag}})
        print "change profile end .............."

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("no server type")
        os._exit(1)
    server_ip = "127.0.0.1"
    server_port = 27017
    server_type = sys.argv[1]
    if len(sys.argv) > 2:
        server_ip = sys.argv[2]
    if len(sys.argv) > 3:
        server_port = int(sys.argv[3])
    print "change server %s %s %s start .............." % (server_type, server_ip, server_port)
    Server(server_type, server_ip, server_port)
    print "change server %s %s %s end .............." % (server_type, server_ip, server_port)