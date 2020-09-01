--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base/extend"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))


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

Helpers.testwar = {
    "测试多人PVP",
    "testwar {玩家ID1,玩家ID2,...}",
    "testwar {999, 234,}",
}
function Commands.testwar(oMaster, lTargets)
    local oWarMgr = global.oWarMgr
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local mArgs = {
        war_type = gamedefines.WAR_TYPE.PVP_TYPE,
    }
    local oWar = oWarMgr:CreateWar(mArgs)

    if #lTargets <= 0 then
        return
    end

    local lRes = {}
    for _, v in ipairs(lTargets) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(v)
        if oPlayer then
            local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
            if not oNowWar then
                table.insert(lRes, oPlayer)
            end
        end
    end
    if #lRes <= 0 then
        oNotifyMgr:Notify(oMaster:GetPid(),"目标正在战斗中")
        return
    end
    local iMiddle = math.floor(#lRes/2 + 1)

    oWarMgr:EnterWar(oMaster, oWar:GetWarId(), {camp_id = 1}, true)
    for i = 1, iMiddle do
        local o = lRes[i]
        oWarMgr:EnterWar(o, oWar:GetWarId(), {camp_id = 2}, true)
    end
    for i = iMiddle + 1, #lRes do
        local o = lRes[i]
        oWarMgr:EnterWar(o, oWar:GetWarId(), {camp_id = 1}, true)
    end

    oWarMgr:StartWarConfig(oWar:GetWarId())
end

function Commands.pk(oMaster,iTarget)
    local oNotifyMgr = global.oNotifyMgr
    local oWarMgr = global.oWarMgr
    local oWorldMgr = global.oWorldMgr
    local iPid = oMaster.m_iPid
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not iTarget then
        oNotifyMgr:Notify(iPid,"请输入目标")
        return
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then
        oNotifyMgr:Notify(iPid,"请输入目标")
        return
    end
    local mOwnPartner = oPlayer.m_oPartnerCtrl:GetFightPartner()
    local mTargetPartner = oTarget.m_oPartnerCtrl:GetFightPartner()
    local mArgs = {
        war_type = gamedefines.WAR_TYPE.PVP_TYPE,
    }
    local oWar = oWarMgr:CreateWar(mArgs)

    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    assert(not oNowWar,string.format("CreateWar err %d",iPid))
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    assert(not oNowWar,string.format("CreateWar err %d",iPid))
    local ret
    if oPlayer:HasTeam() then
        if oPlayer:IsTeamLeader() then
            ret = oWarMgr:TeamEnterWar(oPlayer,oWar:GetWarId(),{camp_id=1},true)
        else
            ret = oWarMgr:EnterWar(oPlayer, oWar:GetWarId(), {camp_id = 1}, true)
        end
    else
        ret = oWarMgr:EnterWar(oPlayer, oWar:GetWarId(), {camp_id = 1}, true)
    end
    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end
    if oTarget:HasTeam() then
        if oTarget:IsTeamLeader() then
            ret = oWarMgr:TeamEnterWar(oTarget,oWar:GetWarId(),{camp_id=2},true)
        else
            ret = oWarMgr:EnterWar(oTarget, oWar:GetWarId(), {camp_id = 2}, true)
        end
    else
        ret = oWarMgr:EnterWar(oTarget, oWar:GetWarId(), {camp_id = 2}, true)
    end
    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end
    oWarMgr:StartWar(oWar:GetWarId())
end

Helpers.setwarattr = {
    "设置战斗属性",
    "setwarattr attr val",
    "setwarattr max_hp 100000",
}
function Commands.setwarattr(oMaster, attr, val)
    if not oMaster.m_mTestWarAttr then
        oMaster.m_mTestWarAttr = {}
    end
    oMaster.m_mTestWarAttr[attr] = val
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        oWar:TestCmd("setwarattr", oMaster:GetPid(), {attr=attr, val=val})
    end
end

Helpers.openwardebug = {
    "开启战斗debug",
    "openwardebug",
    "openwardebug",
}
function Commands.openwardebug(oMaster)
    Commands.setwarattr(oMaster, "wardebug", true)
end

Helpers.addsp = {
    "战斗增加怒气",
    "addsp 怒气值",
    "addsp 100",
}
function Commands.addsp(oMaster,iSP)
    local oNotifyMgr = global.oNotifyMgr
    local oNowWar = oMaster.m_oActiveCtrl:GetNowWar()
    local mData = {
        sp = iSP
    }
    if oNowWar then
        oNowWar:TestCmd("addsp",oMaster.m_iPid,mData)
    end
end

Helpers.wartimeover = {
    "结束战斗本轮操作阶段",
    "wartimeover",
    "wartimeover",
}
function Commands.wartimeover(oMaster)
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        oWar:TestCmd("wartimeover", oMaster:GetPid(), {})
    end
end

function Commands.warend(oMaster)
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        local mArgs = {
            war_result = 1
        }
        oWar:TestCmd("warend",oMaster:GetPid(),{})
    end
end

function Commands.kuafuwarend(oMaster)
    local oWar = oMaster.m_oActiveCtrl:GetProxyWar()
    if oWar then
        local mArgs = {
            war_result = 1
        }
        oWar:TestCmd("warend",oMaster:GetPid(),{})
    end
end

function Commands.win(oMaster)
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        oWar:TestCmd("win",oMaster:GetPid(),{})
    end
end

function Commands.fail(oMaster)
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        oWar:TestCmd("fail",oMaster:GetPid(),{})
    end
end

function Commands.warfail(oMaster)
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        local mArgs = {
            war_result = 2
        }
        oWar:TestCmd("warend",oMaster:GetPid(),mArgs)
    end
end

function Commands.waraddbuff(oMaster,iWid,iBout)
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        oWar:TestCmd("addbuff",oMaster:GetPid(),{wid = iWid,bout=iBout})
    end
end

function Commands.taskwar(oMaster,fidx)
    local oModule = import(service_path("templ"))
    local oTempl = oModule.CTempl:New()
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        return
    end
    oTempl:CreateWar(oMaster.m_iPid,nil,fidx)
end

function Commands.serialwar(oMaster,iFight)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("test")
    oHuodong:CreateSerialWar(oMaster:GetPid(),nil,iFight)
end

function Commands.setperform(oMaster,pfid,iLevel)
    local oNotifyMgr = global.oNotifyMgr
    local pid = oMaster.m_iPid
    local mTestPerform = oMaster.m_oActiveCtrl:GetInfo("TestPerform",{})
    mTestPerform[pfid] = iLevel
    oMaster.m_oActiveCtrl:SetInfo("TestPerform",mTestPerform)
    oNotifyMgr:Notify(pid,"招式设置成功")
end

function Commands.testrom(oMaster)
    local oHuodongMgr = global.oHuodongMgr
    local iPid = oMaster:GetPid()
    local mRomPlayer = oMaster:PackWarInfo()
    local mRomPartner = {}
    for iPos = 1,4 do
        local oPartner = oMaster.m_oPartnerCtrl:GetPartner(iPos)
        if oPartner then
            table.insert(mRomPartner,oPartner:PackWarInfo())
        end
    end
    local oGlobal = oHuodongMgr:GetHuodong("globaltemple")
    if oGlobal then
        oGlobal:CreateRomWar(iPid,nil,mRomPlayer,mRomPartner,{})
    end
end

function Commands.playerwarskill(oMaster,iSkill,iLv)
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        oWar:TestCmd("playerwarskill",oMaster:GetPid(),{[iSkill]=iLv})
    end
end

function Commands.setwarhp(oMaster,wid,hp)
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        oWar:TestCmd("SetHP",oMaster:GetPid(),{[wid]=hp})
    end
end

function Commands.addbuff(oMaster,iBuff,iBout)
    iBout = iBout or 1
    local oWar = oMaster.m_oActiveCtrl:GetNowWar()
    if oWar then
        oWar:TestCmd("addplayerbuff",oMaster:GetPid(),{buff = iBuff , bout =  iBout})
    end
end


