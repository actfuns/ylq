local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))

local function SendPlayerInfo(iPid,iStyle, oProfile)
    if not oProfile then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oTeamMgr = global.oTeamMgr
    local oOrgMgr = global.oOrgMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oTeam = oTeamMgr:HasTeam(oProfile:GetPid())
    local mNet = {}
    mNet["style"] = iStyle
    mNet["pid"] = oProfile:GetPid()
    mNet["grade"] = oProfile:GetGrade()
    mNet["name"] = oProfile:GetName()
    mNet["school"] = oProfile:GetSchool()
    mNet["model_info"] = oProfile:GetModelInfo()
    mNet["show_id"] = oProfile:GetShowId()
    if oTeam then
        mNet["team_id"] = oTeam.m_ID
        mNet["team_size"] = oTeam:TeamSize()
    end
    interactive.Request(".org","common","GetPlayerOrgInfo",{pid = iPid},function(mRecord,mData)
        local mInfo = mData.info or {}
        if mInfo then
            mNet["org_id"] = mInfo.orgid or 0
            mNet["org_name"] = mInfo.orgname or ""
            mNet["org_level"] = mInfo.orglevel or 0
            mNet["org_pos"] = mInfo.orgpos or 0
        end
        oPlayer:Send("GS2CGetPlayerInfo", mNet)
    end)
end

function C2GSGetPlayerInfo(oPlayer, mData)
    if not oPlayer then
        return
    end
    local iPid = oPlayer:GetPid()
    local target_pid = mData["pid"]
    local iStyle = mData["style"]
    local oWorldMgr = global.oWorldMgr
    local oOrgMgr = global.oOrgMgr
    local oAnotherPlayer = oWorldMgr:GetOnlinePlayerByPid(target_pid)
    local mNet = {}
    if oAnotherPlayer then
        mNet["pid"] = target_pid
        mNet["style"] = iStyle
        mNet["grade"] = oAnotherPlayer:GetGrade()
        mNet["name"] = oAnotherPlayer:GetName()
        mNet["school"] = oAnotherPlayer:GetSchool()
        mNet["model_info"] = oAnotherPlayer:GetModelInfo()
        mNet["team_id"] = oAnotherPlayer:TeamID()
        mNet["team_size"] = oAnotherPlayer:GetTeamSize()
        mNet["school_branch"] = oAnotherPlayer:GetSchoolBranch()
        mNet["org_id"] = oAnotherPlayer:GetOrgID()
        mNet["org_name"] = oAnotherPlayer:GetOrgName()
        mNet["org_level"] = oAnotherPlayer:GetOrgLevel()
        mNet["org_pos"] = oAnotherPlayer:GetOrgPos()
        mNet["show_id"] = oAnotherPlayer:GetShowId()
        if oAnotherPlayer.m_oActiveCtrl:GetNowWar() then
            mNet["in_war"] = 1
        end
        oPlayer:Send("GS2CGetPlayerInfo", mNet)
    else
        local fCallback = function (oProfile)
            SendPlayerInfo(iPid, iStyle,oProfile)
        end
        oWorldMgr:LoadProfile(target_pid,fCallback)
    end
end

function C2GSChangeSchool(oPlayer,mData)
    local iSchoolBranch = mData["school_branch"]
    if not oPlayer:ValidSwitchSchool(iSchoolBranch) then
        return
    end
    oPlayer:SwitchSchool(iSchoolBranch)
end

function C2GSUpvotePlayer(oPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local mGradeConfig = res["daobiao"]["upgrade"]
    local iLimit = mGradeConfig[oPlayer:GetGrade()]["upvote_limit"]
    local iTarget = mData.pid
    local iPid = oPlayer:GetPid()
    if oPlayer.m_oToday:Query("UpvoteCnt",0) >= iLimit then
        oNotifyMgr:Notify(iPid,"今天点赞已达上限")
        return
    end

    oWorldMgr:LoadProfile(iTarget, function (obj)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if obj  and oPlayer then
            obj:AddUpvote(oPlayer)
        end
    end)
end

function C2GSRename(oPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if oWorldMgr:IsClose("rename") then
        oNotifyMgr:Notify(oPlayer:GetPid(), "该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local oRenameMgr = global.oRenameMgr
    oRenameMgr:DoRename(oPlayer, mData.rename)
end

function C2GSPlayerPK(oPlayer,mData)
    local oPubMgr = global.oPubMgr
    oPubMgr:InvitePlayerPK(oPlayer,table_deep_copy(mData))
end

function C2GSWatchWar(oPlayer,mData)
    local iTarget = mData["target_id"]
    local oPubMgr = global.oPubMgr
    oPubMgr:WatchWar(oPlayer,iTarget)
end

function C2GSLeaveWatchWar(oPlayer,mData)
    local oPubMgr = global.oPubMgr
    oPubMgr:LeaveWatchWar(oPlayer)
end


function C2GSPlayerTop4Partner(oPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    local iTargetPid = mData.target_pid
    local iPid = oPlayer:GetPid()
    local fCallback = function (oProfile)
        DoTop4Partner(iPid, oProfile)
    end
    oWorldMgr:LoadProfile(iTargetPid, fCallback)
end

function DoTop4Partner(iPid, oProfile)
    local oWorldMgr = global.oWorldMgr
    local iTargetPid = oProfile:GetPid()
    local fCallback = function(oOfflinePartner)
        DoTop4PartnerFinish(iPid, iTargetPid, oOfflinePartner)
    end
    oWorldMgr:LoadPartner(iTargetPid, fCallback)
end

function DoTop4PartnerFinish(iPid, iTargetPid, oOfflinePartner)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oProfile = oWorldMgr:GetProfile(iTargetPid)
    if oPlayer and oProfile then
        local mNet = oOfflinePartner:PackTop4SimpleInfo()
        table.insert(mNet, {
            ttype = 0,
            name = oProfile:GetName(),
            othername = oProfile:GetSchoolBranchName(),
            power = oProfile:GetPower(),
            grade = oProfile:GetGrade(),
            model_info = oProfile:GetModelInfo(),
            })
        oPlayer:Send("GS2CPlayerTop4Partner", {info_list = mNet})
    end
end

function C2GSInitRoleName(oPlayer,mData)
    if oPlayer.m_oActiveCtrl:GetData("initrolename",0) == 1 then
        return
    end
    local oRenameMgr = global.oRenameMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local sName = mData.name
    local sNewName = trim(sName)
    if not sNewName or sNewName == "" then
        oNotifyMgr:Notify(iPid, "请输入名字")
        return
    end
    oRenameMgr:InitRoleName(oPlayer, sNewName)
end

function C2GSGamePushSetting(oPlayer,mData)
    local sType = mData["type"]
    local iValue = mData["value"]
    if not table_in_list({"partner_travel","trapmine","energy"},sType) then
        return
    end
    oPlayer.m_oActiveCtrl:SetGamePush(sType,iValue)
end

function C2GSGameShare(oPlayer,mData)
    local res = require "base.res"
    local sType = mData["type"]
    local mShareData = res["daobiao"]["gameshare"]
    if not oPlayer:ValidGameShare(sType) then
        return
    end
    oPlayer:SetGameShare(sType)
    local iFirstGameShare = oPlayer.m_oToday:Query("first_game_share",0)
    if iFirstGameShare == 0 then
        oPlayer.m_oToday:Set("first_game_share",1)
        local sReason = string.format("游戏分享%s",sType)
        local iGoldCoin = mShareData[sType]["goldcoin"]
        oPlayer:RewardGoldCoin(iGoldCoin,sReason)
    end
end


function C2GSChangeShape(oPlayer, mData)
    oPlayer:ChangeShape(mData["shape"])
end