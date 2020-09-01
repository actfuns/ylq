local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local res = require "base.res"
local interactive = require "base.interactive"
local record = require "public.record"
local fstring = require "public.colorstring"

local gamedb = import(lualib_path("public.gamedb"))
local cpower = import(lualib_path("public.cpower"))
local datactrl = import(lualib_path("public.datactrl"))
local playerobj = import(service_path("playerobj"))
local gamedefines = import(lualib_path("public.gamedefines"))

local string_gsub = string.gsub


function NewAssistMgr(...)
    local o = CAssistMgr:New(...)
    return o
end

CAssistMgr = {}
CAssistMgr.__index = CAssistMgr
inherit(CAssistMgr, datactrl.CDataCtrl)

function CAssistMgr:New()
    local o = super(CAssistMgr).New(self)
    o.m_mPlayers = {}
    o.m_mPlayerChange = {}
    o.m_mPartnerPropChange = {}
    o.m_iGlobalItemID = 0
    o.m_iServiceID = 0
    return o
end

function CAssistMgr:CloseGS()
    save_all()
    local lPids = table_key_list(self.m_mPlayers)
    for _, iPid in ipairs(lPids) do
        self:Logout(iPid)
    end
end

function CAssistMgr:GetPlayer(iPid)
    return self.m_mPlayers[iPid]
end

function CAssistMgr:Disconnected(iPid)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:Disconnected()
    end
end

function CAssistMgr:Logout(iPid)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:OnLogout()
        self.m_mPlayers[iPid] = nil
        baseobj_delay_release(oPlayer)
    end
end

function CAssistMgr:LoadRoleAssist(mWorldRecord,iPid,mInfo)
    self.m_mPlayers[iPid] = playerobj.NewPlayer(iPid, mInfo)
    self:_LoginLoadModule(mWorldRecord,iPid)
end

local lLoginLoadInfo = {
    {"playerdb", "LoadPlayerItem", "m_oItemCtrl"},
    {"partnerdb", "LoadPartner", "m_oPartnerCtrl"},
    {"playerdb","LoadSkillInfo","m_oSkillCtrl"},
    {"playerdb","LoadParSoulPlan","m_oParSoulCtrl"},
}

function CAssistMgr:_LoginLoadModule(mWorldRecord,iPid, idx)
    idx = idx or 1
    if idx > #lLoginLoadInfo then
        self:LoadEnd(mWorldRecord,iPid)
        return
    end
    local sDBTable, sLoadFunc, rFunc = table.unpack(lLoginLoadInfo[idx])
    local mData = {
        pid = iPid,
    }
    local mArgs = {
        module = sDBTable,
        cmd = sLoadFunc,
        data = mData,
    }
    gamedb.LoadDb(iPid,"common", "LoadDb", mArgs, function (mRecord, mData)
        self:_LoginLoadModuleCB(rFunc, mRecord, mData)
        if not is_release(self) then
            self:_LoginLoadModule(mWorldRecord,iPid, idx+1)
        end
    end)
end

function CAssistMgr:_LoginLoadModuleCB(rFunc, mRecord, mData)
    local pid = mData.pid
    local m = mData.data
    local oPlayer = self.m_mPlayers[pid]
    if not oPlayer then
        return
    end
    if type(rFunc) == "string" then
        if oPlayer[rFunc] then
            oPlayer[rFunc]:Load(m)
        else
            self[rFunc](oPlayer, m)
        end
    else
        rFunc(oPlayer, m)
    end
end

function CAssistMgr:LoadEnd(mWorldRecord,iPid)
    local oPlayer = self:GetPlayer(iPid)
    oPlayer:ConfigSaveFunc()
    local mData = {
        item_share = oPlayer.m_oItemCtrl:GetItemShareReaderCopy(),
        equip_share = oPlayer.m_oEquipMgr:GetEquipMgrReaderCopy(),
        skill_share = oPlayer.m_oSkillMgr:GetSkillMgrReaderCopy(),
        stone_share = oPlayer.m_oStoneMgr:GetStoneMgrReaderCopy(),
        partner_share = oPlayer.m_oPartnerCtrl:GetPartnerShareReaderCopy(),
    }
    interactive.Response(mWorldRecord.source,mWorldRecord.session,mData)
end

function CAssistMgr:OnLogin(iPid,bReEnter,mInfo)
    local o = self:GetPlayer(iPid)
    if o then
        o:OnLogin(bReEnter,mInfo)
    end
end

function CAssistMgr:GetOnlinePlayerByPid(iPid)
    return self.m_mPlayers[iPid]
end

function CAssistMgr:IsOnline(iPid)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    return true
end

function CAssistMgr:DispatchItemID()
    local id = self.m_iGlobalItemID + 1
    self.m_iGlobalItemID = id
    return id
end

function CAssistMgr:Notify(iPid, sMsg)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:Send("GS2CNotify", {
            cmd = sMsg,
        })
    end
end

--玩法控制
function CAssistMgr:IsClose(sKey)
    local mControlData = res["daobiao"]["global_control"][sKey]
    if not mControlData then
        return true
    end
    local sControl = mControlData["is_open"] or "y"
    if sControl == "n" then
        return true
    end
    return false
end

function CAssistMgr:QueryControl(sPlay,sKey)
    local mControlData = res["daobiao"]["global_control"][sPlay]
    assert(mControlData,string.format("err global_coontrol %s",sPlay))
    local val = mControlData[sKey]
    assert(val,string.format("err global_coontrol key %s %s",sPlay,sKey))
    return val
end

function CAssistMgr:QueryGlobalData(sKey)
    local mControlData = res["daobiao"]["global"][sKey]
    assert(mControlData,string.format("err global data %s",sKey))
    local val = mControlData.value
    assert(val,string.format("err global data %s",sKey,val))
    return val
end

function CAssistMgr:SetPlayerPropChange(iPid,lType)
    local mNow = self.m_mPlayerChange[iPid]
    if not mNow then
        mNow = {}
        self.m_mPlayerChange[iPid] = mNow
    end
    for _,sType in pairs(lType) do
        mNow[sType] = true
    end
end

function CAssistMgr:SetPartnerPropChange(iPid, partnerid, l)
    local mPartners = self.m_mPartnerPropChange[iPid]
    if not mPartners then
        mPartners = {}
        self.m_mPartnerPropChange[iPid] = mPartners
    end
    local mProps = mPartners[partnerid]
    if not mProps then
        mProps = {}
        self.m_mPartnerPropChange[iPid][partnerid] = mProps
    end
    for _, v in ipairs(l) do
        mProps[v] = true
    end
end

function CAssistMgr:SendPartnerPropChange()
    if next(self.m_mPartnerPropChange) then
        local mData = self.m_mPartnerPropChange
        for pid, mPartners in pairs(mData) do
            local oPlayer = self:GetPlayer(pid)
            if oPlayer and next(mPartners) then
                for partnerid, v in pairs(mPartners) do
                    local o = oPlayer.m_oPartnerCtrl:GetPartner(partnerid)
                    if o and next(v) then
                        safe_call(o.ClientPropChange,o,oPlayer,v)
                    end
                end
            end
        end
        self.m_mPartnerPropChange = {}
    end
end

function CAssistMgr:DispatchFinishHook()
    self:ShareUpdateData()
    self:SendPartnerPropChange()
end

function CAssistMgr:ShareUpdateData()
    local mRemoteData = {}
    for iPid,lType in pairs(self.m_mPlayerChange) do
        local oPlayer = self:GetOnlinePlayerByPid(iPid)
        for sType,_ in pairs(lType) do
            local mData
            if sType == "equip" then
                oPlayer.m_oEquipMgr:ShareUpdate()
                if not mRemoteData[iPid] then
                    mRemoteData[iPid] = {}
                end
                mRemoteData[iPid][sType] = 1
            elseif sType == "item" then
                oPlayer.m_oItemCtrl:ShareUpdate()
            end
        end
    end
    self.m_mPlayerChange = {}
end

function CAssistMgr:BroadCastNotify(iPid,lMessage,sMsg,mArgs)
    lMessage = lMessage or {"GS2CNotify",}
    local mNet = {
        content = sMsg,
        args = mArgs,
    }
    local mData = {
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        pid = iPid,
        message = lMessage,
        data = mNet,
    }
    interactive.Send(".broadcast", "notify", "ChannelNotify", mData)
end

function CAssistMgr:PushAchieve(iPid,sKey,data)
    interactive.Send(".world", "achieve", "PushAchieve", {
        pid = iPid, key = sKey, data = data,
    })
end

function CAssistMgr:PushCondition(iPid, lCondition)
    interactive.Send(".world", "common", "PushCondition",{
        pid = iPid, condition = lCondition,
        })
end

function CAssistMgr:fixTaskAchieve(iPid)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        local iLevel
        for iPos, oEquip in pairs(oPlayer.m_mEquip or {}) do
            iLevel = math.min(iLevel or oEquip:EquipLevel(), oEquip:EquipLevel())
        end
        if iLevel then
            if iLevel >= 30 then
                global.oAssistMgr:PushAchieve(oPlayer:GetPid(), "穿齐30级装备", {value = 1})
            end
        end
    end
end

function CAssistMgr:InitData()
    self:SyncSumPowerData()
end

function CAssistMgr:SyncSumPowerData()
    local mPower = res["daobiao"]["partner"]["convert_power"]
    for iType,mData in pairs(mPower) do
        cpower.SyncPowerData("partner"..iType,mData)
    end
end

function CAssistMgr:CoinIcon(iType)
    iType = iType or gamedefines.COIN_FLAG.COIN_COIN
    local mCoinInfo = gamedefines.COIN_TYPE[iType]
    assert(mCoinInfo,string.format("MaxCoin %d",iType))
    return mCoinInfo.icon or mCoinInfo.name
end

function CAssistMgr:GetPartnerTextData(iText, args)
    local tUrl = {"partner"}
    return fstring.GetTextData(iText, tUrl, args)
end

function CAssistMgr:GetChuanWenTextData(iText, args)
    return fstring.FormatChuanWen(iText, args)
end