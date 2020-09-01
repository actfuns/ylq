import email
import smtplib
import os
import sys
import httplib
import urllib
import json

from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class CMyEmail(object):
    def __init__(self):
        self.user = "n1@cilugame.com"
        self.pwd = "ZAt6dBqDJeoZeGLT"
        self.to_list = ["guitian.xie@cilugame.com",
		     "yonghao.gu@cilugame.com",
		      "lijian.zhan@cilugame.com",
		      "wei.liu@cilugame.com",
		      "cheng.huang@cilugame.com",
		      "cilugamedebug@163.com",
		  ]
        self.cc_list = []
        self.tag = "n1-server-error"
        self.title = ""
        self.content = ""
        #develop url
        # self.wechat_url = "http://106.75.153.198/logsend/weixin/5"
        # self.wechat_ip = "106.75.153.198"
        #normal url
        self.wechat_url = "https://172.18.123.209:80/logsend/weixin/5"
        self.wechat_ip = "172.18.123.209"


    def send_mail(self):
        try:
            server = smtplib.SMTP_SSL("smtp.exmail.qq.com", port=465, timeout=6)
            server.login(self.user, self.pwd)
            server.sendmail("From <%s>"%self.user, self.to_list, self.get_attach())
            server.close()
            print ("send email success")
        except Exception,e:
            print ("send email failed", e)


    def get_attach(self):
        attach = MIMEMultipart()
        if self.tag:
            attach["Subject"] = self.tag
        if self.user:
            attach["From"] = self.user
        if self.to_list:
            attach["To"] = ";".join(self.to_list)
        if self.cc_list:
            attach["Cc"] = ";".join(self.cc_list)
        if self.content:
            doc = MIMEText(self.content)
            doc["Context-Type"] = "application/octet-stream"
            attach.attach(doc)

        return attach.as_string()

    def send_wechat(self):
        body = json.dumps({'message':self.content, 'title':self.title})
        header = {'Host':self.wechat_ip, 'Content-type':"application/json"}
        conn = httplib.HTTPConnection(self.wechat_ip)
        conn.request(method="POST", url=self.wechat_url, body=body, headers=header)
        response = conn.getresponse()
        res = response.read()
        print res


if __name__ == "__main__":
    if len(sys.argv) == 3:
        title = sys.argv[1]
        content = sys.argv[2]
        if not content or not title:
            os._exit(1)

        mail_box = CMyEmail()
        mail_box.title = title
        mail_box.content = content
        #mail_box.send_mail()
        mail_box.send_wechat()

