--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"
--local aoi = require "aoi.core"
local aoi = require "gaoi.core"

local gamedefines = import(lualib_path("public.gamedefines"))

local mceil = math.ceil
local mmax = math.max
local mmin = math.min
local mfloor = math.floor

function NewAoiMgr(...)
    local o = CAoiMgr:New(...)
    return o
end

CAoiMgr = {}
CAoiMgr.__index = CAoiMgr
inherit(CAoiMgr, logic_base_cls())

function CAoiMgr:New(mInfo)
    local o = super(CAoiMgr).New(self)

    local iMaxX, iMaxY, iGridX, iGridY = mceil(mmax(mInfo.max_x, 1))+1, mceil(mmax(mInfo.max_y, 1))+1, mceil(mmax(mInfo.grid_x, 1)), mceil(mmax(mInfo.grid_y, 1))

    o.m_oSpace = aoi.CreateSpace(iMaxX, iMaxY, iGridX, iGridY)
    o.m_iMaxX = iMaxX
    o.m_iMaxY = iMaxY
    o.m_iGridX = iGridX
    o.m_iGridY = iGridY
    o.m_iMapId = mInfo.map_id
    o.m_mAllObjects = {}

    return o
end

function CAoiMgr:Release()
    super(CAoiMgr).Release(self)
end

function CAoiMgr:CreateObject(iEid, mInfo)
    if self.m_mAllObjects[iEid] then
        record.warning("CAoiMgr(%s) CreateObject failed object exist, eid:%s", self.m_iMapId, iEid)
        print("lxldebug CreateObject")
        print(debug.traceback())
        return {errcode = 1}
    end

    local fX, fY, iType, iAcType, iWeight, iLimit = mInfo.x, mInfo.y, mInfo.type, mInfo.ac_type, mInfo.weight or 0, mInfo.limit or 0
    if fX<0 or fX>self.m_iMaxX or fY<0 or fY>self.m_iMaxY then
        record.warning("CAoiMgr(%s) CreateObject failed pos, x:%s y:%s max_x:%s max_y:%s", self.m_iMapId, fX, fY, self.m_iMaxX, self.m_iMaxY)
        return {errcode = 1}
    end
    if  iWeight<0 then
        record.warning("CAoiMgr(%s) CreateObject failed weight, weight:%s", self.m_iMapId, iWeight)
        return {errcode = 1}
    end
    iWeight = mfloor(iWeight)
    if  iLimit<0 then
        record.warning("CAoiMgr(%s) CreateObject failed limit, limit:%s", self.m_iMapId, iLimit)
        return {errcode = 1}
    end
    iLimit = mfloor(iLimit)

    local lEnter, lLeave = self.m_oSpace:CreateObject(iEid, iType, iAcType, iWeight, iLimit, fX, fY)
    self.m_mAllObjects[iEid] = 1

    return {
        errcode = 0,
        events = {
            enter = lEnter,
            leave = lLeave,
        }
    }
end

function CAoiMgr:UpdateObjectPos(iEid, mInfo, bForce)
    if not self.m_mAllObjects[iEid] then
        record.warning("CAoiMgr(%s) UpdateObjectPos failed object not exist, eid:%s", self.m_iMapId, iEid)
        print("lxldebug UpdateObjectPos")
        print(debug.traceback())
        return {errcode = 1}
    end

    local fX, fY = mInfo.x, mInfo.y
    if fX<0 or fX>self.m_iMaxX or fY<0 or fY>self.m_iMaxY then
        record.warning("CAoiMgr(%s) UpdateObjectPos failed pos, x:%s y:%s max_x:%s max_y:%s", self.m_iMapId, fX, fY, self.m_iMaxX, self.m_iMaxY)
        return {errcode = 1}
    end

    local lEnter, lLeave = self.m_oSpace:UpdateObjectPos(iEid, fX, fY, bForce)

    return {
        errcode = 0,
        events = {
            enter = lEnter,
            leave = lLeave,
        }
    }
end

function CAoiMgr:UpdateObjectWeight(iEid, mInfo)
    if not self.m_mAllObjects[iEid] then
        record.warning("CAoiMgr(%s) UpdateObjectWeight failed object not exist, eid:%s", self.m_iMapId, iEid)
        print("lxldebug UpdateObjectWeight")
        print(debug.traceback())
        return {errcode = 1}
    end

    local fWeight = mInfo.weight
    if  fWeight<0 then
        record.warning("CAoiMgr(%s) UpdateObjectWeight failed weight, weight:%s", self.m_iMapId, fWeight)
        return {errcode = 1}
    end
    local iWeight = mfloor(fWeight)

    local lEnter, lLeave = self.m_oSpace:UpdateObjectWeight(iEid, iWeight)

    return {
        errcode = 0,
        events = {
            enter = lEnter,
            leave = lLeave,
        }
    }
end

function CAoiMgr:RemoveObject(iEid)
    if not self.m_mAllObjects[iEid] then
        record.warning("CAoiMgr(%s) RemoveObject failed object not exist, eid:%s", self.m_iMapId, iEid)
        print("lxldebug RemoveObject")
        print(debug.traceback())
        return {errcode = 1}
    end

    local lEnter, lLeave = self.m_oSpace:RemoveObject(iEid)
    self.m_mAllObjects[iEid] = nil

    return {
        errcode = 0,
        events = {
            enter = lEnter,
            leave = lLeave,
        }
    }
end

function CAoiMgr:GetView(iEid, iType)
    if not self.m_mAllObjects[iEid] then
        record.warning("CAoiMgr(%s) GetView failed object not exist, eid:%s", self.m_iMapId, iEid)
        print("lxldebug GetView")
        print(debug.traceback())
        return {errcode = 1}
    end

    iType = iType or 0
    local lResult = self.m_oSpace:GetView(iEid, iType)

    return {
        errcode = 0,
        result = lResult
    }
end

function CAoiMgr:CreateSceneTeam(iEid, mInfo)
    if self.m_mAllObjects[iEid] then
        record.warning("CAoiMgr(%s) CreateSceneTeam failed object exist, eid:%s", self.m_iMapId, iEid)
        print("zljdebug CreateSceneTeam")
        print(debug.traceback())
        return {errcode = 1}
    end

    local mMem,mShort = mInfo.mem or {}, mInfo.short or {}
    if table_count(mMem) <= 0 then
        record.warning("CAoiMgr(%s) CreateSceneTeam failed object exist, eid:%s", self.m_iMapId, iEid)
        print("zljdebug CreateSceneTeam No Mem")
        print(debug.traceback())
        return {errcode = 1}
    end

    local lEnter, lLeave = self.m_oSpace:CreateSceneTeam(iEid, mMem, mShort)
    self.m_mAllObjects[iEid] = 1

    return {
        errcode = 0,
        events = {
            enter = lEnter,
            leave = lLeave,
        }
    }
end

function CAoiMgr:RemoveSceneTeam(iEid)
    if not self.m_mAllObjects[iEid] then
        record.warning("CAoiMgr(%s) RemoveSceneTeam failed object exist, eid:%s", self.m_iMapId, iEid)
        print("zljdebug RemoveSceneTeam")
        print(debug.traceback())
        return {errcode = 1}
    end

    self.m_oSpace:RemoveSceneTeam(iEid)
    self.m_mAllObjects[iEid] = nil

    return {
        errcode = 2,
    }
end

function CAoiMgr:UpdateSceneTeam(iEid, mInfo)
    if not self.m_mAllObjects[iEid] then
        record.warning("CAoiMgr(%s) UpdateSceneTeam failed object not exist, eid:%s", self.m_iMapId, iEid)
        print("zljdebug UpdateSceneTeam")
        print(debug.traceback())
        return {errcode = 1}
    end

    local mMem,mShort = mInfo.mem or {}, mInfo.short or {}
    if table_count(mMem) <= 0 then
        record.warning("CAoiMgr(%s) UpdateSceneTeam failed object exist, eid:%s", self.m_iMapId, iEid)
        print("zljdebug UpdateSceneTeam No Mem")
        print(debug.traceback())
        return {errcode = 1}
    end

    local lEnter, lLeave = self.m_oSpace:UpdateSceneTeam(iEid, mMem, mShort)

    return {
        errcode = 0,
        events = {
            enter = lEnter,
            leave = lLeave,
        }
    }
end