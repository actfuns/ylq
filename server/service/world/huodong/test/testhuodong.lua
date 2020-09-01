--import module
local global  = require "global"
local extend = require "base.extend"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
	return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_iScheduleID = 1001
    return o
end

function CHuodong:IsOpenDay(iTime)
    return "10:00"
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iWeekDay == 2 and iHour == 21 then
        local oHuodongMgr = global.oHuodongMgr
        oHuodongMgr:SetHuodongState(self.m_sName, self.m_iScheduleID, 2, "10:00")
    end
end

function CHuodong:GetTollGateData(iFight)
    local res = require "base.res"
    local mData = res["daobiao"]["tollgate"]["test"][iFight]
    return mData
end

function CHuodong:GetMonsterData(iMonsterIdx)
    local res = require "base.res"
    local mData = res["daobiao"]["monster"]["test"][iMonsterIdx]
    assert(mData,string.format("CTempl GetMonsterData err: %s %d", self.m_sName, iMonsterIdx))
    return mData
end

function CHuodong:GetGlobalData(idx)
    local res = require "base.res"
    return res["daobiao"]["global"][idx]
end

function CHuodong:GetRewardData(iReward)
    local res = require "base.res"
    local mData = res["daobiao"]["reward"][self.m_sName]["reward"][iReward]
    assert(mData,string.format("CTempl:GetRewardData err:%s %d", self.m_sName, iReward))
    return mData
end

function CHuodong:GetItemRewardData(iItemReward)
    local res = require "base.res"
    local mData = res["daobiao"]["reward"][self.m_sName]["itemreward"][iItemReward]
    assert(mData,string.format("CTempl:GetItemRewardData err:%s %d", self.m_sName, iItemReward))
    return mData
end

function CHuodong:GetEventData(iEvent)
    return {}
end

function CHuodong:GetCreateWarArg(mArg)
    local mArg2 = table_copy(mArg)
    mArg2.remote_war_type = "serialwar"
    return mArg2
end

--发送给战斗服务的数据
function CHuodong:GetRemoteWarArg()
    return {
        war_record = 1,
    }
end

--战斗信息配置
function CHuodong:ConfigWar(oWar,pid,npcobj,iFight)
    oWar:SetData("current_fight",iFight)
end

function CHuodong:SerialWarCallback(oWar,iPid,oNpc,mArgs)
    local iFight = oWar:GetData("current_fight")
    if not iFight then
        return
    end
    local iNextFight = iFight + 1
    oWar:SetData("current_fight",iNextFight)
    local mData = self:GetTollGateData(iNextFight)

    local mMonsterData = mData["monster"] or {}
    local mEnemy = {}
    for _,mData in pairs(mMonsterData) do
        local iMonsterIdx = mData["monsterid"]
        local iCnt = mData["count"]
        for i=1,iCnt do
            local oMonster = self:CreateMonster(oWar,iMonsterIdx,npcobj)
            table.insert(mEnemy, oMonster:PackAttr())
        end
    end
    local mMonster = {
        [2] = mEnemy,
    }
    oWar:RemoteSerialWar(mMonster)
end

