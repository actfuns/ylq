--import module
local global = require "global"
local interactive = require "base.interactive"
local playersend = require "base.playersend"

local gamedefines = import(lualib_path("public.gamedefines"))
local basewar = import(service_path("warobj"))
local basewarrior = import(service_path("npcwarrior"))
local playerwarrior = import(service_path("playerwarrior"))


CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)

function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "chapterfb"
    return o
end



function CWar:Init(mInit,mExtra)
    self.m_FirstWar = mInit["FirstGuide"]
    self.m_SetPartnerAutoCmd = mInit["SetAutoCmd"]
    super(CWar).Init(self,mInit,mExtra)
end

function CWar:ExtendWarEndArg(mArg)
    mArg.m_HasDead = 0
    local mWinWarrior = self:GetWarriorList(1)
    for _,oAction in pairs(mWinWarrior) do
        if oAction:IsDead() then
            mArg.m_HasDead = mArg.m_HasDead + 1
        end
    end
    return mArg
end

function CWar:ReEnterPlayer(iPid)
    local oWarrior = self:GetPlayerWarrior(iPid)
    assert(oWarrior, string.format("ReEnterPlayer error %d", iPid))
    oWarrior:ReEnter()
    if self.m_iWarStatus == gamedefines.WAR_STATUS.START then
        playersend.Send(iPid,"GS2CWarChapterInfo",{start_time = self.m_iStarTime})
    end
end

function CWar:WarStart(mInfo)
    super(CWar).WarStart(self,mInfo)
    self:SendAll("GS2CWarChapterInfo",{start_time = self.m_iStarTime})
end

function CWar:BeforeWarStar(mInfo)
    super(CWar).BeforeWarStar(self,mInfo)
    if self.m_SetPartnerAutoCmd then
        local warriorlist = self:GetWarriorList(1)
        for _,oAction in ipairs(warriorlist) do
            if oAction:IsPartner() then
                local iAutoSkill
                local mPerformList = oAction:GetPerformList()
                for _,iSkill in pairs(mPerformList) do
                    local pfobj = oAction:GetPerform(iSkill)
                    if pfobj:IsSp() then
                        iAutoSkill = pfobj:Type()
                    end
                end
                if iAutoSkill then
                    oAction:SetAutoSkill(iAutoSkill,true)
                    oAction:Set("action_skill",iAutoSkill)
                end
            end
        end
    end
end

function CWar:NewPlayerWarrior(iWid,iPid)
    return NewPlayerWarrior(iWid,iPid)
end


CPlayerWarrior = {}
CPlayerWarrior.__index = CPlayerWarrior
inherit(CPlayerWarrior, playerwarrior.CPlayerWarrior)

function NewPlayerWarrior(...)
    return CPlayerWarrior:New(...)
end


function CPlayerWarrior:GetAutoFightTime()
    local oWar = self:GetWar()
    if self:IsOpenAutoFight() then
        if oWar.m_iBout == 1 and not self:QueryBoutArgs("fight_b1") then
            self:SetBoutArgs("fight_b1",1)
            return 4
        end
        return 0
    end
    if oWar:IsSinglePlayer() then
        return 15
    else
        return 10
    end
end

