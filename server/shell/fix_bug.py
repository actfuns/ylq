# -*-  coding: utf-8  -*-
from pymongo import MongoClient

import pyutils.dbdata as dbdata
import time as time

def GetItemData():
        lShape = [21051,21052,21061,21062,21151,21152,21161,21162,21251,21252,21261,21262,
            21351,21352,21361,21362,21451,21452,21461,21462,21551,21552,21561,21562,21651,21652,
            21661,21662,23051,23052,23061,23062,23151,23152,23161,23162,23251,23252,23261,23262,
            23351,23352,23361,23362,24051,24052,24061,24062,24151,24152,24161,24162,24251,24252,
            24261,24262,24351,24352,24361,24362,24451,24452,24461,24462,25051,25052,25061,25062,
            25151,25152,25161,25162,25251,25252,25261,25262,25351,25352,25361,25362,25451,25452,
            25461,25462,25551,25552,25561,25562,21611,21612,21613,21614,21615,21616,21621,21622,
            21623,21624,21625,21626,21631,21632,21633,21634,21635,21636,21641,21642,21643,21644,
            21645,21646,23011,23012,23013,23014,23015,23016,23021,23022,23023,23024,23025,23026,
            23031,23032,23033,23034,23035,23036,23041,23042,23043,23044,23045,23046,25311,25312,
            25313,25314,25315,25316,25321,25322,25323,25324,25325,25326,25331,25332,25333,25334,
            25335,25336,25341,25342,25343,25344,25345,25346,201004,201005,201006,201007,201150,
            201151,201753,201754,201755,
        ]
        return lShape

def IsDelete(iShape):
    lShape = GetItemData()
    for iDeleteShape in lShape:
        if iShape == iDeleteShape:
            return True;
    return False;

def DeletePartnerItem():
    oClient = MongoClient("127.0.0.1",27017)
    db = oClient.game
    collection = db.partner
    for partner in collection.find():
        iPid = partner["pid"]
        if not partner.has_key("item"):
            continue
        mItem = partner["item"]
        if not mItem["itemdata"].has_key("5"):
            continue
        mContainer = mItem["itemdata"]["5"]
        mDelete = {}
        for iKey,mData in enumerate(mContainer):
            iShape = mData["sid"]
            if IsDelete(iShape) :
                mDelete[iKey] = 1
        for iKey in range(len(mContainer)-1,-1,-1):
            if mDelete.has_key(iKey):
                del mContainer[iKey]
        mItem["itemdata"]["5"] = mContainer
        db.partner.update({"pid":iPid},{"$set":{"item":mItem}})

def ClearPartnerChip():
    oClient = MongoClient("127.0.0.1",27017)
    db = oClient.game
    collection = db.player
    for player in collection.find():
        iPid = player["pid"]
        if not player.has_key("item_info"):
            continue
        mItem = player["item_info"]
        if not mItem["itemdata"].has_key("7"):
            continue
        mItem["itemdata"]["7"] = {}
        db.player.update({"pid":iPid},{"$set":{"item_info":mItem}})

def ClearMail():
    oClient = MongoClient("127.0.0.1",27017)
    db = oClient.game
    collection = db.offline
    for offline in collection.find():
        iPid = offline["pid"]
        if not offline.has_key("mail_info"):
            continue
        db.offline.update({"pid":iPid},{"$set":{"mail_info":{}}})


def DeleteOfflineItem():
    oClient = MongoClient("127.0.0.1",27017)
    db = oClient.game
    collection = db.offline
    for offline in collection.find():
        iPid = offline["pid"]
        if not offline.has_key("partner_info"):
            continue
        mPartner = offline["partner_info"]
        if not mPartner.has_key("show_partner"):
            continue
        mShowPartner = mPartner["show_partner"]
        for iKey,mPartnerData in enumerate(mShowPartner):
            mItemData = mPartnerData["equip"]
            mDelete = {}
            for iKey,mItem in enumerate(mItemData):
                iShape = mItem["data"]["sid"]
                if IsDelete(iShape):
                    mDelete[iKey] = 1
            for iKey in range(len(mItemData)-1,-1,-1):
                if mDelete.has_key(iKey):
                    del mItemData[iKey]
            mPartnerData["equip"] = mItemData
        db.offline.update({"pid":iPid},{"$set":{"partner_info":mPartner}})

def ClearHandBookData():
    oClient = MongoClient("127.0.0.1",27017)
    db = oClient.game
    collection = db.player
    for player in collection.find():
        if player.has_key("handbook"):
            iPid = player["pid"]
            db.player.update({"pid":iPid,}, {"$unset":{"handbook":1}})

def MoveItemTable():
    oClient = MongoClient("127.0.0.1",27017)
    db = oClient.game
    collection = db.item
    for data in collection.find():
        iPid = data["pid"]
        item = data["item"]
        db.player.update({"pid":iPid,},{"$set":{"item_info":item}})

def FixEquipFuWen():
    oClient = MongoClient("127.0.0.1",27017)
    db = oClient.game
    collection = db.player
    for player in collection.find():
        if player.has_key("item_info"):
            iPid = player["pid"]
            iGrade = player["base_info"]["grade"]
            mItemInfo = player["item_info"]
            mEquip = mItemInfo["equip"]
            bModify = False
            for iPos in range(1, 7):
                sPos = str(iPos)
                if mEquip.has_key(sPos):
                    mInfo = mEquip[sPos]
                    if not mInfo.has_key("fuwen_plan"):
                        mPlan = {}
                        mPlan["1"] = {}
                        mPlan["1"]["fuwen"] = mInfo["fuwen"]
                        if mInfo["data"].has_key("back_fuwen"):
                            mPlan["1"]["back_fuwen"] = mInfo["data"]["back_fuwen"]
                        if iGrade >= 25:
                            mPlan["2"] = {}
                            mPlan["2"]["fuwen"] = mInfo["fuwen"]
                        mItemInfo["equip"][sPos]["fuwen_plan"] = mPlan
                        bModify = True
                    mData = mInfo["data"]
                    if not mData.has_key("fuwen_plan"):
                        mData["fuwen_plan"] = 1
                        mItemInfo["equip"][sPos]["data"] = mData
                        bModify = True
            if bModify:
                db.player.update({"pid":iPid}, {"$set":{"item_info":mItemInfo}})

def FixPartnerBaozi():
    sTable = time.strftime("fixdata%Y%m",time.localtime(time.time()))
    oClient = MongoClient("mongodb://%s:%s@%s:%d/"%("root", "bCrfAptbKeW8YoZU", "127.0.0.1", 27017))
    db = oClient.game
    logdb = oClient[sTable]
    collection = db.partner
    for partner in collection.find():
        if not partner.has_key("partner"):
            continue
        mData = partner["partner"]
        if not mData.has_key("partner"):
            continue
        iPid = partner["pid"]
        datas = []
        logs = []
        parData = (dbdata.AfterLoad(mData["partner"]) or [])
        mBaoZi = None
        for i, mPar in enumerate(parData):
            if mPar["partner_type"] == 1754:
                if not mBaoZi:
                    mBaoZi = mPar
                    mBaoZi["name"] = "鲜肉包"
                    if not mBaoZi.has_key("amount"):
                        mBaoZi["amount"] = 1
                else:
                    amount = (mBaoZi["amount"] or 1) + 1
                    mBaoZi["amount"] = amount
                    logs.append({"partner_type":1754,"pid":iPid, "amount":mBaoZi["amount"] or 1, "traceno":mPar["traceno"]})
                status = 0
                if "status" in mBaoZi:
                    status = mBaoZi["status"]
                status = status & ~(1 << 3)
                status = status & ~(1 << 4)
                mBaoZi["status"] = status
            else:
                datas.append(mPar)
        if mBaoZi:
            datas.append(mBaoZi)
        mData["partner"] = dbdata.BeforeSave(datas)
        db.partner.update({"pid":iPid},{"$set":{"partner":mData}})
        if len(logs) > 0:
            logdb.partner.insert_many(logs)

def IsMerge(iSid):
    lMerge = {26911,26912,26913,26914,26915,26916}
    for i in lMerge:
        if iSid == i:
            return True
    return False
# 修复经验符文
def FixPartnerExpEquip():
    sTable = time.strftime("fixdata%Y%m",time.localtime(time.time()))
    oClient = MongoClient("mongodb://%s:%s@%s:%d/"%("root", "bCrfAptbKeW8YoZU", "127.0.0.1", 27017))
    gamedb = oClient.game
    collection = gamedb.player
    logdb = oClient[sTable]
    for player in collection.find():
        if not player.has_key("item_info"):
            continue
        mItemInfo = dbdata.AfterLoad(player["item_info"])
        if not mItemInfo.has_key("itemdata"):
            continue
        mItemData = mItemInfo["itemdata"]
        if not mItemData.has_key("5"):
            continue
        iPid = player["pid"]
        datas = []
        mPEquip = mItemData["5"]
        mMerge = None
        mRecord = {}
        logs = []
        for mData in  mPEquip:
            iSid = mData["sid"]
            if IsMerge(iSid):
                if mRecord.has_key(iSid):
                    m = mRecord[iSid]
                    m["amount"] = (m["amount"] or 0) + (mData["amount"] or 1)
                    mRecord[iSid] = m
                    logs.append({"sid":iSid,"pid":iPid, "amount":mData["amount"], "TraceNo":mData["data"]["TraceNo"]})
                else:
                    mRecord[iSid] = mData
            else:
                datas.append(mData)
        for iSid in mRecord:
            datas.append(mRecord[iSid])
        mItemData["5"] = datas
        mItemInfo["itemdata"] = mItemData
        savedata = dbdata.BeforeSave(mItemInfo)
        gamedb.player.update({"pid":iPid},{"$set":{"item_info":mItemInfo}})
        if len(logs) > 0:
            logdb.item.insert_many(logs)

def FixRankData():
    sTable = time.strftime("fixdata%Y%m",time.localtime(time.time()))
    oClient = MongoClient("mongodb://%s:%s@%s:%d/"%("root", "bCrfAptbKeW8YoZU", "127.0.0.1", 27017))
    gamedb = oClient.game
    collection = gamedb.rank
    logdb = oClient[sTable]
    for rank in collection.find():
        sRank = rank["name"]
        if sRank != "parpower":
            continue
        if not rank.has_key("rank_data"):
            continue
        mRankData = rank["rank_data"]
        if not mRankData.has_key("rank"):
            continue
        mRank = mRankData["rank"]
        for sType in mRank:
            mData = mRank[sType]
            sRankTable = str.format("partner{}", sType)
            savedata = {}
            savedata["name"] = sRankTable
            savedata["rank_data"] = mData
            mData["name"] = sRankTable
            collection.update({"name":sRankTable}, savedata, True)
        sTime = time.strftime("%Y/%m/%d %H:%M:%S",time.localtime(time.time()))
        logdb.rank.insert_one({"name":"parpower", "time":sTime})

def FixColorCoin():
    sTable = time.strftime("fixdata%Y%m",time.localtime(time.time()))
    oClient = MongoClient("mongodb://%s:%s@%s:%d/"%("root", "bCrfAptbKeW8YoZU", "127.0.0.1", 27017))
    gamedb = oClient.game
    collection = gamedb.offline
    logdb = oClient[sTable]
    fixs = []
    for offline in collection.find():
        if not offline.has_key("profile_info"):
            continue
        profile = dbdata.AfterLoad(offline["profile_info"])
        if not profile.has_key("color_coin"):
            continue
        colorcoin = profile["color_coin"] or 0
        if colorcoin <= 0:
            continue
        pid = offline["pid"]
        oldgoldcoin = 0
        if profile.has_key("goldcoin"):
            oldgoldcoin = profile["goldcoin"] or 0
        goldcoin = oldgoldcoin + (colorcoin * 10)
        profile["color_coin"] = 0
        profile["goldcoin"] = goldcoin
        savedata = dbdata.BeforeSave(profile)
        fixs.append({"pid":pid,"colorcoin":colorcoin, "oldgoldcoin":oldgoldcoin})
        collection.update({"pid":pid}, {"$set":{"profile_info":savedata}})
        logdb.offline.insert_one({"name":"parnter_info", "pid":pid, "oldcolorcoin":colorcoin,"colorcoin":profile["color_coin"],"oldgoldcoin":oldgoldcoin, "goldcoin":goldcoin})
    print("FixColorCoin:",fixs)

# 修复经验符文
def FixPartnerEquip():
    sTable = time.strftime("fixdata%Y%m",time.localtime(time.time()))
    oClient = MongoClient("mongodb://%s:%s@%s:%d/"%("root", "bCrfAptbKeW8YoZU", "127.0.0.1", 27017))
    gamedb = oClient.game
    collection = gamedb.player
    logdb = oClient[sTable]

    mUnlock = {}
    mUnlock[1] = 0
    mUnlock[2] =50
    mUnlock[3] = 55
    mUnlock[4] = 60
    for player in collection.find():
        if not player.has_key("item_info"):
            continue
        mItemInfo = dbdata.AfterLoad(player["item_info"])
        if not mItemInfo.has_key("itemdata"):
            continue
        mItemData = mItemInfo["itemdata"]
        if not mItemData.has_key("5"):
            continue
        logs = []
        datas = []
        iPid = player["pid"]
        iGrade = player["base_info"]["grade"]
        mPEquip = mItemData["5"]
        for mData in  mPEquip:
            if mData["data"].has_key("wield"):
                if mData["data"]["wield"] > 0:
                    iSid = int(mData["sid"])
                    iPos = (iSid - 6000000) // 100000
                    if iGrade < mUnlock[iPos]:
                        logs.append({"parid":mData["data"]["wield"],"sid":iSid})
                        mData["data"]["wield"] = 0
        # mItemData["5"] = datas
        # mItemInfo["itemdata"] = mItemData
        # savedata = dbdata.BeforeSave(mItemInfo)
        # gamedb.player.update({"pid":iPid},{"$set":{"item_info":mItemInfo}})
        if len(logs) > 0:
            slog = "pid:%s ,account:%s" %(str(iPid), player["account"])
            print(slog, logs)
            logdb.parequip.insert({"pid":iPid, "unlock_wield_list":logs})

def bianli(m):
    mResult = {}
    for key in m:
        if isinstance(key,int):
            if isinstance(m[key],dict):
                mResult[str(key)] = bianli(m[key])
            else:
                mResult[str(key)] = m[key]
        else:
            if isinstance(m[key],dict):
                mResult[str(key)] = bianli(m[key])
            else:
                mResult[key] = m[key]
    return mResult

def FixChapterfb():
    oClient = MongoClient("mongodb://%s:%s@%s:%d/"%("root", "bCrfAptbKeW8YoZU", "127.0.0.1", 27017))
    db = oClient.game
    collection = db.player
    for info in collection.find():
        iPid = info["pid"]
        if not info.has_key("huodong_info"):
            continue
        mHuodong = dbdata.AfterLoad(info["huodong_info"])
        if not mHuodong.has_key("chapterfb"):
            continue
        mChapter = dbdata.AfterLoad(mHuodong["chapterfb"])
        if mChapter.has_key("finalchapter"):
            mFinalChapter = dbdata.AfterLoad(mChapter["finalchapter"])
            mFinalChapter["type"] = 1
        mNew = {}
        mNew["normal"] = bianli(mChapter)
        collection.update({"pid":iPid}, {"$set":{"huodong_info.chapterfb":mNew}})


def FixChapterfbBakDB():
    oClient = MongoClient("mongodb://%s:%s@%s:%d/"%("root", "bCrfAptbKeW8YoZU", "127.0.0.1", 27017))
    bak_game = oClient.bak_game
    bak_collection = bak_game.player
    db = oClient.game
    collection = db.player
    for info in bak_collection.find():
        iPid = info["pid"]
        if not info.has_key("huodong_info"):
            continue
        mBakHuodong = dbdata.AfterLoad(info["huodong_info"])
        if not mBakHuodong.has_key("chapterfb"):
            continue
        mBakChapter = dbdata.AfterLoad(mBakHuodong["chapterfb"])
        if mBakChapter.has_key("finalchapter"):
            mFinalChapter = dbdata.AfterLoad(mBakChapter["finalchapter"])
            mFinalChapter["type"] = 1
            mNew = {}
            mNew["normal"] = bianli(mFinalChapter)
            collection.update({"pid":iPid}, {"$set":{"huodong_info.chapterfb":mNew}})

def DoScript():
    #FixChapterfbBakDB()
    FixChapterfb()
    # FixPartnerBaozi()
    # FixPartnerExpEquip()
    # FixRankData()
    # FixColorCoin()
    # FixPartnerEquip()
if __name__ == "__main__":
    DoScript()