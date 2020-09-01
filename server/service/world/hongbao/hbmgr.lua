local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))
local hbobj = import(service_path("hongbao.hbobj"))
local hbdefines = import(service_path("hongbao.hbdefines"))
local gamedefines = import(lualib_path("public.gamedefines"))

function NewHbMgr()
    return CHbMgr:New()
end

local sTableName = "hongbao"

CHbMgr = {}
CHbMgr.__index = CHbMgr
inherit(CHbMgr, datactrl.CDataCtrl)

function CHbMgr:New()
    local o = super(CHbMgr).New(self)
    o.m_HbList = {}
    o.m_HongBaoID = 0
    return o
end

function CHbMgr:Release()
    for _, oHongBao in pairs(self.m_HbList) do
        baseobj_safe_release(oHongBao)
    end
    self.m_HongBaoID = nil
    super(CHbMgr).Release(self)
end

function CHbMgr:InitData()
    local mData = {
        name = sTableName,
    }
    local mArgs = {
        module = "global",
        cmd = "LoadGlobal",
        data = mData
    }
    gamedb.LoadDb("hongbao","common", "LoadDb",mArgs, function (mRecord, mData)
        if not is_release(self) then
            local m = mData.data
            self:Load(m)
            self:OnLoaded()
        end
    end)
end

function CHbMgr:ConfigSaveFunc()
    self:ApplySave(function ()
        local oHbMgr = global.oHbMgr
        oHbMgr:CheckSaveDb()
    end)
end

function CHbMgr:CheckSaveDb()
    if self:IsDirty() then
        local mData = {
            name = sTableName,
            data = self:Save()
        }
        gamedb.SaveDb("hongbao","common","SaveDb",{
            module = "global",
            cmd = "SaveGlobal",
            data = mData,
        })
        self:UnDirty()
    end
end

function CHbMgr:Save()
    local mData = {}
    local mHongBao = {}
    for sKey, oHongBao in pairs(self.m_HbList) do
        mHongBao[sKey] = oHongBao:Save()
    end
    mData.hongbao = mHongBao
    mData.hbid = self.m_HongBaoID
    return mData
end

function CHbMgr:Load(mData)
    mData = mData or {}
    local mHongBao = mData.hongbao or {}
    local mHbList = {}
    for sKey,data in pairs(mHongBao) do
        local oHongBao = hbobj.NewHbObj(data)
        oHongBao:Load(data)
        mHbList[sKey] = oHongBao
    end
    self.m_HbList = mHbList
    self.m_HongBaoID = mData.hbid or 0
end

function CHbMgr:MergeFrom(mFromData)
    local mHongBao = mFromData.hongbao or {}
    local mHbList = self.m_HbList
    for _,data in pairs(mHongBao) do
        local iID = self:DispatchHongBaoID()
        data.id = iID
        local oHongBao = hbobj.NewHbObj(data)
        oHongBao:Load(data)
        mHbList[iID] = oHongBao
    end
    return true
end

function CHbMgr:IsDirty()
   if super(CHbMgr).IsDirty(self) then
        return true
    end
    for _,oHongBao in pairs(self.m_HbList) do
        if oHongBao:IsDirty() then
            return true
        end
    end
    return false
end

function CHbMgr:DispatchHongBaoID()
    self:Dirty()
    local id = self.m_HongBaoID
    id = id + 1
    if id > hbdefines.HONGBAO_MAX_CNT then
        id = 1
    end
    self.m_HongBaoID = id
    return id
end

function CHbMgr:ClearHongBao(id)
    self:Dirty()
    local oHongBao = self.m_HbList[db_key(id)]
    if oHongBao then
        baseobj_safe_release(oHongBao)
    end
    self.m_HbList[db_key(id)] = nil
end

function CHbMgr:AddHongBao(oPlayer,sType,iGold,iAmount,sid)
    self:Dirty()
    local mArgs = {
        name = oPlayer:GetName(),
        owner = oPlayer:GetPid(),
        shape = oPlayer:GetShape(),
        title = string.format("%s的红包",oPlayer:GetName()),
        gold = iGold,
        amount = iAmount,
        id = self:DispatchHongBaoID(),
        type = sType,
        endtime = get_time() + 2*3600,
        begintime = get_time(),
        sid = sid
    }
    assert(not self.m_HbList[mArgs.id], string.format("hongbao %d have exist!",mArgs.id))
    local oHongBao = hbobj.NewHbObj(mArgs)
    self.m_HbList[db_key(mArgs.id)] = oHongBao
    return oHongBao
end

function CHbMgr:SendHongBao(oPlayer,sType,iGold,iAmount,sid)
    local sName = hbdefines.GetHongBaoTypeName(sType)
    if not sName then return end
    local oHongBao = self:AddHongBao(oPlayer,sType,iGold,iAmount,sid)
    if oHongBao then
        local sMsg = string.format("{link21,%s,%s,%d}",oHongBao:Title(),oHongBao:SID(),oHongBao:ID())
        if sType == "orgchannel" then
            global.oChatMgr:SendMsg2Org(sMsg,oPlayer:GetOrgID(),oPlayer)
        elseif sType == "worldchannel" then
            global.oChatMgr:SendWOrldChat(oPlayer,sMsg)
        end
    end
end

function CHbMgr:GetHongBaoByID(id)
    return self.m_HbList[db_key(id)]
end

function CHbMgr:HongBaoOption(oPlayer,sAction,id)
    local oHongBao = self:GetHongBaoByID(id)
    if oHongBao then
        if sAction == "draw" then
            self:DrawHbObj(oPlayer,oHongBao)
        elseif sAction == "look" then
            oHongBao:ShowHongBaoInfo(oPlayer)
        end
    else
        oPlayer:NotifyMessage("来晚了，该红包已经失效")
    end
end

function CHbMgr:GetText(iText)
    local res = require "base.res"
    return res["daobiao"]["hongbao"]["text"][iText]["content"]
end

function CHbMgr:DrawHbObj(oPlayer,oHongBao)
    if oHongBao:IsOver() then
        oPlayer:NotifyMessage("来晚了，该红包已经失效")
        return
    end
    if not oHongBao:ValidDrawHbObj(oPlayer) then
        oHongBao:ShowPlayerHBInfo(oPlayer)
        return
    end
    if oPlayer.m_oToday:Query("drawhb_cnt",0) >= 20 then
        oPlayer:NotifyMessage("你今天的红包奖励次数已满，请明天再来抢夺红包")
        return
    end
    oPlayer.m_oToday:Add("drawhb_cnt",1)
    local iTotalGold = oHongBao:GetGold()
    local iAmount = oHongBao:GetAmount()
    local iAvgGold = iTotalGold // iAmount
    local iGetGold = oHongBao:DrawHbObj(oPlayer)
    local iText = 1003
    if iGetGold >= iAvgGold * 2 then
        iText = 1001
    elseif iGetGold >= iAvgGold // 2 then
        iText = 1002
    end
    local sText = self:GetText(iText)
    local sICon = oPlayer.m_oActiveCtrl:CoinIcon(gamedefines.COIN_FLAG.COIN_COIN)
    sText = string.gsub(sText,"$role",{["$role"] = oPlayer:GetName()})
    sText = string.gsub(sText,"$target", oHongBao:GetName())
    sText = string.gsub(sText,"$coin", tostring(iGetGold))
    sText = string.gsub(sText,"$icon", sICon)

    local sType = oHongBao:Type()
    if sType == "orgchannel" then
        global.oChatMgr:SendMsg2Org(sText,oPlayer:GetOrgID())
    elseif sType == "worldchannel" then
        global.oChatMgr:SendWOrldChat(nil,sText)
    end

    if oHongBao:GetAmount() > 1 and oHongBao:GetRemainHbObjAmount() <= 0 then
        local iTime = get_time() - oHongBao:GetBeginTime()
        local sTime = get_second2string(iTime)
        sText = self:GetText(1004)
        sText = string.gsub(sText,"$target", oHongBao:GetName())
        sText = string.gsub(sText,"$time", sTime)
        sText = string.gsub(sText,"$icon", sICon)
        local sMaxName = oHongBao:GetMaxGoldPlayerName()
        local iMaxGold = oHongBao:GetMaxGold()
        local sMinName = oHongBao:GetMinGoldPlayerName()
        if iMaxGold and sMaxName ~= "" and sMinName ~= "" then
            sText = string.gsub(sText,"$role1", sMinName)
            sText = string.gsub(sText,"$role2", sMaxName)
            sText = string.gsub(sText,"$coin", tostring(iMaxGold))
            if sType == "orgchannel" then
                global.oChatMgr:SendMsg2Org(sText,oPlayer:GetOrgID())
            elseif sType == "worldchannel" then
                global.oChatMgr:SendWOrldChat(nil,sText)
            end
        end
    end
end

function CHbMgr:NewHour(iDay,iHour)
    self:CheckOver()
end

function CHbMgr:CheckOver()
    local mDel = {}
    for sKey, oHongBao in pairs(self.m_HbList) do
        if oHongBao:IsOver() then
            table.insert(mDel,oHongBao:ID())
        end
    end
    for _,id in pairs(mDel) do
        self:ClearHongBao(id)
    end
end