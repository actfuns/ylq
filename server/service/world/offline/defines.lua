local global = require "global"

FRIEND_CNTBASE = 50
FRIEND_APPLYLIMIT = 20
FRIEND_CNTMAX = 100

DEGREE_PROTECT = 1000
DEGREE_MAX = 50000


RELATION_COUPLE = 1 --夫妻关系
RELATION_BROTHER = 2 -- 结拜
RELATION_MASTER = 3 --师傅
RELATION_NORMAL_FRIEND = 4 --普通好友
RELATION_SPECIAL_FRIEND = 5 -- 挚友 好友度>1000
RELATION_ORGMEM = 6 --同一帮派
RELATION_STRANGER = 7 --陌生人
RELATION_STUDENT = 8 -- 学生
RELATION_LOVES = 9 -- 恋人

FRIEND_KEEP = list_key_table({
    RELATION_COUPLE,
    RELATION_BROTHER,
    RELATION_MASTER,
    RELATION_STUDENT,
    RELATION_LOVES,
})

--小于10000调用玩家方法
local Func2No = {
    ["RewardCoin"] = 1001,
    ["AddTitle"] = 1002,
    ["RemoveTitles"] = 1003,
    ["SyncTitleName"] = 1004,
    ["SetData"] = 1005,
    ["PushAchieve"] = 1006,
    ["RemoveTitlesByKey"] = 1007,
    ["RedeemCodeReward"] = 1008,
    ["CheckTitleAdjust"] = 1009,

    ["pay_for_gold"] = 10001,
    ["pay_for_huodong_charge"] = 10002,
    ["BanPlayerChat"] = 11001,
    ["FinePlayerMoney"] = 11002,
    ["RemovePlayerItem"] = 11003,
    ["ForceLeaveTeam"] = 11004,
    ["ForceChangeScene"] = 11005,
    ["BanPlayerReport"] = 11006,
    ["ResumeCoin"] = 11007,
    ["BanPlayerChatSelf"] = 11008,
}

local No2Path = {
}

local PathFuncCaChe = {
}

function GetFuncNo(sFunc)
    return Func2No[sFunc]
end

function GetFuncByNo(iFuncNo)
    for sFunc,iNo in pairs(Func2No) do
        if iFuncNo == iNo then
            return sFunc
        end
    end
end

function GetFuncPathByNo(iFuncNo)
    local sPath = No2Path[iFuncNo]
    local sFunc = GetFuncByNo(iFuncNo)
    sFunc = import(service_path(sPath))[sFunc]
    return sFunc
end

mOnlineExecute = {}
mOnlineExecute.pay_for_gold = function(oPlayer, iAmount, lArgs,sProductKey)
    global.oPayMgr.m_oPayCb:pay_for_gold(oPlayer:GetPid(), iAmount, lArgs,sProductKey)
end

mOnlineExecute.pay_for_huodong_charge = function(oPlayer, iAmount, lArgs, sProductKey)
    global.oPayMgr.m_oPayCb:pay_for_huodong_charge(oPlayer:GetPid(), iAmount, lArgs, sProductKey)
end