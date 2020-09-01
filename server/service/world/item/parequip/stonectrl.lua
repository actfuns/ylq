local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local datactrl = import(lualib_path("public.datactrl"))
local loaditem = import(service_path("item.loaditem"))
local stoneobj = import(service_path("item.parequip.stoneobj"))

function NewStoneCtrl(...)
    local o = CStoneCtrl:New(...)
    return o
end

CStoneCtrl = {}
CStoneCtrl.__index = CStoneCtrl
inherit(CStoneCtrl,datactrl.CDataCtrl)

function CStoneCtrl:New(iPid, iEquip)
    local o = super(CStoneCtrl).New(self)
    o.m_iPid = iPid
    o.m_iEquip = iEquip
    o.m_mStone = {}
    return o
end

function CStoneCtrl:Load(mData)
    local lStone = mData["stone_list"] or self.m_mStone
    for _, m in ipairs(lStone) do
        local iPos = m["pos"]
        local oStone = stoneobj.NewStone(iPos)
        oStone:Load(m)
        self.m_mStone[iPos] = oStone
    end
end

function CStoneCtrl:Setup()
    for iPos, oStone in pairs(self.m_mStone) do
        oStone:Setup()
    end
end

function CStoneCtrl:Save()
    local mData = {}
    local lStone = {}
    for iPos, oStone in pairs(self.m_mStone) do
        local m = oStone:Save()
        m["pos"] = iPos
        table.insert(lStone, m)
    end
    mData["stone_list"] = lStone
    return mData
end

function CStoneCtrl:GetApply(sAttr)
    local iVal = 0
    for iPos, oStone in pairs(self.m_mStone) do
        iVal = iVal + oStone:GetApply(sAttr)
    end

    return iVal
end

function CStoneCtrl:GetAllAttrs(mAttr)
    for iPos, oStone in pairs(self.m_mStone) do
        oStone:GetAllAttrs(mAttr)
    end
end

function CStoneCtrl:GetStone(iPos)
    return self.m_mStone[iPos]
end

function CStoneCtrl:AddStone(iPos, iShape)
    local oStone = self:GetStone(iPos)
    if not oStone then
        oStone = stoneobj.NewStone(iPos)
        self.m_mStone[iPos]= oStone
    end
    return oStone:AddStone(iShape)
end

function CStoneCtrl:CountStone(iPos)
    local iCount = 0
    local oStone = self:GetStone(iPos)
    if oStone then
        iCount = oStone:Count()
    end
    return iCount
end

function CStoneCtrl:MaxStoneLevel()
    local iLevel = 1
    for iPos, oStone in pairs(self.m_mStone) do
        iLevel = math.max(iLevel, oStone:Level())
    end
    return iLevel
end

function CStoneCtrl:CountStoneLevel()
    local iCnt = 0
    for iPos, oStone in pairs(self.m_mStone) do
        iCnt = iCnt + iPos * oStone:Count()
    end
    return iCnt
end

function CStoneCtrl:IsDirty()
    local bDirty = super(CStoneCtrl).IsDirty(self)
    if bDirty then
        return true
    end
    for iPos, oStone in pairs(self.m_mStone) do
        if oStone:IsDirty() then
            return true
        end
    end
    return false
end

function CStoneCtrl:UnDirty()
    super(CStoneCtrl).UnDirty(self)
    for iPos, oStone in pairs(self.m_mStone) do
        oStone:UnDirty()
    end
end

function CStoneCtrl:PackStoneInfo()
    local lNet = {}
    for iPos, oStone in pairs(self.m_mStone) do
        table.insert(lNet, oStone:PackNetInfo())
    end
    return lNet
end