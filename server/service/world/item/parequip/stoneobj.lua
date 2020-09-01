local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local datactrl = import(lualib_path("public.datactrl"))
local loaditem = import(service_path("item.loaditem"))
local itemdefines = import(service_path("item.itemdefines"))

function NewStone(...)
    local o = CParStone:New(...)
    return o
end

CParStone = {}
CParStone.__index = CParStone
inherit(CParStone,datactrl.CDataCtrl)

function CParStone:New(iPos)
    local o = super(CParStone).New(self)
    o.m_iPos = iPos
    o.m_Stone = {}
    o.m_mApply = {}
    return o
end

function CParStone:Setup()
    for _, iShape in ipairs(self.m_Stone) do
        local oStone = loaditem.GetItem(iShape)
        local mAttr = oStone:GetApplys()
        if mAttr then
            for sAttr, iVal in pairs(mAttr) do
                self:AddApply(sAttr, iVal)
            end
        end
    end
end

function CParStone:Load(mData)
    self.m_Stone = mData["stone"] or self.m_Stone
end

function CParStone:Save()
    local mData = {}
    mData['stone'] = self.m_Stone
    return mData
end

function CParStone:Pos()
    return self.m_iPos
end

function CParStone:AddStone(iShape)
    self:Dirty()
    local oStone = loaditem.GetItem(iShape)
    local mAttr = oStone:GetApplys()
    if mAttr then
        for sAttr, iVal in pairs(mAttr) do
            self:AddApply(sAttr, iVal)
        end
    end
    table.insert(self.m_Stone, iShape)
    return true
end

function CParStone:Count()
    return #self.m_Stone
end

function CParStone:Level()
    local iLevel = 1
    local mData = itemdefines.GetParStonePosData(self:Pos())
    if mData then
        if #self.m_Stone >= mData["inlay_count"] then
            iLevel = self:Pos()
        end
    end
    return iLevel
end

function CParStone:AddApply(sAttr, iVal)
    local iAttr = self.m_mApply[sAttr] or 0
    self.m_mApply[sAttr] = iAttr + iVal
end

function CParStone:GetApply(sAttr, rDefault)
    rDefault = rDefault or 0
    return self.m_mApply[sAttr] or rDefault
end

function CParStone:GetAllAttrs(mAttr)
    for sAttr, iVal in pairs(self.m_mApply) do
        mAttr[sAttr] = mAttr[sAttr] or 0
        mAttr[sAttr] = mAttr[sAttr] + iVal
    end
end

function CParStone:PackNetInfo()
    local mNet = {}
    mNet["pos"] = self:Pos()
    mNet["sids"] = table_value_list(self.m_Stone)
    local m = {}
    for sAttr, iVal in pairs(self.m_mApply) do
        table.insert(m, {key = sAttr, value = iVal})
    end
    mNet["apply_info"] = m
    return mNet
end