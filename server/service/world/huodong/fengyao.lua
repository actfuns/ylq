--import module
local global  = require "global"
local extend = require "base.extend"
local res = require "base.res"
local extend = require "base.extend"

local huodongbase = import(service_path("huodong.huodongbase"))


function NewHuodong(sHuodongName)
	return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "封妖"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    return o
end

function CHuodong:Init()
	self.m_iScheduleID = 1003
	self:RefeshMonsterSchedule()
end

function CHuodong:RefeshMonsterSchedule()
    local f2
    f2 = function ()
        self:DelTimeCb("RefeshMonster")
        self:AddTimeCb("RefeshMonster", 5*60*1000, f2)
        self:RefeshMonster()
    end
    self:DelTimeCb("RefeshMonster")
    self:AddTimeCb("RefeshMonster", 3*1000, f2)
end

function CHuodong:CheckAnswer(oPlayer, npcobj, iAnswer)
    if iAnswer ~= 1 then
        return false
    end
    if npcobj:InWar() then
        local sText = self:GetTextData(1003)
        self:SayText(oPlayer:GetPid(),npcobj,sText)
        return false
    end
    if oPlayer.m_oActiveCtrl:GetNowWar() then
        return false
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        if oPlayer:GetGrade() < 30 then
            local sText = self:GetTextData(1002)
            sText  = string.gsub(sText,"$name",{["$name"] = oPlayer:GetName()})
            self:SayText(oPlayer:GetPid(),npcobj,sText)
            return false
        end
    else
        local oWorldMgr = global.oWorldMgr
        local lName = {}
        for _,pid in ipairs(oTeam:GetTeamMember()) do
            local pobj = oWorldMgr:GetOnlinePlayerByPid(pid)
            if pobj and pobj:GetGrade() < 30 then
                table.insert(lName, pobj:GetName())
            end
        end
        if next(lName) then
            local sText = self:GetTextData(1002)
            sText = string.gsub(sText,"$name", table.concat(lName, "、"))
            for _,pid in ipairs(oTeam:GetTeamMember()) do
                self:SayText(pid,npcobj,sText)
            end
            return false
        end
    end
    return true
end

function CHuodong:RefeshMonster()
    local lMapId = {201000,203000}
    local lNpcIdx = {1001,1002,1003,1004}
    local oSceneMgr = global.oSceneMgr
    for _, iMapId  in ipairs(lMapId) do
        local mScene = oSceneMgr:GetSceneListByMap(iMapId)
        for _, oScene in ipairs(mScene) do
            local iScene = oScene:GetSceneId()
            local lNpcList = self:GetNpcListByScene(iScene)
            local num = math.max(0, 15 - #lNpcList)
            for i=1,num do
                local x, y = oSceneMgr:RandomPos(iMapId)
                local mPosInfo = {
                    x = x or 0,
                    y = y or 0,
                    z = 0,
                    face_x = 0,
                    face_y = 0,
                    face_z = 0,
                }
                local idx = extend.Random.random_choice(lNpcIdx)
                local oNpc = self:CreateTempNpc(idx)
                self:Npc_Enter_Scene(oNpc, iScene, mPosInfo)
            end
        end
    end
end

function CHuodong:OnWarWin(oWar, pid, npcobj, mArgs)
    super(CHuodong).OnWarWin(self,oWar,pid,npcobj,mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    local lPlayers = self:GetFightList(oPlayer, mArgs)
    for _,pid in ipairs(lPlayers) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            self:AddSchedule(oPlayer)
        end
    end
end