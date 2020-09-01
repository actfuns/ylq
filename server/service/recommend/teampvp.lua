--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"

function NewCollection(...)
    local o = CCollection:New(...)
    return o
end

CCollection = {}
CCollection.__index = CCollection
inherit(CCollection, logic_base_cls())

function CCollection:New()
    local o = super(CCollection).New(self)
    o:InitAll()
    return o
end

function CCollection:InitAll()
    self:ClearAllCache()
end

function CCollection:ClearAllCache()
    self.m_PlayerList = {}
    self.m_NextPtr = nil
    self.m_Cache = nil
end

function CCollection:UpdateInfo(pid,mData)
    if mData["rm"] == 1 then
        self.m_PlayerList[pid] = nil
    else
        self.m_PlayerList[pid] = mData["data"]
    end
end



function CCollection:GetCollecttion(pid,iCnt,excludelist)
    excludelist = excludelist or {}
    table.insert(excludelist,pid)
    local iCheck = iCnt * 4

    local targetlist = {}
    for i=1,iCheck do
        if #targetlist == iCnt then
            break
        end
        if not (self.m_NextPtr and self.m_Cache) then
            self.m_Cache = table_key_list(self.m_PlayerList)
            self.m_NextPtr = nil
        end
        if #self.m_Cache == 0 then
            break
        end
        local iTarget
        self.m_NextPtr,iTarget = next(self.m_Cache, self.m_NextPtr)
        if self.m_NextPtr and not table_in_list(excludelist,iTarget) then
            local m = self.m_PlayerList[iTarget]
            if m then
                local info = {
                pid = iTarget,
                name = m["name"],
                score = m["score"],
                shape = m["shape"],
                grade = m["grade"],
                }
                local mNet = {
                info = info,
                org = m["org"] or 0,
                fight = m["fight"] or 0,
                }
                table.insert(targetlist,mNet)
                table.insert(excludelist,iTarget)
            end
        end
    end
    return targetlist
end

