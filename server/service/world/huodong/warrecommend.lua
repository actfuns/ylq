-- import module
local res = require "base.res"
local global = require "global"

local huodongbase = import(service_path("huodong.huodongbase"))
local net = require "base.net"
local colorstring = require "public.colorstring"

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

----当玩家与另外一名玩家连续组队并进行3场战斗，则战斗结束后，则弹出一个好友推荐添加的弹窗,文档在组队文档里面
CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "warrecommend"
CHuodong.m_sTempName = "战斗好友推荐"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_mWarRecord = {}
    self.m_mTrueRecommend = {}
end

function CHuodong:OnLogin(oPlayer,bReEnter)
    if not bReEnter then
        self.m_mWarRecord[oPlayer.m_iPid] = nil
        self.m_mTrueRecommend[oPlayer.m_iPid] = nil
    end
end

function CHuodong:WarFightEnd(oWar,iPid,oNpc,mArgs)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local lPlayers = self:GetFightList(oPlayer,mArgs)
    local mRecommend = {}
    for _,pid in ipairs(lPlayers) do
        local oMem = global.oWorldMgr:GetOnlinePlayerByPid(pid)
        if oMem then
            table.insert(mRecommend,{id = pid,grade = oMem:GetGrade()})
        end
    end
    local fSort = function(a,b)
        return a["grade"] > b["grade"]
    end
    table.sort(mRecommend,fSort)
    local mRecord = {}
    for i= 1,#mRecommend - 1 do
        local iPlayer1 = mRecommend[i]["id"]
        for j = i + 1,#mRecommend do
            local iPlayer2 = mRecommend[j]["id"]
            if not mRecord[iPlayer1] and self:ValidRecommend(iPlayer1,iPlayer2) then
                mRecord[iPlayer1] = true
                self:Record(iPlayer1,iPlayer2)
            end
            if not mRecord[iPlayer2] and self:ValidRecommend(iPlayer2,iPlayer1) then
                mRecord[iPlayer2] = true
                self:Record(iPlayer2,iPlayer1)
            end
        end
    end
end

function CHuodong:ValidRecommend(iPlayer1,iPlayer2)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPlayer1)
    if not oPlayer or (self.m_mTrueRecommend[iPlayer1] and self.m_mTrueRecommend[iPlayer1][iPlayer2])then
        return false
    end
    local oFriend = oPlayer:GetFriend()
    if oFriend:HasFriend(iPlayer2) or oFriend:IsShield(iPlayer2) or oFriend:FriendsMaxCnt(oPlayer:GetGrade()) <= oFriend:FriendCount() then
        return false
    end
    return true
end

function CHuodong:Record(iPlayer1,iPlayer2)
    if not self.m_mWarRecord[iPlayer1] then
        self.m_mWarRecord[iPlayer1] = {[1]=iPlayer2}
    else
        local iSize = #self.m_mWarRecord[iPlayer1]
        if self.m_mWarRecord[iPlayer1][iSize] ~= iPlayer2 then
            self.m_mWarRecord[iPlayer1] = {[1]=iPlayer2}
            return
        end
        if iSize == 2 then
            self:Recommend(iPlayer1,iPlayer2)
            return
        end
        self.m_mWarRecord[iPlayer1][iSize+1] = iPlayer2
    end
end


--iPlayer2推荐给iPlayer1
function CHuodong:Recommend(iPlayer1,iPlayer2)
    self.m_mWarRecord[iPlayer1] = nil
    self.m_mTrueRecommend[iPlayer1] = self.m_mTrueRecommend[iPlayer1] or {}
    self.m_mTrueRecommend[iPlayer1][iPlayer2] = true
    local oTarget = global.oWorldMgr:GetOnlinePlayerByPid(iPlayer2)
    if not oTarget then
        return
    end
    local sContent = colorstring.FormatColorString("你与#role已经连续有多场配合，是否添加对方为好友今后一起战斗？", {role = oTarget:GetName()})
    local mNet = {
        sContent = sContent,
        sConfirm = "添加好友",
        sCancle = "忽略",
        default = 0,
        time = 30,
    }
    local oCbMgr = global.oCbMgr
    mNet = oCbMgr:PackConfirmData(nil, mNet)
    local func = function(oPlayer,mData)
        if mData.answer and mData.answer == 1 then
            local oFriendMgr = global.oFriendMgr
            oFriendMgr:AddApply(oPlayer, iPlayer2)
        end
    end
    oCbMgr:SetCallBack(iPlayer1,"GS2CConfirmUI",mNet,nil,func)
end