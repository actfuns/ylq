local global = require "global"
local extend = require "base.extend"

local gamedefines = import(lualib_path("public.gamedefines"))
local frienddefines = import(service_path("offline/defines"))

function NewApplyInfoMgr(...)
    return CApplyInfoMgr:New(...)
end

local SortApplyFunc = function (oApply1,oApply2)
    if oApply1.m_iCreateTime ~= oApply2.m_iCreateTime then
        return oApply1.m_iCreateTime < oApply2.m_iCreateTime
    else
        return oApply1.m_ID < oApply2.m_ID
    end
end

local SortFunc = function (mData1,mData2)
    if mData1.createtime ~= mData2.createtime then
        return mData1.createtime < mData2.createtime
    else
        return mData1.teamid < mData2.teamid
    end
end

CApplyInfoMgr = {}
CApplyInfoMgr.__index = CApplyInfoMgr
inherit(CApplyInfoMgr,logic_base_cls())

function CApplyInfoMgr:New(iTeamID)
    local o = super(CApplyInfoMgr).New(self)
    o.m_List = {}
    o.m_iTeamID = iTeamID
    return o
end

function CApplyInfoMgr:GetApplyInfo()
    self:_CheckValidApply()
    local mData = {}
    local mApplyInfo = table_value_list(self.m_List)
    table.sort(mApplyInfo,SortApplyFunc)
    for _,oApplyInfo in ipairs(mApplyInfo) do
        if table_count(mData) < 20 then
           table.insert(mData,oApplyInfo:PackInfo())
        end
    end
    return mData
end

function CApplyInfoMgr:ValidApply()
    self:_CheckValidApply()
    if table_count(self.m_List) >= self:LimitSize() then
        return false
    end
    return true
end

function CApplyInfoMgr:HasApply(pid)
    return self.m_List[pid]
end

function CApplyInfoMgr:AddApply(pid,mArgs)
    local oApplyInfo = CApplyInfo:New(pid)
    oApplyInfo:Init(mArgs)
    self.m_List[pid] = oApplyInfo
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(self.m_iTeamID)
    if not oTeam then
        return
    end
    local mNet = {
        apply_info = oApplyInfo:PackInfo(),
    }
    local mOnlineMem = oTeam:OnlineMember()
    oTeam:BroadCast(mOnlineMem,"GS2CAddTeamApplyInfo",mNet)
end

function CApplyInfoMgr:RemoveApply(pid,target)
    self.m_List[pid] = nil
    local mNet = {}
    mNet["pid"] = pid
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(self.m_iTeamID)
    if not oTeam then
        return
    end
    local mOnlineMem = oTeam:OnlineMember()
    oTeam:BroadCast(mOnlineMem,"GS2CDelTeamApplyInfo",mNet)
end

function CApplyInfoMgr:Size()
    return table_count(self.m_List)
end

function CApplyInfoMgr:LimitSize()
    return 7
end

function CApplyInfoMgr:ClearApply(pid)
    self.m_List = {}
    local mNet = {}
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(self.m_iTeamID)
    if not oTeam then
        return
    end
    local mOnlineMem = oTeam:OnlineMember()
    oTeam:BroadCast(mOnlineMem,"GS2CTeamApplyInfo",mNet)
end

function CApplyInfoMgr:_CheckValidApply()
    local plist = table_key_list(self.m_List)
    for _,pid in pairs(plist) do
        local oApplyInfo = self.m_List[pid]
        if oApplyInfo and not oApplyInfo:Validate() then
            self.m_List[pid] = nil
        end
    end
end

function CApplyInfoMgr:SendApplyInfo(pid)
    local mApplyInfo = self:GetApplyInfo()
    local mNet = {
        apply_info = mApplyInfo
    }
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CTeamApplyInfo",mNet)
end

CApplyInfo = {}
CApplyInfo.__index = CApplyInfo
inherit(CApplyInfo,logic_base_cls())

function CApplyInfo:New(pid)
    local o = super(CApplyInfo).New(self)
    o.m_ID =pid
    return o
end

function CApplyInfo:Init(mArgs)
    self.m_sName = mArgs.name
    self.m_iGrade = mArgs.grade
    self.m_iSchool =mArgs.school
    self.m_mModelInfo = mArgs.model_info
    self.m_iCreateTime = get_time()
    self.m_iSchoolBranch = mArgs.school_branch
end

function CApplyInfo:PackInfo()
    local mData = {
        pid  = self.m_ID,
        name  = self.m_sName,
        grade = self.m_iGrade,
        school = self.m_iSchool,
        model_info = self.m_mModelInfo,
        school_branch = self.m_iSchoolBranch
    }
    return mData
end

function CApplyInfo:Validate()
    if get_time() - self.m_iCreateTime >= 60 * 5 then
        return false
    end
    return true
end

function CApplyInfo:IsOutTime()
    if not self:Validate() then
        return true
    end
    return false
end

CInviteInfoMgr = {}
CInviteInfoMgr.__index = CInviteInfoMgr
inherit(CInviteInfoMgr,logic_base_cls())

function CInviteInfoMgr:New(pid)
    local o = super(CInviteInfoMgr).New(self)
    o.m_ID =pid
    o.m_List = {}
    return o
end

function CInviteInfoMgr:CheckInviteTimeOut()
    if not self.m_List then
        return
    end
    local iTime = get_time()
    for iPid,info in pairs(self.m_List) do
        if (iTime - info.createtime) > 30 then
            self.m_List[iPid] = nil
        end
    end
end

function CInviteInfoMgr:ValidInvite(iPid)
    if self:Size() >= self:LimitSize() then
        return false
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_ID)
    if oPlayer.m_oActiveCtrl:GetNowScene():QueryLimitRule("team") then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止组队")
        return
    end
    if oPlayer.m_oActiveCtrl:IsInTeamBlackList(iPid) then
        return false
    end
    return true
end

function CInviteInfoMgr:AddInvitor(oPlayer,mData)
    local oWorldMgr = global.oWorldMgr
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(self.m_ID)
    local iPid = oPlayer.m_iPid

    if not oTarget then
        oNotifyMgr:Notify(iPid,"该玩家已经下线")
        return
    end

    local oWar = oTarget.m_oActiveCtrl:GetNowWar()
    if oWar then
        oNotifyMgr:Notify(iPid,string.format("%s正在战斗中，请稍后再邀请",oTarget:GetName()))
        return
    end

    local oTeam = oTarget:HasTeam()
    if oTeam then
        oNotifyMgr:Notify(iPid,"玩家已经在队伍中")
        return
    end

    local oInterfaceMgr = global.oInterfaceMgr
    local iType = gamedefines.INTERFACE_TYPE.WAR_RESULT
    local mPlayers = oInterfaceMgr:GetFacePlayers(iType)
    if table_count(mPlayers) == 1 and mPlayers[self.m_ID] then
        oNotifyMgr:Notify(iPid,string.format("%s正忙，请稍后再邀请",oTarget:GetName()))
        return
    end
    self:CheckInviteTimeOut()
    if not self:ValidInvite(iPid) then
        oNotifyMgr:Notify(iPid,string.format("%s正忙，请稍后再邀请",oTarget:GetName()))
        return
    end

    local mNet = {
        pid = iPid,
        createtime = get_time(),
        teaminfo = mData,
    }
    self.m_List[iPid] =  mNet
    self.m_iCurInvitor = iPid

    local iTeamID = oPlayer:TeamID()
    if iTeamID then
        self:_AddInvitor1(oPlayer,mData)
    else
        self:_AddInvitor2(oPlayer,mData)
    end

end

function CInviteInfoMgr:_AddInvitor1(oPlayer,mData)
    local oTeam = oPlayer:HasTeam()
    local oNotifyMgr = global.oNotifyMgr
    local oCbMgr = global.oCbMgr
    local oTeamMgr = global.oTeamMgr
    local oWorldMgr = global.oWorldMgr
    local iOwner = self.m_ID
    local iPid = oPlayer.m_iPid
    local oInvitee = oWorldMgr:GetOnlinePlayerByPid(iOwner)
    local mInvitorInfo = {
        model_info = oPlayer:GetModelInfo(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        name = oPlayer:GetName(),
        target_info = oTeam.m_AutoTarget,
    }
    local bIsLeader = oTeam:IsLeader(oPlayer.m_iPid)
    local func = function (oResponse,mData)
        local oInviteMgr = oTeamMgr:GetInviteMgr(iOwner)
        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oP then
            return
        end
        oInviteMgr:Invite_DoScript1(oP,mData)
    end

    local iAuto_target = oTeam.m_AutoTarget["auto_target"]
    local sTips = ""
    if iAuto_target ~= 0 then
        local sTargetName = self:GetTargetName(iAuto_target)
        sTips = string.format("进行%s(%d - %d)",sTargetName,oTeam.m_AutoTarget["min_grade"] or 0,oTeam.m_AutoTarget["max_grade"] or 0)
    end
    local sContent = string.format("%s 想邀请你加入队伍%s\n是否同意？",oPlayer:GetName(),sTips)
    local mNet1 = {
        sContent = sContent,
        uitype = 1,
        simplerole = oPlayer:PackSimpleRoleInfo(),
        sConfirm = "同意",
        sCancle = "拒绝",
        default = 0,
        time = 30,
        confirmtype = gamedefines.CONFIRM_WND_TYPE.TEAM_INVITE,
        relation = self:GetRelation(oPlayer.m_iPid,self.m_ID),
    }
    mNet1 = oCbMgr:PackConfirmData(nil, mNet1)
    if  bIsLeader then
        oNotifyMgr:Notify(iLeader,string.format("已邀请%s加入队伍，请耐心等待回复",oInvitee:GetName()))
        self.m_iOperator = self.m_ID
        local mTargetTeamSetting  = oInvitee.m_oBaseCtrl:GetSystemSetting("teamsetting")
        local oFriend = oInvitee:GetFriend()
        if mTargetTeamSetting.auto_agree and mTargetTeamSetting.auto_agree == 1 and oFriend:HasFriend(iPid) then
            self:Invite_DoScript1(oPlayer,{answer = 1})
            return
        else
            oCbMgr:SetCallBack(self.m_ID,"GS2CConfirmUI",mNet1,nil,func)
            return
        end
    else
        local sContent2 = string.format("%s 想邀请%s加入队伍%s\n是否同意？",oPlayer:GetName(),oInvitee:GetName(),sTips)
        local mNet2 = {
            sContent = sContent2,
            uitype = 1,
            simplerole = oPlayer:PackSimpleRoleInfo(),
            sConfirm = "同意",
            sCancle = "拒绝",
            time = 30,
        }
        mNet2 = oCbMgr:PackConfirmData(nil, mNet2)
        local iLeader = oTeam.m_iLeader
        local func2 = function(oResponse,mData2)
            local oInviteMgr = oTeamMgr:GetInviteMgr(iOwner)
            local op = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if not oP then
                return
            end
            oInviteMgr:Invite_DoScript2(oP,mData2,mNet1)
        end
        self.m_iOperator = oTeam.m_iLeader
        oCbMgr:SetCallBack(iLeader,"GS2CConfirmUI",mNet2,nil,func2)
    end
end

function CInviteInfoMgr:Invite_DoScript1(oPlayer,mData)
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(self.m_ID,"邀请已过期")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.IN_HOUSE then
            oNotifyMgr:Notify(self.m_ID,"该玩家沉迷宅邸，不能自拔")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS then
            oNotifyMgr:Notify(self.m_ID,"该玩家正在据点战准备中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.CONVOY then
            oNotifyMgr:Notify(self.m_ID,"帝都宅急便护送中，无法进行组队")
        end
        return
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        oNotifyMgr:Notify(self.m_ID,"队伍已解散")
        self.m_iOperator = nil
        self:ClearCurInviteInfo()
        return
    end
    if oPlayer.m_oActiveCtrl:GetNowScene():QueryLimitRule("team") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止组队")
        return
    end
    if oTeam.m_Type == gamedefines.TEAM_CREATE_TYPE.LILIAN then
        oNotifyMgr:Notify(self.m_ID,"玩家正在修行")
        self.m_iOperator = nil
        self:ClearCurInviteInfo()
        return
    end
    local iTeamID = oPlayer.m_oActiveCtrl:GetInfo("TeamID")
    local bIsLeader = oTeam:IsLeader(oPlayer.m_iPid)
    if oTeam:TeamSize() >= 4 then

        oNotifyMgr:Notify(self.m_ID,"队伍成员已满")
    else
        if mData and mData.answer == 1 then
            oTeamMgr:PassInvite(iTeamID,self.m_ID)               ----TODO
        elseif mData and mData.answer == 0 then
            local iBlackListTime = mData.blacklisttime
            if iBlackListTime > 0 then
                local oWorldMgr = global.oWorldMgr
                local oMe = oWorldMgr:GetOnlinePlayerByPid(self.m_ID)
                oMe.m_oActiveCtrl:AddToTeamBlackList(oPlayer.m_iPid,iBlackListTime)
                if not bIsLeader then
                    oMe.m_oActiveCtrl:AddToTeamBlackList(oTeam.m_iLeader,iBlackListTime)
                end
            end
            oTeamMgr:RefuseInvite(iTeamID,self.m_ID,{oPlayer.m_iPid,not bIsLeader and oTeam.m_iLeader or nil},mData.message) -----TODO
        end
    end

    self.m_iOperator = nil
    self:ClearCurInviteInfo()
end

function CInviteInfoMgr:Invite_DoScript2(oPlayer,mData,mNet)
    local oNotifyMgr = global.oNotifyMgr
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local oTeam = oPlayer:HasTeam()
    local iOwner = self.m_ID
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(self.m_ID,"邀请已过期")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.IN_HOUSE then
            oNotifyMgr:Notify(self.m_ID,"该玩家沉迷宅邸，不能自拔")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS then
            oNotifyMgr:Notify(self.m_ID,"该玩家正在据点战准备中，暂时无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.CONVOY then
            oNotifyMgr:Notify(self.m_ID,"帝都宅急便护送中，无法进行组队")
        end
        return
    end
    if not oTeam then
        oNotifyMgr:Notify(self.m_ID,"队伍已解散")
        self.m_iOperator = nil
        self:ClearCurInviteInfo()
        return
    end
    if oTeam.m_Type == gamedefines.TEAM_CREATE_TYPE.LILIAN then
        oNotifyMgr:Notify(self.m_ID,"玩家正在修行")
        self.m_iOperator = nil
        self:ClearCurInviteInfo()
        return
    end
    local oInvitee = oWorldMgr:GetOnlinePlayerByPid(self.m_ID)
    self.m_iOperator = nil
    local iLeadersChoice = mData.answer
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(oTeam.m_iLeader)
    if iLeadersChoice == 1 then
        oNotifyMgr:Notify(oPlayer.m_iPid,string.format("%s同意了你的邀请请求",oLeader:GetName()))
        oNotifyMgr:Notify(oPlayer.m_iPid,string.format("已邀请%s加入队伍，请耐心等待回复",oInvitee:GetName()))
        oNotifyMgr:Notify(oTeam.m_iLeader,string.format("已邀请%s加入队伍，请耐心等待回复",oInvitee:GetName()))
        local mTargetTeamSetting  = oInvitee.m_oBaseCtrl:GetSystemSetting("teamsetting")
        local oFriend = oInvitee:GetFriend()
        if mTargetTeamSetting.auto_agree and mTargetTeamSetting.auto_agree == 1 and oFriend:HasFriend(iPid) then
            self:Invite_DoScript1(oPlayer,{answer = 1})
            return
        end
        local iPid = oPlayer.m_iPid
        local func = function (oResponse,mData2)
            local oInviteMgr = oTeamMgr:GetInviteMgr(iOwner)
            local op = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if not oP then
                return
            end
            oInviteMgr:Invite_DoScript1(oP,mData2)
        end
        self.m_iOperator = self.m_ID
        oCbMgr:SetCallBack(self.m_ID,"GS2CConfirmUI",mNet,nil,func)
    else
        oNotifyMgr:Notify(oPlayer.m_iPid,string.format("%s拒绝了你的邀请请求",oLeader:GetName()))
        self:ClearCurInviteInfo()
    end
end

function CInviteInfoMgr:_AddInvitor2(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer.m_iPid
    local iAutoTargetID = mData.auto_target
    local iMinGrade = mData.min_grade
    local iMaxGrade = mData.max_grade
    local iOwner = self.m_ID
    local oInvitee = oWorldMgr:GetOnlinePlayerByPid(iOwner)
    local mTarget
    if iAutoTargetID then
        mTarget = {
            auto_target = iAutoTargetID,
        }
    end
    local func = function (oResponse,mData2)
        local oTeamMgr = global.oTeamMgr
        local oInviteMgr = oTeamMgr:GetInviteMgr(iOwner)
        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oP then
            return
        end
        oInviteMgr:Invite_DoScript3(oP,mData2,mTarget)
    end

    self.m_iOperator = self.m_ID
    oNotifyMgr:Notify(oPlayer.m_iPid,string.format("已邀请%s加入队伍，请耐心等待回复",oInvitee:GetName()))
    local oFriend = oInvitee:GetFriend()
    local mTargetTeamSetting  = oInvitee.m_oBaseCtrl:GetSystemSetting("teamsetting")
    if mTargetTeamSetting.auto_agree and mTargetTeamSetting.auto_agree == 1 and oFriend:HasFriend(iPid) then
        self:Invite_DoScript3(oPlayer,{answer = 1},mTarget)
        return
    else
        local oCbMgr = global.oCbMgr
        local sTips = ""
        if iAutoTargetID ~= 0 then
            local sTargetName = self:GetTargetName(iAutoTargetID)
            sTips = string.format("进行%s(%d - %d)",sTargetName,iMinGrade or 0,iMaxGrade or 0)
        end
        local sContent = string.format("%s 想邀请你加入队伍%s\n是否同意？",oPlayer:GetName(),sTips)
        local mNet = {
            sContent = sContent,
            uitype = 1,
            simplerole = oPlayer:PackSimpleRoleInfo(),
            sConfirm = "同意",
            sCancle = "拒绝",
            default = 0,
            time = 30,
            confirmtype = gamedefines.CONFIRM_WND_TYPE.TEAM_INVITE,
            relation = self:GetRelation(oPlayer.m_iPid,self.m_ID),
        }
        mNet = oCbMgr:PackConfirmData(nil, mNet)
        oCbMgr:SetCallBack(self.m_ID,"GS2CConfirmUI",mNet,nil,func)
        return
    end
end

function CInviteInfoMgr:Invite_DoScript3(oPlayer,mData,mTarget)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr

    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(self.m_ID,"邀请已过期")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.IN_HOUSE then
            oNotifyMgr:Notify(self.m_ID,"该玩家沉迷宅邸，不能自拔")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS then
            oNotifyMgr:Notify(self.m_ID,"该玩家正在据点战准备中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.CONVOY then
            oNotifyMgr:Notify(self.m_ID,"帝都宅急便护送中，无法进行组队")
        end
        return
    end
    local oTeamMgr = global.oTeamMgr
    self.m_iOperator = nil
    local iResponse = mData.answer
    local who = oWorldMgr:GetOnlinePlayerByPid(self.m_ID)
    if iResponse == 1 then
        local oTeam = oPlayer:HasTeam()
        if not oTeam then
            if oPlayer.m_oActiveCtrl:GetNowScene():QueryLimitRule("team") then
                oNotifyMgr:Notify(self.m_ID,"对方场景禁止组队")
                self:ClearCurInviteInfo()
                return
            end
            if who.m_oActiveCtrl:GetNowScene():QueryLimitRule("team") then
                oNotifyMgr:Notify(self.m_ID,"当前场景禁止组队")
                self:ClearCurInviteInfo()
                return
            end
            if who.m_InArenaGameMatch or who.m_InArenaGame or who.m_oStateCtrl:GetState(1007) then
                oNotifyMgr:Notify(self.m_ID,"正在比武场战斗中,禁止组队")
                self:ClearCurInviteInfo()
                return
            end
            if oPlayer.m_InArenaGameMatch or oPlayer.m_InArenaGame or oPlayer.m_oStateCtrl:GetState(1007) then
                oNotifyMgr:Notify(self.m_ID,"正在比武场战斗中,禁止组队")
                self:ClearCurInviteInfo()
                return
            end
            local fNotifyFunc = function (pid,oTarget,sKey)
                    local oNotifyMgr = global.oNotifyMgr
                    local mOperate = oTarget.m_RefuseTeamOperate["operate"]
                    local mData = mOperate[sKey] or (mOperate["all"] or {})
                    oNotifyMgr:Notify(pid,mData["notify"])
                    self:ClearCurInviteInfo()
                    end

            if oPlayer.m_RefuseTeamOperate then
                fNotifyFunc(oPlayer:GetPid(),oPlayer,"CreateTeam")
                return
            end
            if who.m_RefuseTeamOperate then
                fNotifyFunc(who:GetPid(),who,"CreateTeam")
                return
            end



            oTeamMgr:CreateTeam(oPlayer.m_iPid,mTarget)
        else
            if oTeam.m_Type == gamedefines.TEAM_CREATE_TYPE.LILIAN then
                oNotifyMgr:Notify(self.m_ID,"玩家正在修行")
                self:ClearCurInviteInfo()
                return
            end
            if oPlayer.m_oActiveCtrl:GetNowScene():QueryLimitRule("team") then
                oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止组队")
                self:ClearCurInviteInfo()
                return
            end
            if who.m_oActiveCtrl:GetNowScene():QueryLimitRule("team") then
                oNotifyMgr:Notify(self.m_ID,"当前场景禁止组队")
                self:ClearCurInviteInfo()
                return
            end
            if not oTeam:IsLeader(oPlayer.m_iPid) then
                local oNotifyMgr = global.oNotifyMgr
                oNotifyMgr:Notify(self.m_ID,"邀请信息已过期")
                self:ClearCurInviteInfo()
                return
            end
            if oTeam:TeamSize() >= 4 then

                oNotifyMgr:Notify(self.m_ID,"队伍成员已满")
                self:ClearCurInviteInfo()
                return
            else
                oTeam:SetTeamTarget(mTarget.auto_target)
            end
        end
        local iTeamID = oPlayer.m_oActiveCtrl:GetInfo("TeamID")
        oTeamMgr:PassInvite(iTeamID,self.m_ID)               ----TODO
    else
        local iBlackListTime = mData.blacklisttime
        if iBlackListTime > 0 then
            local oWorldMgr = global.oWorldMgr
            local oMe = oWorldMgr:GetOnlinePlayerByPid(self.m_ID)
            oMe.m_oActiveCtrl:AddToTeamBlackList(oPlayer.m_iPid,iBlackListTime)
        end
        oTeamMgr:RefuseInvite(0,self.m_ID,{oPlayer.m_iPid},mData.message)
    end
    self:ClearCurInviteInfo()
end

function CInviteInfoMgr:ClearCurInviteInfo()
    local iPid = self.m_iCurInvitor
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if  self.m_iOperator then
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(self.m_iOperator)
        if oTarget then
            oNotifyMgr:Notify(iPid,string.format("%s没有做出反应",oTarget:GetName()))
        end
    end
    self:DelTimeCb("ClearCurInviteInfo")
    if self.m_List[iPid] then
        self.m_List[iPid] = nil
    end
    self.m_iCurInvitor = nil
end

function CInviteInfoMgr:HasInvite(iTeamID)
    return self.m_List[iTeamID]
end

function CInviteInfoMgr:Size()
    return table_count(self.m_List)
end

function CInviteInfoMgr:LimitSize()
    return 1
end

function CInviteInfoMgr:_Validate()
    local mTeam = table_key_list(self.m_List)
    for _,iTeamID in pairs(mTeam) do
        local mData = self.m_List[iTeamID]
        local iCreateTime = mData.createtime
        if get_time() - iCreateTime >= 60 * 5 then
            self.m_List[iTeamID] = nil
        end
    end
end

function CInviteInfoMgr:IsOutTime(iTeamID)
    local mData = self.m_List[iTeamID]
    local iCreateTime = mData.createtime or 0
     if get_time() - iCreateTime >= 60*5 then
        return true
    end
    return false
end

function CInviteInfoMgr:SendInviteInfo(target,bLogin)
    self:_Validate()
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local mInviteInfo = table_value_list(self.m_List)
    table.sort(mInviteInfo,SortFunc)
    local mData = {}
    for _,mTeamInfo in ipairs(mInviteInfo) do
        if table_count(mData) < 20 then
            local iTeamID = mTeamInfo["teamid"]
            local oTeam = oTeamMgr:GetTeam(iTeamID)
            if oTeam then
                table.insert(mData,oTeam:PackTeamInfo())
            end
        end
    end
    if table_count(mData) <=0 and not bLogin then
        oNotifyMgr:Notify(target,"暂时还没有人邀请你入队哦")
        return
    end
    local mNet = {}
    mNet["teaminfo"] = mData
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(target)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CInviteInfo",mNet)
end

function CInviteInfoMgr:ClearInviteInfo(target)
    self.m_List = {}
    local mNet = {}
    mNet["teaminfo"] = {}
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(target)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CInviteInfo",mNet)
end

function CInviteInfoMgr:RemoveInvite(iTeamID,target)
    self.m_List[iTeamID] = nil
    local mNet = {}
    mNet["teamid"] = iTeamID
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(target)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CRemoveInvite",mNet)
end

function NewInviteMgr(...)
    return CInviteInfoMgr:New(...)
end

function CInviteInfoMgr:GetTargetName(iTargetID)
    local res = require "base.res"
    local mInfo = res["daobiao"]["autoteam"][iTargetID]
    if mInfo then
        return mInfo["name"]
    end
    return ""
end

function CInviteInfoMgr:GetRelation(iPid,iTarget)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    return global.oFriendMgr:GetPlayerRelation(oPlayer,oTarget)
end