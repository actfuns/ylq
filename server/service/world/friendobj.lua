--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base.extend"
local net = require "base.net"
local record = require "public.record"
local colorstring = require "public.colorstring"
local router = require "base.router"

local gamedb = import(lualib_path("public.gamedb"))
local gamedefines = import(lualib_path("public.gamedefines"))
local defines = import(service_path("offline.defines"))
local loaditem = import(service_path("item.loaditem"))
local analy = import(lualib_path("public.dataanaly"))

function NewFriendMgr(...)
    local o = CFriendMgr:New(...)
    return o
end

CFriendMgr = {}
CFriendMgr.__index = CFriendMgr
inherit(CFriendMgr, logic_base_cls())

function CFriendMgr:New()
    local o = super(CFriendMgr).New(self)
    o.m_SetDoc = {"birthday","sex","signa","photo","labal","addr"}
    return o
end

--登录操作
function CFriendMgr:OnLogin(oPlayer, bReenter)
    --注册频道
    self:FocusAllFriends(oPlayer)

    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oFriend = oPlayer:GetFriend()
    --登录发送好友列表
    local mBlacks = oFriend:GetBlackList()
    local mFriendOfflineChats = oFriend:GetFriendOfflineChats()
    local l1 = {}
    local l2 = {}
    local l3 = oFriend:GetFriendsOnlineStatusInfo()

    for k, _ in pairs(mBlacks) do
        table.insert(l2, tonumber(k))
    end
    for k, v in pairs(mFriendOfflineChats) do
        if #v > 0 then
            local m = {}
            m.pid = tonumber(k)
            m.chat_list = {}
            for _, v2 in ipairs(v) do
                table.insert(m.chat_list, {
                    message_id = v2.message_id,
                    msg = v2.msg,
                })
            end
            table.insert(l1, m)
        end
    end
   oPlayer:Send("GS2CLoginFriend", {
        friend_chat_list = l1,
        black_list = l2,
        friend_onlinestatus_list = l3,
    })

    self:RefreshAppList(oFriend)

    self:RefreshOnlineStatus(oPlayer:GetPid(),1)
    self:RefreshSetting(oPlayer)
    --推荐好友收集信息
    --self:RefreshRecommend(oPlayer:GetPid())
end



function CFriendMgr:OnDisconnected(oPlayer)
    if oPlayer:GetFriend() then
        self:UnFocusAllFriends(oPlayer)
        self:UnFocusStranger(oPlayer)
    end
end

function CFriendMgr:OnLogout(oPlayer)
    self:RefreshOnlineStatus(oPlayer:GetPid(),0)
     self:UnFocusAllFriends(oPlayer)
    self:UnFocusStranger(oPlayer)
end

function CFriendMgr:GetTextData(idx)
    local sText = colorstring.GetTextData(idx, {"friend"})
    return sText
end

--好友操作
function CFriendMgr:LoadProfileAndFriend(iTarget,func)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iTarget, function (o)
        oWorldMgr:LoadFriend(iTarget, function (o2)
            local oProfile = oWorldMgr:GetProfile(iTarget)
            func(oProfile,o2)
            end)
    end)

end

function CFriendMgr:AddApply(oPlayer,iTarget)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oFrd = oPlayer:GetFriend()
    local iGrade = oWorldMgr:QueryControl("friend","open_grade")
    if oPlayer:GetGrade()  < iGrade then
        return
    end
    local iMax = oFrd:FriendsMaxCnt(oPlayer:GetGrade())
    if iMax <= oFrd:FriendCount() then
        oNotifyMgr:Notify(iPid,"你的好友已满，不能发送申请")
        return
    end
    if iPid == iTarget then
        return
    elseif oFrd:HasFriend(iTarget) then
        return
    end
    if iTarget == 0 then
        oNotifyMgr:Notify(iPid, "申请成功")
    end
    self:LoadProfileAndFriend(iTarget,function (oProfile,oFriend)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not ( oPlayer and oFriend ) then
            return
        end
        self:_AddApply(oPlayer,iTarget,oProfile,oFriend)
    end)
end

function CFriendMgr:_AddApply(oPlayer,iTarget,oProfile,oFriend)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr  =  global.oWorldMgr
    local iGrade = oWorldMgr:QueryControl("friend","open_grade")
    if oProfile:GetGrade() < iGrade then
        oNotifyMgr:Notify(oPlayer:GetPid(),"对方等级不足")
        return
    end
    if oFriend:FriendCount() >= oFriend:FriendsMaxCnt(oProfile:GetGrade()) then
        oNotifyMgr:Notify(oPlayer:GetPid(), "对方好友已满")
        return
    end
    local iPid = oPlayer:GetPid()
    local oMyFriend = oPlayer:GetFriend()
    if oFriend:HasFriend(iPid)then
        if self:_AddFriend2(oPlayer:GetFriend(),oPlayer:GetGrade(),iTarget) then
            self:_SenAddFriend(oPlayer,iTarget,oProfile)
            self:AddFriendDegree(iPid,iTarget,1)
            oMyFriend:SetBothFriend(iTarget)
            oFriend:SetBothFriend(iPid)
            self:LogAnalyFriend(iPid,iTarget,1)
        end
        return
    end

    if oMyFriend:GetApplyIndx(iTarget) then
        self:AddFriend(oPlayer,iTarget)
        return
    end

    if not oFriend:GetApplyIndx(iPid) then
        local iSwitch = oFriend:QuerySetting("apply_switch") or 0
        local iApplyGrade = oFriend:QuerySetting("apply_grade") or 0
        if iSwitch ~=0 and iApplyGrade > oPlayer:GetGrade() then
            oNotifyMgr:Notify(iPid, "对方拒绝了你的申请")
            return
        end
        oFriend:AddApply(iPid)
        oNotifyMgr:Notify(iPid, "申请成功")
        self:RefreshAppList(oFriend)
    else
        oNotifyMgr:Notify(iPid, "申请成功")

    end

end

function CFriendMgr:GetPlayerRelation(oPlayer,oTarget)
    return self:GetAllRelation(oPlayer,oTarget)
end


function CFriendMgr:GetAllRelation(oPlayer,oTarget)
    local oMyFriend = oPlayer:GetFriend()
    local iTarget = oTarget:GetPid()
    local iRelation = oMyFriend:GetFriendRelation(iTarget)
    if oMyFriend:GetFriendDegree(iTarget) > 1000 then
        iRelation = iRelation | (2^(defines.RELATION_SPECIAL_FRIEND-1))
    else
        iRelation = iRelation | (2^(defines.RELATION_NORMAL_FRIEND-1))
    end
    if oTarget:GetOrgID() ~= 0 and oTarget:GetOrgID() == oPlayer:GetOrgID() then
        iRelation = iRelation | (2^(defines.RELATION_ORGMEM-1))
    end
    return iRelation
end


function CFriendMgr:RefreshAppList(oFriend)
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(oFriend:GetPid())
    if oTarget then
        local mNet = {
            pidlist= oFriend.m_mAppList
            }
        oTarget:Send("GS2CApplyList",mNet)
    end

end

function CFriendMgr:RemoveApply(oPlayer,iPidList)
    local oFriend = oPlayer:GetFriend()
    local iSend = nil
    for _,pid in ipairs(iPidList) do
        iSend = oFriend:RemoveApply(pid)
    end
    if iSend then
        self:RefreshAppList(oFriend)
    end
end

function CFriendMgr:AddFriend(oPlayer,iTargetPid)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if iTargetPid == iPid then
        oNotifyMgr:Notify(iPid, self:GetTextData(1021))
        return
    end
    local oFriend = oPlayer:GetFriend()
    local iOK=1
    if oFriend:HasFriend(iTargetPid) then
        oNotifyMgr:Notify(iPid, self:GetTextData(1004))
        oFriend:RemoveApply(iTargetPid)
        self:RefreshAppList(oFriend)
        return
    elseif not oFriend:GetApplyIndx(iTargetPid) then
        return
    elseif oFriend:IsShield(iTargetPid) then
        return
    elseif oFriend:FriendCount() >= oFriend:FriendsMaxCnt(oPlayer:GetGrade()) then
        oNotifyMgr:Notify(iPid, self:GetTextData(1002))
        return
    end
    self:LoadProfileAndFriend(iTargetPid,function (oProfile,oFriend)
        local oPlayerObj=oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not (oProfile and oFriend and oPlayerObj) then
            oNotifyMgr:Notify(iPid, "不存在该玩家")
        elseif not is_release(self) then
            self:_AddFriend1(iPid, oFriend, oProfile)
        end
        end)
end

function CFriendMgr:_AddFriend1(iPid, oTargetFriend,oProfile)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    if oTargetFriend:FriendCount() >= oTargetFriend:FriendsMaxCnt(oProfile:GetGrade()) then
        oNotifyMgr:Notify(iPid, "对方好友已满")
        return
    end
    local iTargetPid = oTargetFriend:GetPid()
    local oFriend = oPlayer:GetFriend()
    local oMyProfile = oPlayer:GetProfile()
    --将对方加好友
    if self:_AddFriend2(oFriend,oPlayer:GetGrade(),iTargetPid) then
        oNotifyMgr:Notify(iPid, self:GetTextData(1003))
        self:FocusFriend(oPlayer,iTargetPid)
        self:_SenAddFriend(oPlayer,iTargetPid,oProfile)
        oFriend:SetBothFriend(iTargetPid)
        self:LogAnalyFriend(iPid,iTargetPid,1)
    end
    --对方将自己加好友
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
    local iGrade = oProfile:GetGrade()
    if  oTarget then
        iGrade = oTarget:GetGrade()
    end

    if self:_AddFriend2(oTargetFriend,iGrade,iPid) then
        if oTarget then
            self:_SenAddFriend(oTarget,iPid,oMyProfile)
            self:FocusFriend(oTarget,iPid)
        end
        oTargetFriend:SetBothFriend(iPid)
        self:LogAnalyFriend(iTargetPid,iPid,1)
    end
    self:AddFriendDegree(iPid,iTargetPid,1)
end


function CFriendMgr:_AddFriend2(oFriend,iGrade,iTargetPid)
    if oFriend:FriendCount() < oFriend:FriendsMaxCnt(iGrade) then
        if oFriend:IsShield(iTargetPid) then
            oFriend:Unshield(iTargetPid)
        end
        oFriend:RemoveApply(iTargetPid)
        oFriend:AddFriend(iTargetPid)
        self:RefreshAppList(oFriend)
        local mLog = {
        pid = oFriend:GetPid(),
        target = iTargetPid,
        sum = oFriend:FriendCount(),
        }
        record.user("friend","addfriend",mLog)
        return true
    end
    return false
end

function CFriendMgr:_SenAddFriend(oPlayerObj,iTargetPid,oTargetProfile)
    local mData=self:PackAddFriend(oPlayerObj,oTargetProfile)
    oPlayerObj:Send("GS2CAddFriend", {profile_list = {mData}})
    local oFriend = oPlayerObj:GetFriend()
    local bFriendOnlineStatus = oFriend:GetFriendOnlineStatusById(iTargetPid)
    local iFriendOnlineStatus=0
    if bFriendOnlineStatus then iFriendOnlineStatus=1 end
    local mStatus = {}
    mStatus.onlinestatus = iFriendOnlineStatus
    mStatus.pid = iTargetPid
    oPlayerObj:Send("GS2COnlineStatus",{onlinestatus={mStatus}})
end

function CFriendMgr:LogAnalyFriend(iPid,iTargetPid,operation)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iPid,function (oProfile)
        oWorldMgr:LoadProfile(iTargetPid,function (oTargetProfile)
            local mLog = oProfile:GetPubAnalyData()
            mLog["operation"] = operation
            mLog["friend_role_id"] = iTargetPid
            mLog["friend_role_name"] = oTargetProfile:GetName()
            mLog["friend_role_level"] = oTargetProfile:GetGrade()
            mLog["friend_profession"] = oTargetProfile:GetSchool()
            analy.log_data("friend",mLog)
        end)
    end)
end

function CFriendMgr:PackAddFriend(oPlayer, o)
    local oFriend = oPlayer:GetFriend()
    local pid = o:GetPid()
    local iFriendShip = oFriend:GetFriendDegree(pid)
    local iRelation = oFriend:GetFriendRelation(pid)
    local m = {}
    m.pid = pid
    m.name = o:GetName()
    m.shape = o:GetModelInfo().shape
    m.grade = o:GetGrade()
    m.school = o:GetSchool()
    m.friend_degree = iFriendShip
    m.relation = iRelation
    return net.Mask("base.FriendProfile", m)
end


function CFriendMgr:DelFriend(oPlayer, iTargetPid, endfunc)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    local oFriend = oPlayer:GetFriend()
    if not oFriend:HasFriend(iTargetPid) then
        oNotifyMgr:Notify(iPid, self:GetTextData(1009))
        return
    end

    local mCheckList={
    [defines.RELATION_COUPLE] = 1018,
    [defines.RELATION_BROTHER] = 1019,
    [defines.RELATION_MASTER] = 1020,
    [defines.RELATION_STUDENT] = 1020,
    }

    if not self:CheckRelation(oFriend,iTargetPid,mCheckList) then
        return
    elseif oFriend:GetFriendRelation(iTargetPid) ~= 0 then
        return
    end
    oWorldMgr:LoadFriend(iTargetPid, function (oTargetFriend)
        if not oTargetFriend then
            oNotifyMgr:Notify(iPid, "不存在该玩家")
        else
            self:_DelFriend1(iPid, oTargetFriend, endfunc)
        end
    end)
    self:LogAnalyFriend(iPid,iTargetPid,2)
end

function CFriendMgr:CheckRelation(oFriend,iTarget,mCheck)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oFriend:GetPid()
    for iR,iNotify in pairs(mCheck) do
        if oFriend:HasRelation(iTargetPid, iR) then
         if iNotify then
            oNotifyMgr:Notify(iPid, self:GetTextData(iNotify))
         end
        return false
        end
    end
    return true
end



function CFriendMgr:_DelFriend1(iPid, oTargetFriend, endfunc)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oFriend = oPlayer:GetFriend()
    local iTargetPid = oTargetFriend:GetPid()
    oFriend:DelFriend(iTargetPid)
    oFriend:ClearFriendDegree(iTargetPid)
    oTargetFriend:ClearBothFriend(iPid)
    oTargetFriend:ClearFriendDegree(iPid)
    local mLog = {
    pid = oFriend:GetPid(),
    target = iTargetPid,
    sum = oFriend:FriendCount(),
    }
    record.user("friend","delfriend",mLog)
    oNotifyMgr:Notify(iPid, self:GetTextData(1010))
    oPlayer:Send("GS2CDelFriend", {
        pid_list = {iTargetPid,},
    })
    if endfunc then
        endfunc()
    end
end


function CFriendMgr:QuerySimpleFriendList(oPlayer,lList)
    local oFriend = oPlayer:GetFriend()
    local iPid = oPlayer:GetPid()
    local pidlist ={}
    for _, v in ipairs(lList) do
        if oFriend:HasFriend(v) then
                table.insert(pidlist, v)
        end
    end
    if #pidlist == 0 then
        return
    end
    local callback = function (oFriendMgr,oPlayer,mHandle)
        local plist = {}
        for _,m in ipairs(mHandle) do
            local info = {
                pid = m.pid,
                name = m.name,
                grade = m.grade,
            }
            table.insert(plist,info)
        end
        oPlayer:Send("GS2CSendSimpleInfo",{frdlist=plist})
    end
    if #pidlist == 0 then
        callback(self,iPid,{})
    else
        self:BatchQueryProfile(iPid,pidlist,callback)
    end
end

function CFriendMgr:QueryFriendProfile(oPlayer, lList)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oFriend = oPlayer:GetFriend()
    local lPidList = {}
    local lStrangerList = {}
    for _, v in ipairs(lList) do
        if oFriend:HasFriend(v) then
            table.insert(lPidList, v)
        else
            table.insert(lStrangerList, v)
        end
    end

    self:BatchQueryProfile(iPid, lPidList, self.SendAddFriend)
    self:BatchQueryProfile(iPid, lStrangerList, self.SendStrangerProfile)

end


function CFriendMgr:SendAddFriend(oPlayer, mResult)
    oPlayer:Send("GS2CAddFriend", {
        profile_list = mResult,
    })
end

function CFriendMgr:SendStrangerProfile(oPlayer, mResult)
    oPlayer:Send("GS2CStrangerProfile", {
        profile_list = mResult,
    })
end

function CFriendMgr:BatchQueryProfile(iPid, lPidList, sendfunc)
    local oWorldMgr = global.oWorldMgr
    local iRequestCount = #lPidList
    local mHandle = {
        count = iRequestCount,
        list = {},
        is_sent = false,
    }

    for _, k in ipairs(lPidList) do
        local o = oWorldMgr:GetOnlinePlayerByPid(k)
        if o then
            self:_HandleQueryProfile(iPid, o, mHandle, sendfunc)
        else
            oWorldMgr:LoadProfile(k, function (o)
                if not o then
                    mHandle.count = mHandle.count - 1
                    self:_JudgeSend(iPid, mHandle, sendfunc)
                else
                    self:_HandleQueryProfile(iPid, o, mHandle, sendfunc)
                end
            end)
        end
    end

end

function CFriendMgr:_HandleQueryProfile(iPid, o, mHandle, sendfunc)
    mHandle.count = mHandle.count - 1
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        table.insert(mHandle.list, self:PackAddFriend(oPlayer, o))
    end
    self:_JudgeSend(iPid, mHandle, sendfunc)
end

function CFriendMgr:_JudgeSend(iPid, mHandle, sendfunc)
    if mHandle.count <= 0 and not mHandle.is_sent then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            sendfunc(self, oPlayer, mHandle.list)
        end
        mHandle.is_sent = true
    end
end


function CFriendMgr:QueryFriendApply(oPlayer,plist)
    local mResult={
    wait=#plist,
    data = {},
    send=false,
    }
    local iTarget = oPlayer:GetPid()
    for _,pid in pairs(plist) do
        self:LoadProfileAndFriend(pid,function (oProfile,oFriend)
            local pobj = global.oWorldMgr:GetOnlinePlayerByPid(iTarget)
            if pobj then
                self:_WaitApplyLoad(pobj,oProfile,oFriend,mResult,function (oPlayer,mResult)
                    self:SendApplyProfile(oPlayer,mResult)
                    end)
            end
            end)
    end
end

function CFriendMgr:_WaitApplyLoad(oPlayer,oProfile,oFriend,mResult,endfunc)
    mResult.wait=mResult.wait - 1
    if oProfile and oFriend then
        local mDoc = oFriend:Document()
        local mPack = {
        pro = self:PackAddFriend(oPlayer,oProfile),
        labal = mDoc.labal,
        addr = mDoc.addr,
        }
        table.insert(mResult.data,mPack)
    end
    if mResult.wait <=0 then
        endfunc(oPlayer,mResult)
    end
end

function CFriendMgr:SendApplyProfile(oPlayer,mResult)
    if not mResult.send then
        oPlayer:Send("GS2CApplyProfile",{profile_list=mResult.data})
        mResult.send = true
    end
end



--黑名单
function CFriendMgr:Shield(oPlayer, iTargetPid)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    if iPid == iTargetPid then
        oNotifyMgr:Notify(iPid, "不能拉黑自己")
        return
    end
    local oFriend = oPlayer:GetFriend()
    if oFriend:IsShield(iTargetPid) then
        return
    end
    if table_count(oFriend:GetBlackList()) >=30 then
        oNotifyMgr:Notify(iPid, "添加失败，黑名单列表已满")
        return
    end
    oWorldMgr:LoadProfile(iTargetPid, function (o)
        if not o then
            oNotifyMgr:Notify(iPid, "玩家不存在")
            return
        else
            local sTargetName = o:GetName()
            self:_Shield2(iPid, iTargetPid, sTargetName)
        end
    end)
end

function CFriendMgr:_Shield2(iPid, iTargetPid, sTargetName)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local func
    func = function ()
        if not is_release(self) then
            self:_Shield3(iPid, iTargetPid, sTargetName)
        end
    end
    local oFriend = oPlayer:GetFriend()
    if oFriend:HasFriend(iTargetPid) then
        self:DelFriend(oPlayer, iTargetPid, func)
        return
    end
    func()
end

function CFriendMgr:_Shield3(iPid, iTargetPid, sTargetName)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oFriend = oPlayer:GetFriend()
    if oFriend:IsShield(iTargetPid) then
        return
    end

    oFriend:Shield(iTargetPid)
    oPlayer:Send("GS2CFriendShield", {
        pid_list = {iTargetPid,},
    })
    local sText = self:GetTextData(1012)
    local mNotifyArgs = {
        role = sTargetName,
    }
    oNotifyMgr:BroadCastNotify(iPid,{"GS2CNotify"},sText,mNotifyArgs)
end

function CFriendMgr:Unshield(oPlayer, iTargetPid)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    if iPid == iTargetPid then
        oNotifyMgr:Notify(iPid, "不用对自己移出黑名单")
        return
    end
    local oFriend = oPlayer:GetFriend()
    if not oFriend:IsShield(iTargetPid) then
        return
    end
    oWorldMgr:LoadProfile(iTargetPid, function (o)
        if not o then
            oNotifyMgr:Notify(iPid, "玩家不存在")
            return
        else
            local sTargetName = o:GetName()
            self:_Unshield2(iPid, iTargetPid, sTargetName)
        end
    end)
end

function CFriendMgr:_Unshield2(iPid, iTargetPid, sTargetName)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oFriend = oPlayer:GetFriend()
    if not oFriend:IsShield(iTargetPid) then
        return
    end
    oFriend:Unshield(iTargetPid)
    oPlayer:Send("GS2CFriendUnshield", {
        pid_list = {iTargetPid,},
    })
    local sText = self:GetTextData(1017)
    local mNotifyArgs = {
        role = sTargetName
    }
    oNotifyMgr:BroadCastNotify(iPid,{"GS2CNotify"},sText,mNotifyArgs)
end


--聊天
function CFriendMgr:ChatToFriend(oPlayer, iTargetPid, iMessageId, sMsg)
    sMsg = trim(sMsg)
    if string.len(sMsg) <= 0 then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()

    self:LoadProfileAndFriend(iTargetPid, function (oProfile,o)
        self:_ChatToFriend(iPid,o,oProfile,iTargetPid,iMessageId,sMsg)
    end)
end

function CFriendMgr:_ChatToFriend(iPid,o,oProfile,iTargetPid, iMessageId, sMsg)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if o:IsShield(iPid) then
        return
    end

    if not o:HasFriend(iPid) then
        if not oPlayer then
                    return
        end

        --拒绝陌生人会话
        if o:QuerySetting("strange_chat") ~=0 and oPlayer:GetGrade() < o:QuerySetting("strange_grade") then
            oPlayer:Send("GS2CAckChatTo", {
                    pid = iTargetPid,
                    message_id = iMessageId,
                    })
            oPlayer:Send("GS2CSysFriendChat", {
                    msg = "对方开启了拒绝陌生人消息，发送失败。",
                    })
            return
        end
    end


    local sName = string.format("玩家%d",iPid)
    if oPlayer then
        sName = oPlayer:GetName()
    end


    local mLog  = {
    pid = iPid,
    name = sName,
    target = iTargetPid,
    targetname = oProfile:GetName(),
    text = sMsg,
    svr = skynet.getenv("server_key"),
    }
    record.chat("chat","friend",mLog)

    o:AddChat(iPid, iMessageId, sMsg)
    if oPlayer then
        oPlayer:Send("GS2CAckChatTo", {
        pid = iTargetPid,
        message_id = iMessageId,
        })
    end

    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
    if oTarget then
        oTarget:Send("GS2CChatFrom", {
            pid = iPid,
            message_id = iMessageId,
            msg = sMsg,
                })
    end

    if o:QuerySetting("respond_switch") ~=0 then
        local sRespond = o:QuerySetting("auto_response") or ""
        if sRespond ~= ""  and oPlayer then
            oPlayer:Send("GS2CChatFrom", {
                pid = iTargetPid,
                message_id = 0,
                msg = sRespond,
                })
        end
    end
    if oPlayer then
        local oChatMgr = global.oChatMgr
        local iType = gamedefines.CHANNEL_TYPE.FRIEND_TYPE
        oChatMgr:LogAnaly(oPlayer,iType,sMsg,iTargetPid)
    end
end

function CFriendMgr:AckChatFrom(oPlayer, iSourcePid, iMessageId)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local oFriend = oPlayer:GetFriend()
    oFriend:EraseChat(iSourcePid, iMessageId)
end


--好友频道

function  CFriendMgr:BroadcastList(oPlayer,pidlist,bAdd)
    local sOp = "sub"
    if bAdd then
        sOp = "add"
    end
    local mLog = {
    pid = oPlayer:GetPid(),
    plist = extend.Table.serialize(pidlist),
    op = sOp
    }
    record.user("chat","debug",mLog)
    if #pidlist <=0 then
        return
    end
    local iMyid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local mBroadcastRole = {
        pid = iMyid,
    }

    -- 将自己的ID加入到对方的好友频道,监听好友的变化
    local lChannel = {}

    for _,pid in pairs(pidlist) do
        local iPid = tonumber(pid)
        table.insert(lChannel, {gamedefines.BROADCAST_TYPE.FRIEND_FOCUS_TYPE, iPid, bAdd})
    end
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = lChannel,
        info = mBroadcastRole,
        })

end


function CFriendMgr:FocusFriend(oPlayer,iPid)
    self:BroadcastList(oPlayer,{iPid,},true)
end

function CFriendMgr:UnFocusFriend(oPlayer, iPid)
    self:BroadcastList(oPlayer,{iPid,},false)
end


function CFriendMgr:FocusAllFriends(oPlayer)
    local oFriend = oPlayer:GetFriend()
    assert(oPlayer:GetProfile(),string.format(" Disconnect err profile %d",oPlayer:GetPid()))
    assert(oFriend,string.format(" Disconnect err friend %d",oPlayer:GetPid()))
    local mFriends = oFriend:GetFriends()
    self:BroadcastList(oPlayer,table_key_list(mFriends),true)
end

function CFriendMgr:UnFocusAllFriends(oPlayer)
    local oFriend = oPlayer:GetFriend()
    local mFriends = oFriend:GetFriends()
    self:BroadcastList(oPlayer,table_key_list(mFriends),false)
end

function CFriendMgr:FocusStranger(oPlayer,pidlist)
    local oFriend = oPlayer:GetFriend()
    local mFriends = oFriend:FriendKeyList()
    local mStrangerList = oPlayer.m_FocusFriendList
    extend.Array.remove(pidlist,oPlayer:GetPid())
    if mStrangerList then
        local mRmList = self:DifferentList(mStrangerList,pidlist)
        mRmList = self:DifferentList(mRmList,mFriends)
        self:BroadcastList(oPlayer,mRmList,false)
    end

    local mFocusList = self:DifferentList(pidlist,mFriends)
    oPlayer.m_FocusFriendList = mFocusList
    self:BroadcastList(oPlayer,mFocusList,true)
end

function CFriendMgr:UnFocusStranger(oPlayer)
    local mStrangerList = oPlayer.m_FocusFriendList
    local oFriend = oPlayer:GetFriend()
    local mFriends = oFriend:GetFriends()
    if mStrangerList then
        local mFocusList = self:DifferentList(mStrangerList,mFriends)
        self:BroadcastList(oPlayer,mFocusList,false)
        oPlayer.m_FocusFriendList = nil
    end
end


function CFriendMgr:DifferentList(mainlist,sublist)
    local mdiff = {}
    for k,v in pairs(mainlist) do
        if not sublist[k] then
            table.insert(mdiff,v)
        end
    end
    return mdiff
end



function CFriendMgr:RefreshOnlineStatus(iTarget,iStatus)
    local mData = {}
    mData.onlinestatus = iStatus
    mData.pid = iTarget
    local mPack = {
        message= "GS2COnlineStatus",
        type = gamedefines.BROADCAST_TYPE.FRIEND_FOCUS_TYPE,
        id = iTarget,
        data = {onlinestatus={mData}},
        }
    interactive.Send(".broadcast", "channel", "SendChannel", mPack)
end

function CFriendMgr:FindFriendByPid(oPlayer, iTargetShowId)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    local iShowId = oPlayer:GetShowId()
    if iShowId == iTargetShowId then
        oNotifyMgr:Notify(iPid, self:GetTextData(1008))
        return
    end
    router.Request("cs", ".idsupply", "common", "GetPidByShowId", {
        show_id = iTargetShowId
    }, function (mRecord, mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        self:FindFriendByPid1(oPlayer,iTargetShowId,mData)
    end)
end

--查找玩家
function CFriendMgr:FindFriendByPid1(oPlayer,iTargetPid, mData)
    iTargetPid = mData.pid or iTargetPid
    if not iTargetPid then return end

    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    if iPid == iTargetPid then
        oNotifyMgr:Notify(iPid, self:GetTextData(1008))
        return
    end
    self:SendFindResult(oPlayer,iTargetPid)
end

function CFriendMgr:SendFindResult(oPlayer,iTarget)
    local pid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    self:LoadProfileAndFriend(iTarget,function (oProfile,oFriend)
        if oProfile and oFriend then
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
            if oPlayer then
                self:_SendFindResult(oPlayer,oProfile,oFriend)
            end
        else
            oNotifyMgr:Notify(pid, self:GetTextData(1006))
        end
    end)
end

function CFriendMgr:_SendFindResult(oPlayer,oProfile,oFriend)
    local mDoc = oFriend:Document()
    local mPack = {
    pro = self:PackAddFriend(oPlayer,oProfile),
    labal = mDoc.labal,
    addr = mDoc.addr,
    }
    oPlayer:Send("GS2CSearchFriend",{unit= mPack})
end


function CFriendMgr:FindFriendByName(oPlayer, sName)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if sName == oPlayer:GetName() then
        oNotifyMgr:Notify(iPid, self:GetTextData(1008))
        return
    end

    local oHuodong = global.oHuodongMgr:GetHuodong("virtualchat")
    local mVirtual = oHuodong:PackVirtualPlayerInfo(sName)
    if mVirtual then
        local mPack = {
            pro = mVirtual,
        }
        oPlayer:Send("GS2CSearchFriend",{unit= mPack})
        return
    end
    local mData = {
        name = sName,
    }
    local mArgs = {
        module = "playerdb",
        cmd = "GetPlayerByName",
        data = mData,
    }
    gamedb.LoadDb(iPid,"common","LoadDb", mArgs, function (mRecord,mData)
        if is_release(self) then
            return
        end
        if not mData.data then
            oNotifyMgr:Notify(iPid, self:GetTextData(1006))
            return
        end
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:SendFindResult(oPlayer,mData.pid)
        end
    end)
end

function CFriendMgr:EditDocument(oPlayer,doc)
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr

    oWorldMgr:LoadFriend(iPid, function (oFriend)
        if not oFriend then
            return
        end
        self:_EditDocument(iPid,oFriend,doc)
        end)
end

function CFriendMgr:_EditDocument(iPid,oFriend,doc)
    local mSetData = self.m_SetDoc
    local mDoc = {}
    for _,v in ipairs(mSetData) do
        if doc[v] then
            mDoc[v] = doc[v]
        end
    end
    oFriend:SetDocument(mDoc)
    local  oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        self:TakeDocunment(oPlayer,oPlayer:GetPid())
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30006,1)
        self:AfterEditDoc(oPlayer,mDoc)
    end
end

function CFriendMgr:AfterEditDoc(oPlayer,mDoc)
    local mLog = oPlayer:GetPubAnalyData()
    mLog["faction_id"] = oPlayer:GetOrgID()
    mLog["faction_name"] = oPlayer:GetOrgName()
    mLog["star"] = ""
    mLog["birthday"] = ""
    if mDoc["birthday"] then
        local year,month,day = mDoc["birthday"]["year"],tonumber(mDoc["birthday"]["month"]),tonumber(mDoc["birthday"]["day"])
        mLog["birthday"] = string.format("%s-%02d-%02d",year,month,day)
        mLog["star"] = gamedefines.GetStar(month,day)
    end
    mLog["address"] = mDoc["addr"]or ""
    mLog["autograph"] = mDoc["signa"] or ""
    local mLabel = mDoc["labal"] or {}
    mLog["mark"] = ""
    mLog["sex"] = mDoc["sex"] or ""
    for _,sLabel in pairs(mLabel) do
        if mLog["mark"] == "" then
            mLog["mark"] = sLabel
        else
            mLog["mark"] = string.format("%s&%s",mLog["mark"],sLabel)
        end
    end
    analy.log_data("personalRecord",mLog)
end

function CFriendMgr:TakeDocunment(oPlayer,iTarget)
    local iPid = oPlayer:GetPid()
    interactive.Request(".org","common","GetPlayerOrgInfo",{pid = iTarget},function(mRecord,mData)
        local mInfo = mData.info or {}
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:TakeDocunment2(oPlayer,iTarget,mInfo)
        end
    end)
end

function CFriendMgr:TakeDocunment2(oPlayer,iTarget,mOrgInfo)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local oRankMgr = global.oRankMgr
    self:LoadProfileAndFriend(iTarget,function (oProfile,oFriend)
        oWorldMgr:LoadPartner(iTarget,function (oParCtrl)
            oRankMgr:GetRankInfo(iTarget,"warpower",function  (mData)
                local oPlayerObj = oWorldMgr:GetOnlinePlayerByPid(iPid)
                local oProfile = oWorldMgr:GetProfile(iTarget)
                local oFriend = oWorldMgr:GetFriend(iTarget)
                if not (oProfile and oPlayerObj and oFriend and oParCtrl) then
                    return
                end
                local mPack = self:PackDocument(oPlayer,oProfile,oFriend,oParCtrl,mData,mOrgInfo)
                oPlayerObj:Send("GS2CSendDocument",mPack)
                end)
            end)
        end)
end

function CFriendMgr:PackDocument(oPlayer,oProfile,oFriend,oParCtrl,mRank,mOrgInfo)
    mRank = mRank or {}
    local mData = {}
    local mDoc = oFriend:Document()
    local mSetData = self.m_SetDoc
    mData.pid = oProfile:GetPid()
    mData.grade = oProfile:GetGrade()
    mData.school = oProfile:GetSchool()
    mData.orgname = mOrgInfo.orgname or ""
    mData.name = oProfile:GetName()
    mData.shape = oProfile:GetModelInfo().shape
    mData.school_branch = oProfile:SchoolBranch()
    for _,sKey in ipairs(mSetData) do
        mData[sKey] = mDoc[sKey]
    end
    mData.charm = oProfile:GetUpvoteAmount()
    mData.charm_rank = 0
    mData.power = oProfile:GetPower()
    mData.power_rank  = mRank["rank"] or 0
    mData.show_equip = oFriend:GetData("show_equip",0)
    local mParList = {}
    for idx,oPartner in pairs(oParCtrl:GetShowPartner()) do

        local mPartner =  {
        parid = oPartner:ID(),
        partner_type = oPartner:SID(),
        star = oPartner:GetStar(),
        grade = oPartner:GetGrade(),
        awake = oPartner:GetData("awake",1),
        }
        table.insert(mParList,mPartner)
    end
    local mEquipList = {}
    if oFriend:GetData("show_equip",0) == 1 then
        for iPos,mEquip in pairs(oFriend.m_ShowEquip) do
            local iStoneSid = mEquip.equip_info.stone_sid
            local mEquip = {pos = iPos,item = iStoneSid,quality=mEquip.itemlevel}
            table.insert(mEquipList,mEquip)
        end
    end
    local iUpvote = 0
    if oProfile:IsUpvote(oPlayer:GetPid())  then
        iUpvote = 1
    end

    local mNet = {
    doc = mData,
    parlist = mParList,
    ph_url= oFriend:GetData("photo",""),
    equip = mEquipList,
    is_charm = iUpvote,
    }
    return mNet
end


--好友度

function CFriendMgr:BatchLoadFriend(lPid, endfunc, packfunc)
    local oWorldMgr = global.oWorldMgr
    local mHandle = {
        count = #lPid,
        data = {},
    }
    for _, k in ipairs(lPid) do
        oWorldMgr:LoadFriend(k, function (o)
            mHandle.count = mHandle.count - 1
            if o then
                if packfunc then
                    mHandle.data[k] = packfunc(o)
                else
                    mHandle.data[k] = true
                end
            end
            self:_BatchLoadFriend2(mHandle, endfunc)
        end)
    end
end

function CFriendMgr:_BatchLoadFriend2(mHandle, endfunc)
    if not mHandle or mHandle.count > 0 then
        return
    end
    endfunc(mHandle.data)
end



function CFriendMgr:AddFriendDegreeByWar(oWar)

end

function CFriendMgr:AddFriendDegree(iPid1, iPid2, iDegree)
    local func
    func = function (data)
        if not is_release(self) then
            self:_AddFriendDegree2(iPid1, iPid2, iDegree)
            return
        end
    end
    self:BatchLoadFriend({iPid1, iPid2}, func)
end

function CFriendMgr:_AddFriendDegree2(iPid1, iPid2, iDegree)
    local oWorldMgr = global.oWorldMgr
    local oFriend1 = oWorldMgr:GetFriend(iPid1)
    local oFriend2 = oWorldMgr:GetFriend(iPid2)
    if not oFriend1 or not oFriend2 then
        return
    end
    if not oFriend1:HasFriend(iPid2) or not oFriend2:HasFriend(iPid1) then
        return
    end
    local iSub = oFriend1:GetFriendDegree(iPid2) - oFriend2:GetFriendDegree(iPid1)
    if iSub > 0 then
        oFriend2:AddFriendDegree(iPid1, iDegree)
        if iDegree - iSub > 0 then
            oFriend1:AddFriendDegree(iPid2, iDegree - iSub)
        end
    else
        iSub = -iSub
        oFriend1:AddFriendDegree(iPid2,iDegree)
        if iDegree - iSub > 0 then
            oFriend2:AddFriendDegree(iPid1,iDegree - iSub)
        end
    end
    local oPlayer1 = oWorldMgr:GetOnlinePlayerByPid(iPid1)
    if oPlayer1 then
        self:GS2CRefreshDegree(oPlayer1, iPid2)
    end
    local oPlayer2 = oWorldMgr:GetOnlinePlayerByPid(iPid2)
    if oPlayer2 then
        self:GS2CRefreshDegree(oPlayer2, iPid1)
    end
end

function CFriendMgr:GS2CRefreshDegree(oPlayer, iTargetPid)
    if not oPlayer then
        return
    end
    local mData = {}
    mData.pid = iTargetPid
    mData.degree = oPlayer:GetFriend():GetFriendDegree(iTargetPid)
    oPlayer:Send("GS2CFriendDegree", mData)
end

-- 好友设置
function CFriendMgr:FriendSetting(oPlayer,mData)
    local oFriend = oPlayer:GetFriend()
    oFriend:Setting(mData)
    self:RefreshSetting(oPlayer)
end

function CFriendMgr:RefreshSetting(oPlayer)
    local oFriend = oPlayer:GetFriend()
    local mNet = {
    setting = oFriend:GetSetting()
    }

    oPlayer:Send("GS2CFriendSetting",mNet)
end

--好友推荐
function CFriendMgr:Recommend(oPlayer)
    --[[
    local iPid = oPlayer:GetPid()
    interactive.Request(".recommend","friend","RecommendFriend", {pid=iPid,arg={}}, function (mRecord,mData)
        if mData.success then
            local mData = mData.data
            self:_Recommend(iPid, mData)
        end
    end)
    ]]
end

function CFriendMgr:_Recommend(iPid,mData)
    local func = function (plist,mHandle)
                    local oWorldMgr = global.oWorldMgr
                    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                    if oPlayer then
                        self:_Recommend2Send(oPlayer,mHandle)
                    end
                end
    local handlefunc = function (oProfile)
            return self:_Recommend2PackNet(oProfile)
    end
    self:LoadProfileList(mData,func,handlefunc)
end

function CFriendMgr:_Recommend2Send(oPlayer,mHandle)
    local mNet = {
        recommend_friend_list = mHandle.list,
        }
    oPlayer:Send("GS2CRecommendFriends",mNet)
end

function CFriendMgr:_Recommend2PackNet(oProfile)
    local mNet = {
        pid = oProfile:GetPid(),
        name = oProfile:GetName(),
        shape = oProfile:GetModelInfo().shape,
        }
    return mNet
end

function CFriendMgr:MakeRelation(oProfile,oFriend)
    local mRelation = {friendlist={},}
    local mMyFriends = oFriend:GetFriends()
    for k, _ in pairs(mMyFriends) do
        mRelation.friendlist[tonumber(k)] = 1
    end
    mRelation.grade = oProfile:GetGrade()
    return mRelation
end

function CFriendMgr:RefreshRecommend(pid)
    --[[
    self:LoadProfileAndFriend(pid,function (oProfile,oFriend)
        self:_RefreshRecommend(pid,oProfile,oFriend)
        end)
    ]]
end

function CFriendMgr:_RefreshRecommend(pid,oProfile,oFriend)
    local mRelation = self:MakeRelation(oProfile,oFriend)
    interactive.Send(".recommend", "friend", "UpdateRelationInfo", {
    pid=pid,
    info = mRelation,
    })
end

function CFriendMgr:LoadProfileList(plist,func,handlefunc)
    local oWorldMgr = global.oWorldMgr
    local iRequestCount = #plist
    local mHandle = {
        count = iRequestCount,
        list = {},
        is_sent = false,
    }
    for _,k in ipairs(plist) do
        local o = oWorldMgr:GetOnlinePlayerByPid(k)
        if o then
            mHandle.count=mHandle.count - 1
            local mData = handlefunc(o)
            table.insert(mHandle.list,mData)
        else
           oWorldMgr:LoadProfile(k, function (o)
            mHandle.count=mHandle.count - 1
            if o then
                local mData = handlefunc(o)
                table.insert(mHandle.list,mData)
            end
           end)
       end
       if mHandle.count <= 0 and not mHandle.is_sent then
        func(plist,mHandle)
       end
    end
end

function CFriendMgr:RefreshGrade(oPlayer)
    local mNet = {}
    mNet.pid = oPlayer:GetPid()
    mNet.grade = oPlayer:GetGrade()
    local mData ={
        message="GS2CFriendGrade",
        type = gamedefines.BROADCAST_TYPE.FRIEND_FOCUS_TYPE,
        id = oPlayer:GetPid(),
        data = mNet,
        }
    interactive.Send(".broadcast", "channel", "SendChannel", mData)
end

--广播单一属性
function CFriendMgr:RefreshFriendAttr(oPlayer,sKey,val)
    local m = {}
    m.pid = oPlayer:GetPid()
    m[sKey] = val
    local mNet = {profile_list= {net.Mask("base.FriendProfile", m) }}

    local mData ={
        message="GS2CAddFriend",
        type = gamedefines.BROADCAST_TYPE.FRIEND_FOCUS_TYPE,
        id = oPlayer:GetPid(),
        data = mNet,
        }
    interactive.Send(".broadcast", "channel", "SendChannel", mData)
end

function CFriendMgr:SendNearbyList(oPlayer)
    -- 没这个功能,先随机给他些玩家
    local oWorldMgr = global.oWorldMgr
    local mPlayerList = oWorldMgr:GetOnlinePlayerList()
    local iPid = oPlayer:GetPid()
    local iCnt = 0
    local mNearbyList = {}
    local oFriend = oPlayer:GetFriend()
    local mOldNearbyList = oPlayer.m_OldNearbyList or {}
    local mNowList = {}

    local f = function (oPlayer,oTarget)
        local mData = {}
        mData.pro = self:PackAddFriend(oPlayer,oTarget:GetProfile())
        local mDoc = oTarget:GetFriend():Document()
        mData.labal = mDoc.labal
        mData.addr = mDoc.addr
        return mData
    end
    local iGradeLimit = oWorldMgr:QueryControl("friend","open_grade")
    for uid,obj in pairs(mPlayerList) do
        if obj:GetGrade()>= iGradeLimit and uid ~= iPid and not oFriend:HasFriend(uid) and not mOldNearbyList[uid] then
            iCnt = iCnt + 1
            local mData = {}
            mOldNearbyList[uid] = true
            mNowList[uid] = true
            table.insert(mNearbyList,f(oPlayer,obj))
        end
        if iCnt >= 10 then
            break
        end
    end
    local keylist = table_key_list(mOldNearbyList)
    local mRandom = extend.Random.random_size(keylist,#keylist)
    for _,uid in pairs(mRandom) do
        if iCnt >= 10 then
            break
        end
        local  obj =  oWorldMgr:GetOnlinePlayerByPid(uid)
        if obj and not mNowList[uid] and not oFriend:HasFriend(uid) then
            iCnt = iCnt + 1
            table.insert(mNearbyList,f(oPlayer,obj))
        end
    end
    oPlayer.m_OldNearbyList  = mOldNearbyList
    oPlayer:Send("GS2CNearbyFriend",{profile_list=mNearbyList})
end

function CFriendMgr:SetPhoto(oPlayer,sUrl)
    local oFriend = oPlayer:GetFriend()
    local iTime = 5
    local iGrade = oPlayer:GetGrade()
    if iGrade > 60 then
        iTime = iTime -1
    end
    if iGrade > 80 then
        iTime = iTime -1
    end
    iTime = iTime * 24 * 3600
    oFriend.SetData(sUrl)
    oPlayer.m_oThisTemp:Set("set_photo",1,iTime)
    self:TakeDocunment(oPlayer,oPlayer:GetPid())
end

function CFriendMgr:ShowPartnerInfo(oPlayer,iTarget,parid)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    oWorldMgr:LoadProfile(iTarget,function (oProfile)
        oWorldMgr:LoadPartner(iTarget,function (oParCtrl)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if not (oPlayer and oParCtrl and oProfile) then
                return
            end
            self:_ShowParnterInfo(oPlayer,oParCtrl,oProfile,parid)
        end)
        end)

end

function CFriendMgr:_ShowParnterInfo(oPlayer,oParCtrl,oProfile,parid)
        local oShow = oParCtrl:GetShowPartner()
        for _,oParnter in ipairs(oShow) do
            if oParnter:ID() == parid then
                local mNet = oParnter:PackNetLinkPartner()
                mNet.name = oProfile:GetName()
                mNet.pid = oProfile:GetPid()
                oPlayer:Send("GS2CSendFriendPartnerInfo",{par=mNet})
            end
        end
end

function CFriendMgr:SetShowEquip(oPlayer,iShow)
    local oFriend = oPlayer:GetFriend()
    if iShow ~= 0 then
        oFriend:SetData("show_equip",1)
        local fCallback = function (mRecord,mData)
            self:RefreshEquip(oPlayer,mData)
        end
        oPlayer.m_oItemCtrl:GetEquipList(oPlayer,fCallback)
    else
        oFriend:SetData("show_equip",0)
    end
end

function CFriendMgr:RefreshEquip(oPlayer,mData)
    local oFriend = oPlayer:GetFriend()
    for iPos = 1,6 do
        local mEquip = mData[iPos]
        -- local oNewEquip
        if mEquip then
            -- oNewEquip = loaditem.LoadItem(mEquip["sid"],mEquip)
            -- oNewEquip:SetData("school",oPlayer:GetSchool())
            oFriend:SetEquip(iPos,mEquip)
        end
    end
end

function CFriendMgr:ShowEquipInfo(oPlayer,iTargetPid,iPos)
    local  iPid =  oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    self:LoadProfileAndFriend(iTargetPid,function (oProfile,oFriend)
        local mEquip = oFriend.m_ShowEquip[iPos]
        local oPlayer  = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if mEquip and oPlayer then
            local mNet = {
                pid = iTargetPid,
                item = mEquip,
            }
            oPlayer:Send("GS2CSendFriendEquipInfo",mNet)
        end
    end)
end

