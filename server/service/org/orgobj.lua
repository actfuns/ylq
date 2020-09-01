--import module
local global = require "global"
local interactive = require "base.interactive"
local extend = require "base.extend"
local net = require "base.net"
local res = require "base.res"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))
local orgbase = import(service_path("orgbase"))
local orgmember = import(service_path("orgmember"))
local orglog = import(service_path("orglog"))
local orgapply = import(service_path("orgapply"))
local orgdefines = import(service_path("orgdefines"))


function NewOrg(...)
    return COrg:New(...)
end

OrgHelperFunc = {}

function OrgHelperFunc.orgid(oOrg)
    return oOrg:OrgID()
end

function OrgHelperFunc.name(oOrg)
    return oOrg:GetName()
end

function OrgHelperFunc.level(oOrg)
    return oOrg:GetLevel()
end

function OrgHelperFunc.leadername(oOrg)
    return oOrg:GetLeaderName()
end

function OrgHelperFunc.memcnt(oOrg)
    return oOrg:GetMemberCnt()
end

function OrgHelperFunc.sflag(oOrg)
    return oOrg:GetSFlag()
end

function OrgHelperFunc.flagbgid(oOrg)
    return oOrg:GetFlagBgID()
end

function OrgHelperFunc.aim(oOrg)
    return oOrg:GetAim()
end

function OrgHelperFunc.cash(oOrg)
    return oOrg:GetCash()
end

function OrgHelperFunc.exp(oOrg)
    return oOrg:GetExp()
end

function OrgHelperFunc.rank(oOrg)
    return oOrg:GetRank()
end

function OrgHelperFunc.prestige(oOrg)
    return oOrg:GetPrestige()
end

function OrgHelperFunc.sign_degree(oOrg)
    return oOrg:GetSignDegree()
end

function OrgHelperFunc.red_packet(oOrg)
    return oOrg:GetOpenRedPacket()
end

function OrgHelperFunc.active_point(oOrg)
    return oOrg:GetActivePoint()
end

function OrgHelperFunc.is_open_red_packet(oOrg)
    return oOrg:IsOpenRedPacket()
end

function OrgHelperFunc.apply_count(oOrg)
    return oOrg.m_oApplyMgr:GetApplyCnt()
end

function OrgHelperFunc.red_packet_rest(oOrg)
    return oOrg.m_oBaseMgr:GetRedPacketRest()
end

function OrgHelperFunc.online_count(oOrg)
    return oOrg:GetOnlineMemberCnt()
end

function OrgHelperFunc.mail_rest(oOrg)
    return oOrg:GetMailRest()
end

function OrgHelperFunc.spread_endtime(oOrg)
    return oOrg.m_oBaseMgr:GetData("spread_endtime")
end

COrg = {}
COrg.__index = COrg
inherit(COrg, datactrl.CDataCtrl)

function COrg:New(orgid)
    local o = super(COrg).New(self)
    o.m_iID = orgid
    o.m_bLoading = true
    o:Init()
    return o
end

function COrg:Init()
    self.m_oBaseMgr = orgbase.NewBaseMgr(self:OrgID())
    self.m_oMemberMgr = orgmember.NewMemberMgr(self:OrgID())
    self.m_oLogMgr = orglog.NewLogMgr(self:OrgID())
    self.m_oApplyMgr = orgapply.NewApplyMgr(self:OrgID())
end

function COrg:Create(sName, tArgs)
    self:SetData("name", sName)
    self.m_oBaseMgr:Create(tArgs)
end

function COrg:Release()
    baseobj_safe_release(self.m_oBaseMgr)
    baseobj_safe_release(self.m_oMemberMgr)
    baseobj_safe_release(self.m_oLogMgr)
    baseobj_safe_release(self.m_oApplyMgr)

    super(COrg).Release(self)
end

function COrg:LoadDoneInit()

end

function COrg:ConfigSaveFunc()
    local id = self:OrgID()
    self:ApplySave(function ()
        local oOrgMgr = global.oOrgMgr
        local obj = oOrgMgr:GetNormalOrg(id)
        if not obj then
            record.warning(string.format("org %d save err: no obj", id))
            return
        end
        obj:_CheckSaveDb()
    end)
end

function COrg:_CheckSaveDb()
    assert(not is_release(self), string.format("org %d save err: has release", self:OrgID()))
    self:SaveDb()
end

function COrg:SaveDb()
    local iOrgID = self:OrgID()
    if self:IsDirty() then
        local mData = {orgid = self:OrgID(), data = self:Save()}
        gamedb.SaveDb(iOrgID,"common", "SaveDb",{module = "orgdb",cmd = "SaveOrg",data = mData})
        self:UnDirty()
    end

    if self.m_oBaseMgr:IsDirty() then
        local mData = {orgid = self:OrgID(), data = self.m_oBaseMgr:Save()}
        gamedb.SaveDb(iOrgID,"common", "SaveDb",{module = "orgdb",cmd = "SaveOrgBase",data = mData})
        self.m_oBaseMgr:UnDirty()
    end

    if self.m_oMemberMgr:IsDirty() then
        local mData = {orgid = self:OrgID(), data = self.m_oMemberMgr:Save()}
        gamedb.SaveDb(iOrgID,"common", "SaveDb",{module = "orgdb",cmd = "SaveOrgMember",data = mData})
        self.m_oMemberMgr:UnDirty()
    end

    if self.m_oLogMgr:IsDirty() then
        local mData = {orgid = self:OrgID(), data = self.m_oLogMgr:Save()}
        gamedb.SaveDb(iOrgID,"common", "SaveDb",{module = "orgdb",cmd = "SaveOrgLog",data = mData})
        self.m_oLogMgr:UnDirty()
    end

    if self.m_oApplyMgr:IsDirty() then
        local mData = {orgid = self:OrgID(), data = self.m_oApplyMgr:Save()}
        gamedb.SaveDb(iOrgID,"common", "SaveDb",{module = "orgdb",cmd = "SaveOrgApply",data = mData})
        self.m_oApplyMgr:UnDirty()
    end

end

function COrg:GetAllSaveData()
    local mData = {}
    mData.orgid = self:OrgID()
    mData.name = self:GetName()
    mData.base_info = self.m_oBaseMgr:Save()
    mData.member_info = self.m_oMemberMgr:Save()
    mData.log_info = self.m_oLogMgr:Save()
    mData.apply_info = self.m_oApplyMgr:Save()
    return mData
end

function COrg:LoadAll(data)
    if not data then
        return
    end
    self:Load(data)
    self.m_oBaseMgr:Load(data.base_info)
    self.m_oMemberMgr:Load(data.member_info)
    self.m_oLogMgr:Load(data.log_info)
    self.m_oApplyMgr:Load(data.apply_info)
end

function COrg:Load(m)
    m = m or {}
    self:SetData("name", m.name or string.format("公会%s", self:OrgID()))
end

function COrg:Save()
    local m = {}
    m.name = self:GetData("name")
    return m
end

function COrg:NewHour(iDay,iHour)
    --检查申请过期
    self:CheckApplyOverDue()
    if iHour == 0 then
        self.m_oMemberMgr:ClearWish()
        self.m_oBaseMgr:ClearRedPacket()
        self.m_oBaseMgr:ClearSignDegree()
        self.m_oMemberMgr:CheckAutoReplaceLeader()
        self.m_oMemberMgr:ClearLowActiveMem()
    end
    if iDay == 1 and iHour == 0 then
        self.m_oBaseMgr:CheckDownLevel()
        self.m_oMemberMgr:ClearAllMemberActive()
    end
end

function COrg:OrgID()
    return self.m_iID
end

function COrg:GetName()
    return self:GetData("name")
end

function COrg:GetCash()
    return self.m_oBaseMgr:GetCash()
end

function COrg:AddCash(iCash,sReason,mArgs)
    self.m_oBaseMgr:AddCash(iCash,sReason,mArgs)
end

function COrg:ValidCash(iCash,mArgs)
    mArgs = mArgs or {}
    return self.m_oBaseMgr:ValidCash(iCash,mArgs)
end

function COrg:ResumeCash(iCash,sReason,mArgs)
    mArgs = mArgs or {}
    self.m_oBaseMgr:ResumeCash(iCash,sReason,mArgs)
end

function COrg:GetExp()
    return self.m_oBaseMgr:GetExp()
end

function COrg:AddExp(iExp,sReason,mArgs)
    self.m_oBaseMgr:AddExp(iExp,sReason,mArgs)
end

function COrg:ValidExp(iExp,mArgs)
    return self.m_oBaseMgr:ValidExp(iExp,mArgs)
end

function COrg:ResumeExp(iExp,sReason,mArgs)
    mArgs = mArgs or {}
    self.m_oBaseMgr:ResumeExp(iExp,sReason,mArgs)
end

function COrg:GetPrestige()
    return self.m_oBaseMgr:GetPrestige()
end

function COrg:AddPrestige(iAdd,sReason,mArgs)
    self.m_oBaseMgr:AddPrestige(iAdd,sReason,mArgs)
end

function COrg:GetRank()
    return self.m_oBaseMgr:GetRank()
end

function COrg:SetRank(iRank)
    self.m_oBaseMgr:SetRank(iRank)
end

function COrg:SetPowerLimit(powerlimit)
    self.m_oBaseMgr:SetPowerLimit(powerlimit)
end

function COrg:SetNeedAllow(needallow)
    self.m_oBaseMgr:SetNeedAllow(needallow)
end

function COrg:GetPowerLimit()
    return self.m_oBaseMgr:GetPowerLimit()
end

function COrg:GetNeedAllow()
    return self.m_oBaseMgr:GetNeedAllow()
end

function COrg:SetSFlag(sflag)
    self.m_oBaseMgr:SetSFlag(sflag)
end

function COrg:SetFlagBgID(flagbgid)
    self.m_oBaseMgr:SetFlagBgID(flagbgid)
end

function COrg:GetSFlag()
    return self.m_oBaseMgr:GetSFlag()
end

function COrg:GetFlagBgID()
    return self.m_oBaseMgr:GetFlagBgID()
end

function COrg:GetAim()
    return self.m_oBaseMgr:GetAim()
end

function COrg:SetAim(aim)
    self.m_oBaseMgr:SetAim(aim)
end

function COrg:GetLevel()
    return self.m_oBaseMgr:GetLevel()
end

function COrg:GetLeaderID()
    return self.m_oMemberMgr:GetLeader()
end

function COrg:IsLeader(pid)
    return self.m_oMemberMgr:IsLeader(pid)
end

function COrg:IsSecond(iPid)
    return self.m_oMemberMgr:IsSecond(iPid)
end

function COrg:SetLeader(pid)
    self.m_oMemberMgr:SetLeader(pid)
end

function COrg:SetCreater(pid)
    self.m_oMemberMgr:SetCreater(pid)
end

function COrg:GetCreater()
    return self.m_oMemberMgr:GetCreater()
end

function COrg:UpdateAllMemShare()
    self.m_oMemberMgr:UpdateAllMemShare()
end

function COrg:GetLeaderName()
    local iLeader = self:GetLeaderID()
    local oMemInfo = self.m_oMemberMgr:GetMember(iLeader)
    return oMemInfo:GetName()
end

function COrg:GetLeaderSchool()
    local iLeader = self:GetLeaderID()
    local oMemInfo = self.m_oMemberMgr:GetMember(iLeader)
    return oMemInfo:GetSchool()
end

function COrg:AddApply(oPlayer, iType)
    self.m_oApplyMgr:AddApply(oPlayer, iType)
end

function COrg:GetApplyCnt()
    return self.m_oApplyMgr:GetApplyCnt()
end

function COrg:RemoveApply(pid)
    self.m_oApplyMgr:RemoveApply(pid)
end

function COrg:CheckApplyOverDue()
    self.m_oApplyMgr:CheckApplyOverDue()
end

function COrg:RemoveAllApply()
    self.m_oApplyMgr:RemoveAllApply()
end

function COrg:GetApplyInfo(pid)
    return self.m_oApplyMgr:GetApplyInfo(pid)
end

function COrg:GetApplyListInfo()
    return self.m_oApplyMgr:GetApplyListInfo()
end

function COrg:HasApply(pid)
    if self.m_oApplyMgr:GetApplyInfo(pid) then
        return 1
    else
        return 0
    end
end

function COrg:AcceptMember(oMemInfo)
    if self:GetMemberCnt() < self:GetMaxMemberCnt() then
        self:AddMember(oMemInfo)
        self:RemoveApply(oMemInfo:GetPid())
        return true
    end
    return false
end

function COrg:AddMember(oMemInfo,iPosition)
    self.m_oMemberMgr:AddMember(oMemInfo)
    local mData = oMemInfo:PackOrgApplyInfo()
    mData.position = iPosition or orgdefines.ORG_POSITION.MEMBER
end

function COrg:RemoveMember(pid)
    if self:IsMember(pid) then
        self.m_oMemberMgr:RemoveMember(pid)
    end
end

function COrg:IsMember(pid)
    if self:GetMember(pid) then return true end

    return false
end

function COrg:GetMember(pid)
    return self.m_oMemberMgr:GetMember(pid)
end

function COrg:GetMemberCnt()
    return self.m_oMemberMgr:GetMemberCnt()
end

function COrg:GetMaxMemberCnt()
    local iLevel = self:GetLevel()
    local iMaxCnt = res["daobiao"]["org"]["org_grade"][iLevel]["max_member"]
    return iMaxCnt
end

function COrg:GetOnlineMemberCnt()
     return self.m_oMemberMgr:GetOnlineMemberCnt()
 end

function COrg:SyncMemberData(pid, mData)
    self.m_oMemberMgr:SyncMemberData(pid, mData)
end

function COrg:SyncApplyData(iPid, mData)
    self.m_oApplyMgr:SyncApplyData(iPid, mData)
end

function COrg:SetPosition(pid, iPos)
    self.m_oMemberMgr:SetPosition(pid, iPos)
    global.oOrgMgr:OnUpdatePosition(pid,iPos)
end

function COrg:RemovePosition(pid)
    self.m_oMemberMgr:RemovePostion(pid)
    global.oOrgMgr:OnUpdatePosition(pid,0)
end

function COrg:GetPositionCnt(iPos)
    return self.m_oMemberMgr:GetPositionCnt(iPos)
end

function COrg:GetPosMaxCnt(iPos)
    if iPos == orgdefines.ORG_POSITION.LEADER then
        return 1
    elseif iPos == orgdefines.ORG_POSITION.DEPUTY then
        return 2
    elseif iPos == orgdefines.ORG_POSITION.ELITE then
        return 20
    elseif iPos == orgdefines.ORG_POSITION.FINE then
        return self:GetMaxMemberCnt()
    elseif iPos == orgdefines.ORG_POSITION.MEMBER then
        return self:GetMaxMemberCnt()
    end
    return  0
end

function COrg:GetPosition(iPid)
    return self.m_oMemberMgr:GetPosition(iPid)
end

function COrg:GetJoinTime(iPid)
    return self.m_oMemberMgr:GetJoinTime(iPid)
end

function COrg:GetOrgHonor(iPid)
    return self.m_oMemberMgr:GetOrgHonor(iPid)
end

function COrg:PackOrgInfo()
    local mNet = {}
    mNet.orgid = self:OrgID()
    mNet.name = self:GetName()
    mNet.level = self:GetLevel()
    mNet.leadername = self:GetLeaderName()
    mNet.memcnt = self:GetMemberCnt()
    mNet.sflag = self:GetSFlag()
    mNet.flagbgid = self:GetFlagBgID()
    mNet.aim = self:GetAim()
    mNet.cash = self:GetCash()
    mNet.exp = self:GetExp()
    mNet.rank = self:GetRank()
    mNet.prestige = self:GetPrestige()
    mNet.sign_degree = self:GetSignDegree()
    mNet.active_point = self:GetActivePoint()
    mNet.red_packet = self:GetOpenRedPacket()
    mNet.apply_count = self.m_oApplyMgr:GetApplyCnt()
    mNet.online_count = self:GetOnlineMemberCnt()
    mNet.is_open_red_packet = self:IsOpenRedPacket()
    mNet.red_packet_rest = self:GetRedPacketRest()
    mNet.mail_rest = self:GetMailRest()
    mNet.spread_endtime = self.m_oBaseMgr:GetData("spread_endtime")
    return mNet
end

function COrg:PackOrgListInfo(iPid,info)
    local mNet = {}
    mNet.info = info or self:PackOrgInfo()
    mNet.hasapply = self:HasApply(iPid)
    mNet.powerlimit = self:GetPowerLimit()
    mNet.needallow = self:GetNeedAllow()
    return mNet
end

function COrg:GetSpreadFlag()
    if self.m_oBaseMgr:GetData("spread_endtime",0) > get_time() then
        return 1
    end
    return 0
end

function COrg:PackOrgMemList()
    return self.m_oMemberMgr:PackOrgMemList()
end

function COrg:SendAllMemMail(iMail)
    self.m_oMemberMgr:SendAllMemMail(iMail)
end

function COrg:PushAchieveOrgLv()
    self.m_oMemberMgr:PushAchieveOrgLv()
end

function COrg:GetOrgMemList()
    return self.m_oMemberMgr:GetOrgMemList()
end

function COrg:PackOrgApplyInfo()
    local info = self.m_oApplyMgr:PackApplyInfo()
    info.powerlimit = self:GetPowerLimit()
    info.needallow = self:GetNeedAllow()
    return info
end

function COrg:HasDealJoinAuth(iPid)
    local position = self:GetPosition(iPid)
    local mData = res["daobiao"]["org"]["member_limit"][position]
    if not mData then return false end

    return mData["agree_reject_join"] == 1
end

function COrg:HasKickAuth(iPid, iKickPid)
    local position = self:GetPosition(iPid)
    local iPos = self:GetPosition(iKickPid)
    local mData = res["daobiao"]["org"]["member_limit"][position]
    if not mData then return false end

    local ret = extend.Array.find(mData["del_pos"], iPos)
    if not ret then return false end

    return  true
end

function COrg:HasMailAuth(iPid)
    local position = self:GetPosition(iPid)
    local mData = res["daobiao"]["org"]["member_limit"][position]
    if not mData then return false end

    return mData["mail"] == 1
end

function COrg:HasUpdateAimAuth(iPid)
    local position = self:GetPosition(iPid)
    local mData = res["daobiao"]["org"]["member_limit"][position]
    if not mData then return false end

    return mData["edit_aim"] == 1
end

function COrg:HasUpdateFlagAuth(iPid)
    local position = self:GetPosition(iPid)
    local mData = res["daobiao"]["org"]["member_limit"][position]
    if not mData then return false end
    return mData["edit_flag"] == 1
end

function COrg:HasSetPosAuth(iPid, iPos)
    local position = self:GetPosition(iPid)
    local mData = res["daobiao"]["org"]["member_limit"][position]
    if not mData then return false end

    if position >= iPos then return false end

    local ret = extend.Array.find(mData["authorize_pos"], iPos)
    if not ret then return false end
    return  true
end

function COrg:ValidKick(iPid)
    local position = self:GetPosition(iPid)
    local iLevel = self:GetLevel()
    local mData = res["daobiao"]["org"]["org_grade"][iLevel]
    local iLimit = 0
    if position == orgdefines.ORG_POSITION.LEADER then
        iLimit = mData["masterkick"]
    elseif position == orgdefines.ORG_POSITION.DEPUTY then
        iLimit = mData["subkick"]
    end
    if self.m_oBaseMgr:QueryKickCnt(position) >= iLimit then
        return false
    end
    return true
end

function COrg:AddKickCnt(iPid)
    local position = self:GetPosition(iPid)
    self.m_oBaseMgr:AddKickCnt(position)
end

function COrg:HasBanChatAuth(iPid)
    local position = self:GetPosition(iPid)
    local mData = res["daobiao"]["org"]["member_limit"][position]
    if not mData then return false end
    return mData["ban_chat"] == 1
end

function COrg:HasInvite(iPid)
    local iPosition = self:GetPosition(iPid)
    local mData = res["daobiao"]["org"]["member_limit"][iPosition]
    if not mData then
        return
    end
    return mData["invite"] == 1
end

function COrg:HasPromoteOrgLevel(iPid)
    local iPosition = self:GetPosition(iPid)
    local mData = res["daobiao"]["org"]["member_limit"][iPosition]
    if not mData then
        return
    end
    return mData["upgrade"] == 1
end


function COrg:AddLog(iPid,sText)
    local oMem = self:GetMember(iPid)
    if not oMem and iPid ~= 0 then
        return
    end
    local iPosition = 0
    if oMem then
        iPosition = oMem:GetPosition()
    end
    self.m_oLogMgr:AddHistory(iPid, iPosition, sText)
end

function COrg:GS2CGetOnlineMember(oPlayer, bAll)
    local mNet = {}
    local oOrgMgr = global.oOrgMgr
    for _, oMem in pairs(self.m_oMemberMgr:GetMemberMap()) do
        local oOther = oOrgMgr:GetOnlinePlayerByPid(oMem:GetPid())
        if oOther and oPlayer:GetPid() ~= oOther:GetPid() then
            table.insert(mNet, oOther:PackSimpleInfo())
        end
    end
    oPlayer:Send("GS2CGetOnlineMember", {infos=mNet})
end

function COrg:GiveLeader2Other(iPid, iTarPid)
    -- 禅让帮主
    if not self:IsLeader(iPid) then
        return
    end
    if not self:GetMember(iTarPid) then
        return
    end

    local iOldPos = self:GetPosition(iTarPid)
    self:RemovePosition(iTarPid)
    self:RemovePosition(iPid)
    self:SetLeader(iTarPid)
    self:SetPosition(iPid, iOldPos)

    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:PropChange("org_pos")
        oPlayer:ClientPropChange({["org_pos"]=true})
        oPlayer:Send("GS2CSetPositionResult", {pid=iTarPid, position=orgdefines.ORG_POSITION.LEADER})
        oPlayer:Send("GS2CSetPositionResult", {pid=iPid, position=iOldPos})
    end

    local oTarget = oOrgMgr:GetOnlinePlayerByPid(iTarPid)
    if oTarget then
        oTarget:PropChange("org_pos")
        oTarget:ClientPropChange({["org_pos"]=true})
        oTarget:Send("GS2CSetPositionResult", {pid=iTarPid, position=orgdefines.ORG_POSITION.LEADER})
        oTarget:Send("GS2CSetPositionResult", {pid=iPid, position=iOldPos})
    end
    local oMemInfo = self.m_oMemberMgr:GetMember(iTarPid)
    local sName = oMemInfo:GetName()

    oOrgMgr:CheckOrgTitle(self:OrgID(),iPid)
    oOrgMgr:CheckOrgTitle(self:OrgID(),iTarPid)
end

function COrg:SetMemPosition(oPlayer, iTarPid, iPos)
    if not self:HasSetPosAuth(oPlayer:GetPid(), iPos)  then return end

    if self:GetPosition(iTarPid) <= self:GetPosition(oPlayer:GetPid()) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1027))
        return
    end

    local oOrgMgr = global.oOrgMgr
    local oMem = self:GetMember(iTarPid)
    if not oMem then
        oPlayer:Notify(oOrgMgr:GetOrgText(1014))
        return
    end

    if iPos == orgdefines.ORG_POSITION.MEMBER then
        oPlayer:Notify(oOrgMgr:GetOrgText(1026))
        return
    end

    if self:GetPositionCnt(iPos)  >= self:GetPosMaxCnt(iPos) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1015))
        return
    end

    local sPositionName = orgdefines.GetPositionName(iPos)
    local sText = oOrgMgr:GetOrgLog(1006,{role1=oPlayer:GetName(),role2=oMem:GetName(),position=sPositionName})
    self:AddLog(oPlayer:GetPid(),sText)

    self:RemovePosition(iTarPid)
    self:SetPosition(iTarPid, iPos)
    oPlayer:Send("GS2CSetPositionResult", {pid=iTarPid, position=iPos})

    local oTarget = oOrgMgr:GetOnlinePlayerByPid(iTarPid)
    if oTarget then
        oTarget:PropChange("org_pos")
        oTarget:ClientPropChange({["org_pos"]=true})
        oTarget:Send("GS2CSetPositionResult", {pid=iTarPid, position=iPos})
    end

    oOrgMgr:CheckOrgTitle(self:OrgID(),iTarPid)
end

function COrg:GetOrgUpdateInfo(m)
    local mRet = {}
    if not m then
        m = OrgHelperFunc
    end
    for k, _ in pairs(m) do
        local f = assert(OrgHelperFunc[k], string.format("GetOrgUpdateInfo fail f get %s", k))
        mRet[k] = f(self)
    end
    return net.Mask("OrgInfo", mRet)
end

function COrg:UpdateOrgInfo(mNet)
    self.m_oMemberMgr:UpdateOrgInfo(mNet)
end

function COrg:GetSignDegree()
    return self.m_oBaseMgr:GetSignDegree()
end

function COrg:AddSignDegree(iSignDegree)
    self.m_oBaseMgr:AddSignDegree(iSignDegree)
end

function COrg:ClearSignDegree()
    self.m_oBaseMgr:ClearSignDegree()
end

function COrg:GetOrgWishList()
    local mData = self.m_oMemberMgr:GetOrgWishList()
    return mData
end

function COrg:InOrgWishUI(iPid)
    return self.m_oBaseMgr:InOrgWishUI(iPid)
end

function COrg:OpenWishUI(iPid)
    self.m_oBaseMgr:OpenWishUI(iPid)
end

function COrg:LeaveWishUI(iPid)
    self.m_oBaseMgr:RemoveWish(iPid)
end

function COrg:BoardCastWishUI(sMessage,mNet)
    self.m_oBaseMgr:BoardCastWishUI(sMessage,mNet)
end

function COrg:GetOpenRedPacket()
    return self.m_oBaseMgr:GetOpenRedPacket()
end

function COrg:OpenRedPacket(oPlayer,idx,iGold,iAmount)
    self.m_oBaseMgr:OpenRedPacket(oPlayer,idx,iGold,iAmount)
end

function COrg:ClearRedPacket()
    self.m_oBaseMgr:ClearRedPacket()
end

function COrg:ValidDrawRedPacket(oPlayer,idx)
    return self.m_oBaseMgr:ValidDrawRedPacket(oPlayer,idx)
end

function COrg:DrawOrgRedPacket(oPlayer,idx)
    self.m_oBaseMgr:DrawOrgRedPacket(oPlayer,idx)
end

function COrg:GetDrawRedPacketInfo(iPid,idx)
    return self.m_oBaseMgr:GetDrawRedPacketInfo(iPid,idx)
end

function COrg:SendOrgRedPacket(oPlayer,idx)
    self.m_oBaseMgr:SendOrgRedPacket(oPlayer,idx)
end

function COrg:OnlineMemCnt()
    return self.m_oMemberMgr:OnlineMemCnt()
end

function COrg:SendOrgLog(oPlayer)
    local mNet = self.m_oLogMgr:PackHistoryListInfo()
    oPlayer:Send("GS2COrgLog",{log_info = mNet})
end

function COrg:GetActivePoint()
    return self.m_oBaseMgr:GetActivePoint()
end

function COrg:RewardActivePoint(iPid,iActivePoint,sReason,mArgs)
    self.m_oBaseMgr:RewardActivePoint(iActivePoint,sReason,mArgs)
    local oMem = self:GetMember(iPid)
    if oMem then
        oMem:AddActivePoint(iActivePoint)
    end
end

function COrg:ValidPromoteLevel()
    local iLevel = self:GetLevel()
    local mData = res["daobiao"]["org"]["org_grade"][iLevel]
    local iExp = mData["exp_need"]
    local iCash = mData["coin_need"]
    if iExp > 0 and  not self:ValidExp(iExp) then
        return false
    end
    if iCash > 0 and not self:ValidCash(iCash) then
        return false
    end
    return true
end

function COrg:PromoteLevel(oPlayer)
    self.m_oBaseMgr:PromoteLevel(oPlayer)
end

--可能没在线
function COrg:OnLeaveOrg(iPid)
    self.m_oBaseMgr:OnLeaveOrg(iPid)
    local oMem = self:GetMember(iPid)
    if oMem then
        oMem:OnLeaveOrg(self:OrgID())
    end
end

function COrg:RewardOrgOffer(iPid,iOrgOffer)
    local oMem = self:GetMember(iPid)
    if oMem then
        oMem:RewardOrgOffer(iOrgOffer)
    end
end

function COrg:IsOpenRedPacket()
    if self.m_oBaseMgr:IsOpenRedPacket() then
        return 1
    end
    return 0
end

function COrg:SetOpenRedPacket()
    self.m_oBaseMgr:SetOpenRedPacket()
end

function COrg:CheckRedPacketUI()
    self.m_oBaseMgr:CheckRedPacketUI()
end

function COrg:SendRedPacketUI(oPlayer)
    self.m_oBaseMgr:SendRedPacketUI(oPlayer)
end

function COrg:GetRedPacketRest()
    return self.m_oBaseMgr:GetRedPacketRest()
end

function COrg:GetMailRest()
    local iLimitCnt = res["daobiao"]["org"]["rule"][1]["mail_cnt"]
    return math.max(0,iLimitCnt-self:QueryToday("mail_cnt",0))
end

function COrg:SetToday(k,v)
    return self.m_oBaseMgr.m_oToday:Set(k,v)
end

function COrg:AddToday(k,v)
    return self.m_oBaseMgr.m_oToday:Add(k,v)
end

function COrg:QueryToday(k,default)
    return self.m_oBaseMgr.m_oToday:Query(k,default)
end

function COrg:OnChangeName()
    self:UpdateOrgInfo({name=true})
    self.m_oMemberMgr:SyncOrgTitle()
    
end

function COrg:TestOP(oPlayer,iCmd,mArgs)
    if iCmd == 100 then
        oPlayer:Notify("101-清除公会签到进度")
        oPlayer:Notify("102-清除公会红包")
        oPlayer:Notify("103-清除公会许愿")
        oPlayer:Notify("104 iDay iHour-公会刷时,例:104 1 0")
        oPlayer:Notify("107-公会降级")
        oPlayer:Notify("108-查看公会")
        oPlayer:Notify("109 星期数-109 10")
        oPlayer:Notify("110 增加公会声望 例如110 10")
        oPlayer:Notify("111 去除红包开启时间限制")
    elseif iCmd == 101 then
        self:ClearSignDegree()
    elseif iCmd == 102 then
        self:ClearRedPacket()
    elseif iCmd == 103 then
        self.m_oMemberMgr:ClearWish()
    elseif iCmd == 104 then
        if table_count(mArgs) < 2 then
            return
        end
        local iDay,iHour = table.unpack(mArgs)
        self:NewHour(iDay,iHour)
    elseif iCmd == 106 then
        self.m_oBaseMgr.m_oToday:ClearData()
    elseif iCmd == 107 then
        self.m_oBaseMgr:DownLevel()
    elseif iCmd == 108 then
        local iCreateWeekNo = self.m_oBaseMgr:GetData("create_week_no")
        oPlayer:Notify(string.format("公会创建的周数:%s",iCreateWeekNo))
        oPlayer:Notify(string.format("当前的的周数:%s",get_weekno()))
    elseif iCmd == 109 then
        if table_count(mArgs) <=0 then
            oPlayer:Notify("请输入参数")
            return
        end
        local iWeekNo = table.unpack(mArgs)
        self.m_oBaseMgr:SetData("create_week_no",iWeekNo)
    elseif iCmd == 110 then
        local iAdd = table.unpack(mArgs)
        iAdd = tonumber(iAdd)
        if not iAdd then return end
        self.m_oBaseMgr:AddPrestige(iAdd,"gm指令",{pid=oPlayer:GetPid()})
    elseif iCmd == 111 then
        self.m_TestHongBao = true
    elseif iCmd == 112 then
        self.m_oMemberMgr:ClearLowActiveMem()
    elseif iCmd == 113 then
        local list = mArgs
        local redlist = {}
        for _,num in ipairs(list) do
            if tonumber(num) == 1 then
                table.insert(redlist,true)
            else
                table.insert(redlist,false)
            end
        end
        oPlayer:Send("GS2CControlRedPacketUI", {redlist=redlist})
    elseif iCmd == 114 then
        local mInfo = oPlayer:GetInfo("leaveorg",{})
        mInfo["leavetime"] = 1
        oPlayer:SetInfo("leaveorg",mInfo)
    elseif iCmd == 115 then
        local iCnt = self.m_oBaseMgr:QueryKickCnt()
        local oMem = self:GetMember(oPlayer:GetPid())
        if oMem then
            oPlayer:Notify("已踢人次数："..self.m_oBaseMgr:QueryKickCnt(oMem:GetPosition()))
        end
    end
end