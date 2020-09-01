--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"
local extend = require "base/extend"
local record = require "public.record"

local shareobj = import(lualib_path("base.shareobj"))
local datactrl = import(lualib_path("public.datactrl"))

function NewPlayer(...)
    local o = CPlayer:New(...)
    return o
end

PropHelperFunc = {}

function PropHelperFunc.org_id(oPlayer)
    return oPlayer:GetOrgID()
end

function PropHelperFunc.org_status(oPlayer)
    return oPlayer:GetOrgStatus()
end

function PropHelperFunc.org_pos(oPlayer)
    return oPlayer:GetOrgPos()
end

function PropHelperFunc.org_offer(oPlayer)
    return oPlayer:GetOffer()
end

function PropHelperFunc.orgname(oPlayer)
    return oPlayer:GetOrgName()
end

function PropHelperFunc.org_build_status(oPlayer)
    return oPlayer:GetToday("org_build_status",0)
end

function PropHelperFunc.org_sign_reward(oPlayer)
    return oPlayer:GetToday("org_sign_reward",0)
end

function PropHelperFunc.org_red_packet(oPlayer)
    return oPlayer:GetToday("org_red_packet",0)
end

function PropHelperFunc.give_org_wish(oPlayer)
    local mData = table_key_list(oPlayer:GetToday("give_org_wish",{}))
    return mData
end

function PropHelperFunc.give_org_equip(oPlayer)
    local mData = table_key_list(oPlayer:GetToday("give_org_equip",{}))
    return mData
end

function PropHelperFunc.org_build_time(oPlayer)
    return oPlayer:GetToday("org_build_time",0)
end

function PropHelperFunc.is_org_wish(oPlayer)
    return oPlayer:GetToday("org_wish",0)
end

function PropHelperFunc.is_equip_wish(oPlayer)
    return oPlayer:GetToday("org_wish_equip",0)
end

function PropHelperFunc.org_leader(oPlayer)
    return oPlayer:GetLeaderName()
end

function PropHelperFunc.org_level(oPlayer)
    return oPlayer:GetLevel()
end

CPlayer = {}
CPlayer.__index = CPlayer
inherit(CPlayer, datactrl.CDataCtrl)

function CPlayer:New(iPid,mInfo)
    local o = super(CPlayer).New(self,mInfo)
    o.m_iPid = iPid
    o.m_oOrgInfoShareObj = COrgInfoShareObj:New()
    o.m_oOrgInfoShareObj:Init()
    return o
end

function CPlayer:Release()
    baseobj_delay_release(self.m_oOrgInfoShareObj)
    self.m_iPid = nil
    super(CPlayer).Release(self)
end

function CPlayer:GetPid()
    return self.m_iPid
end

function CPlayer:GetName()
    return self:GetInfo("name")
end

function CPlayer:GetGrade()
    return self:GetInfo("grade")
end

function CPlayer:GetSchool()
    return self:GetInfo("school")
end

function CPlayer:GetSchoolBranch()
    return self:GetInfo("school_branch")
end

function CPlayer:GetOffer()
    return self:GetInfo("offer")
end

function CPlayer:GetShape()
    return self:GetInfo("shape")
end

function CPlayer:GetPower()
    return self:GetInfo("power",0) + self:GetInfo("partnerpower",0)
end

function CPlayer:NewHour(iDay,iHour)
    if iHour == 0 then
        self:PropChange("org_build_status","org_sign_reward","org_red_packet","give_org_wish","org_build_time","is_org_wish","is_equip_wish","give_org_equip")
    end
end

function CPlayer:OnLogin(bReEnter)
end

function CPlayer:OnLogout()
end

function CPlayer:Disconnected()
end

function CPlayer:Send(sMessage, mData)
    playersend.Send(self:GetPid(),sMessage,mData)
end

function CPlayer:Notify(sMsg)
    self:Send("GS2CNotify", {cmd = sMsg})
end

function CPlayer:GetModelInfo()
    return self:GetInfo("model_info")
end

function CPlayer:PackSimpleRoleInfo()
    local mRole = {}
    mRole["pid"] = self.m_iPid
    mRole["name"] = self:GetName()
    mRole["grade"] = self:GetGrade()
    mRole["model_info"] = self:GetModelInfo()
    mRole["school"] = self:GetSchool()
    return mRole
end

function CPlayer:RoleInfo(m)
    local mRet = {}
    if not m then
        m = PropHelperFunc
    end
    for k, _ in pairs(m) do
        local f = assert(PropHelperFunc[k], string.format("RoleInfo fail f get %s", k))
        mRet[k] = f(self)
    end
    return net.Mask("base.Role", mRet)
end

function CPlayer:PropChange(...)
    local l = table.pack(...)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:SetPlayerPropChange(self:GetPid(), l)
end

function CPlayer:ClientPropChange(m)
    local mRole = self:RoleInfo(m)
    self:Send("GS2CPropChange", {
        role = mRole,
    })
end

function CPlayer:HasTeam()
    return self:GetInfo("team")
end

function CPlayer:GetOrg()
    local oOrgMgr = global.oOrgMgr
    local oOrg = oOrgMgr:GetPlayerOrg(self:GetPid())
    return oOrg
end

function CPlayer:GetOrgID()
    local oOrgMgr = global.oOrgMgr
    local oOrg = oOrgMgr:GetPlayerOrg(self:GetPid())
    if oOrg then
        return oOrg:OrgID()
    end
    return 0
end

function CPlayer:GetOrgName()
    local oOrg = self:GetOrg()
    if oOrg then
        return oOrg:GetName()
    else
        return ""
    end
end

function CPlayer:GetOrgExp()
    local oOrg = self:GetOrg()
    if oOrg then
        return oOrg:GetExp()
    else
        return ""
    end
end

function CPlayer:GetOrgStatus()
    local iOrg = self:GetOrgID()
    if  iOrg and iOrg ~= 0 then
        return 2
    end
    return 0
end

function CPlayer:GetOrgPos()
    local oOrg = self:GetOrg()
    if oOrg then
        return oOrg:GetPosition(self:GetPid())
    end
    return 0
end

function CPlayer:GetOrgLevel()
    local oOrg = self:GetOrg()
    if oOrg then
        return oOrg:GetLevel()
    end
    return 0
end

function CPlayer:GetOrgSFlag()
    local oOrg = self:GetOrg()
    if oOrg then
        return oOrg:GetSFlag()
    end
    return 0
end

function CPlayer:GetLeaderName()
    local oOrg = self:GetOrg()
    if oOrg then
        return oOrg:GetLeaderName()
    end
    return ""
end

function CPlayer:GetLevel()
    local oOrg = self:GetOrg()
    if oOrg then
        return oOrg:GetLevel()
    end
    return 0
end

function CPlayer:GetJoinTime()
    local oOrg = self:GetOrg()
    if oOrg then
        return oOrg:GetJoinTime(self:GetPid())
    end
    return 0
end

function CPlayer:AddToday(sKey,value)
    local mToday = self:GetInfo("today",{})
    local iVal = mToday[sKey] or 0
    iVal = iVal + value
    mToday[sKey] = iVal
    self:SetInfo("today",mToday)
    interactive.Send(".world", "org", "SetToday", {
        pid = self:GetPid(),
        key = sKey,
        value = iVal
    })
end

function CPlayer:SetToday(sKey,value)
    local mToday = self:GetInfo("today",{})
    mToday[sKey] = value
    self:SetInfo("today",mToday)
    interactive.Send(".world", "org", "SetToday", {
        pid = self:GetPid(),
        key = sKey,
        value = value
    })
end

function CPlayer:GetToday(sKey,default)
    local iDayNo = self:GetInfo("dayno")
    local iNowDayNo = get_dayno()
    if iDayNo ~= iNowDayNo then
        self:SetInfo("dayno",iNowDayNo)
        self:SetInfo("today",{})
    end
    local mToday = self:GetInfo("today",{})
    return mToday[sKey] or default
end

function CPlayer:GetPreLeaveOrgTime()
    local mInfo = self:GetInfo("leaveorg",{})
    return mInfo["leavetime"] or 0
end

function CPlayer:IsPreLeaveOrg(iOrgID)
    local mInfo = self:GetInfo("leaveorg",{})
    if mInfo["orgid"] == iOrgID then
        return true
    end
    return false
end

function CPlayer:IsOrgBuilding()
    local iOrgBuildStatus = self:GetToday("org_build_status",0)
    if table_in_list({1,2,3},iOrgBuildStatus) then
        return true
    end
    return false
end

function CPlayer:IsOrgBuildDone()
    local iOrgBuildStatus = self:GetToday("org_build_status",0)
    if iOrgBuildStatus == 4 then
        return true
    end
    return false
end

function CPlayer:ValidBuildOrg()
    if self:GetToday("org_build_status",0) == 0 then
        return true
    end
    return false
end

function CPlayer:OrgBuildStatus()
    return self:GetToday("org_build_status",0)
end

function CPlayer:SetOrgBuildStatus(iStatus)
    self:SetToday("org_build_status",iStatus)
    self:PropChange("org_build_status")
end

function CPlayer:StartOrgBuild(iBuildType,iTime)
    self:DelTimeCb("org_build")
    local iEndTime = get_time()
    self:SetToday("org_build_time",iEndTime)
    self:PropChange("org_build_time")
    self:SetToday("org_build_type",iBuildType)
    self:SetOrgBuildStatus(iBuildType)

    self:AddSchedule("org_build")

    self:OrgBuildFinish()

    -- local iPid = self:GetPid()
    -- self:AddTimeCb("org_build",iTime*1000,function ()
    --     local oOrgMgr = global.oOrgMgr
    --     local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    --     if oPlayer then
    --         oPlayer:OrgBuildFinish()
    --     end
    -- end)
end

function CPlayer:AddSchedule(schedule)
    interactive.Send(".world", "org", "AddSchedule", {
        pid = self:GetPid(),
        schedule = schedule
    })
end

function CPlayer:OrgBuildFinish()
    self:DelTimeCb("org_build")
    if not self:IsOrgBuilding() then
        return
    end
    local iBuildType = self:GetToday("org_build_type",0)
    local iStatus = 4
    self:SetOrgBuildStatus(iStatus)
end

function CPlayer:DoneOrgBuild()
    local iStatus = 5
    self:SetOrgBuildStatus(iStatus)
end

function CPlayer:CheckOrgBuild()
    if not self:IsOrgBuilding() then
        return
    end
    local iTime = self:GetToday("org_build_time",0)
    if iTime == 0 then
        return
    end
    if self:OrgBuildStatus() >= 4 then
        return
    end
    local iPid = self:GetPid()
    if iTime > get_time() then
        iTime = iTime - get_time()
        self:AddTimeCb("org_build",iTime*1000,function ()
            local oOrgMgr = global.oOrgMgr
            local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer:OrgBuildFinish()
            end
        end)
    else
        self:OrgBuildFinish()
    end
end


function CPlayer:IsOrgSignReward(idx)
    if idx < 1 then
        return
    end
    local iValue = self:GetToday("org_sign_reward",0)
    local iMask = 1 << (idx-1)
    if iValue & iMask ~= 0 then
        return true
    end
    return false
end

--公会签到奖励
function CPlayer:SetOrgSignReward(idx)
    local iMask = 1 << (idx-1)
    local iValue = self:GetToday("org_sign_reward",0)
    iValue = iValue | iMask
    self:SetToday("org_sign_reward",iValue)
    self:PropChange("org_sign_reward")
end

function CPlayer:IsOrgRedPacket(idx)
    if idx < 1 then
        return
    end
    local iValue = self:GetToday("org_red_packet",0)
    local iMask = 1 << (idx-1)
    if iValue & iMask ~= 0 then
        return true
    end
    return false
end

function CPlayer:SetOrgRedPacket(idx)
    local iMask = 1 << (idx - 1)
    local iValue = self:GetToday("org_red_packet",0)
    iValue = iValue | iMask
    self:SetToday("org_red_packet",iValue)
    self:PropChange("org_red_packet")
end

function CPlayer:RewardOrgOffer(iOffer,sReason,mArgs)
    interactive.Send(".world", "org", "RewardOrgOffer", {
        pid = self:GetPid(),
        offer = iOffer,
        reason = sReason,
        args = mArgs,
    })
end

function CPlayer:PushBookCondition(sKey, mData)
    interactive.Send(".world", "org", "PushBookCondition", {
        pid = self:GetPid(),
        key = sKey,
        data = mData
    })
end

function CPlayer:AddOrgWish(iTarget)
    local mGive = self:GetToday("give_org_wish",{})
    mGive[iTarget] = 1
    self:SetToday("give_org_wish",mGive)
    self:ClientPropChange({["give_org_wish"] = true})
end

function CPlayer:AddOrgEquipWish(iTarget)
    local mGive = self:GetToday("give_org_equip",{})
    mGive[iTarget] = 1
    self:SetToday("give_org_equip",mGive)
    self:ClientPropChange({["give_org_equip"] = true})
end

function CPlayer:RecivePlayerData(mData)
    for sAttr,value in pairs(mData) do
        self:SetInfo(sAttr,value)
    end
end

function CPlayer:PackRole2Chat()
    local mRoleInfo = {}
    mRoleInfo.pid = self:GetPid()
    mRoleInfo.grade = self:GetGrade()
    mRoleInfo.name = self:GetName()
    mRoleInfo.shape = self:GetShape()
    return mRoleInfo
end

function CPlayer:PackRole2OrgChat()
    local mRoleInfo = self:PackRole2Chat()
    local oOrg = self:GetOrg()
    if oOrg then
        -- mRoleInfo.position = oOrg:GetPosition(self:GetPid())
        -- mRoleInfo.honor = oOrg:GetOrgHonor(self:GetPid())
    end
    return mRoleInfo
end

function CPlayer:ShareChange()
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:SetPlayerShareChange(self:GetPid(),true)
end

function CPlayer:HookShareChange()
    self:UpdateData()
end

function CPlayer:PackRemoteData()
    local mBase = {
        orgid = self:GetOrgID(),
        orgname = self:GetOrgName(),
        orgexp = self:GetOrgExp(),
        orgstatus = self:GetOrgStatus(),
        orgpos = self:GetOrgPos(),
        orglevel = self:GetOrgLevel(),
        orgsflag = self:GetOrgSFlag(),
        jointime = self:GetJoinTime(),
    }
    return {
        base = mBase,
    }
end

function CPlayer:UpdateData()
    local mData = self:PackRemoteData()
    self.m_oOrgInfoShareObj:UpdateOrgData(mData)
end

function CPlayer:GetOrgInfoReaderCopy()
    return self.m_oOrgInfoShareObj:GenReaderCopy()
end

COrgInfoShareObj = {}
COrgInfoShareObj.__index = COrgInfoShareObj
inherit(COrgInfoShareObj, shareobj.CShareWriter)

function COrgInfoShareObj:New()
    local o = super(COrgInfoShareObj).New(self)
    o.m_mBase = {}
    return o
end

function COrgInfoShareObj:UpdateOrgData(mData)
    self.m_mBase = mData.base or {}
    self:Update()
end

function COrgInfoShareObj:Pack()
    local m = {}
    m.base = self.m_mBase
    return m
end