local global = require "global"
local record = require "public.record"

function NewClientMgr()
    return CClientMgr:New()
end

CClientMgr = {}
CClientMgr.__index = CClientMgr
inherit(CClientMgr, logic_base_cls())

function CClientMgr:New()
    local o = super(CClientMgr).New(self)
    o.m_List = {}
    return o
end

function CClientMgr:AddClient(oClient)
    table.insert(self.m_List,oClient)
end

function CClientMgr:SelectClient(sServerKey)
    local sType = string.match(sServerKey,"(%a+)%d*")
    local iNo
    if sType == "gs" then
        local num = #self.m_List
        local id = string.match(sServerKey,"%a+(%d+)")
        id = tonumber(id)
        iNo = math.floor(id%num+1)
    elseif sType == "bs" then
        iNo = 1
    elseif sType == "cs" then
        iNo = 2
    elseif sType == "ks" then
        iNo = 3
    else
        record.warning("no server type "..sServerKey)
        return
    end
    return self.m_List[iNo]
end

function CClientMgr:SendP2P(mRecord,mData)
    local sServerKey = mRecord.dessk
    local oClient = self:SelectClient(sServerKey)
    if oClient then
        oClient:SendP2P(mRecord,mData)
    end
end
