--import module
--romAI
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

    local mPerformList = self:GetAblePerfromList(oAction)

    local oPerform = self:ChoosePerfrom(oAction,mPerformList)
    local iTarget = self:ChooseAITarget(oAction,oPerform)
    local mCmd = {
        cmd = "skill",
        data = {
            action_wlist = {oAction:GetWid()},
            select_wlist = {iTarget},
            skill_id = oPerform.m_ID,
        }
    }
    oWar:SetBoutCmd(oAction:GetWid(),mCmd)
end

function CAI:ValidPerform(oAction,oPerform)
    return oPerform:AiCanPerform(oAction)
end


