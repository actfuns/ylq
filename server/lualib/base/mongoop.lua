
local skynet = require "skynet"
local mongo = require "mongo"
local bson = require "bson"
local serverdefines = require "public.serverdefines"

local MIX_TYPE = 1

local tinsert = table.insert

local M = {}

local CMongoObj = {}
CMongoObj.__index = CMongoObj
M.CMongoObj = CMongoObj

function CMongoObj:New()
    local o = setmetatable({}, self)
    o.m_sDbName = nil
    o.m_oClient = nil
    return o
end

function CMongoObj:Release()
    release(self)
end

function CMongoObj:Init(oClient, sDbName)
    self.m_oClient = oClient
    self.m_sDbName = sDbName
end

function CMongoObj:GetDB()
    if self.m_oClient then
        return self.m_oClient[self.m_sDbName]
    end
end

function CMongoObj:CreateIndex(sTableName, ...)
    local t = self:GetDB()[sTableName]
    t:ensureIndex(...)
    return
end

function CMongoObj:InsertLowPriority(sTableName, ...)
    local t = self:GetDB()[sTableName]
    t:insert(...)
    return true
end

function CMongoObj:Insert(sTableName, ...)
    local t = self:GetDB()[sTableName]
    t:insert(...)
    local r = self:GetDB():runCommand("getLastError")
    local ok = r and r.ok == 1 and r.err == bson.null
    if not ok then
        print(string.format("lxldebug Insert %s error:%s", sTableName, r.err))
    end
    return ok, r.err
end

function CMongoObj:BatchInsert(sTableName, ...)
    local t = self:GetDB()[sTableName]
    t:batch_insert(...)
    local r = self:GetDB():runCommand("getLastError")
    local ok = r and r.ok == 1 and r.err == bson.null
    if not ok then
        print(string.format("lxldebug BatchInsert %s error:%s", sTableName, r.err))
    end
    return ok, r.err
end

function CMongoObj:Delete(sTableName, ...)
    local t = self:GetDB()[sTableName]
    t:delete(...)
    local r = self:GetDB():runCommand("getLastError")
    local ok = r and r.ok == 1 and r.err == bson.null
    if not ok then
        print(string.format("lxldebug Delete %s error:%s", sTableName, r.err))
    end
    return ok, r.err
end

function CMongoObj:Update(sTableName, ...)
    local t = self:GetDB()[sTableName]
    t:update(...)
    local r = self:GetDB():runCommand("getLastError")
    if not r or r.err ~= bson.null then
        print(string.format("lxldebug Update %s error:%s", sTableName, r.err))
        return false, r.err
    end
    local ok = r.n > 0
    if not ok then
        print(string.format("lxldebug Update %s failed", sTableName))
    end
    return ok, r.err
end

function CMongoObj:Find(sTableName, ...)
    local t = self:GetDB()[sTableName]
    local r = t:find(...)
    return r
end

function CMongoObj:FindOne(sTableName, ...)
    local t = self:GetDB()[sTableName]
    local r = t:findOne(...)
    if r then
        r._id = nil
    end
    return r
end

function CMongoObj:FindAndModify(sTableName, ...)
    local t = self:GetDB()[sTableName]
    local r = t:findAndModify(...)
    if not r or r.ok ~= 1 then
        print(string.format("mongoop FindAndModify %s failed", sTableName))
        return nil, r.err
    end
    return r.value
end



function M.NewMongoObj(...)
    return CMongoObj:New(...)
end

function M.NewMongoClient(mConf)
    return mongo.client(mConf)
end

local function _before_recu(t)
    local lst = {}
    for k, v in pairs(t) do
        if type(k) == "number" then
            tinsert(lst, k)
        end
    end

    if #lst > 0 then
        for _, k in ipairs(lst) do
            t[tostring(k)] = t[k]
            t[k] = nil
        end
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            _before_recu(v)
        end
    end

    if #lst > 0 then
        t._meta_intkey = lst
    end
end

local function _after_recu(t)
    local lst = t._meta_intkey
    if lst then
        for _, k in ipairs(lst) do
            if not t[k] then
                local sk = tostring(k)
                t[k] = t[sk]
                t[sk] = nil
            end
        end
        t._meta_intkey = nil
    end
    for k, v in pairs(t) do
        if type(v) == "table" then
            _after_recu(v)
        end
    end
end

function M.ChangeBeforeSave(mData)
    _before_recu(mData)
end

function M.ChangeAfterLoad(mData)
    _after_recu(mData)
end

return M
