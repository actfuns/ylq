--import module
local global = require "global"
local skynet = require "skynet"
local bson = require "bson"

local interactive = require "base.interactive"

function GetClubFightInfo(mRecord,mData)
    local oHuodong = global.oAssistDHMgr:GetHuodong("clubarena")
    local mResult = oHuodong:GetClubFightInfo(mData)
    interactive.Response(mRecord.source, mRecord.session, { success = true , data = mResult ,})
end

function LockWar(mRecord,mData)
    local oHuodong = global.oAssistDHMgr:GetHuodong("clubarena")
    local mResult = oHuodong:LockWar(mData)
    interactive.Response(mRecord.source, mRecord.session, { success = true , data = mResult ,})
end

function UnLockWar(mRecord,mData)
    local oHuodong = global.oAssistDHMgr:GetHuodong("clubarena")
    oHuodong:UnLockWar(mData)
end

function OnWarEnd(mRecord,mData)
    local oHuodong = global.oAssistDHMgr:GetHuodong("clubarena")
    local r,mResult = safe_call(oHuodong.OnWarEnd,oHuodong,mData)
    mResult = mResult or {}
    interactive.Response(mRecord.source, mRecord.session, { success = true , data = mResult ,})
end

function CreateNewMember(mRecord,mData)
    local oHuodong = global.oAssistDHMgr:GetHuodong("clubarena")
    oHuodong:CreateNewMember(mData["pid"],mData["data"])
end

function OpenMainUI(mRecord,mData)
    local oHuodong = global.oAssistDHMgr:GetHuodong("clubarena")
    local mResult = oHuodong:OpenMainUI(mData["pid"])
    interactive.Response(mRecord.source, mRecord.session, { success = true , data = mResult ,})
end

function GetRewardDay(mRecord,mData)
    local oHuodong = global.oAssistDHMgr:GetHuodong("clubarena")
    local mResult = oHuodong:RewardDay()
    interactive.Response(mRecord.source, mRecord.session, { success = true , data = mResult ,})
end

function UpdateInfo(mRecord,mData)
    local oHuodong = global.oAssistDHMgr:GetHuodong("clubarena")
    oHuodong:UpdateInfo(mData)
end



function TestOP(mRecord,mData)
    local iFlag = mData["flag"]
    local args = mData["args"]
    local mArg = mData["data"]
    local oHuodong = global.oAssistDHMgr:GetHuodong("clubarena")
    if iFlag == 901 then
        print("============Clubarena Message==============")
        print("NewbieQueue:",#oHuodong.m_NewbieQueue)
        print("Member :",table_count(oHuodong.m_Member))
        for iClub,oClub in pairs(oHuodong.m_ClubList) do
            local mMaster = oClub.m_Master
            print(string.format("club:%s -- robot:%s  :  master:%s ",iClub,table_count(oClub.m_RobotList),ConvertTblToStr(mMaster)))
            local mRobotList = {}
            for iPost,m in pairs(oClub.m_Member) do
                if not m["robot"] then
                    print(string.format("   [%s]:%s",iPost,ConvertTblToStr(m)))
                else
                    mRobotList[m["robot"]] = (mRobotList[m["robot"]] or 0) + 1
                end
            end
            for iRobot,iNo in pairs(mRobotList) do
                print(string.format("   <robot>[%s]:%s",iRobot,iNo))
            end
        end
        print("************ Clubarena Exit *****************")
    elseif iFlag == 100002 then
        local iPid = mArg["pid"]
        if oHuodong:GetMember(iPid) then
            return
        end
        for iClub,oClub in pairs(oHuodong.m_ClubList) do
            local iPost
            if oClub.m_Master["robot"] then
                iPost = 0
            elseif #oClub.m_RobotList > 0 then
                iPost = oClub.m_RobotList[1]
            end
            if iPost then
                oHuodong:CreateNewMember(iPid,mArg["data"])
                oClub:PopMember(iPost)
                oClub:AddMember(iPost,{pid=iPid})
                oHuodong:DeleteNewbie(iPid)
                break
            end
        end
        if not oHuodong:GetMember(iPid) then
            oHuodong:CreateNewMember(iPid,mArg["data"])
        else
            print("GetNOD:",oHuodong:GetMember(iPid))
        end
    elseif iFlag == 100003 then
        for pid,_ in pairs(oHuodong.m_Member) do
            oHuodong:DeleteMember(pid)
        end
        oHuodong.m_Member = {}
        oHuodong.m_Init = 0
        oHuodong.m_NewbieQueue = {}
        oHuodong.m_TmpWar = {}
        oHuodong.m_ClubList = {}
        oHuodong:DelTimeCb("CheckAutoReward")
        oHuodong:LoadFinish()
    end
end

