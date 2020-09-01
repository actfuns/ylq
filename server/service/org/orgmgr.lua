local global = require "global"
local interactive = require "base.interactive"
local extend = require "base.extend"
local record = require "public.record"
local res = require "base.res"
local colorstring = require "public.colorstring"
local router = require "base.router"
local playersend = require "base.playersend"

local gamedb = import(lualib_path("public.gamedb"))
local gamedefines = import(lualib_path("public.gamedefines"))
local orgobj = import(service_path("orgobj"))
local orgmeminfo = import(service_path("orgmeminfo"))
local orgdefines = import(service_path("orgdefines"))
local playerobj = import(service_path("playerobj"))

function NewOrgMgr(...)
    return COrgMgr:New(...)
end

COrgMgr = {}
COrgMgr.__index = COrgMgr
inherit(COrgMgr,logic_base_cls())

function COrgMgr:New()
    local o = super(COrgMgr).New(self)
    o.m_mPlayers = {}
    o.m_mNormalOrgs = {}
    o.m_mNormalOrgNames = {}
    o.m_mNormalOrgFlags = {}
    o.m_mPlayer2OrgID = {}              --玩家公会ID映射

    o.m_mNormalOrgLoaded = false
    o.m_mNormalOrgLoading = {}

    o.m_lWaitLoadingFunc = {}

    o.m_mOrgListCache = {}
    o.m_mMulApplyTime = {}              --　一键申请时间记录　不存库
    o.m_mOrgCreatingName = {}

    o.m_mPlayerPropChange = {}
    o.m_mPlayerShareChange = {}

    return o
end

function COrgMgr:LoadAllOrg()
    local mArgs = {
        module = "orgdb",
        cmd = "GetAllOrgID",
    }
    gamedb.LoadDb("org","common", "LoadDb", mArgs, function (mRecord, mData)
        if not is_release(self) then
            self:LoadAllNormalOrg(mRecord, mData)
        end
    end)
end

function COrgMgr:LoadAllNormalOrg(mRecord, mData)
    local lData = mData.data
    if not lData or not next(lData) then
        self:OnAllNormalOrgLoaded()
        return
    end
    for _, v in ipairs(lData) do
        local orgid = v.orgid
        self.m_mNormalOrgLoading[orgid] = true
        self:LoadNormalOrg(orgid)
    end
end



function COrgMgr:LoadNormalOrg(orgid)
    local mArgs = {
        module = "orgdb",
        cmd = "LoadWholeOrg",
        data = {orgid = orgid},
    }
    gamedb.LoadDb(orgid,"common", "LoadDb", mArgs, function (mRecord, mData)
        if not is_release(self) then
            self:LoadNormalOrg2(mRecord, mData)
        end
    end)
end

function COrgMgr:LoadNormalOrg2(mRecord, mData)
    local orgid = mData.orgid
    if not self.m_mNormalOrgLoading[orgid] then
        return
    end
    local oOrg = orgobj.NewOrg(orgid)
    oOrg:LoadAll(mData.data)
    oOrg:ConfigSaveFunc()

    self.m_mNormalOrgs[oOrg:OrgID()] = oOrg
    self.m_mNormalOrgNames[oOrg:GetName()] = oOrg
    self.m_mNormalOrgFlags[oOrg:GetSFlag()] = oOrg

    self.m_mNormalOrgLoading[orgid] = nil
    oOrg:LoadDoneInit()
    if not next(self.m_mNormalOrgLoading) then
        self:OnAllNormalOrgLoaded()
    end
end

function COrgMgr:OnAllNormalOrgLoaded()
    self.m_mNormalOrgLoaded = true
    self:OnAllOrgLoaded()
end

function COrgMgr:OnAllOrgLoaded()
    if not self.m_mNormalOrgLoaded then
        return
    end
    self:WakeUpFunc()
    self:GenerateCache()
end

function COrgMgr:Execute(func)
    if self.m_mNormalOrgLoaded then
        func()
    else
        table.insert(self.m_lWaitLoadingFunc,func)
    end
end

function COrgMgr:WakeUpFunc()
    local lWaitFuncs = self.m_lWaitLoadingFunc
    self.m_lWaitLoadingFunc = {}
    for _,func in pairs(lWaitFuncs) do
        func()
    end
end

function COrgMgr:NewHour(iDay,iHour)
    for orgid, oOrg in pairs(self.m_mNormalOrgs) do
        oOrg:NewHour(iDay,iHour)
    end
    for iPid,oPlayer in pairs(self.m_mPlayers) do
        oPlayer:NewHour(iDay,iHour)
    end
end


function COrgMgr:CreateNormalOrg(oPlayer, sName, tArgs)
    local iVal = res["daobiao"]["org"]["rule"][1]["cost"]
    local iPid = oPlayer:GetPid()
    interactive.Request(".world", "org", "ValidGoldCoin", {pid = iPid,value=iVal}, function (mRecord, mData)
        if mData.suc then
            self:CreateNormalOrg2(iPid,sName,tArgs)
        end
    end)
end

function COrgMgr:CreateNormalOrg2(iPid, sName, tArgs)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end

    if self:GetNormalOrgByName(sName) or self.m_mOrgCreatingName[sName] then
        oPlayer:Notify(self:GetOrgText(1016))
        return
    end

    local fCallback = function (mRecord,mData)
        self:CreateNormalOrg3(mData,iPid,sName,tArgs)
    end
    router.Request("cs",".idsupply","common","GenOrgId",{},fCallback)
end

function COrgMgr:CreateNormalOrg3(mData, iPid, sName, tArgs)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end

    if self:GetNormalOrgByName(sName) or self.m_mOrgCreatingName[sName] then
        oPlayer:Notify(self:GetOrgText(1016))
        return
    end
    self.m_mOrgCreatingName[sName] = true
    local iVal = res["daobiao"]["org"]["rule"][1]["cost"]
    interactive.Request(".world", "org", "ResumeGoldCoin", {pid = iPid,value=iVal}, function (mRecord, mData2)
        if mData2.suc then
            self:CreateNormalOrg4(mData, iPid, sName, tArgs)
        end
    end)
end

function COrgMgr:CreateNormalOrg4(mData, iPid, sName, tArgs)
    self.m_mOrgCreatingName[sName] = nil

    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    assert(oPlayer,"createorg err no player "..iPid)

    local orgid = mData.id
    local tData = {
        pid = iPid,
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        offer = oPlayer:GetOffer(),
        shape = oPlayer:GetShape(),
        power = oPlayer:GetPower(),
        school_branch = oPlayer:GetSchoolBranch(),
    }
    local oMember = orgmeminfo.NewMemberInfo()
    oMember:Create(iPid, tData)

    local oOrg = orgobj.NewOrg(orgid)
    oOrg:Create(sName, tArgs)

    local iPosition = orgdefines.ORG_POSITION.LEADER
    oOrg:AddMember(oMember,iPosition)
    oOrg:SetLeader(iPid)
    oOrg:SetCreater(iPid)

    --删除申请信息更新离线模块
    local mData = {
        data = oOrg:GetAllSaveData(),
    }

    gamedb.SaveDb(orgid,"common", "SaveDb",{module = "orgdb",cmd = "CreateOrg",data = mData})

    oOrg:ConfigSaveFunc()

    self:AddNormalOrg(oOrg)
    self:OnJoinOrg(iPid, orgid)

    local mNet = {info=oOrg:PackOrgInfo()}
    oPlayer:PropChange("org_status", "org_id")
    oPlayer:ClientPropChange({["org_id"]=true,["org_status"]=true})

    oPlayer:Notify(self:GetOrgText(1017))
    oPlayer:Send("GS2COrgMainInfo", mNet)
    record.user("org", "create", {pid=iPid, orgid=oOrg:OrgID()})
    self:GenerateCache()

    local sText = self:GetOrgLog(1001,{rolename=oPlayer:GetName(),orgname=sName})
    oOrg:AddLog(oPlayer:GetPid(),sText)
    self:LogAnalyData(oOrg,iPid,1)

    self:PushDataToOrgPrestigeRank(oOrg)
end

function COrgMgr:AddNormalOrg(oOrg)
    local id = oOrg:OrgID()
    local name = oOrg:GetName()
    local flag = oOrg:GetSFlag()
    self.m_mNormalOrgs[id] = oOrg
    self.m_mNormalOrgNames[name] = oOrg
    self.m_mNormalOrgFlags[flag] = oOrg
    self:OnCreateOrg(oOrg)
end

function COrgMgr:OnCreateOrg(oOrg)
    local mOrgInfo = {
        orgid = oOrg:OrgID(),
        orgname = oOrg:GetName(),
        orgleader = oOrg:GetLeaderName(),
        orgsflag = oOrg:GetSFlag(),
        orgaim = oOrg:GetAim(),
        orgbgid = oOrg:GetFlagBgID(),
    }

    interactive.Send(".world", "org", "OnCreateOrg",{
        orginfo = mOrgInfo,
    })
end

function COrgMgr:DeleteNormalOrg(oOrg)
    local id = oOrg:OrgID()
    local name = oOrg:GetName()
    local flag = oOrg:GetSFlag()

    local mData = {
        orgid = id,
    }
    gamedb.SaveDb(id,"common", "SaveDb",{module = "orgdb",cmd = "RemoveOrg",data = mData})

    baseobj_delay_release(oOrg)
    self.m_mNormalOrgs[id] = nil
    self.m_mNormalOrgNames[name] = nil
    self.m_mNormalOrgFlags[flag] = nil
    record.user("org","release",{orgid=id})
    self:AfterDeleteOrg(id)
    self:GenerateCache()
end

function COrgMgr:AfterDeleteOrg(iOrgID)
    local mData = {
        orgid = iOrgID,
    }
    interactive.Send(".rank", "rank", "DeleteOrg", mData)
end

function COrgMgr:DismissNormalOrg(iOrgID)
    local oOrg = self:GetNormalOrg(iOrgID)
    if not oOrg then return end
    local sText = self:GetOrgText(1020)
    self:SendDismissTip(iOrgID,sText)
    for iPid, oMem in pairs(oOrg.m_oMemberMgr:GetMemberMap()) do
        self:LeaveOrg(iPid, iOrgID)
    end
    self:DeleteNormalOrg(oOrg)
end

function COrgMgr:ForceRenameOrg(iOrgID, sNewName)
    local oOrg = self:GetNormalOrg(iOrgID)
    if not oOrg then return false end

    local oOldName = oOrg:GetName()
    oOrg:SetData("name", sNewName)
    self:OnOrgChangeName(oOldName, sNewName)
    oOrg:OnChangeName()
    self:RefreshDbName(iOrgID, sOldName, sNewName)
end

function COrgMgr:RefreshDbName(iOrgId, sOldName, sNewName)
    local mData = {
        name = sNewName,
        orgid = iOrgId,
    }
    interactive.Send(".rank", "rank", "OnUpdateOrgName", mData)
end

function COrgMgr:SendDismissTip(iOrgID,sTip)
    local mNet = {stip=sTip}
    interactive.Send(".broadcast", "channel", "SendChannel", {
        message = "GS2CLeaveOrgTips",
        id = iOrgID,
        type = gamedefines.BROADCAST_TYPE.ORG_TYPE,
        data = mNet,
        exclude = {},
    })
end

function COrgMgr:GetNormalOrg(id)
    return self.m_mNormalOrgs[id]
end

function COrgMgr:GetNormalOrgByName(sName)
    return self.m_mNormalOrgNames[sName]
end

function COrgMgr:GetNormalOrgByFlag(sFlag)
    return self.m_mNormalOrgFlags[sFlag]
end

function COrgMgr:AcceptMember(orgid, pid)
    local oOrg = self:GetNormalOrg(orgid)
    if not oOrg then
        return
    end
    local oMem = oOrg:GetApplyInfo(pid)
    local flag = oOrg:AcceptMember(oMem)
    if flag then
        self:OnJoinOrg(pid, orgid)
    end
    return flag
end

function COrgMgr:AddForceMember(orgid, oPlayer)
    local oOrg = self:GetNormalOrg(orgid)
    if not oOrg then
        return
    end
    local pid = oPlayer:GetPid()
    local tArgs = {
        pid = pid,
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        offer = oPlayer:GetOffer(),
        shape = oPlayer:GetShape(),
        power = oPlayer:GetPower(),
        school_branch = oPlayer:GetSchoolBranch(),
    }
    local oMember = orgmeminfo.NewMemberInfo()
    oMember:Create(pid, tArgs)

    local flag = oOrg:AcceptMember(oMember)
    if flag then
        self:OnJoinOrg(pid, orgid)
    end
    return flag
end

function COrgMgr:PushAchieve(iPid,sKey,mArgs)
    interactive.Send(".achieve","common","PushAchieve",{
        pid = iPid , key= sKey , data=mArgs
    })
end

function COrgMgr:RemoveOrgTitles(iPid)
    interactive.Send(".world", "title", "RemoveTitles", {
        pid = iPid,
        tidlist = {1077,1078,1079,1080,1081}
    })
end

function COrgMgr:CheckOrgTitle(iOrgID,iPid)
    local oOrg = self:GetNormalOrg(iOrgID)
    if not oOrg then return end
    local iPosition = oOrg:GetPosition(iPid)
    if not iPosition then
        return
    end
    local iTid
    if iPosition == orgdefines.ORG_POSITION.LEADER then
        iTid = 1081
    elseif iPosition == orgdefines.ORG_POSITION.DEPUTY then
        iTid = 1080
    elseif iPosition == orgdefines.ORG_POSITION.ELITE then
        iTid = 1079
    elseif iPosition == orgdefines.ORG_POSITION.FINE then
        iTid = 1078
    elseif iPosition == orgdefines.ORG_POSITION.MEMBER then
        iTid = 1077
    end
    local res = require "base.res"
    local mData = res["daobiao"]["title"]["title"][iTid]
    local sName = string.gsub(mData["realname"],"$orgname",oOrg:GetName())
    self:RemoveOrgTitles(iPid)
    interactive.Send(".world", "title", "AddTitle", {
        pid = iPid,
        tid = iTid,
        name = sName,
    })
end

function COrgMgr:OnJoinOrg(pid, iOrgID)
    self:OnJoinDelApplys(pid, iOrgID)
    self:SetPlayerOrgID(pid, iOrgID)

    local oPlayer = self:GetOnlinePlayerByPid(pid)
    if oPlayer then
        self:OnOrgChannel(iOrgID, oPlayer)
        oPlayer:PropChange("org_status", "org_id", "orgname", "org_pos")
        oPlayer:ShareChange()
    end
    self:CheckOrgTitle(iOrgID,pid)
    local oOrg = self:GetNormalOrg(iOrgID)
    if oOrg then
        for iGrade=1,5 do
            if oOrg:GetLevel() >= iGrade then
                self:PushAchieve(pid,string.format("公会等级大于等于%d级的数量",iGrade),{value=1})
            end
        end
        local oMem = oOrg:GetMember(pid)
        local sText = self:GetOrgLog(1010,{rolename=oMem:GetName()})
        oOrg:AddLog(pid,sText)
        if oPlayer then
            oPlayer:Send("GS2COrgMainInfo", {info=oOrg:PackOrgInfo()})
        end
        interactive.Send(".world", "org", "OnJoinOrg", {
             playerinfo = {orgid=iOrgID,pid = pid,name = oMem:GetName(),position = oMem:GetPosition(),}
        })
        self:LogAnalyData(oOrg,pid,1)
    end
    record.user("org", "join", {pid=pid, orgid=iOrgID})
end

function COrgMgr:OnJoinDelApplys(pid, iOrgID)
    for orgid, oOrg in pairs(self.m_mNormalOrgs) do
        if iOrgID ~= orgid then
            oOrg:RemoveApply(pid)
        end
    end
end

function COrgMgr:GetApplysCnt(pid)
    local iCnt = 0
    for orgid, oOrg in pairs(self.m_mNormalOrgs) do
        if oOrg:GetApplyInfo(pid) then
            iCnt = iCnt + 1
        end
    end
    return iCnt
end

function COrgMgr:LeaveOrg(pid, iOrgID)
    local oOrg = self:GetNormalOrg(iOrgID)
    if oOrg then
        oOrg:OnLeaveOrg(pid)
        oOrg:RemoveMember(pid)
        self:SetPlayerOrgID(pid, nil)
        local oPlayer = self:GetOnlinePlayerByPid(pid)
        if oPlayer then
            self:SetLeaveOrgInfo(oPlayer,iOrgID)
            oPlayer:ShareChange()
            self:OffOrgChannel(iOrgID, oPlayer)
            oPlayer:PropChange("org_status", "org_id", "orgname")
            oPlayer:DelTimeCb("org_build")
            oPlayer:DoneOrgBuild()
        end
        self:RemoveOrgTitles(pid)
    end
end

function COrgMgr:SetLeaveOrgInfo(oPlayer,iOrgID)
    local mInfo = oPlayer:GetInfo("leaveorg",{})
    local iLeaveTime = mInfo["leavetime"] or 0
    if iLeaveTime == 0 then
        iLeaveTime = 1
    else
        iLeaveTime = get_time()
    end
    mInfo["leavetime"] = iLeaveTime
    mInfo["orgid"] = iOrgID
    oPlayer:SetInfo("leaveorg",mInfo)
    interactive.Send(".world", "org", "SetLeaveOrgInfo",
        {pid = oPlayer:GetPid(), leaveorgtime = iLeaveTime, orgid = iOrgID}
    )
end

function COrgMgr:OnCreateOrgFail(orgid)
end

function COrgMgr:OnOrgChangeName(sOldName, sNewName)
    local oOrg = self:GetNormalOrgByName(sOldName)
    if oOrg then
        self.m_mNormalOrgNames[sOldName] = nil
        self.m_mNormalOrgNames[sNewName] = oOrg
    end
end

function COrgMgr:OnOrgChangeFlag(sOldFlag, sNewFlag)
    local oOrg = self:GetNormalOrgByFlag(sOldFlag)
    if oOrg then
        self.m_mNormalOrgFlags[sOldFlag] = nil
        self.m_mNormalOrgFlags[sNewFlag] = oOrg
    end
end

function COrgMgr:GenerateCache()
    local mNormalOrgs = {}
    local lOrgIDs = table_key_list(self.m_mNormalOrgs)
    table.sort(lOrgIDs)
    for _, orgid in pairs(lOrgIDs) do
        local oOrg = self.m_mNormalOrgs[orgid]
        table.insert(mNormalOrgs, oOrg:PackOrgInfo())
    end
    self.m_mOrgListCache = mNormalOrgs
end

function COrgMgr:GetOrgListCache()
    return self.m_mOrgListCache
end

-- 这个方法只是同步玩家响应信息与申请信息
function COrgMgr:SyncPlayerData(iPid, mData)
    for _,oOrg in pairs(self.m_mNormalOrgs) do
        oOrg:SyncApplyData(iPid, mData)
    end
end

function COrgMgr:OnDisconnected(iPid)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
    local iOrgID = oPlayer:GetOrgID()
    self:OffOrgChannel(iOrgID, oPlayer)
    if oOrg then
        oOrg:LeaveWishUI(oPlayer:GetPid())
    end
end

function COrgMgr:OnLogout(iPid)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    local oOrg = oPlayer:GetOrg()
    if oOrg then
        self:OffOrgChannel(oOrg:OrgID(), oPlayer)
        oOrg:LeaveWishUI(iPid)
    end
    self.m_mPlayers[iPid] = nil
    baseobj_delay_release(oPlayer)
end

function COrgMgr:OnLogin(iPid, bReEnter, mInfo)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if bReEnter and not oPlayer then return end
    if not oPlayer then
        oPlayer = playerobj.NewPlayer(iPid,mInfo)
        self.m_mPlayers[iPid] = oPlayer
    end
    if not bReEnter then
        oPlayer:CheckOrgBuild()
        self:PushBackShareObj(oPlayer)
        oPlayer:ShareChange()
    end
    oPlayer:ClientPropChange()
    oPlayer:OnLogin(bReEnter)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
    local iOrgID = oOrg:OrgID()
    self:OnOrgChannel(iOrgID, oPlayer)
    if not bReEnter then
        self:PushOrgGradeAchieve(oPlayer)
        local info = oOrg:GetOrgUpdateInfo({online_count=true})
        self:UpdateOrgInfo(iOrgID,{info=info})
    end
    oPlayer:Send("GS2COrgMainInfo", {info=oOrg:PackOrgInfo()})
    if oOrg:IsOpenRedPacket() then
        oOrg:SendRedPacketUI(oPlayer)
    end
end

function COrgMgr:PushBackShareObj(oPlayer)
    local mData = {
        org_share = oPlayer:GetOrgInfoReaderCopy(),
        org_position = oPlayer:GetOrgPos(),
    }
    interactive.Send(".world", "org", "InitOrgShareObj", {
        pid = oPlayer:GetPid(),
        data = mData,
    })
end

function COrgMgr:PushOrgGradeAchieve(oPlayer)
    local oOrg = oPlayer:GetOrg()
    local iLevel = oOrg:GetLevel()
    for iGrade=1,5 do
        if iLevel >= iGrade then
            self:PushAchieve(oPlayer:GetPid(),string.format("公会等级大于等于%d级的数量",iGrade),{value=1})
        end
    end
end

function COrgMgr:GetOrgText(iText, m)
    local sText = colorstring.GetTextData(iText, {"org"})
    if sText and m then
        sText = colorstring.FormatColorString(sText, m)
    end
    return sText
end

function COrgMgr:GetOrgLog(iText,m)
    local mData = res["daobiao"]["org"]["org_log"]
    local sText = mData[iText]["text"]
    if sText and m then
        sText = colorstring.FormatColorString(sText,m)
    end
    return sText
end

function COrgMgr:GetNormalOrgList()
    return self.m_mNormalOrgs
end

function COrgMgr:GetAllowOrgID(oPlayer,power)
    local oTarget
    for iOrgID,oOrg in pairs(self.m_mNormalOrgs) do
        local powerlimit =oOrg:GetPowerLimit()
        local needallow = oOrg:GetNeedAllow()
        local iSpreadFlag = oOrg:GetSpreadFlag()
        local spread_power = oOrg.m_oBaseMgr:GetData("spread_power",0)
        local iCnt = oOrg:GetMemberCnt()
        if iSpreadFlag == 1 and power >= spread_power then
            oTarget = oTarget or oOrg
            if self:CompareOrg(oPlayer,oTarget,oOrg) then
                oTarget = oOrg
            end
        elseif needallow == 0 and power >= powerlimit and iCnt < oOrg:GetMaxMemberCnt() then
            oTarget = oTarget or oOrg
            if self:CompareOrg(oPlayer,oTarget,oOrg) then
                oTarget = oOrg
            end
        end
    end
    if oTarget then
        return oTarget:OrgID()
    end
    return 0
end

function COrgMgr:CompareOrg(oPlayer,oOrg,oOrg2)
    if oPlayer:IsPreLeaveOrg(oOrg2:OrgID()) then
        return false
    end
    if oOrg:OrgID() == oOrg2:OrgID() then
        return false
    end
    local iSpreadFlag = oOrg:GetSpreadFlag()
    local iSpreadFlag2 = oOrg2:GetSpreadFlag()
    if iSpreadFlag2 ~= iSpreadFlag then
        return iSpreadFlag2 > iSpreadFlag
    end
    local iLevel = oOrg:GetLevel()
    local iLevel2 = oOrg2:GetLevel()
    if iLevel ~= iLevel2 then
        return iLevel2 > iLevel
    end

    local iCnt = oOrg:GetMemberCnt()
    local iCnt2 = oOrg2:GetMemberCnt()
    if iCnt < 5 and iCnt2 < 5 then
        return math.random(2) == 1
    end
    return iCnt2 > iCnt
end

function COrgMgr:IsClose(oPlayer)
    local mControlData = res["daobiao"]["global_control"]["org"]
    if not mControlData then
        oPlayer:Notify("该功能正在维护，已临时关闭。请您留意系统公告。")
        return true
    end
    local sControl = mControlData["is_open"] or "y"
    if sControl == "n" then
        oPlayer:Notify("该功能正在维护，已临时关闭。请您留意系统公告。")
        return true
    end
    return false
end

function COrgMgr:OnOrgChannel(iOrgID, oPlayer)
    local mBroadcastRole = {
        pid = oPlayer:GetPid(),
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.ORG_TYPE, iOrgID, true},
        },
        info = mBroadcastRole,
    })
end

function COrgMgr:OffOrgChannel(iOrgID, oPlayer)
    local mBroadcastRole = {
        pid = oPlayer:GetPid(),
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.ORG_TYPE, iOrgID, false},
        },
        info = mBroadcastRole,
    })
end

function COrgMgr:ApplyJoinOrg(oPlayer,mData)
    local iPid = oPlayer:GetPid()
    local iOrgID = mData.orgid
    local flag = mData.flag
    local power = oPlayer:GetPower()

    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    if oPlayer:GetOrgID() ~= 0 then
        oPlayer:Notify(oOrgMgr:GetOrgText(1001))
        return
    end
    local iLeaveTime = oPlayer:GetPreLeaveOrgTime()
    if get_time() - iLeaveTime <= 3600 *12 then
        oPlayer:Notify(oOrgMgr:GetOrgText(2005))
        return
    end
    local iLimitGrade = res["daobiao"]["global_control"]["org"]["open_grade"]
    if oPlayer:GetGrade() < iLimitGrade then
        oPlayer:Notify(oOrgMgr:GetOrgText(1002, {grade=iLimitGrade}))
        return
    end

    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if not oOrg then
        oPlayer:Notify(oOrgMgr:GetOrgText(1003))
        return
    end
    local powerlimit = oOrg:GetPowerLimit()
    local needallow = oOrg:GetNeedAllow()
    if power < powerlimit then
        oPlayer:Notify("战斗力未达到限制战斗力，无法申请该公会")
        return
    end
    if needallow == 0 then
        local flag = oOrgMgr:AddForceMember(iOrgID,oPlayer)
        if not flag then
            oPlayer:Notify("公会成员已满")
        else
            oPlayer:Send("GS2COrgMainInfo", {info=oOrg:PackOrgInfo()})
            record.user("org", "join", {pid=iPid, orgid=iOrgID})
            self:LogAnalyData(oOrg,iPid,1)
        end
    else
        if not oOrg:GetApplyInfo(iPid) then
            local iLimitCnt = res["daobiao"]["org"]["rule"][1]["max_apply_num"]
            if oOrgMgr:GetApplysCnt(iPid) >= iLimitCnt then
                oPlayer:Notify("你申请的公会数量已达上限")
                return
            end
            oOrg:AddApply(oPlayer, orgdefines.ORG_APPLY.APPLY)
            oPlayer:Send("GS2CApplyJoinOrg",{flag=flag, orgid=iOrgID})
            record.user("org", "apply", {pid=iPid, orgid=iOrgID})
        else
            oPlayer:Notify("你已经申请了该公会")
        end
    end
end

function COrgMgr:ApplyJoinOrgBySpread(oPlayer,mData)
    local iPid = oPlayer:GetPid()
    local iOrgID = mData.orgid
    local power = oPlayer:GetPower()

    if self:IsClose(oPlayer) then
        return
    end
    if oPlayer:GetOrgID() ~= 0 then
        oPlayer:Notify(self:GetOrgText(1001))
        return
    end
    local iLeaveTime = oPlayer:GetPreLeaveOrgTime()
    if get_time() - iLeaveTime <= 3600 *12 then
        oPlayer:Notify(self:GetOrgText(2005))
        return
    end
    local iLimitGrade = res["daobiao"]["global_control"]["org"]["open_grade"]
    if oPlayer:GetGrade() < iLimitGrade then
        oPlayer:Notify(self:GetOrgText(1002, {grade=iLimitGrade}))
        return
    end

    local oOrg = self:GetNormalOrg(iOrgID)
    if not oOrg then
        oPlayer:Notify(self:GetOrgText(1003))
        return
    end
    if oOrg.m_oBaseMgr:GetData("spread_endtime",0) < get_time() then
        oPlayer:Notify("该公会不在招募时间")
        return
    end
    local spread_power = oOrg.m_oBaseMgr:GetData("spread_power",0)
    if power < spread_power then
        oPlayer:Notify("战斗力未达到限制战斗力，无法申请该公会")
        return
    end
    local flag = self:AddForceMember(iOrgID,oPlayer)
    if not flag then
        oPlayer:Notify("公会成员已满")
    else
        oPlayer:Send("GS2COrgMainInfo", {info=oOrg:PackOrgInfo()})
        record.user("org", "join", {pid=iPid, orgid=iOrgID})
        self:LogAnalyData(oOrg,iPid,1)
    end
end

function COrgMgr:SendMsg2Org(sMsg, iOrgID, oPlayer)
    local mRoleInfo = {pid = 0}                                 --系统
    if oPlayer then
        mRoleInfo = oPlayer:PackRole2OrgChat()
    end
    interactive.Send(".world", "org", "SendMsg2Org", {
        msg = sMsg,
        orgid = iOrgID,
        roleinfo = mRoleInfo,
    })
end

function COrgMgr:CalAddOrgTime(iPid,iTimes)
    interactive.Send(".world", "org", "CalAddOrgTime", {
        pid = iPid,
        time = iTimes,
    })
end

function COrgMgr:ValidDoOrg(oPlayer)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return false
    end
    local iPid = oPlayer:GetPid()
    local oMem = oOrg:GetMember(iPid)
    if not oMem then
        return false
    end
    return true
end

function COrgMgr:StartOrgBuild(oPlayer,mData)
    local iBuildType = mData["build_type"]
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local iPid = oPlayer:GetPid()
    local oMem = oOrg:GetMember(iPid)
    if not oMem then
        return
    end
    local mBuildData = orgdefines.GetBuildData(iBuildType)
    if not mBuildData then
        return
    end
    local sFunName,iVal
    if mBuildData["cost_gold"] > 0 then
        iVal = mBuildData["cost_gold"]
        sFunName = "ResumeGoldCoin"
    elseif mBuildData["cost_coin"] > 0 then
        iVal = mBuildData["cost_coin"]
        sFunName = "ResumeCoin"
    else
        return
    end
    if oPlayer:OrgBuildStatus() ~= 0 then
        return
    end
    if oMem:InLock("orgbuild") then
        return
    end
    oMem:Lock("orgbuild",4)
    interactive.Request(".world", "org", sFunName, {pid = iPid,value=iVal,sReason="公会建设"}, function (mRecord, mData2)
        if mData2.suc then
            self:StartOrgBuild2(iPid, iBuildType)
        end
    end)
end

function COrgMgr:StartOrgBuild2(iPid,iBuildType)
    local mBuildData = orgdefines.GetBuildData(iBuildType)
    if not mBuildData then
        return
    end
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local oMem = oOrg:GetMember(iPid)
    if not oMem then
        return
    end

    local iTimes = mBuildData["time"]
    oPlayer:StartOrgBuild(iBuildType,iTimes)
    local iSignDegree = mBuildData["sign_degree"]
    oOrg:AddSignDegree(iSignDegree)
    local sName = mBuildData["build_name"]
    record.user("org", "orgbuild", {pid=iPid, orgid=oOrg:OrgID(),build_name=sName,build_type=iBuildType})
    self:DoneOrgBuild(oPlayer)
end

function COrgMgr:SpeedOrgBuild(oPlayer,mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local iPid = oPlayer:GetPid()
    local oMem = oOrg:GetMember(iPid)
    if not oMem then
        return
    end
    if not oPlayer:IsOrgBuilding() then
        oPlayer:Notify("建设进度已经过期")
        return
    end
    local iGoldCoin = mData["gold_coin"]
    local iBuildTime = oPlayer:GetToday("org_build_time")
    local iHour = math.ceil((iBuildTime - get_time())/3600)
    local iVal = res["daobiao"]["org"]["rule"][1]["org_sign_cash"]
    local iCalGoldCoin = iHour * iVal
    iCalGoldCoin = math.max(iCalGoldCoin,iVal)
    if iGoldCoin ~= iCalGoldCoin then
        oPlayer:Notify("水晶计算有误，请确认")
        return
    end
    interactive.Request(".world", "org", "ResumeGoldCoin", {pid = iPid,value=iGoldCoin,reason="加快公会建设"}, function (mRecord, mData)
        if mData.suc then
            self:SpeedOrgBuild2(iPid,iGoldCoin)
        end
    end)
end

function COrgMgr:SpeedOrgBuild2(iPid,iGoldCoin)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
    oPlayer:OrgBuildFinish()
    record.user("org", "speedbuild", {pid=iPid, orgid=oOrg:OrgID(),goldcoin=iGoldCoin})
end

function COrgMgr:DoneOrgBuild(oPlayer)
    local iPid = oPlayer:GetPid()
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    if not oPlayer:IsOrgBuildDone() then
        oPlayer:Notify("建设进度已经过期")
        return
    end
    oPlayer:DoneOrgBuild()
    local iBuildType = oPlayer:GetToday("org_build_type",0)
    local mData = orgdefines.GetBuildData(iBuildType)
    local iCash = mData["start_cash"] + mData["cash"]
    local iExp = mData["start_exp"] + mData["exp"]
    local iOffer = mData["start_offer"] + mData["offer"]
    local sReason = "公会建设完成"

    oOrg:AddCash(iCash,sReason)
    oOrg:AddExp(iExp,sReason)
    oPlayer:RewardOrgOffer(iOffer,sReason,{cancel_tip=1})
    oPlayer:PushBookCondition("完成公会建设任务次数", {value = 1})

    local sText = self:GetOrgText(1024, {orgcash=iCash,orgexp=iExp})
    oPlayer:Notify(sText)

    record.user("org", "build_done", {pid=iPid, orgid=oOrg:OrgID(),build_type=iBuildType})

    local oOrgMgr = global.oOrgMgr
    local sName = mData["build_name"]
    local sLog = oOrgMgr:GetOrgLog(1002,{rolename=oPlayer:GetName(),buildname=sName})
    oOrg:AddLog(oPlayer:GetPid(),sLog)

     self:PushAchieve(iPid,"公会建设次数",{value=1})
end

function COrgMgr:OrgSignReward(oPlayer,mData)
    local idx = mData["idx"]
    local iPid = oPlayer:GetPid()
    if oPlayer:IsOrgSignReward(idx) then
        oPlayer:Notify("该奖励无法重复领取")
        return
    end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local mData = orgdefines.GetOrgSignRewardData(idx)
    if not mData then
        return
    end
    local iSignDegree = mData["sign_degree"]
    if not iSignDegree then
        return
    end
    local iNowSignDegree = oOrg:GetSignDegree()
    if iNowSignDegree < iSignDegree then
        oPlayer:Notify("领取失败，未达到领取要求")
        return
    end
    oPlayer:SetOrgSignReward(idx)

    self:OrgSignRewardToPlayer(iPid,mData["item_list"])

    record.user("org", "orgsignreward", {pid=iPid, orgid=oOrg:OrgID(),idx=idx})
end

function COrgMgr:OrgSignRewardToPlayer(iPid,mItemList)
    interactive.Send(".world", "org", "OrgSignReward", {
        pid = iPid,
        item_list = mItemList
    })
end

function COrgMgr:OrgWishList(oPlayer)
    if not self:ValidDoOrg(oPlayer) then
        return
    end
    local iPid = oPlayer:GetPid()
    local oOrg = oPlayer:GetOrg()
    local mData = oOrg:GetOrgWishList()
    oPlayer:Send("GS2COrgWishList",{
        mem_list = mData
    })
    oOrg:OpenWishUI(iPid)
    local oMember = oOrg:GetMember(iPid)
    if oMember then
        oMember:GiveWishItem()
        oMember:GiveWishEquip()
    end
end

function COrgMgr:ValidOrgWish(oPlayer,iPartnerType)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return false
    end
    local iPid = oPlayer:GetPid()
    local oMem = oOrg:GetMember(iPid)
    if not oMem then
        return false
    end
    if oPlayer:GetToday("org_wish",0) == 1 then
        return false
    end
    if oMem:IsOrgWish() then
        oPlayer:Notify(self:GetOrgText(3002))
        return
    end
    return true
end

function COrgMgr:GetItemData(iSID)
    local res = require "base.res"
    local mData = res["daobiao"]["item"][iSID]
    assert(mData,string.format("itembase GetItemData err:%s",self.m_SID))
    return mData
end

function COrgMgr:OrgWish(oPlayer,mData)
    local iPartnerChip = mData["partner_chip"]
    if not iPartnerChip then
        return
    end
    local iPid = oPlayer:GetPid()
    if not self:ValidDoOrg(oPlayer) then
        return
    end
    if not self:ValidOrgWish(oPlayer,iPartnerChip) then
        return
    end
    local oOrg = oPlayer:GetOrg()
    local oMem = oOrg:GetMember(iPid)

    local mItemData = self:GetItemData(iPartnerChip)
    if not mItemData then return end

    local iPartnerType = mItemData["partner_type"]
    local mPartnerData = self:GetPartnerData(iPartnerType)
    local iRare = mPartnerData["rare"]
    local mWishData = orgdefines.GetOrgWishData(iRare)
    if not mWishData then
        record.info("orgwish err partner type "..iPartnerType.."  chip "..iPartnerChip.." pid "..iPid)
        return
    end
    local iSumCnt = mWishData["amount"]
    local mData = {
        partner_chip = iPartnerChip,
        partner_type = iPartnerType,
        sum_cnt = iSumCnt,
        gain_cnt = 0,
    }
    oMem:RefreshOrgWish(mData)
    local mData = oMem:PackOrgMemInfo()
    oPlayer:Send("GS2CRefreshOrgMember",{mem_info = mData})
    oPlayer:SetToday("org_wish",1)
    oPlayer:PropChange("is_org_wish")

    local sKey = string.format("许愿%s次数", mItemData["name"])
    oPlayer:PushBookCondition(sKey, {value = 1})
    self:PushAchieve(iPid,"伙伴碎片许愿次数",{value=1})

    record.user("org", "orgwish", {pid=iPid, orgid=oOrg:OrgID(),partner_chip=iPartnerChip})

    oPlayer:AddSchedule("OrgWish")

    local mTip = {6001,6002}
    local iMsg = mTip[math.random(#mTip)]
    local iQuality = mItemData.quality
    local sName = self:ForMatItemColor(iQuality,mItemData.name)
    local sMsg = self:GetOrgText(iMsg, {name=sName})
    sMsg = "{link24,"..iPartnerChip..","..oPlayer:GetName()..", "..iPid..","..sMsg.."}"
    self:HandleOrgChat(oPlayer,sMsg)
end

function COrgMgr:GiveOrgWish(oPlayer,mData)
    local iPid = oPlayer:GetPid()
    local iTarget = mData["target"]
    if not self:ValidDoOrg(oPlayer) then
        return
    end
    if iPid == iTarget then
        oPlayer:Notify("自己无法完成自己的愿望")
        return
    end
    local oOrg = oPlayer:GetOrg()
    local oTarget = oOrg:GetMember(iTarget)
    if not oTarget then
        return
    end
    local iLimit = res["daobiao"]["org"]["rule"][1]["give_wish_limit"]
    if iLimit <= oPlayer:GetToday("give_wish_cnt",0) then
        oPlayer:Notify(self:GetOrgText(5002))
        return
    end
    if not oTarget:IsOrgWish() then
        oPlayer:Notify(self:GetOrgText(3001))
        return
    end
    if oTarget:IsDoneWish() then
        oPlayer:Notify(self:GetOrgText(3001))
        return
    end
    local mGive = oPlayer:GetToday("give_org_wish",{})
    if mGive[iTarget] then
        oPlayer:Notify(self:GetOrgText(3003))
        return
    end

    local oMem = oOrg:GetMember(iPid)
    if not oMem then return end
    if oMem:InLock("givewish") then return end
    oMem:Lock("givewish",4)

    local iOrgID = oPlayer:GetOrgID()
    local iPartnerChip = oTarget:GetWishPartnerItem()
    local mItemList = {{iPartnerChip,1}}

    local fCallback = function (mRecord,mData)
         self:GiveOrgWish2(iOrgID,iPid,iTarget)
         record.user("org", "givewish", {pid=iPid, orgid=iOrgID,target=iTarget,partner_chip=iPartnerChip})
    end
    self:RemoveItemList(iPid,mItemList,"帮助公会许愿",fCallback)
end

function COrgMgr:RemoveItemList(iPid,mItemList,sReason,fCallback)
    local mInfo = {
        pid = iPid,
        itemlist = mItemList,
        reason = sReason,
    }
    interactive.Request(".world", "org", "RemoveItemList", mInfo, function (mRecord, mData)
        if mData.suc then
            fCallback()
        end
    end)
end

function COrgMgr:ForMatItemColor(iQuality, sName)
    local res = require "base.res"
    local mData = res["daobiao"]["itemcolor"][iQuality]
    assert(mData, string.format("format org item color err:%s,%s", iQuality, sName))
    return string.format(mData.color,sName)
end

function COrgMgr:GiveOrgWish2(iOrgID,iPid,iTarget)
    local oOrg = self:GetNormalOrg(iOrgID)
    assert(oOrg,string.format("give org wish err:%s %s %s",iOrgID,iPid,iTarget))
    local oMember = oOrg:GetMember(iPid)
    local oTarget = oOrg:GetMember(iTarget)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if not oPlayer or not oTarget or not oMember then
        return
    end

    oMember:Unlock("givewish")
    oPlayer:AddToday("give_wish_cnt",1)
    oPlayer:AddOrgWish(iTarget)

    local mWishData = oTarget:GetOrgWishData()
    local iPartnerChip = mWishData["partner_chip"]
    local iPartnerType = mWishData["partner_type"]
    local mPartnerData = self:GetPartnerData(iPartnerType)
    local iRare = mPartnerData["rare"]
    local mWishData = orgdefines.GetOrgWishData(iRare)
    local iOrgOffer = mWishData["org_offer"] or 1

    oPlayer:RewardOrgOffer(iOrgOffer,"帮助公会许愿")

    oTarget:AddWishPartnerItem(oPlayer)

    local mData = oTarget:PackOrgMemInfo()
    oPlayer:Send("GS2CRefreshOrgMember",{mem_info = mData})

    if oOrg:InOrgWishUI(iTarget) then
        oTarget:GiveWishItem()
    end

    local sKey = string.format("许愿池捐赠%s", mPartnerData.name)
    oPlayer:PushBookCondition(sKey, {value=1})
    self:PushAchieve(iPid,"给予其他玩家许愿内容次数",{value=1})

    local iLimit = res["daobiao"]["org"]["rule"][1]["give_wish_limit"]
    local iRest = iLimit - oPlayer:GetToday("give_wish_cnt",0)

    local mItemData = self:GetItemData(iPartnerChip)
    local iQuality = mItemData.quality
    local sName = self:ForMatItemColor(iQuality,mItemData.name)

    local sMsg = self:GetOrgText(5001, {name=sName,cnt=iRest})
    oPlayer:Notify(sMsg)

    sMsg = self:GetOrgText(6003, {role1=oMember:GetName(),role2=oTarget:GetName(),name=sName})
    self:SendMsg2Org(sMsg,iOrgID)
end

--公会装备许愿

function COrgMgr:ValidOrgWishEquip(oPlayer)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return false end
    local oMem = oOrg:GetMember(oPlayer:GetPid())
    if not oMem then return false end
    if oPlayer:GetToday("org_wish_equip",0) == 1 then
        return false
    end
    if oMem:IsOrgWishEquip() then
        oPlayer:Notify(self:GetOrgText(3002))
        return
    end
    return true
end

function COrgMgr:OrgWishEquip(oPlayer,mData)
    local sid = mData["sid"]
    if not self:ValidDoOrg(oPlayer) then
        return
    end
    if not self:ValidOrgWishEquip(oPlayer) then
        return
    end
    local iPid = oPlayer:GetPid()
    local oOrg = oPlayer:GetOrg()
    local oMem = oOrg:GetMember(iPid)
    local mItemData = self:GetItemData(sid)
    if not mItemData then return end

    local mWishData = orgdefines.GetOrgWishEquipData(sid)
    local iSumCnt = mWishData["amount"]
    local mData = {
        sid = sid,
        sum_cnt = iSumCnt,
        gain_cnt = 0,
    }
    oMem:RefreshOrgWishEquip(mData)
    local mData = oMem:PackOrgMemInfo()

    oPlayer:Send("GS2CRefreshOrgMember",{mem_info = mData})
    oPlayer:SetToday("org_wish_equip",1)
    oPlayer:PropChange("is_equip_wish")

    record.user("org", "equipwish", {pid=iPid, orgid=oOrg:OrgID(),sid=sid})

    local mTip = {6001,6002}
    local iMsg = mTip[math.random(#mTip)]
    local iQuality = mItemData.quality
    local sName = self:ForMatItemColor(iQuality,mItemData.name)

    local sMsg = self:GetOrgText(iMsg, {name=sName or ""})
    sMsg = "{link24,"..sid..","..oPlayer:GetName()..", "..iPid..","..sMsg.."}"
    self:HandleOrgChat(oPlayer,sMsg)
end

function COrgMgr:GiveOrgEquipWish(oPlayer,mData)
    if not self:ValidDoOrg(oPlayer) then return end

    local iTarget = mData.target
    local iPid = oPlayer:GetPid()
    local oOrg = oPlayer:GetOrg()
    local oTarget = oOrg:GetMember(iTarget)
    if not oTarget then
        return
    end
    if iPid == iTarget then
        oPlayer:Notify("自己无法完成自己的愿望")
        return
    end
    local iLimit = res["daobiao"]["org"]["rule"][1]["give_wish_limit"]
    if iLimit <= oPlayer:GetToday("give_wish_cnt",0) then
        oPlayer:Notify(self:GetOrgText(5002))
        return
    end
    if not oTarget:IsOrgWishEquip() or  oTarget:IsDoneEquipWish() then
        oPlayer:Notify(self:GetOrgText(3001))
        return
    end
    local mGive = oPlayer:GetToday("give_org_equip",{})
    if mGive[iTarget] then
        oPlayer:Notify(self:GetOrgText(3003))
        return
    end
    local sid = oTarget:GetWishEquipItem()

    local oMem = oOrg:GetMember(iPid)
    if not oMem then return end
    if oMem:InLock("givewish") then return end
    oMem:Lock("givewish",4)

    local iOrgID = oOrg:OrgID()
    local fCallback = function (mRecord,mData)
        local oOrgMgr = global.oOrgMgr
        local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:GiveOrgEquipWish2(oPlayer,iTarget)
            record.user("org", "giveequipwish", {pid=iPid, orgid=iOrgID,target=iTarget,sid=sid})
        end
    end

    self:RemoveItemList(iPid,{{sid,1}},"帮助公会许愿",fCallback)
    self:PushAchieve(iPid,"给予其他玩家许愿内容次数",{value=1})
end

function COrgMgr:GetItemName(iSid)
    local res = require "base.res"
    local mData = res["daobiao"]["item"][iSid]
    return mData["name"] or ""
end

function COrgMgr:GiveOrgEquipWish2(oPlayer,iTarget)
    local oOrg = oPlayer:GetOrg()
    local oMember = oOrg:GetMember(oPlayer:GetPid())
    local oTarget = oOrg:GetMember(iTarget)
    if not oMember or not oTarget then return end

    oTarget:Unlock("givewish")
    oPlayer:AddToday("give_wish_cnt",1)
    oPlayer:AddOrgEquipWish(iTarget)

    local sid = oTarget:GetWishEquipItem()
    local mWishData = orgdefines.GetOrgWishEquipData(sid)
    local iOrgOffer = mWishData["org_offer"] or 1
    oPlayer:RewardOrgOffer(iOrgOffer,"帮助公会许愿")


    oTarget:AddWishEquip(oPlayer)

    local mData = oTarget:PackOrgMemInfo()
    oPlayer:Send("GS2CRefreshOrgMember",{mem_info = mData})
    if oOrg:InOrgWishUI(iTarget) then
        oTarget:GiveWishEquip()
    end

    local iLimit = res["daobiao"]["org"]["rule"][1]["give_wish_limit"]
    local iRest = iLimit - oPlayer:GetToday("give_wish_cnt",0)
    local mItemData = self:GetItemData(sid)

    local iQuality = mItemData.quality
    local sName = self:ForMatItemColor(iQuality,mItemData["name"] or "")

    local sMsg = self:GetOrgText(5001, {name=sName,cnt=iRest})
    oPlayer:Notify(sMsg)

    sMsg = self:GetOrgText(6003, {role1=oMember:GetName(),role2=oTarget:GetName(),name=sName})
    self:SendMsg2Org(sMsg,oOrg:OrgID())
end

function COrgMgr:ValidOpenRedPacket(oPlayer)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return false
    end
    local iPid = oPlayer:GetPid()
    local iPosition = oOrg:GetPosition(iPid)
    if not table_in_list({orgdefines.ORG_POSITION.LEADER,orgdefines.ORG_POSITION.DEPUTY},iPosition) then
        oPlayer:Notify("仅会长和副会长可以开启")
        return false
    end
    if oOrg:GetOpenRedPacket() > 0 then
        oPlayer:Notify("已经开启了红包玩法")
        return false
    end
    if oOrg:IsOpenRedPacket() == 1 then
        oPlayer:Notify("已经开启了红包玩法")
        return false
    end
    if oOrg.m_TestHongBao then
        return true
    end
    local iTime = get_time()
    local mDate = os.date("*t",iTime)
    local iHour = mDate.hour
    if iHour < 19 or iHour >= 21 then
        oPlayer:Notify("未达到活动时间，请于19点到21点开启抢夺")
        return false
    end
    return true
end

function COrgMgr:OpenOrgRedPacket(oPlayer,mData)
    if not self:ValidOpenRedPacket(oPlayer) then
        return
    end
    local oOrg = oPlayer:GetOrg()
    oOrg:SetOpenRedPacket()
    local mData = orgdefines.GetHongBaoData()
    local iSignDegree = oOrg:GetSignDegree()
    local bRedPacket = false
    for idx,mSignData in pairs(mData) do
        local iSign = mSignData["sign_degree"]
        if iSign <= iSignDegree then
            bRedPacket = true
            local iGold = mSignData["gold"]
            local iAmount = mSignData["amount"]
            oOrg:OpenRedPacket(oPlayer,idx,iGold,iAmount)
        end
    end
    if not bRedPacket then
        oOrg:UpdateOrgInfo({is_open_red_packet=true})
        return
    end
    oOrg:CheckRedPacketUI()
    local sMsg = string.format("【%s】开启了红包，大家快去抢，先到先得~",oPlayer:GetName())
    self:SendMsg2Org(sMsg,oPlayer:GetOrgID())

    local sText = self:GetOrgLog(1014,{rolename=oPlayer:GetName()})
    oOrg:AddLog(oPlayer:GetPid(),sText)
    oOrg:UpdateOrgInfo({red_packet = true,is_open_red_packet=true})
    local iPid = oPlayer:GetPid()
    local iPosition = oOrg:GetPosition(iPid)
    record.user("org", "openredpacket", {pid=iPid, orgid=oOrg:OrgID(),position=iPosition})
end

function COrgMgr:DrawOrgRedPacket(oPlayer,mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local idx = mData["idx"]
    if not table_in_list({1,2,3},idx) then
        return
    end
    local iPid = oPlayer:GetPid()
    if not oOrg:ValidDrawRedPacket(oPlayer,idx) then
        local mData = oOrg:GetDrawRedPacketInfo(iPid,idx)
        if not mData then
            return
        end
        oPlayer:Send("GS2CDrawOrgRedPacket",mData)
        return
    end
    if oPlayer:IsOrgRedPacket(idx) then
        oPlayer:Notify(self:GetOrgText(1022))
        return
    end
    oOrg:DrawOrgRedPacket(oPlayer,idx)

    self:ShowKeepItem(iPid)

    record.user("org", "drawredpacket", {pid=iPid, orgid=oOrg:OrgID(),idx=idx})
end

function COrgMgr:ShowKeepItem(iPid)
    interactive.Send(".world", "org", "ShowKeepItem", {
        pid = iPid,
    })
end

function COrgMgr:SendOrgRedPacket(oPlayer,mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local idx = mData["idx"]
    oOrg:SendOrgRedPacket(oPlayer,idx)
end

function COrgMgr:SendOrgLog(oPlayer,mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    oOrg:SendOrgLog(oPlayer)
end

function COrgMgr:ValidPromoteOrgLevel(oPlayer)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return false
    end
    local iPid = oPlayer:GetPid()
    if not oOrg:HasPromoteOrgLevel(iPid) then
        return false
    end
    return true
end

function COrgMgr:PromoteOrgLevel(oPlayer)
    if not self:ValidPromoteOrgLevel(oPlayer) then
        return
    end
    local oOrg = oPlayer:GetOrg()
    if not oOrg:ValidPromoteLevel() then
        oPlayer:Notify(self:GetOrgText(4003))
        return
    end
    oOrg:PromoteLevel(oPlayer)
end

function COrgMgr:SpreadOrg(oPlayer,powerlimit)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local iPid = oPlayer:GetPid()
    if not oOrg:HasInvite(iPid) then
        return
    end
    local oMem = oOrg:GetMember(iPid)
    if not oMem then
        return
    end
    if oMem:InLock("orgspread") then
        return
    end
    oMem:Lock("orgspread",2)
    interactive.Request(".world", "org", "ResumeGoldCoin", {pid = iPid,value=200,reason="公会招募"}, function (mRecord, mData)
        if mData.suc then
            local oP = self:GetOnlinePlayerByPid(iPid)
            if oP then
                self:SpreadOrg2(oP, powerlimit)
            end
        end
    end)
end

function COrgMgr:SpreadOrg2(oPlayer,powerlimit)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local iPid = oPlayer:GetPid()
    if not oOrg:HasInvite(iPid) then
        return
    end
    if powerlimit then
        oOrg.m_oBaseMgr:SetData("spread_power",powerlimit)
    end
    oOrg.m_iSpreadWorld = get_time() + 3600

    local iNowTime = get_time()
    local iTime = oOrg.m_oBaseMgr:GetData("spread_endtime",0)
    if iTime > iNowTime then
        iTime = iTime + 3600
    else
        iTime = iNowTime + 3600
    end
    oOrg.m_oBaseMgr:SetData("spread_endtime",iTime)

    oOrg:UpdateOrgInfo({spread_endtime=true})

    interactive.Send(".world", "org", "SpreadOrg", {
        pid = iPid,
        orgid = oOrg:OrgID(),
        orgname = oOrg:GetName()
    })
end

function COrgMgr:ClickOrgRecruit(oPlayer,mData)
    local iOrgID = mData["orgid"]
    local oOrg = self:GetNormalOrg(iOrgID)
    if not oOrg then
        oPlayer:Notify(self:GetOrgText(4007))
        return
    end
    if oPlayer:GetOrg() then
        oPlayer:Notify(self:GetOrgText(4008))
        return
    end
    local mData = {
        orgid = iOrgID
    }
    self:ApplyJoinOrg(oPlayer,mData)
end

function COrgMgr:OrgOnlineCount(oPlayer,mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    oPlayer:Send("GS2COrgOnlineCount",{
        online_count = oOrg:GetOnlineMemberCnt()
    })
end

function COrgMgr:LogAnalyData(oOrg,iPid,operation)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    local mLog = {}
    mLog["operation"] = operation
    mLog["faction_id"] = oOrg:OrgID()
    mLog["faction_level"] = oOrg:GetLevel()
    mLog["faction_name"] = oOrg:GetName()
    mLog["faction_pro"] = oOrg:GetPosition(iPid)
    mLog["faction_num"] = oOrg:GetMemberCnt()
    if operation ~= 1 then
        mLog["faction_num"] = mLog["faction_num"] - 1
    end
    interactive.Send(".world", "org", "LogAnalyData", {
        pid = iPid,
        log = mLog,
    })
end

function COrgMgr:UpdateOrgInfo(iOrgID,mNet)
    interactive.Send(".broadcast", "channel", "SendChannel", {
        message = "GS2CUpdateOrgInfo",
        id = iOrgID,
        type = gamedefines.BROADCAST_TYPE.ORG_TYPE,
        data = mNet,
        exclude = {},
    })
end

function COrgMgr:SendOrgMessage(iOrgID,sMessage,mNet)
    interactive.Send(".broadcast", "channel", "SendChannel", {
        message = sMessage,
        id = iOrgID,
        type = gamedefines.BROADCAST_TYPE.ORG_TYPE,
        data = mNet,
        exclude = {},
    })
end

function COrgMgr:SyncTerraWarInfo(oOrg,mData)
    local mInfo = oOrg:GetOrgUpdateInfo(mData)
    interactive.Send(".world","org","SyncTerraWarInfo",{
        id = oOrg:OrgID(),
        data = mInfo,
        exclude = {},
        })
end

function COrgMgr:SetPlayerOrgID(iPid, iOrgID)
    self.m_mPlayer2OrgID[iPid] = iOrgID
end

function COrgMgr:GetPlayerOrgID(iPid)
    return self.m_mPlayer2OrgID[iPid]
end

function COrgMgr:GetPlayerOrg(iPid)
    local iOrgID = self.m_mPlayer2OrgID[iPid]
    if iOrgID then
        return self:GetNormalOrg(iOrgID)
    end
end

function COrgMgr:ReciveOrgRank(mInfo)
    mInfo = mInfo or {}
    for _,mUnit in pairs(mInfo) do
        local orgid,iRank = table.unpack(mUnit)
        local oOrg = self:GetNormalOrg(orgid)
        if oOrg then
            oOrg:SetRank(iRank)
        end
    end
end

function COrgMgr:Send(iPid,sMessage,mData)
    playersend.Send(iPid,sMessage,mData)
end

function COrgMgr:Notify(iPid,sMsg)
    self:Send(iPid,"GS2CNotify", {cmd = sMsg})
end

function COrgMgr:LogChat(pid,name,channel,text)
    local mLog = {
        pid = pid,
        name = name,
        channel = channel,
        text = text,
        svr = skynet.getenv("server_key"),
    }
    record.chat("chat","chat",mLog)
end

function COrgMgr:HandleOrgChat(oPlayer, sMsg)
    sMsg = trim(sMsg)
    local oOrg = oPlayer:GetOrg()

    if string.len(sMsg) == 0 or not oOrg then return end
    local oMem = oOrg:GetMember(oPlayer:GetPid())

    if not oMem or not oMem:CheckBanChat() then return end
    local iType = gamedefines.CHANNEL_TYPE.ORG_TYPE

    self:SendMsg2Org(sMsg, oPlayer:GetOrgID(), oPlayer)
end

function COrgMgr:SendOrgChat(sMsg, iOrgID, mRole, mExclude)
    if mRole["pid"] ~= 0 then
        self:LogChat(mRole["pid"],mRole["name"],gamedefines.CHANNEL_TYPE.ORG_TYPE,sMsg)
    end
    local mNet = {
        cmd = sMsg,
        type = gamedefines.CHANNEL_TYPE.ORG_TYPE,
        role_info = mRole,
    }

    interactive.Send(".broadcast", "channel", "SendChannel", {
        message = "GS2CChat",
        id = iOrgID,
        type = gamedefines.BROADCAST_TYPE.ORG_TYPE,
        data = mNet,
        exclude = mExclude,
    })
end

function COrgMgr:GetOnlinePlayerByPid(iPid)
    return self.m_mPlayers[iPid]
end

function COrgMgr:PushDataToOrgPrestigeRank(oOrg)
    local mData = {}
    mData.orgid = oOrg:OrgID()
    mData.org_level = oOrg:GetLevel()
    mData.org_name = oOrg:GetName()
    mData.flag = oOrg:GetSFlag()
    mData.leader = oOrg:GetLeaderName()
    mData.prestige = oOrg:GetPrestige()
    mData.flagbgid = oOrg:GetFlagBgID()
    mData.time = get_time()

    interactive.Send(".world", "org", "PushOrgPrestigeRank", {name="orgprestige",data=mData})
end

function COrgMgr:GetMailInfo(iIdx)
    local mInfo = res["daobiao"]["mail"][iIdx]
    local mData = {
        title = mInfo.desc,
        subject = mInfo.subject,
        context = mInfo.content,
        keeptime = mInfo.keepday * 3600 * 24,
        readtodel = mInfo.readtodel,
        autoextract = mInfo.autoextract,
    }
    return mData, mInfo.name
end

function COrgMgr:SendMail(iSendeId, sSenderName, iReceiverId, mMailInfo, mMoney, mItems, mPartners)
    interactive.Send(".world", "org", "SendMail", {
        iSendeId = iSendeId,
        sSenderName = sSenderName,
        iReceiverId = iReceiverId,
        mMailInfo = mMailInfo,
        mMoney = mMoney,
        mItems = mItems,
        mPartners = mPartners
    })
end

--伙伴导表数据
function COrgMgr:GetPartnerData(iPartnerType)
    local res = require "base.res"
    local mData = res["daobiao"]["partner"]["partner_info"][iPartnerType]
    assert(mData, string.format("partnerdata err:%s", iPartnerType))
    return mData
end

function COrgMgr:GiveItem(iPid,sidlist,sReason,mArgs)
    interactive.Send(".world", "org", "GiveItem", {
        pid = iPid,
        sidlist = sidlist,
        sReason = sReason,
        mArgs = mArgs
    })
end

function COrgMgr:RewardOrgRedPacket(iPid,iRewardGold,iID)
    interactive.Send(".world", "org", "RewardOrgRedPacket", {
        pid = iPid,
        gold = iRewardGold,
        id = iID,
    })
end

function COrgMgr:OnUpdatePosition(iPid,iPosition)
    local mData = {
        position = iPosition,
        pid = iPid,
    }
    interactive.Send(".rank", "rank", "OnUpdatePosition", mData)
    interactive.Send(".world", "org", "OnUpdatePosition", mData)
end

function COrgMgr:CloseGS()
    save_all()
end

function COrgMgr:OnKickMember(iPid)
    interactive.Send(".world", "org", "OnKickMember", {
        pid = iPid,
    })
end

function COrgMgr:SetPlayerPropChange(iPid, l)
    local mNow = self.m_mPlayerPropChange[iPid]
    if not mNow then
        mNow = {}
        self.m_mPlayerPropChange[iPid] = mNow
    end
    for _, v in ipairs(l) do
        mNow[v] = true
    end
end

function COrgMgr:SendPlayerPropChange()
    if next(self.m_mPlayerPropChange) then
        local mPlayerPropChange = self.m_mPlayerPropChange
        for k, v in pairs(mPlayerPropChange) do
            local oPlayer = self:GetOnlinePlayerByPid(k)
            if oPlayer and next(v) then
                safe_call(oPlayer.ClientPropChange,oPlayer,v)
            end
        end
        self.m_mPlayerPropChange = {}
    end
end

function COrgMgr:SetPlayerShareChange(iPid, l)
    self.m_mPlayerShareChange[iPid] = true
end

function COrgMgr:SendPlayerShareChange()
    if next(self.m_mPlayerShareChange) then
        local mPlayerShareChange = self.m_mPlayerShareChange
        for iPid, _ in pairs(mPlayerShareChange) do
            local oPlayer = self:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                safe_call(oPlayer.HookShareChange,oPlayer)
            end
        end
        self.m_mPlayerShareChange = {}
    end
end

function COrgMgr:OrgDispatchFinishHook()
    self:SendPlayerPropChange()
    self:SendPlayerShareChange()
end

function COrgMgr:UpdateRankOrgInfo(oOrg)
    local mInfo = {
        org_level=oOrg:GetLevel(),
        flag=oOrg:GetSFlag(),
        leader=oOrg:GetLeaderName(),
        flagbgid=oOrg:GetFlagBgID()
    }
    interactive.Send(".rank", "rank", "OnUpdateOrgInfo", {orgid=oOrg:OrgID(),info=mInfo})
end

function COrgMgr:StartOrgWar()
    local orglist = {}
    local spareinfo
    local spare_active = 0
    for _,oOrg in pairs(self.m_mNormalOrgs) do
        local iactive = oOrg:GetActivePoint()
        if iactive >= 4800 then
            table.insert(orglist,{id=oOrg:OrgID(),active=oOrg:GetActivePoint(),name=oOrg:GetName()})
        else
            if iactive > spare_active then
                spare_active = iactive
                spareinfo = {id=oOrg:OrgID(),active=oOrg:GetActivePoint(),name=oOrg:GetName()}
            end
        end
    end
    table.sort(orglist, function(v1, v2)
        if v1.active == v2.active then
            return v1.id < v2.id
        end
        return v1.active > v2.active
    end)
    for iNo=#orglist,21,-1 do
        table.remove(orglist,iNo)
    end
    if #orglist % 2 == 1 then
        if spareinfo then
            table.insert(orglist,spareinfo)
        else
            table.remove(orglist,#orglist)
        end
    end
    for _,info in pairs(orglist) do
        local oOrg = self:GetNormalOrg(info.id)
        if oOrg then
            self:SendAllMemMail(oOrg,72)
        end
    end
    if #orglist >= 2 then
        self:SetOrgWarOpen(true)
    end
    return orglist
end

function COrgMgr:SetOrgWarOpen(Val)
    self.m_bOrgWar = Val
end

function COrgMgr:IsOrgWarOpen()
    return self.m_bOrgWar
end

function COrgMgr:SendAllMemMail(oOrg,iMail)
    interactive.Send(".world", "org", "SendAllMemMail", {
        mail=iMail,
        mem = oOrg:GetOrgMemList(),
    })
end

function COrgMgr:HandleConfictNameOrg(mRequestRecord,mData)
    local mInfo = {
        module = "orgdb",
        cmd = "GetConflictNameOrg",
    }
    gamedb.LoadDb("merge", "common", "LoadDb", mInfo,
    function (mRecord, mData)
        self:_HandleConfictNameOrg1(mRequestRecord, mRecord, mData)
    end)
end

function COrgMgr:_HandleConfictNameOrg1(mRequestRecord, mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    for iOrgId, sOrgName in pairs(mData) do
        local oOrg = oOrgMgr:GetNormalOrg(iOrgId)
        if oOrg then
            oOrgMgr:ForceRenameOrg(iOrgId, sOrgName.."*"..oOrg:ShowID())
            --[[
            --给帮主发改名卡
            local iLeader = oOrg:GetLeaderID()
            if iLeader then
                local mData, name = oMailMgr:GetMailInfo(9002)
                oMailMgr:SendMail(0, name, iLeader, mData, 0, {oItem})
            end
            ]]
        end
    end
    print("----merger HandleConfictNameOrg end: ", table_count(mData), mData)
    interactive.Response(mRequestRecord.source, mRequestRecord.session, {})
end