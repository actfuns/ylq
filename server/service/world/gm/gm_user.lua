--import module

local global = require "global"
local interactive = require "base.interactive"
local extend = require "base/extend"
local record = require "public.record"
local router = require "base.router"

local gamedb = import(lualib_path("public.gamedb"))
local gmcommon = import(service_path("gm/gm_common"))

Commands = {}
Helpers = {}
Opens = {}  --是否对外开放

Helpers.help = {
    "GM指令帮助",
    "help 指令名",
    "help 'clearall'",
}
function Commands.help(oMaster, sCmd)
    if sCmd then
        local o = Helpers[sCmd]
        if o then
            local sMsg = string.format("%s:\n指令说明:%s\n参数说明:%s\n示例:%s\n", sCmd, o[1], o[2], o[3])
            oMaster:Send("GS2CGMMessage", {
                msg = sMsg,
            })
        else
            oMaster:Send("GS2CGMMessage", {
                msg = "没查到这个指令"
            })
        end
    end
end

Helpers.sendsys = {
    "发送系统聊天信息",
    "sendsys 内容(非数字加上单引号) ",
    "sendsys 233333  ",
}
function Commands.sendsys(oMaster, sMsg, ...)
    local oChatMgr = global.oChatMgr
    oChatMgr:HandleSysChat(tostring(sMsg), ...)
end

function Commands.onlinestat(oMaster)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iCnt = oWorldMgr:OnlineAmount()
    oNotifyMgr:Notify(oMaster:GetPid(),string.format("当前在线人数:%d",iCnt))
end

Helpers.setname = {
    "设置名字",
    "setname 名字",
    "示例: setname '小强'",
}
function Commands.setname(oMaster, s)
    oMaster:SetName(s)
    oMaster:DoSave()
end

Helpers.addactive = {
    "增加活跃度",
    "addactive 活跃度",
    "addactive 9999",
}

function Commands.addactive(oMaster,iPoint)
    oMaster:RewardActive(iPoint,"gm")
end

function Commands.checkplayer(oMaster, iTarget)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oMaster:GetPid()
    if oWorldMgr:IsOnline(iTarget) then
        oNotifyMgr:Notify(iPid, "玩家在线")
        return
    end
    if oWorldMgr:IsLogining(iTarget) then
        oNotifyMgr:Notify(iPid, "玩家正在登录")
        return
    end
    oNotifyMgr:Notify(iPid, "玩家下线")
end

Helpers.setofflinetime = {
    "设置离线判断时间模式",
    "setofflinetime 模式(1为永不下线,2为很久下线(10min左右),3为正常下线(3min左右),4为尽快下线(10s以内))",
    "示例: setofflinetime 1",
}
function Commands.setofflinetime(oMaster, iMode)
    local oNotifyMgr = global.oNotifyMgr
    if table_in_list({1, 2, 3, 4}, iMode) then
        oMaster:SetTestLogoutJudgeTimeMode(iMode)
        oNotifyMgr:Notify(oMaster.m_iPid, string.format("你设置的离线判断时间模式为%s", iMode))
    else
        oNotifyMgr:Notify(oMaster.m_iPid, "只有1 2 3 4模式")
    end
end

Helpers.getofflinetime = {
    "获取离线判断时间模式",
    "getofflinetime",
    "示例: getofflinetime",
}
function Commands.getofflinetime(oMaster)
    local i = oMaster:GetTestLogoutJudgeTimeMode()
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oMaster.m_iPid, string.format("你设置的离线判断时间模式为%s", i))
end

--秒变土豪玩家
function Commands.supermode(oMaster)
    local oNotifyMgr = global.oNotifyMgr
    if oMaster.m_oBaseCtrl:GetData("supermode",0) ~=0 then
        return
    end

    oMaster:Dirty()
    oMaster.m_oBaseCtrl:SetData("supermode", 1)
    local iVal = 10000000
    local iTarget = oMaster:GetPid()
    oMaster:RewardExp(9999999,"gm", {bEffect = false})
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iTarget,function (oProfile)
        if not oProfile then
            return
        end
        oProfile:AddGoldCoin(iVal,"gm")
    end)
    oMaster:RewardCoin(iVal,"gm")
    oMaster:RewardMedal(iVal,"gm")
    oMaster:RewardArenaMedal(iVal,"gm指令")
    oMaster.m_oThisWeek:Add("arenamedal",iVal)

    local res = require "base.res"
    local iNum = 0
    local mPartnerList = res["daobiao"]["partner"]["partner_info"]
    for iPartnerType,info in pairs(mPartnerList) do
        if info then
            if info["usable"] == 1 then
                oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "addpartner", {{iPartnerType, 1}})
                iNum = iNum + 1
                if iNum == 4 then
                    break
                end
            end
        else
            global.oNotifyMgr:Notify(oMaster:GetPid(), string.format("导表不存在:%s伙伴",iPartnerType))
        end
    end

    for iPartner = 1,4 do
        oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "awakepartner", {iPartner})
        oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "addpartnerstar", {iPartner, 6})
        oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "addexp", {iPartner, 10000000})
        if iPartner > 2 then
            local iPost = iPartner
            oMaster.m_oPartnerCtrl:Forward("C2GSPartnerFight", oMaster:GetPid(), {fight_info={pos=iPost,parid=iPartner}})
        end
    end
end

--清除新手指引信息
function Commands.cleanguidance(oMaster)
    oMaster.m_oActiveCtrl:SetData("guidanceinfo",{})
    oMaster.m_oActiveCtrl:GS2CGuidanceInfo()
end

Helpers.setshape = {
    "设置造型",
    "setshape 造型",
    "示例: setshape 1",
}
function Commands.setshape(oMaster, iShape)
    oMaster.m_oBaseCtrl:ChangeShape(iShape)
end

Helpers.addschedule = {
    "完成一次日程",
    "addschedule 日程id",
    "addschedule 1001",
}
function Commands.addschedule(oMaster, sid)
    oMaster:AddSchedule(sid)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oMaster:GetPid(),string.format("日程 %d +1",sid))
end




Helpers.addskillexp = {
    "增加修炼技能经验",
    "addskillexp 技能编号 经验值",
    "addskillexp 4001 1000",
}
function Commands.addskillexp(oMaster, iSk, iVal)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oMaster:GetPid()
    local oSk = oMaster.m_oSkillCtrl:GetSkill(iSk)
    if not oSk then
        oNotifyMgr:Notify(iPid, string.format("经验id编号:%s不存在!", iSk))
        return
    end
    if oSk:IsMaxLevel() then
        oNotifyMgr:Notify(iPid, "已达技能等级上限")
        return
    end
    if oSk.AddExp then
        oSk:AddExp(oMaster, iVal, "gm测试")
        oSk:GS2CRefresh(oMaster)
        oNotifyMgr:Notify(iPid, "添加成功")
    end
end

Helpers.switchschool = {
    "切换门派",
    "switchschool 门派id 门派分支",
    "switchschool 1  2"
}
function Commands.switchschool(oMaster,iSchool,iSchoolBranch)
    local iCurSchool = oMaster:GetSchool()
    if iCurSchool ~= iSchool then
        oMaster.m_oBaseCtrl:SetData("school",iSchool)
        oMaster.m_oItemCtrl:ClearEquip()
        oMaster.m_oItemCtrl:CheckEquip(oMaster)
        oMaster.m_oItemCtrl:GiveSecondEquip(oMaster)
    end
    if not oMaster:ValidSwitchSchool(iSchoolBranch) then
        return
    end
    oMaster:SwitchSchool(iSchoolBranch)
end

Helpers.newdaypl = {
    "刷新天变量",
    "示例:newdaypl",
}

function Commands.newdaypl(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    -- local oHuodongMgr = global.oHuodongMgr
    -- oHuodongMgr:NewDay(iWeekDay)
    oPlayer.m_oToday:ClearData()
    oPlayer.m_oScheduleCtrl:Reset()
    oPlayer:NewDay()
    oPlayer.m_oPartnerCtrl:TestCmd(oPlayer:GetPid(), "cleartodaydata", {})
    oNotifyMgr:Notify(oPlayer:GetPid(),"天变量清理完毕")
    local oHuodong = global.oHuodongMgr:GetHuodong("onlinegift")
    oHuodong:GMNewDay(oPlayer)
end

Helpers.newweekpl = {
    "刷新周变量",
    "示例:newweekpl",
}
function Commands.newweekpl(oMaster,pid)
    local oPlayer = oMaster
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if pid then
        oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    end
    if not oPlayer then
        oNotifyMgr:Notify(oMaster:GetPid(),"没找到玩家")
        return
    end
    oPlayer.m_oThisWeek:ClearData()
    oNotifyMgr:Notify(oMaster:GetPid(),"周变量清理完毕")
end

function Commands.newmonthpl(oMaster,pid)
    local oPlayer = oMaster
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if pid then
        oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    end
    if not oPlayer then
        oNotifyMgr:Notify(oMaster:GetPid(),"没找到玩家")
        return
    end
    oPlayer.m_oMonth:ClearData()
    oNotifyMgr:Notify(oMaster:GetPid(),"月变量清理完毕")
end


Helpers.testpower = {
    "调整战力",
    "testpower 战力值",
    "testpower 9999",
}

function Commands.testpower(oMaster,iPower)
    if not tonumber(iPower) then return end
    if iPower == 0 then
        oMaster.m_TestPower = nil
    else
        oMaster.m_TestPower = iPower
    end
    oMaster:PropChange("power")
    oMaster:ClientPropChange({["power"]=true})
end

function Commands.SetTreasureTimes(oMaster)
    local iCurTimes = oMaster.m_oActiveCtrl:GetTreasureTotalTimes()
    local t = iCurTimes + (5 - iCurTimes%5) - 1
    oMaster.m_oActiveCtrl:SetTreasureTotalTimes(t)
end

Helpers.savedb = {
    "触发存盘",
    "savedb ",
    "savedb ",
}
function Commands.savedb(oMaster)
    record.info("-------------savedb")
    oMaster:DoSave()
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "savedb", {})
end

Helpers.mergesave = {
    "触发MERGE",
    "mergesave ",
    "mergesave ",
}
function Commands.mergesave(oMaster, iPid)
    local oWorldMgr = global.oWorldMgr
    local obj = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if obj then
        record.info(string.format("-------------savedb---%d %d",oMaster:GetPid(),iPid))
        oMaster:AddSaveMerge(obj)
    end
end

function Commands.testsecondprop(oMaster)
    local mPropInfo = {}
    local lSecondProp = {"speed","mag_defense","phy_defense","mag_attack","phy_attack","max_hp", "max_mp"}
    for _, sProp in pairs(lSecondProp) do
        local mData = {}
        mData.base = oMaster:GetBaseAttr(sProp)
        mData.extra = oMaster:GetAttrAdd(sProp)
        mData.ratio = oMaster:GetBaseRatio(sProp)
        mData.name = sProp
        table.insert(mPropInfo, mData)
    end
    local mNet = {}
    mNet["prop_info"] = mPropInfo
    oMaster:Send("GS2CGetSecondProp", mNet)
end

function Commands.setplayerattr(oMaster, iPid, mAttr)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        oPlayer = oMaster
    end
    oPlayer.m_oActiveCtrl:SetData("test_attr", mAttr)
    oPlayer:ActivePropChange()
end

function Commands.errormsg(oMaster)
    local a = b + c
end

function Commands.applykuafuwar(oMaster)
    global.oKFMgr:ApplyEnterGame(oMaster,"kfequalarena")
end

function Commands.disconnect(oMaster)
    oMaster:Disconnect()
end

----------------------------------------开放指令------------------------------------
Helpers.set = {
    "设置玩家基础属性",
    "set key value",
    "set 'testman' 99",
}
Opens["set"] = true
function Commands.set(oMaster, sKey, value)
    oMaster:SetData(sKey, value)
end

Helpers.get = {
    "获取玩家基础属性",
    "get key",
    "get 'testman'",
}
Opens["get"] = true
function Commands.get(oMaster, sKey)
    local oNotifyMgr = global.oNotifyMgr
    local value = oMaster:GetData(sKey, 0)
    local sMsg = string.format("查询到的%s 值为%s", sKey, tostring(value))
    oNotifyMgr:Notify(oMaster:GetPid(), sMsg)
end

Helpers.sendsys = {
    "冻结玩家水晶",
    "frozen 命令编号 数目  ",
    "frozen 101 100()  ",
}
Opens["frozen"] = true
function Commands.frozen(oMaster,iCmd,iGold)
    local oNotifyMgr = global.oNotifyMgr
    local oProfile = oMaster:GetProfile()
    local iPid = oMaster.m_iPid
    if iCmd == 101 then
        local iSession = oProfile:FrozenMoney("goldcoin",iGold,"gm")
        record.info(string.format("冻结session:%s",iSession))
    elseif iCmd == 102 then
        local iSession = iGold
        local mData = oProfile:UnFrozenMoney(iSession)
    end
end

Helpers.delrole = {
    "删除该角色",
    "delrole ",
}
Opens["delrole"] = true
function Commands.delrole(oMaster)
    local oNotifyMgr = global.oNotifyMgr
    local mData = {
        pid = oMaster:GetPid()
    }
    gamedb.SaveDb("gm","common", "SaveDb", {
        module = "playerdb",
        cmd = "RemovePlayer",
        data = mData
    })
    oNotifyMgr:Notify(oMaster:GetPid(), "删除成功")
end

Helpers.SendBrocast = {
    "发送跑马灯广播",
    "SendBrocast '广播内容'",
    "SendBrocast '广播内容'",
}
Opens["SendBrocast"] = true
function Commands.SendBrocast(oMaster,sMsg)
    gmcommon.Commands.SendBrocast(sMsg)
end

Opens["addfrienddegree"] = true
function Commands.addfrienddegree(oMaster,iTarget,iAdd)
    iTarget = tonumber(iTarget)
    iAdd = tonumber(iAdd)
    local oFriend = oMaster:GetFriend()
    local oNotifyMgr = global.oNotifyMgr
    if not oFriend:HasFriend(iTarget) then
        oNotifyMgr:Notify(oMaster:GetPid(),string.format("%d is not your friend",iTarget))
        return
    end
    local oFriendMgr  = global.oFriendMgr
    oFriendMgr:AddFriendDegree(oMaster:GetPid(),iTarget,iAdd)
    oNotifyMgr:Notify(oMaster:GetPid(),"addfrienddegree success!!")
end

--检查公告
function Commands.gonggao(oMaster)
    router.Request("cs", ".serversetter", "common", "GetNoticeList", mData, function (r, d)
        local data = d.data or {}
        local mNotice = {}
        for _,info in pairs(data) do
            local year,month,day,hour,min,sec = string.match(info["createTime"],"(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
            year,month,day,hour,min,sec = tonumber(year),tonumber(month),tonumber(day),tonumber(hour),tonumber(min),tonumber(sec)
            local iTime = os.time({year = year,month = month,day = day,hour=hour,min=min,sec=sec})
            if info["state"] ~= 0 then
                table.insert(mNotice,{title=info["title"],content=info["content"],hot=info["hot"]})
            end
        end
        oMaster:Send("GS2CTestNotice", {notices = mNotice})
    end)
end

Opens.setshowid = true
Helpers.setshowid = {
    "靓号设置指令",
    "setshowid showid, pid",
    "setshowid 5201314, 12041",
}
function Commands.setshowid(oMaster, iShowId, iPid)
    iPid = iPid or oMaster:GetPid()
    local oShowIdMgr = global.oShowIdMgr
    if iShowId == iPid then
        oShowIdMgr:SetShowId(iPid)
    else
        local oNotifyMgr = global.oNotifyMgr
        local mData = {pid = iPid, show_id = iShowId}

        router.Request("cs", ".idsupply", "common", "CheckShowId", mData, function (mRecord, mData)
            local iRet = mData.ret
            if iRet == 1 then
                oNotifyMgr:Notify(oMaster:GetPid(), iShowId .. " 不是靓号")
            elseif iRet == 2 then
                oNotifyMgr:Notify(oMaster:GetPid(), "新旧ID一致")
            elseif iRet == 3 then
                oNotifyMgr:Notify(oMaster:GetPid(), "旧靓号ID未过期")
            elseif iRet == 4 then
                oNotifyMgr:Notify(oMaster:GetPid(), iShowId .. " 被占用")
            else
                oShowIdMgr:SetShowId(iPid, iShowId)
            end
        end)
    end
end

Opens.getshowid = true
Helpers.getshowid = {
    "靓号设置指令",
    "getshowid",
    "getshowid",
}
function Commands.getshowid(oMaster)
    local iShowId = oMaster:GetShowId()
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oMaster:GetPid(), "当前靓号为"..iShowId)
end


function Commands.AddEnergy(oMaster,iValue)
    if iValue > 0 then
        oMaster.m_oActiveCtrl:RewardEnergy(iValue,"gm")
    else
        oMaster.m_oActiveCtrl:ResumeEnergy(-iValue,"gm")
    end
end

function Commands.PrintOldGuidance(oMaster)
    oMaster.m_oActiveCtrl:PrintOldGuidance()
end

function Commands.printpid(oMaster)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oMaster:GetPid(), "玩家id:"..oMaster:GetPid())
end

function Commands.printpower(oMaster, iMode)
    oMaster.m_cPower:Print(iMode)
end