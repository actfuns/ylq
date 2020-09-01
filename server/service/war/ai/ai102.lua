--import module
-- AUTO Player AI
local global = require "global"
local skynet = require "skynet"

local aibase = import(service_path("ai/aibase"))

function NewAI(...)
    local o = CAI:New(...)
    return o
end

CAI = {}
CAI.__index = CAI
inherit(CAI, aibase.CAI)

function CAI:New(iAI)
    local o = super(CAI).New(self,iAI)
    return o
end

function CAI:Command(oAction)
    local oWar = oAction:GetWar()
    if not oWar then
        return
    end

    local iWid = oAction:GetWid()
    local iCamp = oAction:GetCampId()
    local iAutoSkill = oAction:ChooseSkillAuto()
    if iAutoSkill ~= oAction:GetData("auto_skill",0) then
        oAction:SetAutoSkill(iAutoSkill,true)
    end

    local oPerform = oAction:GetPerform(iAutoSkill)
    if not oPerform then
        iAutoSkill = oAction:GetNormalAttackSkillId()
        oPerform = oAction:GetPerform(iAutoSkill)
        oAction:SetAutoSkill(iAutoSkill,true)
        oAction:Set("action_skill",nil)
    end
    if not oPerform:AiCanPerform(oAction) then
        iAutoSkill = oAction:GetNormalAttackSkillId()
        oPerform = oAction:GetPerform(iAutoSkill)
    end
    local oNewPerform = oAction:OnAIChoosePerform(oPerform)
    if oNewPerform then
        oPerform = oNewPerform
        iAutoSkill = oPerform.m_ID
    end
    local iTarget = self:ChooseAITarget(oAction,oPerform)
    if oPerform:TargetType() == 2 then
        local mWarTarget = oWar:GetExtData("war_target",{})
        local iExtTargetWid = mWarTarget[iCamp]
        if iExtTargetWid then
            local oWarrior = oWar:GetWarrior(iExtTargetWid)
            if oWarrior and oWarrior:IsAlive() and oWarrior:GetHp() > 0 then
                iTarget = iExtTargetWid
            end
        end
    end
    local mCmd = {
        cmd = "skill",
        data = {
            action_wlist = {oAction:GetWid()},
            select_wlist = {iTarget},
            skill_id = iAutoSkill,
        }
    }
    oWar:AddBoutCmd(iWid,mCmd)
end

function CAI:NowCommand(oAction)
    local oWar = oAction:GetWar()
    if not oWar then
        return
    end
    
    local iWid = oAction:GetWid()
    local iCamp = oAction:GetCampId()
    local iAutoSkill = oAction:ChooseSkillAuto()
    local oPerform = oAction:GetPerform(iAutoSkill)
    if not oPerform then
        local iAutoSkill = oAction:GetNormalAttackSkillId()
        oPerform = oAction:GetPerform(iAutoSkill)
    end
    if not oPerform then
        return
    end
    local iTarget = self:ChooseAITarget(oAction,oPerform)
    if oPerform:TargetType() == 2 then
        local mWarTarget = oWar:GetExtData("war_target",{})
        local iExtTargetWid = mWarTarget[iCamp]
        if iExtTargetWid then
            iTarget = iExtTargetWid
        end
    end
    local mCmd = {
        cmd = "skill",
        data = {
            action_wlist = {oAction:GetWid()},
            select_wlist = {iTarget},
            skill_id = iAutoSkill,
        }
    }
    oWar:AddBoutCmd(iWid,mCmd)
end