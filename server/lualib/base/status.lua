--import module

function NewStatus(...)
    local o = CStatus:New(...)
    return o
end

CStatus = {}
CStatus.__index = CStatus

function CStatus:New()
    local o = setmetatable({}, self)
    o.m_iStatus = nil
    o.m_iStatusTime = nil
    o.m_mExtra = {}
    return o
end

function CStatus:Release()
    release(self)
end

function CStatus:Set(iStatus, iTime)
    if not iTime then
        iTime = get_msecond()
    end
    self.m_iStatus = iStatus
    self.m_iStatusTime = iTime
end

function CStatus:Get()
    return self.m_iStatus, self.m_iStatusTime
end

function CStatus:GetExtra(sKey)
    return self.m_mExtra[sKey]
end

function CStatus:SetExtra(sKey, rValue)
    self.m_mExtra[sKey] = rValue
end
