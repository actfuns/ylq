local global = require "global"
local interactive = require "base.interactive"

function CloseGS(mRecord, mData)
    global.oAssistMgr:CloseGS()
end

function LoadRoleAssist(mRecord,mData)
    local iPid = mData.pid
    global.oAssistMgr:LoadRoleAssist(mRecord,iPid,mData)
end

function OnLogin(mRecord, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = mData.pid
    local bReEnter = mData.reenter
    oAssistMgr:OnLogin(iPid,bReEnter,mData)
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local mRet = {}
    if oPlayer then
        mRet.equip = { 
            equip_se = oPlayer.m_oItemCtrl:GetWieldEquipSkill(),
        }
    end
    interactive.Response(mRecord.source,mRecord.session,mRet)
end

function OnLogout(mRecord, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = mData.pid
    oAssistMgr:Logout(iPid)
end