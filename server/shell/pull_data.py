import os
import sys
import httplib
import json

class CMgDump(object):
    def __init__(self,serverkey,dbname,tablename):
        self.tablename = tablename
        self.args = {"serverkey":serverkey,"dbname":dbname,"tablename":tablename}
        self.module = "query"
        self.bs_ip = "127.0.0.1"

    def request_data(self):
        body = json.dumps({'module':self.module, 'cmd':'PullData',"args":self.args})
        header = {'Content-type':"application/json"}

        conn = httplib.HTTPConnection(self.bs_ip,20003)
        conn.request(method="POST", url='/backend', body=body, headers=header)

        response = conn.getresponse()
        res = response.read()
        ret = json.loads(res)

        if ( ret["errcode"] != 0 ):
            print "[ errcode =",ret["errcode"],"]   pull data failed"
            return
        if ( not os.path.exists("pulldata") ):
            os.makedirs("pulldata")

        filename = "".join(("pulldata/",self.tablename,".json"))
        file_object = open(filename,"w")
        file_object.truncate()
        for info in ret["data"]:
            content = json.dumps(info,ensure_ascii=False)
            file_object.write(content.encode("utf8"))
            file_object.write("\n")
        file_object.close()


if __name__ == "__main__":
    if len(sys.argv) == 4:
        serverkey = sys.argv[1]
        dbname = sys.argv[2]
        tablename = sys.argv[3]

        mg_dump = CMgDump(serverkey,dbname,tablename)
        mg_dump.request_data()
