--import module

local global = require "global"
local skynet = require "skynet"

local loadskill = import(service_path("skill/loadskill"))

function C2GSLearnSkill(oPlayer, mData)
    local sType = mData["type"]
    local iSkill = mData["sk"]
    local oPubMgr = global.oPubMgr
    local oLearnSkill = oPubMgr:GetLearnSkillObj(sType)
    if oLearnSkill then
        oLearnSkill:Learn(oPlayer,iSkill)
    end
end

function C2GSFastLearnSkill(oPlayer,mData)
    local sType = mData["type"]
    local oPubMgr = global.oPubMgr
    local oLearnSkill = oPubMgr:GetLearnSkillObj(sType)
    if oLearnSkill then
        oLearnSkill:FastLearn(oPlayer)
    end
end

function C2GSLearnCultivateSkill(oPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPubMgr = global.oPubMgr

    if oWorldMgr:IsClose("cultivate_skill") then
        oNotifyMgr:Notify(oPlayer:GetPid(), "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return 
    end

    local iSk = mData["sk"]
    local iCount = mData["count"]
    if iCount <= 0 or iCount > 10 then
        return
    end

    local oLearnSkill = oPubMgr:GetLearnSkillObj("cultivate")
    if oLearnSkill then
        oLearnSkill:Learn(oPlayer, iSk, iCount)
    end
end

function C2GSWashSchoolSkill(oPlayer,mData)
    local iCostType = mData["cost_type"]
    if not oPlayer:ValidResetSkillPoint(iCostType) then
        return
    end
    oPlayer:ResetSkillPoint(iCostType)
end
