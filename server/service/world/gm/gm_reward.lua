--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base/extend"
local net = require "base.net"
local record = require "public.record"
local httpuse = require "public.httpuse"

local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item/loaditem"))
local itemnet = import(service_path("netcmd/item"))
local loadtask = import(service_path("task/loadtask"))
local loadpartner = import(service_path("partner/loadpartner"))
local itemdefines = import(service_path("item/itemdefines"))


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

Helpers.rewardorgcash = {
    "奖励公会资金",
    "rewardorgcash 公会id 数量",
    "rewardorgcash 公会id 200",
}
function Commands.rewardorgcash(oMaster,iOrgID,iVal)
    interactive.Send(".org", "common", "RewardOrgCash", {
        orgid = oMaster:GetOrgID(),
        value = iVal,
        reason = "gm",
    })
end

Helpers.rewardorgexp = {
    "奖励公会经验",
    "rewardorgexp 公会id 数量",
    "rewardorgexp 公会id 200",
}
function Commands.rewardorgexp(oMaster,iOrgID,iVal)
    interactive.Send(".org", "common", "RewardOrgExp", {
        pid = oMaster:GetPid(),
        orgid = iOrgID,
        value = iVal,
        reason = "gm",
    })
end

Helpers.addorgdegree = {
    "增加公会签到进度",
    "addorgdegree 公会id 进度数目",
    "addorgdegree 公会id 200",
}
function Commands.addorgdegree(oMaster,iOrgID,iVal)
    interactive.Send(".org", "common", "AddOrgDegree", {
        pid = oMaster:GetPid(),
        orgid = iOrgID,
        value = iVal,
        reason = "gm",
    })
end

Helpers.rewardtrapmine = {
    "奖励探索点",
    "rewardtrapmine 数量",
    "rewardtrapmine 200",
}
function Commands.rewardtrapmine(oMaster,iVal)
    iVal = iVal or 1
    if iVal > 0 then
        oMaster:RewardTrapminePoint(iVal,"gm")
    else
        local iPoint = oMaster.m_oActiveCtrl:GetData("trapmine_point", 0)
        oMaster.m_oActiveCtrl:SetData("trapmine_point", math.max(0, iPoint + iVal))
        oMaster:PropChange("trapmine_point")
    end
    local iPoint = oMaster.m_oActiveCtrl:GetData("trapmine_point", 0)
    global.oNotifyMgr:Notify(oMaster:GetPid(), string.format("探索点:%s", iPoint))
end

function Commands.givereward(oMaster,sHuodong,iReward, iCnt)
    local oHuodongMgr = global.oHuodongMgr
    local oNotifyMgr = global.oNotifyMgr
    local oHuodong = oHuodongMgr:GetHuodong(sHuodong)
    if not oHuodong then
        oNotifyMgr:Notify(oMaster:GetPid(),string.format("没这个活动:%s",sHuodong))
        return
    end
    iCnt = iCnt or 1
    for i=1,iCnt do
        local err = safe_call(oHuodong.Reward,oHuodong,oMaster:GetPid(),iReward)
        if not err then
            oNotifyMgr:Notify(oMaster:GetPid(),string.format("给予奖励报错:%d",iReward))
            return
        else
        end
    end
    oNotifyMgr:Notify(oMaster:GetPid(),string.format("给予奖励:%s,%d,%d",sHuodong,iReward, iCnt))
end


--------------------------------------------开放指令-----------------------------------
Helpers.rewardcoin = {
    "奖励金币",
    "rewardcoin 玩家id 数量",
    "rewardcoin 玩家id 200",
}
Opens["rewardcoin"] = true
function Commands.rewardcoin(oMaster,iTarget,iVal)
    if not iTarget then
        return
    end
    if not iVal then
        return
    end
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsOnline(iTarget) then
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        if oPlayer then
            oPlayer:RewardCoin(iVal,"gm")
        end
    else
        local oPubMgr = global.oPubMgr
        oPubMgr:OnlineExecute(iTarget,"RewardCoin",{iVal,"gm"})
    end
end

Helpers.rewardorgoffer = {
    "奖励帮贡",
    "rewardorgoffer 玩家id 数量",
    "rewardorgoffer 玩家id 200",
}
Opens["rewardorgoffer"] = true
function Commands.rewardorgoffer(oMaster,iTarget,iVal)
    if not iTarget then
        return
    end
    if not iVal then
        return
    end
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsOnline(iTarget) then
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        if oPlayer then
            oPlayer:RewardOrgOffer(iVal,"gm")
        end
    else
        local oPubMgr = global.oPubMgr
        oPubMgr:OnlineExecute(iTarget,"RewardOrgOffer",{iVal,"gm"})
    end
end

Helpers.addgoldcoin={
    "增加水晶",
    "addgoldcoin 玩家id 数目",
    "addgoldcoin 玩家id 1000"
}
Opens["addgoldcoin"] = true
function Commands.addgoldcoin(oMaster,iTarget,iVal)
    if not iTarget then
        return
    end
    if not iVal then
        return
    end
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iTarget,function (oProfile)
        if not oProfile then
            return
        end
        oProfile:AddGoldCoin(iVal,"gm")
    end)
end

Helpers.rewardexp = {
    "奖励经验",
    "rewardexp 经验数量",
    "rewardexp 200",
}
Opens["rewardexp"] = true
function Commands.rewardexp(oMaster,iTarget,iVal)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if iTarget == 0 then
        iTarget = oMaster:GetPid()
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        oNotifyMgr:Notify(oMaster:GetPid(),"该玩家不在线，不能增加经验")
        return
    end
    oTarget:RewardExp(iVal,"gm",{bEffect = false})
    oNotifyMgr:Notify(oMaster:GetPid(),"指令执行成功")
end

Helpers.rewardmedal = {
    "奖励金币",
    "rewardmedal 数量",
    "rewardmedal 200",
}
Opens["rewardmedal"] = true
function Commands.rewardmedal(oMaster,iTarget,iVal)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if iTarget == 0 then
        iTarget = oMaster:GetPid()
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        oNotifyMgr:Notify(oMaster:GetPid(),"该玩家不在线，不能增加经验")
        return
    end
    oTarget:RewardMedal(iVal,"gm")
    oNotifyMgr:Notify(oMaster:GetPid(),"指令执行成功")
end

Helpers.arenamedal = {
    "增加比武荣誉",
    "arenamedal num",
    "arenamedal 999",
}
Opens["arenamedal"] = true
function Commands.arenamedal(oMaster,iTarget,ipoint)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if iTarget == 0 then
        iTarget = oMaster:GetPid()
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        oNotifyMgr:Notify(oMaster:GetPid(),"该玩家不在线，不能增加经验")
        return
    end
    oTarget:RewardArenaMedal(ipoint,"gm指令")
    oTarget.m_oThisWeek:Add("arenamedal",ipoint)
    oNotifyMgr:Notify(oMaster:GetPid(),"指令执行成功")
end

Helpers.addskin = {
    "增加皮肤卷",
    "addskin 皮肤卷",
    "addskin 9999",
}
Opens["addskin"] = true
function Commands.addskin(oMaster,iTarget,iPoint)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if iTarget == 0 then
        iTarget = oMaster:GetPid()
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        oNotifyMgr:Notify(oMaster:GetPid(),"该玩家不在线，不能增加经验")
        return
    end
    oTarget:RewardSkin(iPoint,"gm")
    oNotifyMgr:Notify(oMaster:GetPid(),"指令执行成功")
end

Helpers.addtravelscore = {
    "增加皮肤卷",
    "addtravelscore 积分",
    "addtravelscore 9999",
}
Opens["addtravelscore"] = true
function Commands.addtravelscore(oMaster,iTarget, iScore)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr

    if iTarget == 0 then
        iTarget = oMaster:GetPid()
    end
    local iPid = oMaster:GetPid()
    if type(iScore) ~= "number" then
        oNotifyMgr:Notify(iPid, "参数错误")
        return
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        oNotifyMgr:Notify(iTarget, "玩家不在线")
        return
    end
    oTarget:AddTravelScore(iScore, "gm")
end


Helpers.addcolorcoin = {
    "增加彩晶",
    "addcolorcoin pid 数目",
    "addcolorcoin pid 9999",
}
Opens["addcolorcoin"] = true
function Commands.addcolorcoin(oMaster,iTarget, iVal)
    if not iTarget then
        return
    end
    if not iVal or type(iVal) ~= "number" or iVal <= 0 then
        global.oNotifyMgr:Notify(oMaster:GetPid(), "参数错误")
        return
    end
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsOnline(iTarget) then
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        if oPlayer then
            oPlayer:RewardColorCoin(iVal,"gm")
        end
    else
        oWorldMgr:LoadProfile(iTarget, function(oProfile)
            oProfile:RewardColorCoin(iColorCoin,sReason)
        end)
    end
end

Helpers.addshape = {
    "增加彩晶",
    "addshape pid 皮肤id",
    "addshape pid 116",
}
Opens["addshape"] = true
function Commands.addshape(oMaster, iTarget, iShape)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oPlayer then
        local shapes = oPlayer.m_oActiveCtrl:GetData("shape_list", {})
        if table_in_list(shapes, iShape) then
            oNotifyMgr:Notify(oMaster:GetPid(), "皮肤已存在")
            return
        end
        local res = require "base.res"
        local mShape = res["daobiao"]["roleskin"][iShape]
        if not mShape then
            oNotifyMgr:Notify(oMaster:GetPid(), "皮肤id不存在")
            return
        end
        if oMaster:GetSchool() ~= mShape.school then
            oNotifyMgr:Notify(oMaster:GetPid(), "不可添加其他职业皮肤")
            return
        end
        if oMaster:GetSex() ~= mShape.sex then
            oNotifyMgr:Notify(oMaster:GetPid(), "不可添加其他性别皮肤")
            return
        end
        oPlayer:AddShape(iShape, "gm")
    else
        oNotifyMgr:Notify(oMaster:GetPid(),"需要填写玩家id")
    end
end

Helpers.addhischarge = {
    "增加历史充值",
    "addhischarge pid val",
    "addhischarge pid 100",
}
Opens["addhischarge"] = true
function Commands.addhischarge(oMaster, iTarget, iVal)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oPlayer then
        oPlayer:AddHistoryCharge(iVal)
        oPlayer:AfterChargeGold(iVal,"gm指令")
    else
        oNotifyMgr:Notify(oMaster:GetPid(),"玩家不在线")
    end
end

Helpers.yybaogift = {
    "发放应用宝礼包",
    "yybaogift gid",
    "yybaogift 10001",
}

function Commands.yybaogift(oMaster, iGid)
    local oBackendMgr = global.oBackendMgr
    oBackendMgr:RewardYYBaoGift(oMaster:GetPid(), iGid)
end