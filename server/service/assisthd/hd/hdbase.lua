--import module
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))



function NewAssistHD(...)
    return CAssistHD:New(...)
end

CAssistHD = {}
CAssistHD.__index = CAssistHD
inherit(CAssistHD,datactrl.CDataCtrl)

function CAssistHD:New(sName)
    local o = super(CAssistHD).New(self)
    o.m_sName = sName
    return o
end

function CAssistHD:Init()
end

function CAssistHD:NewDay(iWeekDay)
    -- body
end

function CAssistHD:NewHour(iWeekDay, iHour)
    -- body
end


function CAssistHD:ResName()
    return self.m_sName
end


function CAssistHD:Load(mData)
    -- body
end

function CAssistHD:Save()
    -- body
end



function CAssistHD:NeedSave()
    return false
end



function CAssistHD:IsLoading()
    if not self:NeedSave() then
        return false
    end
    return self.m_bLoading
end


function CAssistHD:MergeFrom(mFromData)
    return false, "merge function is not implemented"
end




function CAssistHD:LoadDb()
    if not self:NeedSave() then
        return
    end
    local mData = {
        name = self.m_sName
    }
    local mArgs = {
        module = "global",
        cmd = "LoadAssistHD",
        data = mData
    }
    gamedb.LoadDb(self.m_sName,"common", "LoadDb",mArgs, function (mRecord, mData)
        if not is_release(self) then
            local m = mData.data or {}
            self:Load(m)
            self:LoadFinish()
            self.m_bLoading = false
            self:ConfigSaveFunc()
        end
    end)
end

function CAssistHD:LoadFinish()
end

function CAssistHD:ConfigSaveFunc()
    local sName = self.m_sName
    self:ApplySave(function ()
        local oAssistDHMgr = global.oAssistDHMgr
        local obj = oAssistDHMgr:GetHuodong(sName)
        if not obj then
            record.warning(string.format("huodong %s save err: no obj", sName))
            return
        end
        obj:_CheckSaveDb()
    end)
end

function CAssistHD:_CheckSaveDb()
    assert(not is_release(self), string.format("huodong %s save err: release", self.m_sName))
    assert(not self:IsLoading(), string.format("huodong %s save err: loading", self.m_sName))
    self:SaveDb()
end

function CAssistHD:SaveDb()
    if self:IsLoading() then
        return
    end
    if is_release(self) then
        return
    end
    if not self:IsDirty() then
        return
    end
    local mData = {
        name = self.m_sName,
        data = self:Save()
    }
    gamedb.SaveDb(self.m_sName,"common","SaveDb",{module="global",cmd="SaveAssistHD",data=mData})
    self:UnDirty()
end


function CAssistHD:GetTextData(iText)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["text"][iText]
    mData = mData["content"]
    assert(mData,string.format("CHuodong:GetTextData err:%s %d", self.m_sName, iText))
    return mData
end







