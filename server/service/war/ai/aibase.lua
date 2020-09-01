--import module

local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))

function NewAI(...)
    local o = CAI:New(...)
    return o
end

CAI = {}
CAI.__index = CAI
inherit(CAI, logic_base_cls())

function CAI:New(id)
    local o = super(CAI).New(self)
    o.m_ID = id
    return o
end

function CAI:Command(oAction)
end

function CAI:GetAblePerfromList(oAction)
    local mPerformList = oAction:GetPerformList()
    local mAbleList = {}
    local iSpecialSkill
    for _,iSkill in pairs(mPerformList) do
        local oPerform = oAction:GetPerform(iSkill)
        if not oPerform:SelfValidCast() then
            goto continue
        end
        if not oPerform:ValidResume(oAction) then
            goto continue
        end
        if not oPerform:CanPerform() then
            goto continue
        end
        if oPerform:InAICD(oAction) then
            goto continue
        end
        if not self:ValidPerform(oAction,oPerform) then
            goto continue
        end
        local mTargetList = oPerform:TargetList(oAction)
        if #mTargetList <= 0 then
            goto continue
        end
        if oAction:IsNpc() and oAction:IsSpecialSkill(iSkill) then
            if oAction:IsSpecialSkillCD() then
                goto continue
            else
                iSpecialSkill = iSkill
            end
        end
        table.insert(mAbleList,iSkill)
        ::continue::
    end
    return mAbleList,iSpecialSkill
end

function CAI:ValidPerform(oAction,oPerform)
    return true
end

function CAI:ChoosePerfrom(oAction,mPerform)
    local iPerform = mPerform[math.random(#mPerform)]
    return self:ChooseAIPerform(oAction,iPerform)
end

function CAI:ChooseAIPerform(oAction,iPerform)
    local oPerform = oAction:GetPerform(iPerform)
    local oNewPerform = oAction:OnAIChoosePerform(oPerform)
    return oNewPerform
end

function CAI:ChooseAITarget(oAction,oPerform)
    local oWar = oAction:GetWar()
    local iWid = oPerform:ChooseAITarget(oAction)
    iWid = oAction:OnChooseAITarget(oPerform,iWid)
    return iWid
end
