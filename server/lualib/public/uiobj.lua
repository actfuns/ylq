--import module
local global = require "global"

function NewUIMgr()
    local o = CUIMgr:New()
    return o
end

CUIMgr = {}
CUIMgr.__index = CUIMgr
inherit(CUIMgr, logic_base_cls())

function CUIMgr:New()
    local o = super(CUIMgr).New(self)
    o.m_mKeep = {}
    return o
end

function CUIMgr:AddKeepItem(iPid, mShow)
    local mKeep = self.m_mKeep[iPid]
    if not mKeep then
        mKeep = {}
        local sFlag = string.format("%s_keep_item", iPid)
        self:DelTimeCb(sFlag)
        self:AddTimeCb(sFlag, 2 * 1000, function()
            self:ClearKeepItem(iPid)
        end)
    end
    table.insert(mKeep, mShow)
    self.m_mKeep[iPid] = mKeep
end

function CUIMgr:GetSendObj(iPid)
end

function CUIMgr:ShowKeepItem(iPid)
    local oPlayer = self:GetSendObj(iPid)
    local lNetItem = self:PackKeepItem(iPid)
    if oPlayer and next(lNetItem) then
        oPlayer:Send("GS2CShowItem", {item_list = lNetItem})
    end
    self:ClearKeepItem(iPid)
end

function CUIMgr:PackKeepItem(iPid)
    local mKeep = self.m_mKeep[iPid]
    local lNetItem = {}
    if mKeep then
        local mShow = {}
        for _, mItem in pairs(mKeep) do
            local mK = mShow[mItem.sid] or {}
            local m = mK[mItem.id] or {}
            local iHave = m[mItem.virtual] or 0
            mShow[mItem.sid] = mK
            mShow[mItem.sid][mItem.id] = m
            mShow[mItem.sid][mItem.id][mItem.virtual] = iHave + mItem.amount
        end
        for iSid, mK in pairs(mShow) do
            for id, m in pairs(mK) do
                for iVirtual, iHave in pairs(m) do
                    table.insert(lNetItem, {
                        id = id,
                        sid = iSid,
                        virtual = iVirtual,
                        amount = iHave,
                        })
                end
            end
        end
    end
    self:ClearKeepItem(iPid)
    return lNetItem
end

function CUIMgr:ClearKeepItem(iPid)
    local sFlag = string.format("%s_keep_item", iPid)
    self:DelTimeCb(sFlag)
    self.m_mKeep[iPid] = nil
end

function CUIMgr:GS2CItemShortWay(oPlayer,sid)
    if oPlayer then
        oPlayer:Send("GS2CItemShortWay", {item=sid})
    end
end

function CUIMgr:GS2CShortWay(pid,iType)
    local mNet = {}
    mNet["type"] = iType
    local oSend = self:GetSendObj(pid)
    if oSend then
        oSend:Send("GS2CShortWay",mNet)
    end
end