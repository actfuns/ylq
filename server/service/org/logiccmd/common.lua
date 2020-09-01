local global = require "global"
local res = require "base.res"
local record = require "public.record"
local interactive = require "base.interactive"

local orgdefines = import(service_path("orgdefines"))
local gamedefines = import(lualib_path("public.gamedefines"))

function OnLogin(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    local iPid = mData.pid
    local bReEnter = mData.reenter
    local mInfo = mData.info or {}
    oOrgMgr:OnLogin(iPid, bReEnter, mInfo)
end

function OnLogout(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    local iPid = mData.pid
    oOrgMgr:OnLogout(iPid)
end

function OnDisconnected(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    local iPid = mData.pid
    oOrgMgr:OnDisconnected(iPid)
end

function NewHour(mRecord,mData)
    local oOrgMgr = global.oOrgMgr
    local iWeekDay = mData.weekday
    local iHour = mData.hour
    oOrgMgr:NewHour(iWeekDay,iHour)
end

function SyncPlayerData(mRecord,mData)
    local iPid = mData.pid
    local data = mData.data
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    oPlayer:RecivePlayerData(data)
    local oOrg = oPlayer:GetOrg()
    if oOrg then
        oOrg:SyncMemberData(iPid, data)
    else
        global.oOrgMgr:SyncPlayerData(iPid, data)
    end
end

function SendOrgRankData(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:ReciveOrgRank(mData.info)
end

function ClearOrgLeave(mRecord,mData)
    local iPid = mData.pid
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
     local mInfo = oPlayer:GetInfo("leaveorg",{})
    mInfo["leavetime"] = 1
    oPlayer:SetInfo("leaveorg",mInfo)
end

function HandleOrgChat(mRecord, mData)
    local iPid = mData.pid
    local sMsg = mData.msg
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    oOrgMgr:HandleOrgChat(oPlayer,sMsg)
end

function GiveOrgWish(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    local iPid = mData.pid
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    oOrgMgr:GiveOrgWish(oPlayer,mData.data)
end

function TestOP(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    local iPid = mData.pid
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
     oOrg:TestOP(oPlayer,mData.cmd,mData.data)
end

function RewardOrgOffer(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    local iPid = mData.pid
    local iVal = mData.value
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
    oOrg:RewardOrgOffer(iPid, iVal)
    local oMem = oOrg:GetMember(iPid)
    if oMem and oMem:GetPosition() == orgdefines.ORG_POSITION.MEMBER then
        local iVal = res["daobiao"]["org"]["rule"][1]["org_mem_offer"]
        local iPos = orgdefines.ORG_POSITION.FINE
        local iNowOffer = oMem:GetHistoryOffer()
        if iNowOffer >= iVal then
            oOrg:SetPosition(iPid,iPos)
        end
    end
end

function RewardActivePoint(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    local iPid = mData.pid
    local iVal = mData.value
    local sReason = mData.reason
    local mArgs = mData.args
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
    oOrg:RewardActivePoint(iPid,iVal,sReason,mArgs)
end

function RewardOrgCash(mRecord,mData)
    local oOrgMgr = global.oOrgMgr
    local iOrgID = mData.orgid
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if oOrg then
        oOrg:AddCash(mData.value,mData.reason)
    end
end

function RewardOrgExp(mRecord,mData)
    local oOrgMgr = global.oOrgMgr
    local iOrgID = mData.orgid
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if oOrg then
        oOrg:AddExp(mData.value,mData.reason)
    end
end

function AddOrgDegree(mRecord,mData)
    local oOrgMgr = global.oOrgMgr
    local iOrgID = mData.orgid
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if oOrg then
        oOrg:AddSignDegree(mData.value,mData.reason)
    end
end

function AddPrestige(mRecord,mData)
    local oOrgMgr = global.oOrgMgr
    local iOrgID = mData.orgid
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if oOrg then
        oOrg:AddPrestige(mData.value,mData.reason, mData.args)
    end
end

function ResumeOrgCash(mRecord,mData)
    local iPid = mData.pid
    local iCostVal = mData.cost
    local sReason = mData.reason
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    local suc = false
    local iCash = 0
    local memlist = {}
    if oPlayer then
        local oOrg = oPlayer:GetOrg()
        if oOrg then
            local iPos = oPlayer:GetOrgPos()
            iCash = oOrg:GetCash()
            if iPos == orgdefines.ORG_POSITION.LEADER or iPos == orgdefines.ORG_POSITION.DEPUTY then
                if oOrg:ValidCash(iCostVal) then
                    memlist = oOrg:GetOrgMemList()
                    oOrg:ResumeCash(iCostVal,sReason,{cancel_tip = true})
                    suc = true
                end
            else
                oPlayer:Notify("限会长和副会长购买")
            end
        end
    end
    interactive.Response(mRecord.source, mRecord.session, {
        suc = suc,
        memlist = memlist,
        remain_cash = iCash,
    })
end

function AddLog(mRecord,mData)
    local iPid = mData.pid
    local sText = mData.text
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
    oOrg:AddLog(oPlayer:GetPid(),sText)
end

function GetOrgSimpleInfo(mRecord,mData)
    local oOrgMgr = global.oOrgMgr
    local iOrgID = mData["org"]
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    local mData = {}
    if oOrg then
        mData = {
        name = oOrg:GetName(),
        id = oOrg:OrgID(),
        level = oOrg:GetLevel(),
        }
    end
    interactive.Response(mRecord.source, mRecord.session, {
        data = mData,
    })
end

function SetOrgMemberData(mRecord ,mData)
    local iPid = mData.pid
    local sKey = mData["key"]
    local val = mData["val"]
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local oMem = oOrg:GetMember(iPid)
    if oMem then
        oMem:SetData(sKey,val)
    end
end

function SetPlayerInfo(mRecord,mData)
    local iPid = mData.pid
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    oPlayer:SetInfo(mData.key,mData.val)
end

function GetOrgMemberData(mRecord,mData)
    local oOrgMgr = global.oOrgMgr
    local iOrgID = mData["org"]
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    local mData = {}
    if oOrg then
        local oMember = oOrg.m_oMemberMgr:GetMemberMap()
        for pid,oMem in pairs(oMember) do
            mData[pid] = oMem:GetSimpleInfo()
        end
    end
    interactive.Response(mRecord.source, mRecord.session, {
        data = mData,
    })
end

function ResetOrgFuBen(mRecord,mData)
    local iPid = mData["pid"]
    local iCost = mData["cost"]
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
    local f = function (iCode,mData)
        local mRes = mData or {}
        mRes["code"] = iCode
        interactive.Response(mRecord.source, mRecord.session, {
            data = mRes,
        })
    end
    if not oPlayer then
        f(1)
        return
    end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        f(2)
        return
    end
    if not ( oOrg:IsLeader(iPid) or oOrg:IsSecond(iPid) ) then
        f(3)
        return
    end
    if iCost > 0 then
        if not oOrg:ValidCash(iCost) then
            f(4)
            return
        end
        oOrg:ResumeCash(iCost,"公会副本重置")
    end
    f(0,{pos = oOrg:GetPosition(iPid)})
end

function CheckRubbishOrg(mRecord,mData)
    local mOrgList = mData["orglist"]
    local mRubbish  = {}
    local oOrgMgr = global.oOrgMgr
    local mNormalOrgList = oOrgMgr:GetNormalOrgList()
    for _,iOrg in ipairs(mOrgList) do
        if not mNormalOrgList[iOrg] then
            table.insert(mRubbish,iOrg)
        end
    end

    interactive.Response(mRecord.source, mRecord.session, {
            rubbish = mRubbish,
        })
end


function GetOrgMemList(mRecord,mData)
    local mInfo = mData.data
    for _,info in pairs(mInfo) do
        local iOrgID = info.orgid
        local oOrg = global.oOrgMgr:GetNormalOrg(iOrgID)
        local lMemList = {}
        if oOrg then
            lMemList = oOrg:GetOrgMemList()
            info.memlist = lMemList
        end
    end
    interactive.Response(mRecord.source, mRecord.session,{
            data = mInfo,
        })
end

function StartOrgWar(mRecord, mData)
    interactive.Response(mRecord.source, mRecord.session,{
            data = global.oOrgMgr:StartOrgWar(),
    })
end

function GetPlayerOrgInfo(mRecord,mData)
    local iPid = mData.pid
    local oOrgMgr = global.oOrgMgr
    local iOrgID = oOrgMgr:GetPlayerOrgID(iPid)
    if not iOrgID then
        interactive.Response(mRecord.source, mRecord.session,{})
        return
    end
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if not oOrg then
        interactive.Response(mRecord.source, mRecord.session,{})
        return
    end
    local oMem = oOrg:GetMember(iPid)
    if not oMem then
        interactive.Response(mRecord.source, mRecord.session,{})
        return
    end
    interactive.Response(mRecord.source, mRecord.session,{
            info = {
                orgid = iOrgID,
                orgname = oOrg:GetName(),
                orglevel = oOrg:GetLevel(),
                orgpos = oMem:GetPosition(),
            }
    })
end

function EndOrgWar(mRecord, mData)
    global.oOrgMgr:SetOrgWarOpen(false)
end

function Forward(mRecord, mData)
    local iPid = mData.pid
    local sCmd = mData.cmd
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)

    if oPlayer then
        local func = ForwardNetcmds[sCmd]
        assert(func, string.format("Forward function:%s not exist!", sCmd))
        func(oPlayer, mData.data)
    end
end

function CloseGS(mRecord, mData)
    global.oOrgMgr:CloseGS()
end

function OrgWarReward(mRecord,mData)
    local oOrgMgr = global.oOrgMgr
    local iOrgID = mData.orgid
    local iCash = mData.cash
    local iPrestige = mData.prestige
    local iExp = mData.exp
    local sReason = mData.reason
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if oOrg then
        if iCash then
            oOrg:AddCash(iCash,sReason)
        end
        if iPrestige then
            oOrg:AddPrestige(iPrestige,sReason)
        end
        if iExp then
            oOrg:AddExp(iExp,sReason)
        end
    end
end

ForwardNetcmds = {}

function ForwardNetcmds.C2GSOrgList(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    if oPlayer:GetOrgID() ~= 0 then
        oPlayer:Notify(oOrgMgr:GetOrgText(1001))
        return
    end

    oOrgMgr:GenerateCache()

    local pid = oPlayer:GetPid()
    local mNet = {}
    for _, mOrgInfo in pairs(oOrgMgr:GetOrgListCache()) do
        local orgid = mOrgInfo.orgid
        local oOrg = oOrgMgr:GetNormalOrg(orgid)
        if oOrg then
            local mInfo = table_copy(mOrgInfo)
            mInfo = oOrg:PackOrgListInfo(pid,mInfo)
            mInfo.info.aim = ""
            local oMem = oOrg:GetApplyInfo(pid)
            if oMem and not oMem:VaildApplyTime() then
                oOrg:RemoveApply(pid)
                oOrg:UpdateOrgInfo({apply_count=true})
            end
            table.insert(mNet, mInfo)
        end
    end

    oPlayer:Send("GS2COrgList",{infos=mNet})
end

function ForwardNetcmds.C2GSSearchOrg(oPlayer, mData)
    local sText = mData.text
    if not sText then return end
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end

    local mNet = {}
    local l = {"(", ")", ".", "%", "+", "-", "*", "?", "[", "^", "$"}
    local sNewText = ""
    for i=1,#sText do
        local sChar = index_string(sText, i)
        if table_in_list(l, sChar) then
            sChar = "%"..sChar
        end
        sNewText = sNewText..sChar
    end
    for sName, oOrg in pairs(oOrgMgr.m_mNormalOrgNames) do
        local iOrgID = oOrg:OrgID()
        local sOrgID = tostring(iOrgID)
        if string.match(sOrgID, sNewText) or string.match(sName, sNewText) then
            local mInfo = oOrg:PackOrgListInfo(pid)
            mInfo.info.aim = ""
            table.insert(mNet, mInfo)
        end
        if #mNet >= 20 then
            break
        end
    end

    if #mNet < 1 then
        oPlayer:Notify("无法搜到该公会")
        return
    end

    oPlayer:Send("GS2CSearchOrg",{infos=mNet})
end

-- 申请入帮
function ForwardNetcmds.C2GSApplyJoinOrg(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:ApplyJoinOrg(oPlayer,mData)
end

-- 申请入帮
function ForwardNetcmds.C2GSJoinOrgBySpread(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:ApplyJoinOrgBySpread(oPlayer,mData)
end

-- 一键申请入帮
function ForwardNetcmds.C2GSMultiApplyJoinOrg(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    if oPlayer:GetOrgID() ~= 0 then
        oPlayer:Notify(oOrgMgr:GetOrgText(1001))
        return
    end
    local iLimitGrade = res["daobiao"]["global_control"]["org"]["open_grade"]
    if oPlayer:GetGrade() < iLimitGrade then
        oPlayer:Notify(oOrgMgr:GetOrgText(1002, {grade=iLimitGrade}))
        return
    end
    local iLeaveTime = oPlayer:GetPreLeaveOrgTime()
    if get_time() - iLeaveTime <= 3600 *12 then
        oPlayer:Notify("离开公会12小时之后才能加入公会")
        return
    end
    local iPid = oPlayer:GetPid()
    local power = oPlayer:GetPower()
    local iOrgID = oOrgMgr:GetAllowOrgID(oPlayer,power)
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if oOrg then
        local flag = oOrgMgr:AddForceMember(iOrgID,oPlayer)
        if not flag then
            oPlayer:Notify("公会成员已满")
        end
    else
        oPlayer:Notify("目前没有适合您自由加入的公会")
    end
end

function ForwardNetcmds.C2GSGetOrgInfo(oPlayer,mData)
    local iOrgID = mData.orgid
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    local pid = oPlayer:GetPid()
    if oOrg then
        local info = oOrg:PackOrgListInfo(pid)
        local meminfo = oOrg:PackOrgMemList()
        oPlayer:Send("GS2CGetOrgInfo",{info=info,meminfo=meminfo})
    end
end

-- 创建公会
function ForwardNetcmds.C2GSCreateOrg(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local sName = mData.name
    local tArgs = {
         sflag=mData.sflag,
         flagbgid=mData.flagbgid,
         aim = mData.aim
    }
    local iLen = string.len(sName)
    local iMaxLen = res["daobiao"]["org"]["rule"][1]["max_name_len"]
    local iMinLen = res["daobiao"]["org"]["rule"][1]["min_name_len"]
    if iLen > iMaxLen*3 or iLen < iMinLen then
        oPlayer:Notify("公会名字长度为4~8")
        return
    end
    if oPlayer:GetOrgID() ~= 0 then
        oPlayer:Notify(oOrgMgr:GetOrgText(1001))
        return
    end
    local iLimitGrade = res["daobiao"]["global_control"]["org"]["open_grade"]
    if oPlayer:GetGrade() < iLimitGrade then
        oPlayer:Notify(oOrgMgr:GetOrgText(1002, {grade=iLimitGrade}))
        return
    end
    if oOrgMgr:GetNormalOrgByFlag(mData.sflag) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1018))
        return
    end
    local iLeaveTime = oPlayer:GetPreLeaveOrgTime()
    if get_time() - iLeaveTime <= 3600 *12 then
        oPlayer:Notify("离开公会后12小时内无法创建公会")
        return
    end
    oOrgMgr:CreateNormalOrg(oPlayer, sName, tArgs)
end

--请求公会主要信息
function ForwardNetcmds.C2GSOrgMainInfo(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
    local mNet = oOrg:PackOrgInfo()
    oPlayer:Send("GS2COrgMainInfo", {info=mNet})
end

-- 请求成员列表
function ForwardNetcmds.C2GSOrgMemberList(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local handle_type = mData.handle_type
    local oOrg =  oPlayer:GetOrg()
    if not oOrg then return end

    oPlayer:Send("GS2COrgMemberInfo", {infos=oOrg:PackOrgMemList(),handle_type=handle_type})
end

-- 打开入帮申请界面
function ForwardNetcmds.C2GSOrgApplyList(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
    oOrg:CheckApplyOverDue()
    oPlayer:Send("GS2COrgApplyList", {infos=oOrg:PackOrgApplyInfo(),powerlimit=oOrg:GetPowerLimit(),needallow=oOrg:GetNeedAllow()})
end

-- 入帮申请处理
function ForwardNetcmds.C2GSOrgDealApply(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end

    local iPid = mData.pid
    local iDeal = mData.deal or 0   -- 1.同意,0.不同意
    if not oOrg:HasDealJoinAuth(oPlayer:GetPid()) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1004))
        return
    end

    if iDeal == 1 then
        if oOrg:IsMember(iPid) then
            oPlayer:Notify(oOrgMgr:GetOrgText(1005))
            oPlayer:Send("GS2COrgDealApply", {pid=iPid,deal=0})
            return
        end

        local oMem = oOrg:GetApplyInfo(iPid)
        if not oMem then
            oPlayer:Notify(oOrgMgr:GetOrgText(1006))
            oPlayer:Send("GS2COrgDealApply", {pid=iPid,deal=0})
            return
        end
        local sName = oMem:GetName()
        if not oMem:VaildApplyTime() then
            oPlayer:Notify(oOrgMgr:GetOrgText(1005))
            oOrg:RemoveApply(iPid)
        else
            local flag = oOrgMgr:AcceptMember(oOrg:OrgID(), iPid)
            if not flag then
                oPlayer:Notify("公会成员已满")
                return
            end
            local oInPlayer = oOrgMgr:GetOnlinePlayerByPid(iPid)
            if oInPlayer then
                oInPlayer:Notify("成功加入公会")
            end
            local sText = oOrgMgr:GetOrgLog(1007,{role1=oPlayer:GetName(),role2=sName})
            oOrg:AddLog(oPlayer:GetPid(),sText)
        end
        oOrg:UpdateOrgInfo({apply_count=true})
    else
        oOrg:RemoveApply(iPid)
        oOrg:UpdateOrgInfo({apply_count=true})
    end
    oPlayer:Send("GS2COrgDealApply", {pid=iPid,deal=iDeal})

    record.user("org", "dealapply", {pid=oPlayer:GetPid(), target = iPid, orgid=oOrg:OrgID(),deal=iDeal})
end

local function orgaimlen(str)
    local count = 0
    local len = 0
    local limit = string.len(str)
    while count < limit do
        local utf8 = string.byte(str, count + 1)
        if utf8 == nil then
            break
        end
        len = len + 1
        --utf8字符1byte,中文3byte
        if utf8 > 127 then
            count = count + 3
        else
            count = count + 1
        end
    end
    return len
end

-- 修改宣言
function ForwardNetcmds.C2GSUpdateAim(oPlayer, mData)
    local aim = mData.aim
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local iPid = oPlayer:GetPid()
    local oOrg = oOrgMgr:GetNormalOrg(oPlayer:GetOrgID())
    if not oOrg then
        return
    end
    if not oOrg:HasUpdateAimAuth(iPid) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1004))
        return
    end
    local iLen = orgaimlen(aim)
    if iLen < 0 or iLen > 150 then
        oPlayer:Notify("公告字数过多")
        return
    end
    oOrg:SetAim(aim)
    oPlayer:Send("GS2COrgAim", {orgid=oOrg:OrgID(), aim=oOrg:GetAim()})
    local sText = oOrgMgr:GetOrgLog(1003,{rolename=oPlayer:GetName()})
    oOrg:AddLog(iPid,sText)
    oOrg:UpdateOrgInfo({aim = true})
    oOrgMgr:UpdateRankOrgInfo(oOrg)
end

--拒绝所有申请
function ForwardNetcmds.C2GSRejectAllApply(oPlayer, mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end

    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    if not oOrg:HasDealJoinAuth(oPlayer:GetPid()) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1004))
        oPlayer:Send("GS2CRejectAllApplyResult", {result=0})
        return
    end
    oOrg:RemoveAllApply()
    oOrg:UpdateOrgInfo({apply_count=true})
    oPlayer:Send("GS2CRejectAllApplyResult", {result=1})
    record.user("org", "dealallapply", {pid=oPlayer:GetPid(),orgid=oOrg:OrgID()})
end

-- 设置职位
function ForwardNetcmds.C2GSOrgSetPosition(oPlayer, mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end

    local iTarPid = mData.pid
    local iPosition = mData.position
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local iOldp = oOrg:GetPosition(iTarPid)
    local oMem = oOrg:GetMember(iTarPid)
    if not oMem then
        return
    end
    if iPosition == orgdefines.ORG_POSITION.LEADER then
        oOrg:GiveLeader2Other(oPlayer:GetPid(), iTarPid)
        local sText = oOrgMgr:GetOrgLog(1008,{role1=oPlayer:GetName(),role2=oMem:GetName()})
        oOrg:AddLog(oPlayer:GetPid(),sText)
    else
        oOrg:SetMemPosition(oPlayer, iTarPid, iPosition)
    end
    local iNewp = oOrg:GetPosition(iTarPid)
    record.user("org", "setpos", {orgid=oOrg:OrgID(),pid=oPlayer:GetPid(),target=iTarPid,oldp=iOldp,newp=iNewp})
end

-- 脱离公会
function ForwardNetcmds.C2GSLeaveOrg(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    if oOrgMgr:IsOrgWarOpen() then
        oPlayer:Notify("公会战期间，不能退出公会")
        return
    end
    PlayerLeaveOrg(oPlayer)
end

function PlayerLeaveOrg(oPlayer)
    local iOrgID = oPlayer:GetOrgID()
    if iOrgID == 0 then
        return
    end
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if not oOrg then
        return
    end
    local oMem = oOrg:GetMember(oPlayer:GetPid())
    if not oMem then
        return
    end

    local sText = oOrgMgr:GetOrgText(1021)
    oMem:SendTips(sText)

    local sText = oOrgMgr:GetOrgLog(1011,{rolename=oPlayer:GetName()})
    oOrg:AddLog(oPlayer:GetPid(),sText)
    oOrgMgr:LogAnalyData(oOrg,oPlayer:GetPid(),2)
    if oOrg:IsLeader(oPlayer:GetPid()) then
        if oOrg:GetMemberCnt()  > 1 then
            oPlayer:Notify(oOrgMgr:GetOrgText(1007))
            return
        end
        oOrgMgr:LeaveOrg(oPlayer:GetPid(), iOrgID)
        oOrgMgr:DeleteNormalOrg(oOrg)
    else
        oOrgMgr:LeaveOrg(oPlayer:GetPid(), iOrgID)
    end
    oPlayer:Send("GS2CDelMember", {pid=oPlayer:GetPid()})
    record.user("org", "leave", {orgid=iOrgID,pid=oPlayer:GetPid()})
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if oOrg then
        oOrg:BoardCastWishUI("GS2CDelMember",{pid = oPlayer:GetPid()})
    end
end

-- 世界频道宣传公会
function ForwardNetcmds.C2GSSpreadOrg(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:SpreadOrg(oPlayer,mData.powerlimit)
end

local function ValidAddKickCnt(oMem)
    local iLastOnline = oMem:GetData("logout_time",0)
    local iNowTime = get_time()
    if iNowTime - iLastOnline >= 6*3600 and oMem:GetActivePoint() == 0 and oMem:GetHistoryOffer() == 0 then
        return false
    end
    if iNowTime - iLastOnline >= 2*24*3600 then
        return false
    end
    return true
end

-- 踢出公会
function ForwardNetcmds.C2GSKickMember(oPlayer, mData)
    local iKickPid = mData.pid
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    if oOrgMgr:IsOrgWarOpen() then
        oPlayer:Notify("公会战期间，不能踢出成员")
        return
    end
    local iPid = oPlayer:GetPid()
    local iOrgID = oPlayer:GetOrgID()
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if not oOrg then
        return
    end
    local oMem = oOrg:GetMember(iKickPid)
    if not oMem then
        oPlayer:Notify(oOrgMgr:GetOrgText(1014))
        return
    end

    if not oOrg:HasKickAuth(iPid, iKickPid) then
        return
    end

    if not oOrg:ValidKick(iPid) and not ValidAddKickCnt(oMem) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1025))
        return
    end

    local sText = oOrgMgr:GetOrgText(1019)
    oMem:SendTips(sText)
    oOrgMgr:LogAnalyData(oOrg,iKickPid,3)

    if ValidAddKickCnt(oMem) then
        oOrg:AddKickCnt(iPid)
    end
    oOrgMgr:OnKickMember(iKickPid)

    local sText = oOrgMgr:GetOrgLog(1012,{role1=oPlayer:GetName(),role2=oMem:GetName()})
    oOrg:AddLog(oPlayer:GetPid(),sText)
    oOrgMgr:LeaveOrg(iKickPid, iOrgID)
    oPlayer:Send("GS2CDelMember", {pid=iKickPid})

    local oInPlayer = oOrgMgr:GetOnlinePlayerByPid(iKickPid)
    if oInPlayer then
        oInPlayer:Send("GS2CDelMember", {pid=iKickPid})
    end



    record.user("org", "kick", {orgid=iOrgID,pid=oPlayer:GetPid(),kickid=iKickPid})
end

-- 邀请入帮
function ForwardNetcmds.C2GSInvited2Org(oPlayer, mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end

    local iOrgID = oOrg:OrgID()
    local invitePid = mData.pid
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    if oOrg:GetMemberCnt() >= oOrg:GetMaxMemberCnt() then
        oPlayer:Notify("公会人员已达上限，无法邀请。")
        return
    end
    local oInPlayer = oOrgMgr:GetOnlinePlayerByPid(invitePid)
    if not oInPlayer then
        oPlayer:Notify("对方不在线")
        return
    end
    if oInPlayer:GetOrgID() ~= 0 then
        oPlayer:Notify("对方已有公会")
        return
    end
    local iLimitGrade = res["daobiao"]["global_control"]["org"]["open_grade"]
    if oInPlayer:GetGrade() < iLimitGrade then
        oPlayer:Notify(oOrgMgr:GetOrgText(1008,{level=iLimitGrade}))
        return
    end
    local iLeaveTime = oInPlayer:GetPreLeaveOrgTime()
    if get_time() - iLeaveTime <= 3600 *12 then
        oPlayer:Notify("对方离开公会后12小时内无法加入公会")
        return
    end

    if oInPlayer.m_OrgInviteTime and get_time() - oInPlayer.m_OrgInviteTime < 5 *60 then
        oPlayer:Notify("对忙正忙，无法进行邀请")
        return
    end

    local mData = {}
    mData.orgId = oPlayer:GetOrgID()
    oPlayer:Notify(oOrgMgr:GetOrgText(1009))
    oInPlayer.m_OrgInviteTime = get_time() + 5 * 60
    oInPlayer:Send("GS2CInvited2Org", {orgid=iOrgID,pid=oPlayer:GetPid(), pname=oPlayer:GetName(), org_name=oOrg:GetName(), org_level=oOrg:GetLevel()})
    record.user("org", "invite", {orgid=iOrgID,pid=oPlayer:GetPid(),inviteid=invitePid})
end

-- 处理公会邀请信息
function ForwardNetcmds.C2GSDealInvited2Org(oPlayer, mData)
    local invitePid = mData.pid
    local iOrgID = mData.orgid
    local flag = mData.flag or 0
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end

    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if not oOrg then return end
    oPlayer.m_OrgInviteTime = nil
    if flag == 0 then
        local oInPlayer = oOrgMgr:GetOnlinePlayerByPid(invitePid)
        if oInPlayer then
            oInPlayer:Notify(oOrgMgr:GetOrgText(1010, {role=oPlayer:GetName()}))
        end
        oPlayer:Notify(oOrgMgr:GetOrgText(1011, {bpname=oOrg:GetName()}))
    else
        if oPlayer:GetOrgID() ~= 0 then
            oPlayer:Notify(oOrgMgr:GetOrgText(1001))
            return
        end
        local iLimitGrade = res["daobiao"]["global_control"]["org"]["open_grade"]
        if oPlayer:GetGrade() < iLimitGrade then
            oPlayer:Notify(oOrgMgr:GetOrgText(1002, {grade=iLimitGrade}))
            return
        end
        if not oOrg:GetMember(invitePid) then
            oPlayer:Notify("邀请者已退出该公会")
            return
        end
        if oOrg:GetMemberCnt() >= oOrg:GetMaxMemberCnt() then
            oPlayer:Notify("公会人员已达上限，无法加入。")
            return
        end
        local iNeedAllow = oOrg:GetNeedAllow()
        local isAdd = false
        if iNeedAllow == 0 then
            isAdd = oOrgMgr:AddForceMember(iOrgID, oPlayer)
        end
        if not isAdd then
            oOrg:AddApply(oPlayer, orgdefines.ORG_APPLY.INVITED)
            oPlayer:Notify(oOrgMgr:GetOrgText(1012, {bpname=oOrg:GetName()}))
            record.user("org", "apply", {pid=oPlayer:GetPid(), orgid=oOrg:OrgID()})
        else
            local sText = oOrgMgr:GetOrgLog(1010,{rolename=oPlayer:GetName()})
            oOrg:AddLog(oPlayer:GetPid(),sText)
            oPlayer:Notify(oOrgMgr:GetOrgText(1013, {bpname=oOrg:GetName()}))
        end
    end
    record.user("org", "dealinvite", {orgid=iOrgID,pid=oPlayer:GetPid(),flag=flag})
end

function ForwardNetcmds.C2GSSetApplyLimit(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local oOrg = oPlayer:GetOrg()
    local powerlimit = mData.powerlimit or 0
    local needallow = mData.needallow or 0
    if not oOrg then return end
    if not table_in_list({0,1},needallow) then
        oPlayer:Notify("格式不正确")
        return
    end
    if powerlimit < 0 or powerlimit > 999999999 then
        oPlayer:Notify("格式不正确")
        return
    end
    oOrg:SetPowerLimit(powerlimit)
    oOrg:SetNeedAllow(needallow)
    oPlayer:Send("GS2CSetApplyLimitResult", {result=1})
    oPlayer:Notify("保存成功")

    record.user("org", "setlimit", {orgid=oOrg:OrgID(),pid=oPlayer:GetPid(),limit=powerlimit,allow=needallow})
    local sText = oOrgMgr:GetOrgLog(1009,{rolename=oPlayer:GetName()})
    oOrg:AddLog(oPlayer:GetPid(),sText)
end

function ForwardNetcmds.C2GSUpdateFlagID(oPlayer, mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local oOrg = oPlayer:GetOrg()
    local sflag = mData.sflag
    local flagbgid = mData.flagbgid
    if not oOrg then return end
    if not oOrg:HasUpdateFlagAuth(oPlayer:GetPid()) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1004))
        return
    end
    local sOldFlag = oOrg:GetSFlag()
    if sflag ~= sOldFlag and oOrgMgr:GetNormalOrgByFlag(sflag) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1018))
        return
    end
    -- local iVal = res["daobiao"]["org"]["rule"][1]["change_flag_price"]
    -- if not oPlayer:ValidGoldCoin(iVal) then
    --     return
    -- end
    oOrg:SetSFlag(sflag)
    oOrg:SetFlagBgID(flagbgid)
    oPlayer:Send("GS2CUpdateFlagID", {result=1})
    -- oPlayer:ResumeGoldCoin(iVal, "修改会徽")
    oOrgMgr:OnOrgChangeFlag(sOldFlag,oOrg:GetSFlag())
    oOrg:UpdateOrgInfo({sflag = true,flagbgid=true})
    oOrg:UpdateAllMemShare()
    oOrgMgr:SyncTerraWarInfo(oOrg,{sflag = true,flagbgid=true})
    record.user("org", "updateflag", {orgid=oOrg:OrgID(),pid=oPlayer:GetPid(),sflag=sflag,flagbgid=flagbgid})
end

function ForwardNetcmds.C2GSGetAim(oPlayer, mData)
    local iOrgID = mData.orgid
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local oOrg = oOrgMgr:GetNormalOrg(iOrgID)
    if not oOrg then
        oPlayer:Notify(oOrgMgr:GetOrgText(1003))
        return
    end
    oPlayer:Send("GS2COrgAim", {orgid=iOrgID, aim=oOrg:GetAim()})
end

function ForwardNetcmds.C2GSBanChat(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    local target = mData.target
    local flag = mData.flag or 0
    local oOrg = oPlayer:GetOrg()
    if not oOrg then return end
    if not oOrg:HasBanChatAuth(oPlayer:GetPid()) then
        oPlayer:Notify(oOrgMgr:GetOrgText(1004))
        return
    end
    local oMem = oOrg:GetMember(target)
    if not oMem then
        oPlayer:Notify(oOrgMgr:GetOrgText(1014))
        return
    end
    if flag == 1 then
        oMem:BanChat()
        oPlayer:Notify("禁言成功")
        local sMsg = oOrgMgr:GetOrgText(2004, {role=oMem:GetName()})
        oOrgMgr:SendMsg2Org(sMsg, oOrg:OrgID())
    elseif flag == 0 then
        oMem:UnBanChat()
        oPlayer:Notify("解除禁言成功")
    end
    oPlayer:Send("GS2CRefreshOrgMember",{mem_info = oMem:PackOrgMemInfo()})
end

function ForwardNetcmds.C2GSOrgBuild(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:StartOrgBuild(oPlayer,mData)
end

function ForwardNetcmds.C2GSSpeedOrgBuild(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:SpeedOrgBuild(oPlayer,mData)
end

function ForwardNetcmds.C2GSDoneOrgBuild(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:DoneOrgBuild(oPlayer)
end

function ForwardNetcmds.C2GSOrgSignReward(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:OrgSignReward(oPlayer,mData)
end

function ForwardNetcmds.C2GSOrgWishList(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:OrgWishList(oPlayer)
end

function ForwardNetcmds.C2GSOrgWish(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:OrgWish(oPlayer,mData)
end

function ForwardNetcmds.C2GSOrgEquipWish(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:OrgWishEquip(oPlayer,mData)
end

function ForwardNetcmds.C2GSGiveOrgWish(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:GiveOrgWish(oPlayer,mData)
end

function ForwardNetcmds.C2GSGiveOrgEquipWish(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:GiveOrgEquipWish(oPlayer,mData)
end

function ForwardNetcmds.C2GSLeaveOrgWishUI(oPlayer,mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    oOrg:LeaveWishUI(oPlayer:GetPid())
end

function ForwardNetcmds.C2GSOpenOrgRedPacket(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:OpenOrgRedPacket(oPlayer,mData)
    local oOrg = oPlayer:GetOrg()
     oOrg:UpdateOrgInfo({is_open_red_packet=true,red_packet_rest=true,red_packet=true})
end

function ForwardNetcmds.C2GSDrawOrgRedPacket(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:DrawOrgRedPacket(oPlayer,mData)
end

function ForwardNetcmds.C2GSOrgRedPacket(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:SendOrgRedPacket(oPlayer,mData)
end

function ForwardNetcmds.C2GSOrgLog(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:SendOrgLog(oPlayer,mData)
end

function ForwardNetcmds.C2GSPromoteOrgLevel(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:PromoteOrgLevel(oPlayer,mData)
end

function ForwardNetcmds.C2GSOrgRecruit(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:OrgRecruit(oPlayer)
end

function ForwardNetcmds.C2GSClickOrgRecruit(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:ClickOrgRecruit(oPlayer,mData)
end

function ForwardNetcmds.C2GSOrgOnlineCount(oPlayer,mData)
    local oOrgMgr = global.oOrgMgr
    if oOrgMgr:IsClose(oPlayer) then
        return
    end
    oOrgMgr:OrgOnlineCount(oPlayer)
end

function ForwardNetcmds.C2GSOrgSendMail(oPlayer,mData)
    local content = mData.content
    if type(content) ~= "string" then return end
    if clientstrlen(content) > 50 then return end

    local iPid = oPlayer:GetPid()
    local oOrg = oPlayer:GetOrg()
    if oOrg then
        local iLimitCnt = res["daobiao"]["org"]["rule"][1]["mail_cnt"]
        if oOrg:QueryToday("mail_cnt",0) >= iLimitCnt then
            oPlayer:Notify("每天仅可发放"..iLimitCnt.."次通知，请于明天再来发放")
            return
        end
        if not oOrg:HasMailAuth(iPid) then
            oPlayer:Notify(oOrgMgr:GetOrgText(1004))
            return
        end
        local oMem = oOrg:GetMember(iPid)
        if not oMem then return end
        if oMem:InLock("orgmail") then
            return
        end
        oMem:Lock("orgmail",3)
        oOrg:AddToday("mail_cnt",1)
        oOrg:UpdateOrgInfo({mail_rest=true})
        local sSubject = "无"
        local sName = oPlayer:GetName()
        if oOrg:IsLeader(iPid) then
            sSubject = "来自会长#B"..sName.."#n的通知"
        elseif oOrg:IsSecond(iPid) then
            sSubject = "来自副会长#B"..sName.."#n的通知"
        end
        local mMem = oOrg:GetOrgMemList()
        interactive.Send(".world", "org", "OrgSendMail",{
            pid = iPid,
            name = sName,
            list = mMem,
            subject = sSubject,
            content = content
        })
        oPlayer:Send("GS2CMailResult",{result=1})
    end
end

function ForwardNetcmds.C2GSOrgQQAction(oPlayer,mData)
    local iAction = mData["action"]
    local oOrgMgr = global.oOrgMgr
    local mNet = {
        pid = oPlayer:GetPid(),
        action = iAction,
    }
    local iOrgID = oPlayer:GetOrgID()
    local sMessage = "GS2COrgQQAction"
    oOrgMgr:SendOrgMessage(iOrgID,sMessage,mNet)
end

function ForwardNetcmds.C2GSOrgRename(oPlayer,mData)
    local oOrg = oPlayer:GetOrg()
    if not oOrg then
        return
    end
    local iPid = oPlayer:GetPid()
    if not oOrg:IsLeader(iPid) then
        oPlayer:Notify("只有会长可以改名")
        return
    end
    local oOrgMgr = global.oOrgMgr
    local iOrgID = oOrg:OrgID()
    local sName = mData.name or ""
    oOrgMgr:ForceRenameOrg(iOrgID,sName)
end