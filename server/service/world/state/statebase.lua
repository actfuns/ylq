local global = require "global"

local datactrl = import(lualib_path("public.datactrl"))

CState = {}
CState.__index = CState
inherit(CState,datactrl.CDataCtrl)

function CState:New(iState)
    local o = super(CState).New(self,iState)
    o.m_iID = iState
    return o
end

function CState:MapFlag()
    local res = require "base.res"
    return res["daobiao"]["state"][self.m_iID]["flag"]
end

function CState:IsTempState()
    return false
end

function CState:GetDaoBiaoData()
    local res = require "base.res"
    local mData = res["daobiao"]["state"][self.m_iID]
    return mData
end

function CState:SetOwner(iPid)
    self.m_iOwner = iPid
end

function CState:GetOwner()
    return self.m_iOwner
end

function CState:QueryTable(sKey)
    return self:GetDaoBiaoData()[sKey]
end


function CState:Load(mData)
    mData = mData or {}
    self.m_mData = mData.data or {}
    self:SetData("time",mData["time"])
    if self:GetData("time") then
        local iPid = self:GetOwner()
        local oWorldMgr = global.oWorldMgr
        local iState = self.m_iID
        local fCallback = function ()
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                local oState = oPlayer.m_oStateCtrl:GetState(iState)
                if oState then
                    oState:TimeOut(iPid)
                end
            end
        end
        local iTime = self:GetData("time") - get_time()
        if iTime > 0 then
            self:AddTimeCb("timeout",iTime * 1000,fCallback)
        end
    end
end

function CState:Save()
    local mData = {}
    mData["time"] = self:GetData("time")
    mData["data"] = self.m_mData
    return mData
end

function CState:Config(oPlayer,mArgs)
    mArgs = mArgs or {}
    local iTime = mArgs["time"]
    if iTime then
        local iPid = oPlayer:GetPid()
        local iState = self.m_iID
        local iEndTime = iTime + get_time()
        self:SetData("time",iEndTime)
        local oWorldMgr = global.oWorldMgr
        local func = function ()
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                local oState = oPlayer.m_oStateCtrl:GetState(iState)
                if oState then
                    oState:TimeOut(iPid)
                end
            end
        end
        if iTime > 0 then
            self:AddTimeCb("timeout",iTime * 1000,func)
        end
    end
end

function CState:TimeOut(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    assert(oPlayer,string.format("state timeout err:%d %d",iPid,self.m_iID))
    oPlayer.m_oStateCtrl:RemoveState(self.m_iID)
end

function CState:ID()
    return self.m_iID
end

function CState:IsOutTime()
    local iEndTime = self:GetData("time")
    if not iEndTime or iEndTime == 0 then
        return false
    end
    if get_time() < iEndTime then
        return false
    end
    return true
end

function CState:Time()
    return self:GetData("time")
end

function CState:Name()
    return self:QueryTable("name")
end

function CState:Desc()
    return self:QueryTable("desc")
end

function CState:Click(oPlayer,mData)
end

function CState:PackNetInfo()
    return {
        state_id = self.m_iID,
        time = self:GetData("time",0),
        name = self:Name(),
        desc = self:Desc(),
    }
end

function CState:Refresh(pid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CRefreshState",{state_info=self:PackNetInfo()})
end

function NewState(iState)
    local o = CState:New(iState)
    return o
end
