--import module
local skynet = require "skynet"
local global = require "global"
local res = require "base.res"
local extend = require "base.extend"
local net = require "base.net"
local interactive = require "base.interactive"

local datactrl = import(lualib_path("public.datactrl"))
local orgdefines = import(service_path("orgdefines"))

function NewMemberMgr(...)
    return COrgMemberMgr:New(...)
end

COrgMemberMgr = {}
COrgMemberMgr.__index = COrgMemberMgr
inherit(COrgMemberMgr, datactrl.CDataCtrl)

function COrgMemberMgr:New(orgid)
    local o = super(COrgMemberMgr).New(self, {orgid = orgid})
    o:Init()
    return o
end

function COrgMemberMgr:Release()
    for id, oMember in pairs(self.m_mMember) do
        baseobj_safe_release(oMember)
    end
    super(COrgMemberMgr).Release(self)
end

function COrgMemberMgr:GetOrg()
    local orgid = self:GetInfo("orgid")
    local oOrgMgr = global.oOrgMgr
    return oOrgMgr:GetNormalOrg(orgid)
end

function COrgMemberMgr:Init()
    self.m_mMember = {}
    self.m_mPostion = {}
end

function COrgMemberMgr:Load(mData)
    if not mData then
        return
    end
    self:SetData("leader", mData.leader)
    self:SetData("creater", mData.creater)
    local oOrgMgr = global.oOrgMgr
    if mData.member then
        for id,data in pairs(mData.member) do
            local pid = tonumber(id)
            local oMember = NewMember()
            oMember:Load(data)
            self.m_mMember[pid] = oMember
            self:_AddPosition(pid, oMember:GetPosition())
            oOrgMgr:SetPlayerOrgID(pid,self:GetInfo("orgid"))
        end
    end
end

function COrgMemberMgr:Save()
    local mData = {}
    mData.leader = self:GetData("leader")
    mData.creater = self:GetData("creater")
    local mMember = {}
    for id, oMember in pairs(self.m_mMember) do
        id = db_key(id)
        local data = oMember:Save()
        mMember[id] = data
    end
    mData.member = mMember
    return mData
end

function COrgMemberMgr:GetCreater()
    return self:GetData("creater",0)
end

function COrgMemberMgr:SetCreater(iPid)
    self:Dirty()
    self:SetData("creater",iPid)
end

function COrgMemberMgr:UnDirty()
    super(COrgMemberMgr).UnDirty(self)
    for _, oMember in pairs(self.m_mMember) do
        if oMember:IsDirty() then
            oMember:UnDirty()
        end
    end
end

function COrgMemberMgr:IsDirty()
    local bDirty = super(COrgMemberMgr).IsDirty(self)
    if bDirty then
        return true
    end
    for _, oMember in pairs(self.m_mMember) do
        if oMember:IsDirty() then
            return true
        end
    end
    return false
end

function COrgMemberMgr:GetMemIdsBylPos(lPos)
    local lMemID = {}
    for _,iPos in ipairs(lPos) do
        lMemID = list_combine(lMemID, self:GetMemIdsByPosition(iPos))
    end
    return lMemID
end

function COrgMemberMgr:GetMemIdsByPosition(iPos)
    return self.m_mPostion[iPos] or {}
end

function COrgMemberMgr:GetMemPosMap()
    return self.m_mPostion
end

function COrgMemberMgr:GetMember(pid)
    return self.m_mMember[pid]
end

function COrgMemberMgr:GetMemberMap()
    return self.m_mMember
end

function COrgMemberMgr:GetOrgMemList()
    local mPlayer = {}
    for _,oMember in pairs(self.m_mMember) do
        table.insert(mPlayer,oMember:GetPid())
    end
    return mPlayer
end

function COrgMemberMgr:UpdateOrgInfo(info)
    local oOrg = self:GetOrg()
    if not oOrg then return end
    info = info or {}
    info = oOrg:GetOrgUpdateInfo(info)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:UpdateOrgInfo(self:GetInfo("orgid"),{info=info})
end

function COrgMemberMgr:PushAchieveOrgLv()
    local oOrg = self:GetOrg()
    local iLevel = oOrg:GetLevel()
    for iPid,oMember in pairs(self.m_mMember) do
        for iGrade=1,5 do
            if iLevel >= iGrade then
                global.oOrgMgr:PushAchieve(iPid,string.format("公会等级大于等于%d级的数量",iGrade),{value=1})
            end
        end
    end
end

function COrgMemberMgr:AddMember(oMemInfo)
    local pid = oMemInfo:GetData("pid")
    local tArgs = {
        pid = oMemInfo:GetData("pid"),
        name = oMemInfo:GetData("name"),
        grade = oMemInfo:GetData("grade"),
        school = oMemInfo:GetData("school"),
        offer = oMemInfo:GetData("offer"),
        logout_time = oMemInfo:GetData("logout_time"),
        shape = oMemInfo:GetData("shape"),
        power = oMemInfo:GetData("power"),
        school_branch = oMemInfo:GetData("school_branch"),
    }

    self:Dirty()
    local oMember = NewMember()
    oMember:Create(pid, tArgs)
    self.m_mMember[pid] = oMember
    self:UpdateOrgInfo({memcnt=true})

    local oOrgMgr = global.oOrgMgr
    local sMsg = oOrgMgr:GetOrgText(2001, {role=tArgs.name})
    oOrgMgr:SendMsg2Org(sMsg, self:GetInfo("orgid"))
    oOrgMgr:CalAddOrgTime(pid,1)
end

function COrgMemberMgr:RemoveMember(pid)
    if self:IsLeader(pid) then
        -- 处理禅让
        return
    end
    self:Dirty()
    self:RemovePostion(pid)
    local oMember = self.m_mMember[pid]
    self.m_mMember[pid] = nil

    if oMember then
        local name = oMember:GetName()
        baseobj_delay_release(oMember)
        self:UpdateOrgInfo({memcnt=true})
        local oOrgMgr = global.oOrgMgr
        local sMsg = oOrgMgr:GetOrgText(2002, {role=name})
        oOrgMgr:SendMsg2Org(sMsg, self:GetInfo("orgid"))
    end
end

function COrgMemberMgr:ClearAllMemberActive()
    for iPid,oMem in pairs(self.m_mMember) do
        oMem:ClearActivePoint()
    end
end

function COrgMemberMgr:IsLeader(pid)
    return self:GetLeader() == pid
end

function COrgMemberMgr:IsSecond(iPid)
    local iPosition = self:GetPosition(iPid)
    if iPosition == orgdefines.ORG_POSITION.DEPUTY then
        return true
    end
    return false
end

function COrgMemberMgr:GetLeader()
    return self:GetData("leader")
end

function COrgMemberMgr:SetLeader(pid)
    local oOrgMgr = global.oOrgMgr
    self:SetData("leader", pid)
    self:SetPosition(pid, orgdefines.ORG_POSITION.LEADER)
    oOrgMgr:OnUpdatePosition(pid,orgdefines.ORG_POSITION.LEADER)
    local mMail, sMail = oOrgMgr:GetMailInfo(29)
    oOrgMgr:SendMail(0, sMail, pid, mMail)
    local oOrg = self:GetOrg()
    if oOrg then
        oOrgMgr:UpdateRankOrgInfo(oOrg)
    end
end

function COrgMemberMgr:IsDeputy(pid)
    return self:GetPosition(pid) == orgdefines.ORG_POSITION.DEPUTY
end

function COrgMemberMgr:GetMemberCnt()
    return table_count(self.m_mMember)
end

function COrgMemberMgr:SendAllMemMail(iMail)
    local oOrgMgr = global.oOrgMgr
    local mMail, sMail = oOrgMgr:GetMailInfo(iMail)
    for pid,_ in pairs(self.m_mMember) do
        oOrgMgr:SendMail(0, sMail, pid, mMail)
    end
end

function COrgMemberMgr:GetOnlineMemberCnt()
    local cnt = 0
    for pid,obj in pairs(self.m_mMember) do
        local oOrgMgr = global.oOrgMgr
        if oOrgMgr:GetOnlinePlayerByPid(pid) then
            cnt = cnt + 1
        end
    end
    return cnt
end

function COrgMemberMgr:GetPidOnPos(iPos)
    return self.m_mPostion[iPos] or {}
end

function COrgMemberMgr:GetJoinTime(pid)
    local oMember = self:GetMember(pid)
    if oMember then
        return oMember:GetJoinTime()
    end
end

function COrgMemberMgr:GetPosition(pid)
    local oMember = self:GetMember(pid)
    if oMember then
        return oMember:GetPosition()
    end
end

function COrgMemberMgr:_AddPosition(pid, iPos)
    if not self.m_mPostion[iPos] then
        self.m_mPostion[iPos] = {}
    end
    table.insert(self.m_mPostion[iPos], pid)
end

function COrgMemberMgr:_DelPosition(pid)
    if self.m_mPostion[iPos] then
        extend.Array.remove(self.m_mPostion[iPos], pid)
    end
end

function COrgMemberMgr:SetPosition(pid, iPos)
    self:Dirty()
    self:_AddPosition(pid, iPos)
    local oMember = self:GetMember(pid)
    if oMember then
        oMember:SetPosition(iPos)
        local oOrgMgr = global.oOrgMgr
        local sPosition = orgdefines.GetPositionName(iPos)
        local sMsg = oOrgMgr:GetOrgText(2003, {role=oMember:GetName(),position=sPosition})
        oOrgMgr:SendMsg2Org(sMsg, self:GetInfo("orgid"))
        if iPos == orgdefines.ORG_POSITION.LEADER then
            self:UpdateOrgInfo({leadername=true})
        end
        local oPlayer = oOrgMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            oPlayer:ShareChange()
        end
    end
end

function COrgMemberMgr:RemovePostion(pid)
    self:Dirty()
    local oMember = self:GetMember(pid)
    if oMember then
        local iPos = oMember:GetPosition()
        oMember:SetPosition(0)
        if self.m_mPostion[iPos] then
            extend.Array.remove(self.m_mPostion[iPos], pid)
        end
    end
end

function COrgMemberMgr:GetPositionCnt(iPos)
    local tPos = self.m_mPostion[iPos]
    if not tPos then
        return 0
    end
    return #tPos
end

function COrgMemberMgr:SyncMemberData(pid, mData)
    local oMember = self:GetMember(pid)
    if oMember then
        oMember:SyncData(mData)
    end
    if pid == self:GetLeader() then
        local oOrg = self:GetOrg()
        global.oOrgMgr:UpdateRankOrgInfo(oOrg)
        self:UpdateOrgInfo({leadername=true})
    end
end

function COrgMemberMgr:PackOrgMemList()
    local mNet = {}
    for iPid,oMem in pairs(self.m_mMember) do
        local m = oMem:PackOrgMemInfo()
        m.honor = self:GetOrgHonor(iPid)
        table.insert(mNet, m)
    end
    return mNet
end

function COrgMemberMgr:GetOrgPosition(pid)
    local oMem = self:GetMember(pid)
    if oMem then
        return oMem:GetPosition()
    end
    return 0
end

function COrgMemberMgr:GetOrgHonor(pid)
    return 0
end

function COrgMemberMgr:PackOrgMemInfo(pid)
    local mNet = {}
    local  oMem = self:GetMember(pid)
    mNet.position = self:GetOrgPosition(pid)
    mNet.honor = self:GetOrgHonor(pid)
    mNet.org_offer = oMem:GetHistoryOffer()
    mNet.huoyue = oMem:GetDayHuoYue()
    return mNet
end

function COrgMemberMgr:GetOrgWishList()
    local mData = {}
    for iPid,oMem in pairs(self.m_mMember) do
        if oMem:IsOrgWish() or oMem:IsOrgWishEquip() then
            table.insert(mData,oMem:PackOrgMemInfo())
        end
    end
    return mData
end

function COrgMemberMgr:OnlineMemCnt()
    local iCnt = 0
    for iPid,oMem in pairs(self.m_mMember) do
        if oMem:GetOnlineTime() == 0 then
            iCnt = iCnt + 1
        end
    end
    return iCnt
end

function COrgMemberMgr:ClearWish()
    for iPid,oMem in pairs(self.m_mMember) do
        if oMem:IsOrgWish() then
            oMem:ClearWish()
        end
        if oMem:IsOrgWishEquip() then
            oMem:ClearWishEquip()
        end
    end
end

function COrgMemberMgr:UpdateAllMemShare()
    local oOrgMgr = global.oOrgMgr
    for iPid,oMem in pairs(self.m_mMember) do
        local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:ShareChange()
        end
    end
end

function COrgMemberMgr:ValidAutoReplaceLeader()
    local iLeader = self:GetLeader()
    local oLeader = self:GetMember(iLeader)
    if self:GetMemberCnt() <= 1 then
        return false
    end
    if oLeader:GetOnlineTime() == 0 then
        return false
    end
    local iLimitTime = 7 * 3600 * 24
    local iLastOnline = oLeader:GetData("logout_time",0)
    local iNowTime = get_time()
    if iNowTime - iLastOnline < iLimitTime then
        return false
    end
    return true
end

function COrgMemberMgr:CheckAutoReplaceLeader()
    if not self:ValidAutoReplaceLeader() then
        return
    end
    local oOrg = self:GetOrg()
    local iLeader = self:GetLeader()
    local oLeader = self:GetMember(iLeader)
    local mAutoPlayer = {}
    for iPid,oMember in pairs(self.m_mMember) do
        if oMember:ValidAutoReplaceLeader() and not self:IsLeader(iPid) then
            table.insert(mAutoPlayer,{oMember:GetPosition(),oMember:GetHistoryOffer(),oMember:GetJoinTime(),iPid})
        end
    end
    if #mAutoPlayer <= 0 then
        return
    end
    local fSortFunc = function (tMem1,tMem2)
        if tMem1[1] ~= tMem2[1] then
            return tMem1[1] < tMem2[1]
        else
            if tMem1[2] ~= tMem2[2] then
                return tMem1[2] > tMem2[2]
            else
                if tMem1[3] ~= tMem2[3] then
                    return tMem1[3] < tMem2[3]
                else
                    return tMem1[4] < tMem2[4]
                end
            end
        end
    end
    table.sort(mAutoPlayer,fSortFunc)
    local mData = mAutoPlayer[1]
    local iPosition,iOrgOffer,iJoinTime,iPid = table.unpack(mData)
    oOrg:GiveLeader2Other(iLeader, iPid)
    local oMember = self:GetMember(iPid)
    local oOrgMgr = global.oOrgMgr
    local sText = oOrgMgr:GetOrgText(4005,{leader = oLeader:GetName(),member = oMember:GetName()})
    oOrgMgr:SendOrgChat(sText,self:GetInfo("orgid"),{pid = 0})

    local sText = oOrgMgr:GetOrgLog(1018,{oldleader = oLeader:GetName(),newleader = oMember:GetName()})
    oOrg:AddLog(0,sText)
end

function COrgMemberMgr:ClearLowActiveMem()
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsOrgWarOpen() then
        return
    end
    local iLeader = self:GetLeader()
    local iLimitTime = 2*24*3600
    local mDel = {}
    for iPid,oMember in pairs(self.m_mMember) do
        local iLogoutTime = oMember:GetOnlineTime()
        if iPid ~=iLeader and oMember:GetPosition() == orgdefines.ORG_POSITION.MEMBER and
         iLogoutTime ~= 0 and get_time() - iLogoutTime > iLimitTime then
            table.insert(mDel,iPid)
        end
    end
    local iOrgID = self:GetInfo("orgid")
    for _,iPid in pairs(mDel) do
        local mMail, sMail = oOrgMgr:GetMailInfo(47)
        oOrgMgr:SendMail(0, sMail, iPid, mMail)
        oOrgMgr:OnKickMember(iPid)
        oOrgMgr:LeaveOrg(iPid, iOrgID)
    end
end

function COrgMemberMgr:SyncOrgTitle()
    local oOrgMgr = global.oOrgMgr
    local iOrgID = self:GetInfo("orgid")
    for iPid,oMember in pairs(self.m_mMember) do
        oOrgMgr:CheckOrgTitle(iOrgID,iPid)
    end
end

function NewMember(...)
    return CMember:New(...)
end

CMember = {}
CMember.__index = CMember
inherit(CMember, datactrl.CDataCtrl)

function CMember:New()
    local o = super(CMember).New(self)
    return o
end

function CMember:Create(pid, tArgs)
    self:SetData("pid", pid)
    self:SetData("name", tArgs["name"])
    self:SetData("grade", tArgs["grade"])
    self:SetData("school", tArgs["school"])
    self:SetData("school_branch", tArgs["school_branch"])
    self:SetData("shape", tArgs["shape"])
    self:SetData("power", tArgs["power"])
    self:SetData("jointime", get_time())
    self:SetData("position", orgdefines.ORG_POSITION.MEMBER)
    self:SetData("logout_time", tArgs["logout_time"])
    self:SetData("banchat_time",0)
    self:SetData("offer", tArgs["offer"] or 0)
    self:SetData("org_offer", tArgs["org_offer"] or 0)
end

function CMember:Load(mData)
    if not mData then
        return
    end
    local iPosition = math.min(orgdefines.ORG_POSITION.MEMBER,mData.position)
    self:SetData("pid", mData.pid)
    self:SetData("name", mData.name)
    self:SetData("grade", mData.grade)
    self:SetData("school", mData.school)
    self:SetData("school_branch", mData.school_branch)
    self:SetData("jointime", mData.jointime)
    self:SetData("position", iPosition)
    self:SetData("logout_time", mData.logout_time)
    self:SetData("shape", mData.shape)
    self:SetData("power", mData.power)
    self:SetData("banchat_time", mData.banchat_time)
    self:SetData("org_build_time",mData.org_build_time)
    self:SetData("org_wish",mData.org_wish)
    self:SetData("org_wish_equip",mData.org_wish_equip)
    self:SetData("partner_item",mData.partner_item)
    self:SetData("equip_item",mData.equip_item)
    self:SetData("org_offer",mData.org_offer)
    self:SetData("offer",mData.offer)
    self:SetData("fb_boss",mData.fb_boss or 0)
end

function CMember:Save()
    local mData = {}
    mData.pid = self:GetData("pid")
    mData.name = self:GetData("name")
    mData.grade = self:GetData("grade")
    mData.school = self:GetData("school")
    mData.school_branch = self:GetData("school_branch")
    mData.jointime = self:GetData("jointime")
    mData.position = self:GetData("position")
    mData.logout_time = self:GetData("logout_time")
    mData.shape = self:GetData("shape")
    mData.power = self:GetData("power")
    mData.banchat_time = self:GetData("banchat_time")
    mData.org_build_time = self:GetData("org_build_time")
    mData.org_wish = self:GetData("org_wish")
    mData.org_wish_equip = self:GetData("org_wish_equip")
    mData.partner_item = self:GetData("partner_item")
    mData.equip_item = self:GetData("equip_item")
    mData.org_offer = self:GetData("org_offer")
    mData.offer = self:GetData("offer")
    mData.fb_boss = self:GetData("fb_boss",0)
    return mData
end

function CMember:GetPid()
    return self:GetData("pid")
end

function CMember:GetPower()
    return self:GetData("power")
end

function CMember:GetShape()
    return self:GetData("shape")
end

function CMember:GetName()
    return self:GetData("name")
end

function CMember:GetGrade()
    return self:GetData("grade")
end

function CMember:GetSchool()
    return self:GetData("school")
end

function CMember:GetSchoolBranch()
    return self:GetData("school_branch")
end

function CMember:GetHistoryOffer()
    return self:GetData("org_offer", 0)
end

function CMember:GetJoinTime()
    return self:GetData("jointime")
end

function CMember:GetPosition()
    local position = self:GetData("position")
    if not position or position == 0 then
        return orgdefines.ORG_POSITION.MEMBER
    end
    return self:GetData("position")
end

function CMember:SetPosition(iPos)
    self:SetData("position", iPos)
end

function CMember:SyncData(mData)
    for k,v in pairs(mData) do
        if self:GetData(k) then
            self:SetData(k, v)
        end
    end
end

function CMember:PackOrgMemInfo()
    local mNet = {}
    mNet.pid = self:GetPid()
    mNet.name = self:GetName()
    mNet.grade = self:GetGrade()
    mNet.school = self:GetSchool()
    mNet.school_branch = self:GetSchoolBranch()
    mNet.position = self:GetPosition()
    mNet.offline = self:GetOnlineTime()
    mNet.power = self:GetPower()
    mNet.shape = self:GetShape()
    mNet.org_wish = self:GetOrgWishData()
    mNet.org_wish_equip = self:GetOrgWishEquipData()
    mNet.active_point = self:GetActivePoint()
    mNet.org_offer = self:GetHistoryOffer()
    mNet.has_team = self:HasTeam()
    mNet.inbanchat = self:InBanChat()
    return mNet
end

function CMember:GetSimpleInfo()
    local mData = {
        pid = self:GetPid(),
        fb_boss = self:GetData("fb_boss")
    }
    return mData
end

function CMember:HasTeam()
    local iPid = self:GetPid()
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer or (oPlayer and oPlayer:HasTeam()) then
        return 1
    end
    return 0
end

function CMember:GetOnlineTime()
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:GetOnlinePlayerByPid(self:GetPid()) then
        return 0
    end
    return self:GetData("logout_time")
end

function CMember:BanChat()
    self:SetData("banchat_time", get_time() + 24*3600 )
end

function CMember:UnBanChat()
    self:SetData("banchat_time", 0)
end

function CMember:InBanChat()
    local iBanChatTime = self:GetData("banchat_time",0)
    local iNowTime = get_time()
    if iBanChatTime > iNowTime then
        return true
    end
    return false
end

function CMember:CheckBanChat()
    local iPid = self:GetPid()
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    local iBanChatTime = self:GetData("banchat_time",0)
    local iNowTime = get_time()
    if iBanChatTime > iNowTime then
        local iRestTime = iBanChatTime - iNowTime
        if oPlayer then
            oPlayer:Notify(string.format("您已被禁言，请在%s过尝试。",get_second2string(iRestTime)))
        end
        return false
    end
    return true
end

function CMember:IsOrgWish()
    if self:GetData("org_wish") then
        return true
    end
    return false
end

function CMember:GetOrgWishData()
    return self:GetData("org_wish",{})
end

function CMember:RefreshOrgWish(mData)
    self:Dirty()
    local mWishData = self:GetData("org_wish",{})
    mWishData.partner_chip = mData.partner_chip or mWishData.partner_chip
    mWishData.partner_type = mData.partner_type or mWishData.partner_type
    mWishData.sum_cnt = mData.sum_cnt or mWishData.sum_cnt
    mWishData.gain_cnt = mData.gain_cnt or mWishData.gain_cnt
    self:SetData("org_wish",mWishData)
end

function CMember:ClearWish()
    self:Dirty()
    self:SetData("org_wish",nil)
end

function CMember:IsDoneWish()
    local mWishData = self:GetOrgWishData()
    local iGainCnt = mWishData["gain_cnt"]
    local iSumCnt = mWishData["sum_cnt"]
    if iGainCnt > 0 and iGainCnt >= iSumCnt then
        return true
    end
    return false
end

function CMember:GetWishPartnerItem()
    local mWishData = self:GetOrgWishData()
    return mWishData["partner_chip"]
end

function CMember:AddPartnerItem(mItemData)
    self:Dirty()
    local mData = self:GetData("partner_item",{})
    local iDayNo = get_dayno()
    iDayNo = tostring(iDayNo)
    local mItem = mData[iDayNo] or {}
    table.insert(mItem,{
        item = mItemData.item,
        msg = mItemData.msg
    })
    mData[iDayNo] = mItem
    self:SetData("partner_item",mData)
end

function CMember:AddWishPartnerItem(oPlayer)
    local oOrgMgr = global.oOrgMgr
    local mWishData = self:GetOrgWishData()
    local iPartnerItem = mWishData["partner_chip"]
    local iPartnerType = mWishData["partner_type"]
    local iGainCnt = mWishData["gain_cnt"]
    mWishData["gain_cnt"] = iGainCnt + 1
    self:SetData("org_wish",mWishData)
    local mPartnerData = oOrgMgr:GetPartnerData(iPartnerType)
    local mItem = {iPartnerItem,1}
    local mData = {
        item = mItem,
        msg = string.format("%s给予你%s伙伴碎片",oPlayer:GetName(),mPartnerData["name"])
    }
    self:AddPartnerItem(mData)
end

function CMember:GiveWishItem()
    local iPid = self:GetData("pid")
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local mPartnerItem = self:GetData("partner_item",{})
    if table_count(mPartnerItem) <= 0 then
        return
    end
    self:Dirty()
    local mRomoteItem = {}
    for iDayNo,mItemData in pairs(mPartnerItem) do
        for _,mWish in pairs(mItemData) do
            local mItem = mWish["item"]
            local sMsg = mWish["msg"]
            oPlayer:Notify(sMsg)
            table.insert(mRomoteItem,mItem)
        end
    end
    self:SetData("partner_item",nil)
    if #mRomoteItem > 0 then
        oOrgMgr:GiveItem(iPid,mRomoteItem,"公会许愿", {cancel_tip=1})
    end
end

function CMember:GetActivePoint()
    return self:GetData("active_point",0)
end

function CMember:AddActivePoint(iPoint)
    local iActivePoint = self:GetData("active_point",0)
    iActivePoint = iActivePoint + iPoint
    self:SetData("active_point",iActivePoint)
end

function CMember:ClearActivePoint()
    self:SetData("active_point",0)
end

function CMember:OnLeaveOrg(iOrgID)
    local oOrgMgr = global.oOrgMgr
    local mPartnerItem = self:GetData("partner_item",{})
    local mEquipData = self:GetData("equip_item",{})
    self:Dirty()
    local mGiveItem = {}
    for _,mItemData in pairs(mPartnerItem) do
        for _,mWish in pairs(mItemData) do
            table.insert(mGiveItem,mWish["item"])
        end
    end
    for _,mItemData in pairs(mEquipData) do
        for _,mWish in pairs(mItemData) do
            table.insert(mGiveItem,mWish["item"])
        end
    end
    interactive.Send(".world", "org", "OnLeaveOrg", {
        orgid = iOrgID,
        pid = self:GetData("pid"),
        item = mGiveItem,
    })
end

function CMember:RewardOrgOffer(iOffer)
    self:Dirty()
    local iNowOffer = self:GetData("org_offer",0)
    iNowOffer = iNowOffer + iOffer
    self:SetData("org_offer",iNowOffer)
end

function CMember:ValidAutoReplaceLeader()
    local iJoinDay = tonumber(res["daobiao"]["global"]["org_auto_replace_leader_day"]["value"])
    local iOrgOffer = tonumber(res["daobiao"]["global"]["org_auto_replace_leader_offer"]["value"])
    local iJoinTime = self:GetJoinTime()
    local iNowTime = get_time()
    local iLimitTime = iJoinDay * 3600 * 24
    if iNowTime - iJoinTime < iLimitTime then
        return false
    end
    if self:GetHistoryOffer() <= iOrgOffer then
        return false
    end
    local oOrgMgr = global.oOrgMgr
    local iPid = self:GetData("pid")
    local iLastOnline = self:GetData("logout_time")
    if iNowTime - iLastOnline > 7 * 3600 * 24 and not oOrgMgr:GetOnlinePlayerByPid(iPid) then
        return false
    end
    return true
end

function CMember:SendTips(sTip)
    local oOrgMgr = global.oOrgMgr
    local iPid = self:GetData("pid")
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CLeaveOrgTips",{stip=sTip})
    end
end

--装备许愿开始
function CMember:IsOrgWishEquip()
    if self:GetData("org_wish_equip") then
        return true
    end
    return false
end

function CMember:GetOrgWishEquipData()
    return self:GetData("org_wish_equip",{})
end

function CMember:GetWishEquipItem()
    local mWishData = self:GetOrgWishEquipData()
    return mWishData["sid"]
end

function CMember:RefreshOrgWishEquip(mData)
    self:Dirty()
    local mWishItemData = self:GetData("org_wish_equip",{})
    mWishItemData.sid = mData.sid or mWishItemData.sid
    mWishItemData.gain_cnt = mData.gain_cnt or mWishItemData.gain_cnt
    mWishItemData.sum_cnt = mData.sum_cnt or mWishItemData.sum_cnt
    self:SetData("org_wish_equip",mWishItemData)
end

function CMember:ClearWishEquip()
    self:Dirty()
    self:SetData("org_wish_equip",nil)
end

function CMember:IsDoneEquipWish()
    local mWishData = self:GetOrgWishEquipData()
    local iGainCnt = mWishData["gain_cnt"]
    local iSumCnt = mWishData["sum_cnt"]
    if iGainCnt > 0 and iGainCnt >= iSumCnt then
        return true
    end
    return false
end

function CMember:AddEquipItem(mItemData)
    self:Dirty()
    local mData = self:GetData("equip_item",{})
    local iDayNo = get_dayno()
    iDayNo = tostring(iDayNo)
    local mItem = mData[iDayNo] or {}
    table.insert(mItem,{
        item = mItemData.item,
        msg = mItemData.msg
    })
    mData[iDayNo] = mItem
    self:SetData("equip_item",mData)
end

function CMember:AddWishEquip(oPlayer)
    local oPubMgr = global.oPubMgr
    local mWishEquipData = self:GetOrgWishEquipData()
    local sid = mWishEquipData["sid"]
    local iGainCnt = mWishEquipData["gain_cnt"]
    mWishEquipData["gain_cnt"] = iGainCnt + 1
    self:SetData("org_wish_equip",mWishEquipData)
    local oDBItem = res["daobiao"]["item"][sid]
    local mItem = {sid,1}
    local mData = {
        item = mItem,
        msg = string.format("%s给予你%s",oPlayer:GetName(),oDBItem["name"])
    }
    self:AddEquipItem(mData)
end

function CMember:GiveWishEquip()
    local iPid = self:GetData("pid")
    local oPlayer = global.oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local mEquipItem = self:GetData("equip_item",{})
    if table_count(mEquipItem) <= 0 then
        return
    end
    self:Dirty()
    local mRomoteItem = {}
    for iDayNo,mItemData in pairs(mEquipItem) do
        for _,mWish in pairs(mItemData) do
            local mItem = mWish["item"]
            local sMsg = mWish["msg"]
            oPlayer:Notify(sMsg)
            table.insert(mRomoteItem,mItem)
        end
    end
    self:SetData("equip_item",nil)
    self:RewardWishEquip(mRomoteItem)
end

function CMember:RewardWishEquip(mRomoteItem)
    local iPid = self:GetData("pid")
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    oOrgMgr:GiveItem(iPid,mRomoteItem,"装备许愿", {cancel_tip=1})
end

--装备许愿结束

function CMember:Lock(sEvent,iDelay)
    local mLockInfo = self.m_LockInfo
    if not mLockInfo then
        mLockInfo = {}
    end
    mLockInfo[sEvent] = get_time() + iDelay
    self.m_LockInfo = mLockInfo
end

function CMember:InLock(sEvent)
    local mLockInfo = self.m_LockInfo or {}
    local iTime = mLockInfo[sEvent]
    if iTime and iTime > get_time() then
        return true
    end
    return false
end

function CMember:Unlock(sEvent)
    local mLockInfo = self.m_LockInfo
    if mLockInfo then
        mLockInfo[sEvent] = nil
    end
end