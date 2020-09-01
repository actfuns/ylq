--import module
local global = require "global"
local extend = require "base.extend"

function NewVoteBox(...)
    return CVoteBox:New(...)
end

CVoteBox = {}
CVoteBox.__index = CVoteBox
inherit(CVoteBox,logic_base_cls())

function CVoteBox:New(sTopic, oPlayer, oTeam, func, bLeave, iPassCnt, bLeaveAsRefuse)
    local o = super(CVoteBox).New(self)
    oTeam.m_oVoteBox = o
    o.m_iPID = oPlayer:GetPid()
    o.m_iTeamID = oTeam.m_ID
    o.m_sTopic = sTopic
    bLeave = bLeave or false
    o.m_bLeave = bLeave
    if bLeave then
        o.m_lMember = extend.Table.keys(oTeam:OnlineMember())
    else
        o.m_lMember = oTeam:GetTeamMember()
    end
    extend.Array.remove(o.m_lMember, oPlayer:GetPid())
    o.m_mVoteResult = {}
    o.m_iPassCnt = iPassCnt or -1      -- -1.全票通过，2.通过人数
    o.m_bLeaveAsRefuse = bLeaveAsRefuse or true
    o.m_bEnd = false
    o.HandleEnd = func
    return o
end

function CVoteBox:GetPlayer()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iPID)
    return oPlayer
end

function CVoteBox:GetTeam()
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(self.m_iTeamID)
    return oTeam
end

function CVoteBox:ConfirmData()
    if self.CustomConfirmData then
        return self.CustomConfirmData(self.m_sTopic)
    else
        return {
            sContent = self.m_sTopic,
        }
    end
end

function CVoteBox:Answer2Agree(iAnswer)
    if self.CustomAnswer then
        return self.CustomAnswer(iAnswer)
    else
        if iAnswer == 1 then
            return 1
        else
            return 0
        end
    end
end

function CVoteBox:Start()
    local oCbMgr = global.oCbMgr
    for _, pid in ipairs(self.m_lMember) do
        local mData = oCbMgr:PackConfirmData(pid, self:ConfirmData())
        local oTeamMgr = global.oTeamMgr
        local iTeamID = self.m_iTeamID
        local func = function (oPlayer,mData)
            local oTeam = oTeamMgr:GetTeam(iTeamID)
            local iAgree = oTeam:Answer2Agree(mData["answer"])
            oTeam:Vote(oPlayer:GetPid(), iAgree)
        end
        oCbMgr:SetCallBack(pid,"GS2CConfirmUI",mData,nil,func)
    end
end

function CVoteBox:OnLeaveTeam(pid, iFlag)
    if self.m_bEnd then
        return
    end
    if self.m_bLeave and iFlag == 2 then
        return
    end
    if self.m_bLeaveAsRefuse then
        self:Refuse(pid)
    else
        extend.Array.remove(self.m_lMember, pid)
        self:CheckEnd()
    end
end

function CVoteBox:Vote(pid, iAgree)
    if self.m_bEnd then
        return
    end
    if self.m_mVoteResult[pid] then
        return
    end
    if iAgree == 1 then
        self:Agree(pid)
    else
        self:Refuse(pid)
    end
end

function CVoteBox:Agree(pid)
    self.m_mVoteResult[pid] = 1
    if self.HandleAgree then
        self.HandleAgree(self, pid)
    end
    self:CheckEnd()
end

function CVoteBox:Refuse(pid)
    self.m_mVoteResult[pid] = 0
    if self.HandleRefuse then
        self.HandleRefuse(self, pid)
    end
    if self.m_iPassCnt == -1 then
        self:End(false)
        return
    end
    self:CheckEnd()
end

function CVoteBox:CheckEnd()
    if self.m_bEnd then
        return
    end
    if self.m_iPassCnt == -1 then
        for _, pid in ipairs(self.m_lMember) do
            if self.m_mVoteResult[pid] == 0 then
                self:End(false)
            elseif not self.m_mVoteResult[pid] then
                return
            end
        end
        self:End(true)
    else
        local cnt = 0
        local iAll = 0
        for pid, iAgree in pairs(self.m_mVoteResult) do
            iAll = iAll + 1
            if iAgree == 1 then
                cnt = cnt + 1
                if cnt >= self.m_iPassCnt then
                    self:End(true)
                end
            end
        end
        if iAll >= #self.m_lMember then
            self:End(false)
        end
    end
end

function CVoteBox:End(bResult)
    if self.m_bEnd then
        return
    end
    self.m_bEnd = true
    local oTeam = self:GetTeam()
    if oTeam then
        oTeam.m_oVoteBox = self
    end
    local oPlayer = self:GetPlayer()
    self.HandleEnd(self, oPlayer, oTeam, bResult)
end

function CVoteBox:CloseComfirmUI()
    local oUIMgr = global.oUIMgr
    local oWorldMgr = global.oWorldMgr
    for _, pid in ipairs (self.m_lMember) do
        if not self.m_mVoteResult[pid] then
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid) 
            oUIMgr:GS2CCloseConfirmUI(oPlayer)
        end
    end
end