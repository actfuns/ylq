--import module
local global = require "global"
local res = require "base.res"
local interactive = require "base.interactive"
local extend = require "base.extend"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))

local sName = "partner"

function NewPartnerCmtMgr(...)
    return CPartnerCmtMgr:New(...)
end

CPartnerCmtMgr = {}
CPartnerCmtMgr.__index = CPartnerCmtMgr
inherit(CPartnerCmtMgr, datactrl.CDataCtrl)

function CPartnerCmtMgr:New()
    local o = super(CPartnerCmtMgr).New(self)
    o.m_mList = {}
    o.m_iMaxSize = 200
    o:Schedule()
    return o
end

function CPartnerCmtMgr:NewComment(iPartnerType)
    local o = CComment:New(iPartnerType)
    return o
end

function CPartnerCmtMgr:ConfigSaveFunc()
    self:ApplySave(function ()
        local oWorldMgr = global.oWorldMgr
        local oPartnerCmtMgr = global.oPartnerCmtMgr
        oPartnerCmtMgr:CheckSaveDb()
    end)
end

function CPartnerCmtMgr:InitData()
    local mData = {
        name = "partner",
    }
    local mArg = {
        module = "global",
        cmd = "LoadGlobal",
        data = mData,
    }
    gamedb.LoadDb("partner","common", "LoadDb",mArg, function (mRecord, mData)
        if not is_release(self) then
            local m = mData.data
            self:Load(m)
            self:OnLoaded()
        end
    end)
end

function CPartnerCmtMgr:Load(mData)
    mData = mData or {}
    for sType, m in pairs(mData) do
        local iType = tonumber(sType)
        local oComment = CComment:New(iType)
        oComment:Load(m)
        self.m_mList[iType] = oComment
    end
end

function CPartnerCmtMgr:MergeFrom(mFromData)
    return false, "merge function is not implemented"
end

function CPartnerCmtMgr:Schedule()
end

function CPartnerCmtMgr:Save()
    local mData = {}
    for iType, oCmt in pairs(self.m_mList) do
        iType = db_key(iType)
        mData[iType] = oCmt:Save()
    end

    return mData
end

function CPartnerCmtMgr:CheckSaveDb()
    if self:IsDirty() then
        local mData = {
            name = "partner",
            data = self:Save()
        }
        gamedb.SaveDb("partner","common","SaveDb",{
            module = "global",
            cmd = "SaveGlobal",
            data = mData
        })
        self:UnDirty()
    end
end

function CPartnerCmtMgr:NewDay(iDay)
    for iType, oCmt in pairs(self.m_mList) do
        oCmt:NewDay(iDay)
    end
end

function CPartnerCmtMgr:GetObj(iType)
    return self.m_mList[iType]
end

function CPartnerCmtMgr:IsDirty()
    local bDirty = super(CPartnerCmtMgr).IsDirty(self)
    if bDirty then
        return true
    end
    for _, o in pairs(self.m_mList) do
        if o:IsDirty() then
            return true
        end
    end
    return false
end

function CPartnerCmtMgr:UnDirty()
    super(CPartnerCmtMgr).UnDirty(self)
    for _, o in pairs(self.m_mList) do
        o:UnDirty()
    end
end

function CPartnerCmtMgr:AddComment(oCmt)
    local iPartnerType = oCmt:PartnerType()
    self.m_mList[iPartnerType] = oCmt
    self:Dirty()
end

function CPartnerCmtMgr:MaxCmtSize()
    return self.m_iMaxSize
end

function CPartnerCmtMgr:TestOP(oPlayer, iCmd, ...)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local mArg = {...}
    if iCmd == 101 then
        local iMaxSize = table.unpack(mArg) or 200
        if iMaxSize <= 0 then
            return
        end
        self.m_iMaxSize = iMaxSize
        oNotifyMgr:Notify(iPid, string.format("评论上限已设:%s次", iMaxSize))
    end
end

CComment = {}
CComment.__index = CComment
inherit(CComment, datactrl.CDataCtrl)

function CComment:New(iType)
    local o = super(CComment).New(self)
    o.m_iPartnerType = iType
    o.m_mList = {}
    o.m_mHotList = {}
    o.m_mDailyCmt = {}
    return o
end

function CComment:Load(mData)
    mData = mData or {}
    local mList = mData.list or {}
    for id, m in ipairs(mList) do
        local mVoteList = {}
        for _, iPid in ipairs(m.vote_list) do
            mVoteList[iPid] = true
        end
        m.vote_list = mVoteList
        table.insert(self.m_mList, m)
    end

    local mHotList = mData.hot_list or {}
    for id, m in ipairs(mHotList) do
        local mVoteList = {}
        for _, iPid in ipairs(m.vote_list) do
            mVoteList[iPid] = true
        end
        m.vote_list = mVoteList
        table.insert(self.m_mHotList, m)
    end
end

function CComment:Save()
    local mData = {}
    mData["list"] = {}
    for _, m in ipairs(self.m_mList) do
        local mVote = {}
        for iPid, _ in pairs(m.vote_list) do
            table.insert(mVote, iPid)
        end
        table.insert(mData["list"], {
            pid = m.pid,
            name = m.name,
            msg = m.msg,
            create_time = m.create_time,
            vote_list = mVote,
            })
    end

    mData["hot_list"] = {}
    for _, m in ipairs(self.m_mHotList) do
        local mVote = {}
        for iPid, _ in pairs(m.vote_list) do
            table.insert(mVote, iPid)
        end
        table.insert(mData["hot_list"], {
            pid = m.pid,
            name = m.name,
            msg = m.msg,
            create_time = m.create_time,
            vote_list = mVote,
            })
    end
    return mData
end

function CComment:DailyComment(oPlayer)
    local iPid = oPlayer:GetPid()
    if self.m_mDailyCmt[iPid] then
        return 1
    end
    return 0
end

function CComment:NewDay(iDay)
    self.m_mDailyCmt = {}
end

function CComment:PartnerType()
    return self.m_iPartnerType
end

function CComment:MaxSize()
    return global.oPartnerCmtMgr:MaxCmtSize()
end

function CComment:Size()
    return #self.m_mList + #self.m_mHotList
end

function CComment:ValidAdd(iPid, bNotify)
    local oNotifyMgr = global.oNotifyMgr

    if self.m_mDailyCmt[iPid] then
        if bNotify then
            oNotifyMgr:Notify(iPid, "每天只能发一条评论")
        end
        return false
    end
    return true
end

function CComment:Add(oPlayer, sMsg)
    self:Dirty()

    local iSize = self:Size()
    local iMaxSize = self:MaxSize()
    while (iSize >= iMaxSize) do
        self:Remove()
        iSize = iSize - 1
    end

    local iPid = oPlayer:GetPid()
    local sName = oPlayer:GetName()
    local mData = {
        pid = iPid,
        name = sName,
        msg = sMsg,
        vote_list = {},
        create_time = get_time()
    }
    table.insert(self.m_mList, mData)
    self.m_mDailyCmt[iPid] = true
    self:GS2CPartnerCommentInfo(oPlayer)
end

function CComment:Remove()
    if next(self.m_mList) then
        table.remove(self.m_mList, 1)
    end
end

function CComment:ValidVote(iPid, iType, iID, bNotify)
    local oNotifyMgr = global.oNotifyMgr
    local mData = self.m_mList[iID]
    if iType == 1 then
        mData = self.m_mHotList[iID]
    end
    if not mData then
        if bNotify then
            oNotifyMgr:Notify(iPid, "评论不存在")
        end
        return false
    end
    if mData.vote_list[iPid] then
        if bNotify then
            oNotifyMgr:Notify(iPid, "不可重复点赞")
        end
        return false
    end
    return true
end

function CComment:UpVote(oPlayer, iType, iID)
    local iPid = oPlayer:GetPid()
    local mData = self.m_mList[iID]
    if iType == 1 then
        mData = self.m_mHotList[iID]
    end
    local mVote = mData.vote_list
    if not mVote[iPid] then
        mVote[iPid] = true
        if iType == 1 then
            self:AdjustHotList(iID)
        else
            self:CheckHotList(iID)
        end
        self:GS2CPartnerCommentInfo(oPlayer)
    end
end

function CComment:AdjustHotList(iID)
    local mData = self.m_mHotList[iID]
    if not mData then
        return
    end
    local iTmpVote = table_count(mData.vote_list)
    local iPos
    for i = iID-1, 1, -1 do
        local m = self.m_mHotList[i]
        local iVote = table_count(m.vote_list)
        if iTmpVote > iVote then
            iPos = i
        elseif m.create_time < mData.create_time then
            iPos = i
        end
    end
    if iPos then
        self:Dirty()
        table.remove(self.m_mHotList, iID)
        table.insert(self.m_mHotList, iPos, mData)
    end
end

function CComment:CheckHotList(iID)
    local bChange = false
    local mData = self.m_mList[iID]
    if mData then
        local iHotID = #self.m_mHotList
        local iVote = table_count(mData.vote_list)
        if iHotID == 3 then
            local mMinHot = self.m_mHotList[iHotID]
            local iHotVote = #mMinHot.vote_list
            if iVote > iHotVote then
                self:ExchangeData(iID, iHotID)
                bChange = true
            elseif iVote == iHotVote then
                if mData.create_time > mMinHot.create_time then
                    self:ExchangeData(iID, iHotID)
                    bChange = true
                end
            end
        else
            if iVote > 0 then
                self:Dirty()
                table.insert(self.m_mHotList, mData)
                table.remove(self.m_mList, iID)
                bChange = true
            end
        end
    end

    return bChange
end

function CComment:ExchangeData(iID, iHotID)
    self:Dirty()
    local mOldHot = self.m_mHotList[iHotID]
    local mNewHot = self.m_mList[iID]
    table.remove(self.m_mHotList, iHotID)
    table.remove(self.m_mList, iID)

    local iPos = 1
    local iNewVote = table_count(mNewHot.vote_list)
    for _, m in ipairs(self.m_mHotList) do
        local iVote = table_count(m.vote_list)
        if iNewVote < iVote then
            iPos = iPos + 1
        elseif iNewVote == iVote then
            if mNewHot.create_time < m.create_time then
                iPos = iPos + 1
            end
        end
    end
    table.insert(self.m_mHotList, iPos, mNewHot)

    iPos = 1
    for _, m in ipairs(self.m_mList) do
        if mOldHot.create_time < m.create_time then
            iPos = iPos + 1
        end
    end
    table.insert(self.m_mList, iPos, mOldHot)

    if self:Size() > self:MaxSize() then
        self:Remove()
    end
end

function CComment:PackMsgData()
    local mList = {}
    local iLen = #self.m_mList
    for id = 1, iLen  do
        local mData = self.m_mList[id]
        local mVote = {}
        for iPid, _ in pairs(mData.vote_list) do
            table.insert(mVote, iPid)
        end
        table.insert(mList, {
            id = id,
            pid = mData.pid,
            name = mData.name,
            msg = mData.msg,
            vote_list = mVote,
            create_time = mData.create_time,
            })
    end

    local mHotList = {}
    local iLen = #self.m_mHotList
    for id = 1, iLen do
        local mData = self.m_mHotList[id]
        local mVote = {}
        for iPid, _ in pairs(mData.vote_list) do
            table.insert(mVote, iPid)
        end
        table.insert(mHotList, {
            id = id,
            pid = mData.pid,
            name = mData.name,
            msg = mData.msg,
            vote_list = mVote,
            create_time = mData.create_time,
            })
    end

    local mNet = {}
    mNet["list"] = mList
    mNet["hot_list"] = mHotList

    return mNet
end

function CComment:GS2CPartnerCommentInfo(oPlayer)
    if oPlayer then
        local mNet = self:PackMsgData(oPlayer)
        mNet["partner_type"] = self:PartnerType()
        mNet["is_comment"] = self:DailyComment(oPlayer)
        oPlayer:Send("GS2CPartnerCommentInfo", mNet)
    end
end