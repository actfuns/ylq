--import module
local global = require "global"

function AnalyTime(sTime)
    local year,month,day = string.match(sTime,"(%d+)-(%d+)-(%d+)")
    year,month,day = tonumber(year),tonumber(month),tonumber(day)
    return year,month,day
end

function AnalyTimeStamp(sTime)
    local year,month,day = string.match(sTime,"(%d+)-(%d+)-(%d+)")
    year,month,day = tonumber(year),tonumber(month),tonumber(day)
    return os.time({year = year,month = month,day = day,hour=0,min=0,sec=0})
end

function AnalyTimeStamp2(sTime)
    if not sTime or sTime == "" then
        return
    end
    local year,month,day,hour,min,sec = string.match(sTime,"(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    year,month,day,hour,min,sec = tonumber(year),tonumber(month),tonumber(day),tonumber(hour),tonumber(min),tonumber(sec)
    return os.time({year = year,month = month,day = day,hour=hour,min=min,sec=sec})
end

function FormatTime(iTime)
    local m = os.date("*t", iTime)
    return string.format("%04d-%02d-%02d",m.year,m.month,m.day)
end

function FormatTimeToSec(iTime)
    local m = os.date("*t", iTime)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d",m.year,m.month,m.day,m.hour,m.min,m.sec)
end

function FormatHourMin(iTime)
    local mDate = os.date("*t", iTime)
    return string.format("%02d:%02d",mDate.hour,mDate.min)
end

function GetDateInfo(iTime)
    local mDate = os.date("*t", iTime)
    return mDate.year,mDate.month,mDate.day
end

ServerName = {
    ["dev_gs10001"] = "开发服",
    ["pro_gs10001"] = "月见岛服",
}

ServerOpenTime = {
    ["dev_gs10001"] = "2017-06-01 00:00:00",
    ["pro_gs10001"] = "2017-08-03 11:00:00",
}

function GetServerName(sServer)
    return ServerName[sServer] or "未知服务器"
end

function GetServerOpenTime(sServer)
    return ServerOpenTime[sServer] or "未开"
end

tPlatformName = {
    "Andorid","越狱IOS","IOS"
}

function GetPlatformList(platformIds)
    if type(platformIds) ~= "table" then
        return
    end
    local list = {}
    for _,id in pairs(platformIds) do
        if tPlatformName[tonumber(id)] then
            table.insert(list,tPlatformName[tonumber(id)])
        end
    end
    return list
end

function GetChannelList(channelIds)
    if type(channelIds) ~= "table" then
        return
    end
    local oBackendInfoMgr = global.oBackendInfoMgr
    local mRet = oBackendInfoMgr:GetChannelList()
    local list = {}
    for _,id in pairs(channelIds) do
        for _,data in pairs(mRet) do
            if data.id == id then
                table.insert(list,data.description)
            end
        end
    end
    return list
end

function GetAllChannelList()
    local oBackendInfoMgr = global.oBackendInfoMgr
    local mRet = oBackendInfoMgr:GetChannelList()
    local list = {}
    for _,data in pairs(mRet) do
        table.insert(list,data.description)
    end
    return list
end

-- 游戏log 类型
GAME_LOG_MAP = {
    {"account", "账号日志"},
    {"player", "玩家日志"},

    {"coin", "货币日志"},
    {"friend", "好友日志"},
    {"item", "物品日志"},
    {"mail", "邮件日志"},
    {"online", "在线人数日志"},
    {"org", "公会日志"},
    {"orgfuben", "公会副本日志"},
    {"partner", "伙伴日志"},
    {"shop", "商店日志"},
    {"skill", "技能日志"},
    {"task", "任务日志"},
    {"title", "称谓日志"},

    {"arenagame", "比武场日志"},
    {"equipfuben", "装备副本日志"},
    {"pefuben", "御灵副本日志"},
    {"pata", "爬塔日志"},
    {"worldboss", "次元妖兽日志"},
    {"lilian", "历练日志"},
    {"treasure","宝图日志"},
    {"schedule","日程日志"},
    {"equip","装备日志"},
    {"endlesspve", "好友召唤"},
    {"minglei","明雷日志"},
    {"chat","聊天日志"},
    {"msattack","怪物攻城日志"},
    {"huodong","充值日志"},
    {"travel", "游历日志"},
    {"fuli", "福利日志"},
    {"yjfuben", "梦魇日志"},
    {"orgwar", "公会战"},
    {"achieve", "成就日志"},
    {"trapmine", "暗雷日志"},
    {"loginreward", "登录奖励日志"},
    {"partner_equip", "伙伴符文日志"},
    {"picture", "图鉴日志"},
    {"equalarena", "公平竞技日志"},
    {"question", "答题日志"},
    {"terrawars", "据点战日志"},
    {"fieldboss", "野外boss日志"},
    {"pay", "充值日志"},
    {"npcfight", "挑战npc日志"},
    {"house", "宅邸日志"},
    {"handbook", "伙伴图鉴日志"},
    {"rewardback", "奖励找回日志"},
    {"teampvp", "协同战斗日志"},
    {"chapterfb", "推图日志"},
    {"onlinegift", "在线奖励日志"},
    {"convoy", "护送日志"},
    {"shimen", "师门日志"},
    {"achievetask", "成就任务日志"},
    {"rank", "排行榜日志"},
    {"hirepartner", "伙伴招募日志"},
    {"clubarena", "比武馆日志"},
    {"gradegift", "等级礼包日志"},
    {"oneRMBgift", "一元礼包"},
    {"addcharge", "限时累充"},
    {"daycharge", "连续充值"},
    {"chargescore","消费积分"},
    {"limitopen", "活动开启"},
}

function GetYearMonthList(iStartTime, iEndTime)
    local iStartYear,iStartMonth = GetDateInfo(iStartTime)
    local iEndYear,iEndMonth = GetDateInfo(iEndTime)

    local lRet = {}
    local iMonth = iStartMonth
    for i = iStartYear, iEndYear do
        for j = iStartMonth, 12 do
            if i == iEndYear and j > iEndMonth then
                break
            end
            table.insert(lRet, {i, j})
        end
    end
    return lRet
end
