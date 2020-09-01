local skynet = require "skynet"
local global = require "global"
local interactive = require "base.interactive"
local extend = require "base.extend"
local CBaseOfflineCtrl = import(service_path("offline.baseofflinectrl")).CBaseOfflineCtrl
local defines = import(service_path("offline.defines"))
local loaditem = import(service_path("item.loaditem"))

CFriendCtrl = {}
CFriendCtrl.__index = CFriendCtrl
inherit(CFriendCtrl, CBaseOfflineCtrl)

function CFriendCtrl:New(pid)
    local o = super(CFriendCtrl).New(self, pid)
    o.m_sDbFlag = "Friend"
    o.m_mFriends = {}
    o.m_mChats = {}
    o.m_mBlackList = {}
    o.m_mRelations = {}
    o.m_mAppList = {}
    o.m_mDoc = {}
    o.m_mSetting = {}
    o.m_ShowEquip = {}
    o.m_MarryID = 0
    return o
end

function CFriendCtrl:Save()
    local mData = {}
    mData.friends = self.m_mFriends or {}
    mData.chats = self.m_mChats or {}
    mData.black = self.m_mBlackList or {}
    mData.relation = self.m_mRelations or {}
    mData.apply = self.m_mAppList or {}
    mData.doc = self.m_mDoc or {}
    mData.setting = self.m_mSetting or {}
    mData.ph = self:GetData("photo","")
    local mEquip = {}
    for iPos,m in pairs(self.m_ShowEquip) do
        mEquip[db_key(iPos)] = m
    end
    mData["equip"] = mEquip
    mData["show"] = self:GetData("show_equip",0)
    mData["marryid"] = self.m_MarryID or 0
    return mData
end

function CFriendCtrl:Load(mData)
    mData = mData or {}
    self.m_mFriends = mData.friends or {}
    self.m_mChats = mData.chats or {}
    self.m_mBlackList = mData.black or {}
    self.m_mRelations = mData.relation or {}
    self.m_mAppList = mData.apply or {}
    self.m_mDoc = mData.doc or {}
    self.m_mSetting = mData.setting or {}
    self.m_MarryID = mData.marryid or 0
    self:SetData("photo",mData.ph or "")
    self:SetData("show_equip",mData["show"] or 0)

    local mEquip = mData["equip"] or {}
    -- local mEquipBak = mData["equip_bak"] or {}
    for iPos,mEquipData in pairs(mEquip) do
        iPos = tonumber(iPos)
        self.m_ShowEquip[iPos] = mEquipData
    end

    self:_PreCheck()
end

function CFriendCtrl:_PreCheck()
    if self:GetData("show_equip", 0) == 1 and not next(self.m_ShowEquip) then
        self:SetData("show_equip", 0)
    end
end


-- 关系
function CFriendCtrl:SetRelation(iPid, iRelation)
    if not iPid or iPid == 0 then
        return
    end
    assert(defines.FRIEND_KEEP[iRelation],string.format("err SetRalation %d %d",iPid,iRelation))
    self:Dirty()
    local sPid = db_key(iPid)
    local r = self.m_mRelations[sPid] or 0
    self.m_mRelations[sPid] = r | 2 ^ (iRelation - 1)
end

function CFriendCtrl:ResetRelation(iPid, iRelation)
    if not iPid or iPid == 0 then
        return
    end
    local sPid = db_key(iPid)
    local r = self.m_mRelations[sPid]
    if not r then
        return
    end
    self:Dirty()
    self.m_mRelations[sPid] = r & ~ (2 ^ (iRelation - 1))
    if self.m_mRelations[sPid] == 0 then
        self.m_mRelations[sPid] = nil
    end
end

function CFriendCtrl:HasRelation(iPid, iRelation)
    if not iPid or iPid == 0 then
        return false
    end
    local sPid = db_key(iPid)
    local r = self.m_mRelations[sPid] or 0
    return r & 2 ^ (iRelation - 1) ~= 0
end

function CFriendCtrl:GetRelation(iRelation)
    local mPid = {}
    for sPid, r in pairs(self.m_mRelations) do
        if r & 2 ^ (iRelation - 1) ~= 0 then
            mPid[tonumber(sPid)] = iRelation
        end
    end
    return mPid
end

function CFriendCtrl:GetRelations()
    return self.m_mRelations
end

function CFriendCtrl:GetFriendRelation(iPid)
    if not iPid or iPid == 0 then
        return 0
    end
    local sPid = db_key(iPid)
    return self.m_mRelations[sPid] or 0
end

--好友常规操作接口
function CFriendCtrl:FriendsMaxCnt(iGrade)
    local iAmout=defines.FRIEND_CNTBASE
    if iGrade<1 then
        iAmout=0
    else
        iAmout=iAmout+math.floor((iGrade-10)/10*5)
    end
    return math.min(iAmout,defines.FRIEND_CNTMAX)
end

function CFriendCtrl:GetFriends()
    return self.m_mFriends
end

function CFriendCtrl:FriendKeyList()
    local mFriend = {}
    for sPid,_ in pairs(self:GetFriends()) do
        table.insert(mFriend,tonumber(sPid))
    end
    return mFriend
end

function CFriendCtrl:GetFriendOfflineChats()
    return self.m_mChats
end

function CFriendCtrl:HasFriend(iPid)
    local sPid = db_key(iPid)
    if self.m_mFriends[sPid] then
        return true
    end
    return false
end

function CFriendCtrl:FriendCount()
    return table_count(self.m_mFriends)
end

function CFriendCtrl:DelFriend(iPid)
    self:Dirty()
    local oWorldMgr = global.oWorldMgr
    local oFriendMgr = global.oFriendMgr

    local sPid = db_key(iPid)
    self.m_mFriends[sPid] = nil
    global.oAchieveMgr:PushAchieve(self:GetPid(),"好友数量",{value=self:FriendCount()})
end

function CFriendCtrl:AddFriend(iPid, mExtra)
    if not iPid or iPid == 0 then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oFriendMgr = global.oFriendMgr

    self:Dirty()
    local sPid = db_key(iPid)
    mExtra = mExtra or {}
    if not self.m_mFriends[sPid] then
        self.m_mFriends[sPid] = {}
    end
    self.m_mFriends[sPid].friend_degree = mExtra.friend_degree or 0
    global.oAchieveMgr:PushAchieve(self:GetPid(),"好友数量",{value=self:FriendCount()})
end



function CFriendCtrl:SetBothFriend(iPid)
    local sPid = db_key(iPid)
    if not self.m_mFriends[sPid] then
        return
    end
    self:Dirty()
    self.m_mFriends[sPid].both_friend = true
end

function CFriendCtrl:ClearBothFriend(iPid)
    local sPid = db_key(iPid)
    if not self.m_mFriends[sPid] then
        return
    end
    self:Dirty()
    self.m_mFriends[sPid].both_friend = nil
end

function CFriendCtrl:IsBothFriend(iPid)
    local sPid = db_key(iPid)
    if not self.m_mFriends[sPid] then
        return false
    end
    return self.m_mFriends[sPid].both_friend
end

function CFriendCtrl:GetBothFriends()
    local lBothFriend = {}
    for sPid, mInfo in pairs(self.m_mFriends) do
        if mInfo.both_friend then
            table.insert(lBothFriend, tonumber(sPid))
        end
    end
    return lBothFriend
end

--黑名单
function CFriendCtrl:GetBlackList()
    return self.m_mBlackList
end

function CFriendCtrl:IsShield(iPid)
    local sPid = db_key(iPid)
    return self.m_mBlackList[sPid]
end

function CFriendCtrl:Shield(iPid)
    if not iPid or iPid == 0 then
        return
    end
    self:Dirty()
    local sPid = db_key(iPid)
    self.m_mBlackList[sPid] = true
end

function CFriendCtrl:Unshield(iPid)
    self:Dirty()
    local sPid = db_key(iPid)
    self.m_mBlackList[sPid] = nil
end

function CFriendCtrl:HasChat(iPid, iMessageId)
    local sPid = db_key(iPid)
    if not self.m_mChats[sPid] then
        return false
    end
    for _, v in ipairs(self.m_mChats[sPid]) do
        if v.message_id == iMessageId then
            return true
        end
    end
    return false
end

--申请列表
function CFriendCtrl:AddApply(iTarget)
    self:Dirty()
    if #self.m_mAppList >= defines.FRIEND_APPLYLIMIT then
        table.remove(self.m_mAppList,1)
    end
    table.insert(self.m_mAppList,iTarget)
end

function CFriendCtrl:GetApplyIndx(iTarget)
    for k,v in ipairs(self.m_mAppList) do
        if v == iTarget then
            return k
        end
    end
    return nil
end

function CFriendCtrl:RemoveApply(iTarget)
    local idx=self:GetApplyIndx(iTarget)
    if idx then
        self:Dirty()
        table.remove(self.m_mAppList,idx)
    end
    return idx
end


--聊天相关
function CFriendCtrl:GetChat(iPid, iMessageId)
    local sPid = db_key(iPid)
    if not self.m_mChats[sPid] then
        return
    end
    local iIndex
    for k, v in ipairs(self.m_mChats[sPid]) do
        if v.message_id == iMessageId then
            iIndex = k
            return iIndex, v
        end
    end
    return
end

function CFriendCtrl:AddChat(iPid, iMessageId, sMsg)
    if not iPid or iPid == 0 then
        return false
    end
    if self:HasChat(iPid, iMessageId) then
        return false
    end
    self:Dirty()
    local sPid = db_key(iPid)
    if not self.m_mChats[sPid] then
        self.m_mChats[sPid] = {}
    end
    if #self.m_mChats[sPid] >= 30 then
        table.remove(self.m_mChats[sPid], 1)
    end
    table.insert(self.m_mChats[sPid], {message_id = iMessageId, msg = sMsg})
    return true
end

function CFriendCtrl:DelChat(iPid, iMessageId)
    local iIndex = self:GetChat(iPid, iMessageId)
    if not iIndex then
        return false
    end
    self:Dirty()
    local sPid = db_key(iPid)
    table.remove(self.m_mChats[sPid], iIndex)
    if #self.m_mChats[sPid] <= 0 then
        self.m_mChats[sPid] = nil
    end
    return true
end

function CFriendCtrl:EraseChat(iPid, iMessageId)
    local iIndex = self:GetChat(iPid, iMessageId)
    if not iIndex then
        return false
    end
    self:Dirty()
    local sPid = db_key(iPid)
    local l = {}
    for i = iIndex + 1, #self.m_mChats[sPid] do
        table.insert(l, self.m_mChats[sPid][i])
    end
    if #l <= 0 then
        self.m_mChats[sPid] = nil
    else
        self.m_mChats[sPid] = l
    end
    return true
end

function CFriendCtrl:GetFriendsOnlineStatusInfo()
    local mOnlineStatusInfoTbl = {}
    for k,_ in pairs(self.m_mFriends) do
        local iFriendId = tonumber(k)
        local iOnlineStatus = self:GetFriendOnlineStatusById(iFriendId) and 1 or 0
        table.insert(mOnlineStatusInfoTbl,{pid = iFriendId,onlinestatus = iOnlineStatus})
    end
    return mOnlineStatusInfoTbl
end

function CFriendCtrl:GetFriendOnlineStatusById(iFriendId)
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:IsOnline(iFriendId)
end


--好友度
function CFriendCtrl:ClearFriendDegree(iPid)
    local sPid = db_key(iPid)
    if not self.m_mFriends[sPid] then
        return
    end
    self:Dirty()
    local iOldDegree = self.m_mFriends[sPid].friend_degree or 0
    self.m_mFriends[sPid].friend_degree = 0
    return iOldDegree
end

function CFriendCtrl:AddFriendDegree(iPid, iDegree)
    local sPid = db_key(iPid)
    if not self.m_mFriends[sPid] then
        return
    end
    if self.m_mFriends[sPid].friend_degree >= defines.DEGREE_MAX then
        return
    end
    self:Dirty()
    local iOldDegree = self.m_mFriends[sPid].friend_degree or 0
    self.m_mFriends[sPid].friend_degree = iOldDegree + iDegree
end

function CFriendCtrl:GetFriendDegree(iPid)
    local sPid = db_key(iPid)
    if not self.m_mFriends[sPid] then
        return 0
    end
    return self.m_mFriends[sPid].friend_degree or 0
end

--个人档案
function CFriendCtrl:SetDocument(mDoc)
    self:Dirty()
    self.m_mDoc = mDoc
end

function CFriendCtrl:Document()
return self.m_mDoc
end

function CFriendCtrl:Setting(mData)
    local mSet = {}
    local mFilter = {notify= 1 ,strange_chat = 1,strange_grade = 30,apply_switch=1,apply_grade=30,
        auto_response="",respond_switch=0}
    for sKey,default in pairs(mFilter) do
        mSet[sKey] = mData[sKey] or self.m_mSetting[sKey] or default
    end
    self.m_mSetting=mSet
    self:Dirty()
end

function CFriendCtrl:QuerySetting(sKey)
    return self.m_mSetting[sKey]
end

function CFriendCtrl:GetSetting()
    local mSetting=self.m_mSetting
    if table_count(mSetting) ==0 then
        mSetting = {
        notify = 1,
        strange_chat = 0 ,
        strange_grade = 0,
        apply_switch = 0,
        apply_grade = 0,
        auto_response = "",
        }
        self:Setting(mSetting)
    end
    return mSetting
end


function CFriendCtrl:GetProtectFriends(lFriends)
    if not lFriends then
        lFriends = table_key_list(self.m_mFriends)
        extend.Array.append (lFriends, table_key_list(self.m_mRelations))
    end
    local mProtect = {}
    for k, _ in pairs(self:GetRelation(defines.RELATION_COUPLE)) do
        if not mProtect[k] then
            mProtect[k] = 600 + self:GetFriendDegree(k)
        end
    end
    for k, _ in pairs(self:GetRelation(defines.RELATION_MASTER)) do
        if not mProtect[k] then
            mProtect[k] = 300 + self:GetFriendDegree(k)
        end
    end
    for k, _ in pairs(self:GetRelation(defines.RELATION_BROTHER)) do
        if not mProtect[k] then
            mProtect[k] = 200 + self:GetFriendDegree(k)
        end
    end
    for _, k in pairs(lFriends) do
        if k ~= self:GetPid() and not mProtect[k] then
            local iDegree = self:GetFriendDegree(k)
            if iDegree >= defines.DEGREE_PROTECT then
                mProtect[k] = 100 + iDegree
            end
        end
    end
    return mProtect
end

function CFriendCtrl:SendMailByDegree(iDegree, sMail, mMail)
    local oMailMgr = global.oMailMgr
    local iPid = self:GetPid()
    for sPid, mInfo in pairs(self.m_mFriends) do
        if mInfo.both_friend and mInfo.friend_degree > iDegree then
            oMailMgr:SendMail(iPid, sMail, tonumber(sPid), mMail)
        end
    end
end

function CFriendCtrl:SetEquip(iPos,mEquipData)
    self.m_ShowEquip[iPos] = mEquipData
    self:Dirty()
end

function CFriendCtrl:HasMarry()
    return self.m_MarryID ~= 0
end

function CFriendCtrl:GetMarryID()
    return self.m_MarryID
end

function CFriendCtrl:SetMarryID(iPid)
    self.m_MarryID = iPid
    self:Dirty()
end