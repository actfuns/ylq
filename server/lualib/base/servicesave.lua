
local skynet = require "skynet"
local servicetime = require "base.servicetimer"

local M = {}

local oSaveObjMgr

local function Trace(sMsg)
    print(debug.traceback(sMsg))
end


local CSaveObj = {}
CSaveObj.__index = CSaveObj

function CSaveObj:New(id, f, i)
    local o = setmetatable({}, self)
    o.m_oTimer = servicetime.NewTimer()
    o.m_iSaveId = id
    o.m_iSaveTime = math.min(20*60*1000, math.max(1*60*1000, i or 5*60*1000))
    o.m_funcSave = f
    o.m_mMerge = {}
    return o
end

function CSaveObj:Release()
    self.m_oTimer:Release()

    release(self)
end

function CSaveObj:AddTimeCb(sKey, iDelay, func)
    self.m_oTimer:AddCallback(sKey, iDelay, func)
end

function CSaveObj:DelTimeCb(sKey)
    self.m_oTimer:DelCallback(sKey)
end

function CSaveObj:Init()
    self:PrepareSaveDb()
end

function CSaveObj:PrepareSaveDb()
    self:DelTimeCb("DoSaveObj")
    self:AddTimeCb("DoSaveObj", self.m_iSaveTime, function ()
        oSaveObjMgr:DoSaveObj(self:GetSaveId())
    end)
end

function CSaveObj:GetSaveId()
    return self.m_iSaveId
end

function CSaveObj:DoSave()
    xpcall(self.m_funcSave, Trace)
    self:PrepareSaveDb()
end

function CSaveObj:GetMergeMap()
    return self.m_mMerge
end

function CSaveObj:ClearMergeMap()
    self.m_mMerge = {}
end

function CSaveObj:AddMerge(id)
    self.m_mMerge[id] = true
end

function CSaveObj:DelMerge(id)
    self.m_mMerge[id] = nil
end


local CSaveObjMgr = {}
CSaveObjMgr.__index = CSaveObjMgr

function CSaveObjMgr:New()
    local o = setmetatable({}, self)
    o.m_mAllSave = {}
    o.m_iSaveDispatchId = 0
    o.m_mProtectedRepeated = {}
    o.m_iSavingCnt = 0
    return o
end

function CSaveObjMgr:Release()
    for _, v in pairs(self.m_mAllSave) do
        v:Release()
    end
    self.m_mAllSave = {}
    release(self)
end

function CSaveObjMgr:Init()
end

function CSaveObjMgr:GetSaveDispatchId()
    self.m_iSaveDispatchId = self.m_iSaveDispatchId + 1
    return self.m_iSaveDispatchId
end

function CSaveObjMgr:NewSaveObj(f, i)
    local id = self:GetSaveDispatchId()
    local o = CSaveObj:New(id, f, i)
    o:Init()
    self.m_mAllSave[id] = o
    return id
end

function CSaveObjMgr:GetSaveObj(id)
    return self.m_mAllSave[id]
end

function CSaveObjMgr:DoSaveObj(id)
    local o = self.m_mAllSave[id]
    if o then
        self:_RecuSave(o)
    end
end

function CSaveObjMgr:_RecuSave(obj)
    if self.m_mProtectedRepeated[obj:GetSaveId()] then
        return
    end
    self.m_mProtectedRepeated[obj:GetSaveId()] = true
    self.m_iSavingCnt = self.m_iSavingCnt + 1

    local lMerge = table_key_list(obj:GetMergeMap())
    obj:DoSave()

    for _, k in ipairs(lMerge) do
        local o = self:GetSaveObj(k)
        if o then
            self:DelSaveMerge(obj:GetSaveId(), k)
            self:_RecuSave(o)
        end
    end

    self.m_iSavingCnt = self.m_iSavingCnt - 1
    if self.m_iSavingCnt <= 0 then
        self.m_mProtectedRepeated = {}
    end
end

function CSaveObjMgr:DelSaveObj(id)
    local o = self.m_mAllSave[id]
    if o then
        o:Release()
        self.m_mAllSave[id] = nil
    end
end

function CSaveObjMgr:AddSaveMerge(id1, id2)
    local o1 = self:GetSaveObj(id1)
    local o2 = self:GetSaveObj(id2)
    if o1 and o2 then
        o1:AddMerge(id2)
        o2:AddMerge(id1)
    end
end

function CSaveObjMgr:DelSaveMerge(id1, id2)
    local o1 = self:GetSaveObj(id1)
    local o2 = self:GetSaveObj(id2)
    if o1 then
        o1:DelMerge(id2)
    end
    if o2 then
        o2:DelMerge(id1)
    end
end

function CSaveObjMgr:SaveAll()
    for _, v in pairs(self.m_mAllSave) do
        self:_RecuSave(v)
    end
end


function M.Init()
    if not oSaveObjMgr then
        oSaveObjMgr = CSaveObjMgr:New()
        oSaveObjMgr:Init()
    end
end

function M.NewSaveObj(...)
    return oSaveObjMgr:NewSaveObj(...)
end

function M.SaveAll()
    return oSaveObjMgr:SaveAll()
end

function M.AddSaveMerge(...)
    return oSaveObjMgr:AddSaveMerge(...)
end

function M.DelSaveObj(...)
    return oSaveObjMgr:DelSaveObj(...)
end

function M.DoSaveObj(...)
    return oSaveObjMgr:DoSaveObj(...)
end


return M
