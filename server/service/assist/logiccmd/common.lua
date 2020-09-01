local global = require "global"
local interactive = require "base.interactive"

function SendCallBack(mRecord,mData)
    local oCbMgr = global.oCbMgr
    local oAssistMgr = global.oAssistMgr
    local iPid = mData["pid"]
    local iSessionIdx = mData["sessionidx"]
    local iTrueSessionIdx = iSessionIdx // 1000
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oCbMgr:TrueCallback(oPlayer,iTrueSessionIdx,mData)
    end
end

function SwitchSchool(mRecord,mData)
    local iPid = mData.pid
    local iSchoolBranch = mData.school_branch
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer:SwitchSchool(iSchoolBranch)
    end
    local iWeapon
    local oWeapon = oPlayer.m_oItemCtrl:GetEquip(1)
    if oWeapon then
        iWeapon = oWeapon:Model()
    end
    local mRemoteArgs = {
        weapon = iWeapon,
        equip = {equip_se = oPlayer.m_oItemCtrl:GetWieldEquipSkill()},
    }
    interactive.Response(mRecord.source, mRecord.session, {
        success = true,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function GiveSecondEquip(mRecord,mData)
    local iPid = mData.pid
    local iSchoolBranch = mData.school_branch
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oItemCtrl:GiveSecondEquip(oPlayer)
    end
end

function OpenSecondFuwen(mRecord,mData)
    local iPid = mData.pid
    local iSchoolBranch = mData.school_branch
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oItemCtrl:OpenSecondFuwen(oPlayer)
    end
end

function InitShareObj(mRecord,mData)
    local iPid = mData["pid"]
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local mData = {
        item_share = oPlayer.m_oItemCtrl:GetItemShareReaderCopy(),
        equip_share = oPlayer.m_oEquipMgr:GetEquipMgrReaderCopy(),
        stone_share = oPlayer.m_oStoneMgr:GetStoneMgrReaderCopy(),
    }
    interactive.Response(mRecord.source, mRecord.session, mData)
end

function SetPlayerInfo(mRecord,mData)
    local iPid = mData["pid"]
    local key = mData["key"]
    local value = mData["value"]
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer:SetInfo(key,value)
    end
end

function ShowKeepItem(mRecord, mData)
    local oUIMgr = global.oUIMgr
    local iPid = mData.pid
    local lShowInfo = mData.data or {}
    for _, mShow in ipairs(lShowInfo) do
        oUIMgr:AddKeepItem(iPid, mShow)
    end
    oUIMgr:ShowKeepItem(iPid)
end

function SyncPlayerData(mRecord,mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = mData.pid
    local mSyncData = mData.data
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer:SyncPlayerData(mSyncData)
    end
end

function ShowWarEndUI(mRecord, mData)
    local iPid = mData.pid
    local mShow = mData.data or {}

    local oUIMgr = global.oUIMgr
    local lShowInfo = mShow.player_item or {}
    for _, mShow in ipairs(lShowInfo) do
        oUIMgr:AddKeepItem(iPid, mShow)
    end
    mShow.player_item = oUIMgr:PackKeepItem(iPid)

    local  oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer  then
        oPlayer:Send("GS2CWarEndUI", mShow)
    end
end

function GetShowItem(mRecord, mData)
    local iPid =mData.pid
    local oUIMgr = global.oUIMgr
    local lShowInfo = mData.data or {}
    for _, mShow in ipairs(lShowInfo) do
        oUIMgr:AddKeepItem(iPid, mShow)
    end
    interactive.Response(mRecord.source, mRecord.session, {
        pid =iPid,
        data = oUIMgr:PackKeepItem(iPid),
        })
end