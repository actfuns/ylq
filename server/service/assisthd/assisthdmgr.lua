--import module
local global = require "global"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))

function NewAssistHDMgr(...)
    return CAssistHDMgr:New(...)
end

HUODONGLIST = {
    ["clubarena"] = "clubarena",
}

CAssistHDMgr = {}
CAssistHDMgr.__index = CAssistHDMgr
inherit(CAssistHDMgr,logic_base_cls())

function CAssistHDMgr:New()
    local o = super(CAssistHDMgr).New(self)
    o.m_mHuodongList = {}

    for sHuodongName, sDir in pairs(self:GetHuodongList()) do
        local sPath = self:Path(sDir)
        local oModule = import(service_path(sPath))
        assert(oModule,string.format("Create Huodong err:%s %s",sHuodongName,sPath))
        local oHuodong = oModule.NewAssistHD(sHuodongName)
        o.m_mHuodongList[sHuodongName] = oHuodong
        oHuodong:Init()
    end
    return o
end

function CAssistHDMgr:GetHuodongList()
    return HUODONGLIST
end

function CAssistHDMgr:InitData()
    for sName,oHuodong in pairs(self.m_mHuodongList) do
        oHuodong:Init()
        oHuodong:LoadDb()
    end
end


function CAssistHDMgr:Path(sDir)
    return string.format("hd.%s",sDir)
end


function CAssistHDMgr:GetHuodong(sHuodongName)
    return self.m_mHuodongList[sHuodongName]
end

function CAssistHDMgr:NewHour(iWeekDay,iHour)
    for _, oHuodong in pairs(self.m_mHuodongList) do
        safe_call(oHuodong.NewHour, oHuodong, iWeekDay, iHour)
    end
    if iHour == 0 then
        self:NewDay(iWeekDay)
    end
end

function CAssistHDMgr:NewDay(iWeekDay)
    iWeekDay = iWeekDay or get_weekday()
    for _, oHuodong in pairs(self.m_mHuodongList) do
        safe_call(oHuodong.NewDay, oHuodong,iWeekDay)
    end
end

function CAssistHDMgr:CloseGS()
    save_all()
end


