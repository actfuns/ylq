local global  = require "global"

local huodongbase = import(service_path("huodong.huodongbase"))
local loadpartner = import(service_path("partner.loadpartner"))

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "huodong"
CHuodong.m_sTempName = "kuafuHD"
inherit(CHuodong, huodongbase.CHuodong)


--屏蔽部分功能
function CHuodong:AddSchedule(oPlayer)
end

function CHuodong:SetHuodongState(iState)
end


function CHuodong:DoScript(pid,npcobj,s,mArgs)
end

function CHuodong:CreateVirtualScene(iIdx)
end

function CHuodong:TransferPlayer(iPid, iScene, iX, iY)
end


function CHuodong:GobackRealScene(pid)
end


function CHuodong:RemoveSceneById(id)
end

function CHuodong:Reward(iPid, sIdx, mArgs)
end
--


function CHuodong:KFJoinGame(oKFPlayer)
    return {}
end

function CHuodong:KFCmd(oKFPlayer,mData)
end

function CHuodong:TestKFOP(oPlayer,iCmd,...)
end

function CHuodong:GetServerGrade(oWar)
    local oKFMgr = global.oKFMgr
    local iPid = oWar:GetData("CreatePid",0)
    local oPlayer = oKFMgr:GetObject(iTarget1)
    if oPlayer then
        return oPlayer:GetServerGrade()
    end
    return 0
end

function CHuodong:WarFightEnd(oWar,iPid,oNpc,mArgs)
    local oKFMgr = global.oKFMgr
    local win_side = mArgs.win_side
    if oWar.m_RewardDie then
        mArgs.m_RewardDie = true
    end

    if oNpc then
        local oSceneMgr = global.oSceneMgr
        oNpc:ClearNowWar()
        oSceneMgr:NpcLeaveWar(oNpc)
    end

    local mWin = mArgs.win_list or {}
    local mFail = mArgs.fail_list or {}
    local mPlayer=  {}
    list_combine(mPlayer,mWin)
    list_combine(mPlayer,mFail)
    for _,iPid in pairs(mPlayer) do
        local oPlayer = oKFMgr:GetObject(iPid)
        if oPlayer then
            self:AddKeep(iPid,"old_grade",oPlayer:GetGrade())
        end
    end

    if win_side == 1 then
        self:OnWarWin(oWar, iPid, oNpc, mArgs)
    else
        self:OnWarFail(oWar, iPid, oNpc, mArgs)
    end
    self:OnWarEnd(oWar, iPid, oNpc, mArgs,win_side == 1)

    for _,iPid in pairs(mPlayer) do
        self:ClearKeep(iPid)
    end
end

function CHuodong:GetFightPartner(iPid, mWarArgs)
    mWarArgs = mWarArgs or {}
    return mWarArgs.fight_partner[iPid] or {}
end

function CHuodong:CheckPVPCondition(mWarArgs)
    local lWinPlayer = mWarArgs.win_list or {}
    local mWinParName = {}
    for _, iPid in ipairs(lWinPlayer) do
        local mPartner = self:GetFightPartner(iPid, mWarArgs)
        for iParId,mInfo in pairs(mPartner) do
            local m = loadpartner.GetPartnerData(tonumber(mInfo.type))
            mWinParName[m.name] = true
        end
    end
    local lFailPlayer = mWarArgs.fail_list or {}
    local mFailParName = {}
    for _, iPid in ipairs(lFailPlayer) do
        local mPartner = self:GetFightPartner(iPid, mWarArgs)
        for iParId,mInfo in pairs(mPartner) do
            local m = loadpartner.GetPartnerData(tonumber(mInfo.type))
            mFailParName[m.name] = true
        end
    end

    for _, iPid in ipairs(lWinPlayer) do
        if mWinParName["朵屠"] and mFailParName["重华"] then
            self:PushCondition(iPid, "竞技场朵屠战胜重华", {value = 1})
        end
        if mWinParName["执阳"] and mFailParName["青竹"] then
            self:PushCondition(iPid, "竞技场执阳战胜青竹", {value = 1})
        end
        if mWinParName["白殊"] and mFailParName["奉主夜鹤"] then
            self:PushCondition(iPid, "竞技场白殊战胜奉主夜鹤", {value = 1})
        end
        if mWinParName["稻荷"] and mFailParName["莲"] then
            self:PushCondition(iPid, "竞技场稻荷战胜莲", {value = 1})
        end
        if mWinParName["蛇姬"] and mFailParName["犬妖"] then
            self:PushCondition(iPid, "竞技场蛇姬战胜犬妖", {value = 1})
        end
        if mWinParName["青竹"] and mFailParName["执夷"] then
            self:PushCondition(iPid, "竞技场青竹战胜执夷", {value = 1})
        end
        if mWinParName["琥非"] and mFailParName["古娄"] then
            self:PushCondition(iPid, "竞技场琥非战胜古娄", {value = 1})
        end
        if mWinParName["琥非"] and mFailParName["古娄"] then
            self:PushCondition(iPid, "竞技场琥非战胜古娄", {value = 1})
        end
        if mWinParName["黑"] and mFailParName["白殊"] then
            self:PushCondition(iPid, "竞技场黑战胜白殊", {value = 1})
        end
        if mWinParName["黑"] and mFailParName["白"] then
            self:PushCondition(iPid, "竞技场黑战胜白", {value = 1})
        end
        if mWinParName["阿坊"] and mWinParName["马面面"] then
            self:PushCondition(iPid, "竞技场阿坊马面面获胜", {value = 1})
        end
        if mWinParName["伊露"] and mWinParName["白"] then
            self:PushCondition(iPid, "竞技场伊露白获胜", {value = 1})
        end
    end
end

function CHuodong:PushCondition(iPid, sKey, mData)
    local oPlayer = global.oKFMgr:GetObject(iPid)
    if oPlayer then
        oPlayer:SendEvent("HBPushCondition",{
            key = sKey,
            info = mData,
        })
    end
end