-- import module
local global = require "global"
local skyner = require "skynet"
local record = require "public.record"
local interactive = require "base.interactive"
local colorstring = require "public.colorstring"

function WashSchoolSkill(mRecord, mData)
    local iPid = mData.pid
    local iShape = mData.shape
    local iAmount = mData.amount
    local sReason = mData.reason
    local mArgs = mData.args
    local oAssistMgr = global.oAssistMgr
    local mRemoteArgs = {}
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSuc = true
    if oPlayer then
        if iShape > 0 then
            bSuc = oPlayer:RemoveItemAmount(iShape,iAmount,sReason,{})
        end
        if bSuc then
            oPlayer:WashSchoolSkill(sReason,mArgs)
        end
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function LearnSchoolSkill(mRecord,mData)
    local oAssistMgr = global.oAssistMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = mData.pid
    local iSkill = mData.skill
    local iNewLevel = mData.level
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local sReason = "学习门派主动技能"
    local bSuc = false
    if oPlayer then
        bSuc = true
        local oSk = oPlayer.m_oSkillCtrl:GetSkill(iSkill)
        local iLevel = oSk:Level()
        oPlayer.m_oSkillCtrl:SetLevel(iSkill,iNewLevel)
        oPlayer.m_oSkillCtrl:LogSkill("role_skill",iSkill, iLevel, oSk:Level(), sReason)
        oPlayer:SkillShareUpdate()
        oNotifyMgr:Notify(iPid, string.format("%s的等级提升为%d级",oSk:Name(),oSk:Level()))
        local sKey = string.format("主角技能%s级次数", iNewLevel)
        global.oAssistMgr:PushAchieve(iPid, sKey, {value = 1})
    end

    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc
    })
end