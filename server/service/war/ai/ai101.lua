--import module
--NPCAI
local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"

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
    local mPerformList = oAction:GetPerformList()

    local iPerform = oAction.m_TempPerform
    if not oAction:GetPerform(iPerform) then
        local mPerform,iSpecialSkill = self:GetAblePerfromList(oAction)
        if #mPerform == 0 then
            return
        end
        if iSpecialSkill then
            iPerform = iSpecialSkill
        else
            iPerform = mPerform[math.random(#mPerform)]
        end
    end
    local oPerform = self:ChooseAIPerform(oAction,iPerform)
    iPerform = oPerform.m_ID
    --选目标
    local mTarget = oPerform:TargetList(oAction)
    local iWid = self:ChooseAITarget(oAction,oPerform)

    local mCmd = {
        cmd = "skill",
        data = {
            action_wlist = {oAction:GetWid()},
            select_wlist = {iWid},
            skill_id = iPerform,
        }
    }
    oWar:SetBoutCmd(oAction.m_iWid,mCmd)
    oAction.m_TempPerform = nil
end