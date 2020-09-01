#coding:utf-8
import commands
import os
import sys
import time

def scrapy():
    cmd = """top -b -n 1 |grep skynet"""
    status, result = commands.getstatusoutput(cmd)
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    lresult = result.split("\n")
    if len(lresult) > 0:
        with open("top-action-5500.log", "a+") as fp:
            fp.write(timestamp + "  " + lresult[0] + "\n")

    cmd = """echo 'mem' | nc -q 1 localhost 7001 |grep -E 'world|TOTAL'"""
    status, result = commands.getstatusoutput(cmd)
    lresult = result.split("\n")
    if len(lresult) > 1:
         with open("top-action-mem-5500.log", "a+") as fp:
            fp.write(timestamp + "  " + " ".join(lresult) + "\n")
   


if __name__ == "__main__":
    scrapy()