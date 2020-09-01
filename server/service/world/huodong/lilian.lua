-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName
)end

local REWARD_TIMES = 20

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "历练"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iHour == 0 then
    	self:RewardTimes(iHour)
    end
end

function CHuodong:RewardTimes(iHour)
    local oWorldMgr = global.oWorldMgr
    local mOnlinePlayer = oWorldMgr:GetOnlinePlayerList()
    for iPid,oPlayer in pairs(mOnlinePlayer) do
        oPlayer.m_oTaskCtrl:AddLilianTimes(REWARD_TIMES,string.format("%s点奖励任务次数",iHour))
    end
end

function CHuodong:GetLilianFgihtData()
    local res = require "base.res"
    local mData = res["daobiao"]["task"]["lilian"]["fight"] or {}
    return mData
end

function CHuodong:RefreshMonster(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local iAveGrade = oTeam:GetTeamAveGrade()
    local iMonsterGrade = (math.floor(iAveGrade/5) * 5) -10
    if iMonsterGrade == 0 then
        iMonsterGrade = 25
    end
    local mFightData = self:GetLilianFgihtData()
    assert(mFightData[iMonsterGrade],string.format("RefreshMonster failed,MonsterGrade:%d",iMonsterGrade))
    local mGrade2Fight = mFightData[iMonsterGrade]["fightid"]
    assert(mGrade2Fight,string.format("RefreshMonster failed,MonsterGrade:%d",iMonsterGrade))
    local iFight = mGrade2Fight[math.random(#mGrade2Fight)]
    local iGroupId = tonumber(res["daobiao"]["global"]["lilian_scene_group"]["value"])
    local iMapId = self:RamdomSceneId(iGroupId)
    local oTask = oPlayer.m_oTaskCtrl:GetLilianTask()
    oTask:RefreshMonster(iMapId,iFight,iMonsterGrade)
end

function CHuodong:RamdomSceneId(iGroupId)
    local res = require "base.res"
    local mMapList = {}
    if res["daobiao"]["scenegroup"][iGroupId] then
        mMapList = res["daobiao"]["scenegroup"][iGroupId]
    else
        return 101000
    end
    mMapList = mMapList["maplist"]
    return mMapList[math.random(#mMapList)]
end