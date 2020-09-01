-- import file

local md5 = require "md5"
local serverdefines = require "public.serverdefines"

local serverinfo = import(lualib_path("public.serverinfo"))

function NewDemiSdk(...)
    return CDemiSdk:New(...)
end

function NewPayId(...)
    return CPayId:New(...)
end

CDemiSdk = {}
CDemiSdk.__index = CDemiSdk

function CDemiSdk:New(bPay, iSeqBase)
    local o = setmetatable({}, self)
    o.m_iLastTimeStamp = nil
    if bPay then
        o.m_oPayId = NewPayId(iSeqBase)
    end
    return o
end

function CDemiSdk:GetAppId()
    return serverinfo.DEMI_SDK.app_id
end

function CDemiSdk:GetAppKey()
    return serverinfo.DEMI_SDK.app_key
end

function CDemiSdk:GetMachineId()
    return serverinfo.DEMI_SDK.machine_id
end

function CDemiSdk:Sign(mParam)
    local lKey = table_key_list(mParam)
    table.sort(lKey)
    local s = ""
    for _, sKey in ipairs(lKey) do
        s = s..sKey.."="..mParam[sKey].."&"
    end
    s = s.."key="..self:GetAppKey()
    return md5.sumhexa(s)
end

function CDemiSdk:GeneratePayid()
    return self.m_oPayId:GeneratePayid(self:GetAppId(), self:GetMachineId())
end


CPayId = {}
CPayId.__index = CPayId

CPayId.c_iUsingEpoch = 1503644905000
CPayId.c_iAppidBits = 14
CPayId.c_iMachineidBits = 3
CPayId.c_iSequenceBits = 7
CPayId.c_iTimestampShift = CPayId.c_iAppidBits + CPayId.c_iMachineidBits + CPayId.c_iSequenceBits
CPayId.c_iAppidShift = CPayId.c_iMachineidBits + CPayId.c_iSequenceBits
CPayId.c_iMachineidShift = CPayId.c_iSequenceBits

function CPayId:New(iSeqBase)
    local o = setmetatable({}, self)
    o.m_iSeqBase = iSeqBase
    o.m_iLastTimeStamp = nil
    return o
end

function CPayId:GetMaxSequence()
    return (1<<self.c_iSequenceBits) -1
end

function CPayId:GetCurrentTimeStamp()
    return math.floor(get_time(true) * 1000)
end

function CPayId:GetSequence()
    local iTime = self:GetCurrentTimeStamp()
    if self.m_iLastTimeStamp and iTime == self.m_iLastTimeStamp then
        self.m_iSequence = self.m_iSequence + PAY_SERVICE_COUNT
        assert(self.m_iSequence <= self:GetMaxSequence(), string.format("pay sequence bigger than %s", self:GetMaxSequence()))
    else
        self.m_iSequence = self.m_iSeqBase
        self.m_iLastTimeStamp = iTime
    end
    return self.m_iSequence
end

function CPayId:GeneratePayid(iAppId, iMachineId)
    local iTimeStamp = self:GetCurrentTimeStamp() - self.c_iUsingEpoch
    local iSequence = self:GetSequence()
    return (iTimeStamp << self.c_iTimestampShift) | iAppId << self.c_iAppidShift | (iMachineId << self.c_iMachineidShift) | iSequence
end
