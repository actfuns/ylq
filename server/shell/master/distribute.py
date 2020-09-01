#!/usr/bin/python
#coding:utf-8
import subprocess
import multiprocessing
import os.path
import sys
import time

SERVER_KEY_LIST = {
    "./shell/master/rsync_conf.sh" : 1,
    "./shell/gen_config.sh" : 1,
}

NON_SERVER_KEY = {
    "./shell/bs_close.sh" : 1,
    "./shell/bs_run.sh" : 1,
    "./shell/bs_start.sh" : 1,
    "./shell/cs_close.sh" : 1,
    "./shell/cs_run.sh" : 1,
    "./shell/cs_start.sh" : 1,
    "./shell/gs_close.sh" : 1,
    "./shell/gs_run.sh" : 1,
    "./shell/gs_start.sh" : 1,
    "./shell/open_gate.sh" : 1,
    "./shell/pull_data.sh" : 1,
}

FILTER_SERVER_TYPE = {
    "./shell/bs_close.sh" : ["bs"],
    "./shell/bs_run.sh" : ["bs"],
    "./shell/bs_start.sh" : ["bs"],
    "./shell/cs_close.sh" : ["cs"],
    "./shell/cs_run.sh" : ["cs"],
    "./shell/cs_start.sh" : ["cs"],
    "./shell/gs_close.sh" : ["gs"],
    "./shell/gs_run.sh" : ["gs"],
    "./shell/gs_start.sh" : ["gs"],
    "./shell/open_gate.sh" : ["gs"],
    "./shell/pull_data.sh" : ["bs"],
}

def GetServerType(sServerKey):
    p = subprocess.Popen("./shell/master/info/get_server_type.sh %s" % sServerKey, shell=True, stdout=subprocess.PIPE)
    outdata, errdata = p.communicate()
    if outdata:
        outdata = outdata.strip("\n")
    return outdata

def TransServerKey(sServerKey, sShell):
    ret = ""
    if sShell in NON_SERVER_KEY:
        pass
    elif sShell in SERVER_KEY_LIST:
        ret = sServerKey
    else:
        ret = GetServerType(sServerKey)
    return ret

def GetServerIp(sServerKey):
    p = subprocess.Popen("./shell/master/info/get_ip.sh %s" % sServerKey, shell=True, stdout=subprocess.PIPE)
    outdata, errdata = p.communicate()
    return outdata

def ShellExec(bRemote, sServerKey, sShell, lArgs):
    serverarg = TransServerKey(sServerKey, sShell)
    if serverarg:
        lArgs.insert(0, serverarg)

    if not bRemote:
        sCmd = "%s %s" % (sShell, " ".join(lArgs))
    else:
        sIp = GetServerIp(sServerKey)
        if not sIp:
            print "shell exec error server key %s"%sServerKey
            return
        sCmd = """ssh -fnp 932 cilu@%s "
cd %s;
%s %s;
"
""" % (sIp, sServerKey, sShell, " ".join(lArgs))

    result = "[%s] exec [%s %s]：\n" % (sServerKey, sShell, " ".join(lArgs))
    p = subprocess.Popen(sCmd, shell=True, stdout=subprocess.PIPE)
    outdata, errdata = p.communicate()
    return result + outdata

def PrintResult(result):
    print result


class CDistribute(object):
    def __init__(self, args):
        self.m_sServers = args[2]
        self.m_sShell = args[3]
        self.m_lArgs = args[4:]
        self.m_lPools = multiprocessing.Pool(processes = 10)

    def LocalExec(self):
        self.ServerExec(False)

    def RemoteExec(self):
        self.ServerExec(True)

    def ServerExec(self, bRemote):
        lServers = self.GetServerkeysFromList(self.m_sServers)
        if lServers:
            pass
        elif self.IsKnownServerKey(self.m_sServers):
            lServers.append(self.m_sServers)

        lServers = self.FilterServer(lServers, self.m_sShell)
        if lServers:
            for sServerKey in lServers:
                self.m_lPools.apply_async(ShellExec, args=(bRemote, sServerKey, self.m_sShell, self.m_lArgs), callback=PrintResult)
            self.m_lPools.close()
            self.m_lPools.join()
        else:
            print "no servers distribute!!!"

    def GetServerkeysFromList(self, sServerList):
        lServers = []
        sFilePath = "./shell/master/list/" + sServerList + ".list"
        if os.path.exists(sFilePath):
            with open(sFilePath, "r") as f:
                for line in f:
                    lServers.append(line.strip("\n"))
            return lServers
        return lServers

    def IsKnownServerKey(self, sServerKey):
        p = subprocess.Popen("./shell/master/info/is_known_server_key.sh %s" % sServerKey, shell=True, stdout=subprocess.PIPE)
        outdata, errdata = p.communicate()
        if outdata:
            return True
        return False

    def FilterServer(self, lServers, sShell):
        if sShell in FILTER_SERVER_TYPE:
            ret = []
            lServerType = FILTER_SERVER_TYPE[sShell]
            for sServerKey in lServers:
                if GetServerType(sServerKey) in lServerType:
                    ret.append(sServerKey)
            return ret
        else:
            return lServers


if __name__ == "__main__":
    sLocal = sys.argv[1]
    oDistribute = CDistribute(sys.argv)
    if sLocal == "local":
        oDistribute.LocalExec()
    else:
        oDistribute.RemoteExec()