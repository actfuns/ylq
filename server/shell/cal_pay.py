#!/usr/bin/python
#coding:utf-8

import pyutils.dbdata as db

PRODUCT_MAP = {
	"com.kaopu.ylq.6" : 6,
	"com.kaopu.ylq.12":12,
	"com.kaopu.ylq.30" : 30,
	"com.kaopu.ylq.68" : 68,
	"com.kaopu.ylq.128" : 128,
	"com.kaopu.ylq.328" : 328,
	"com.kaopu.ylq.648" : 648,
	"com.kaopu.ylq.yk" : 30,
	"com.kaopu.ylq.zsk" : 98,
	"com.kaopu.ylq.czjj" : 98,
	"com.kaopu.ylq.lb.1" : 1,
	"com.kaopu.ylq.lb.6" : 6,
	"com.kaopu.ylq.lb.12" : 12,
	"com.kaopu.ylq.lb.30" : 30,	
	"com.kaopu.ylq.lb.68" : 68,
	"com.kaopu.ylq.lb.128" : 128,
	"com.kaopu.ylq.lb.328" : 328,

	"com.cilu.n1_gold_6":6,
	"com.cilu.n1_gold_12":12,
	"com.cilu.n1_gold_30" : 30,
	"com.cilu.n1_gold_68" : 68,
	"com.cilu.n1_gold_128" : 128,
	"com.cilu.n1_gold_328" : 328,
	"com.cilu.n1_gold_648" : 648,
	"com.cilu.n1_yk" : 30,
	"com.cilu.n1_zsk" : 98,
	"com.cilu.n1_czjj" : 98,
}


class CPayCount(object):
	def __init__(self):
		self.m_sDB = "game"
		self.m_mResult = {}

	def pay_count(self):
		conn = db.GetConnection()
		coll = conn[self.m_sDB]["pay"]
		for data in coll.find():
			data = db.AfterLoad(data)
			account = data["account"]
			channel = data["demi_channel"]
			productId = data["product_key"]
			amount = data["product_amount"]
			sKey = self.gen_key(account, channel)
			m = self.m_mResult.get(sKey)
			if m is None:
				m = {"account":account, "channel":channel, "paycount":0}
				self.m_mResult[sKey] = m

			price = PRODUCT_MAP.get(productId)
			if price is None:
				print "not find productId %s" % (productId)
				continue

			m["paycount"] += price * amount

	def gen_key(self, account, channel):
		return "%s-%s" % (channel, account) 


	def show_resutl(self):
		for key, m in self.m_mResult.items():
			print " %s  %s  %s" % (m.get("channel"), m.get("paycount"), m.get("account"))


	def write_mongo(self):
		conn = db.GetConnection()
		coll = conn[self.m_sDB]["cbt_pay"]
		coll.ensure_index([("account", 1), ("channel", 1)])
		for key, m in self.m_mResult.items():
			insert_info = db.BeforeSave({"account":m.get("account"), "channel":m.get("channel"), "paycount":m.get("paycount")})
			coll.insert(insert_info)


	def write_file(self):
		f = open("cbt_pay.txt", "a")
		# f.write("channel  paycount  account\n")
		for key, m in self.m_mResult.items():
			f.write("%s %s %s \n" % (m.get("account"), m.get("channel"), m.get("paycount")))
		f.close()


if __name__ == "__main__":
    print "begin paycount start .............."
    obj = CPayCount()
    obj.pay_count()
    obj.write_mongo()
    obj.write_file()
    print "begin paycount end .............."
