--import module
local skynet = require "skynet"

local basectrl = import(service_path("playerctrl.basectrl"))
local activectrl = import(service_path("playerctrl.activectrl"))
local itemctrl = import(service_path("playerctrl.itemctrl"))
local timectrl = import(lualib_path("public.timectrl"))
local taskctrl = import(service_path("playerctrl.taskctrl"))
local skillctrl = import(service_path("playerctrl.skillctrl"))
local schedulectrl = import(service_path("playerctrl.schedulectrl"))
local statectrl = import(service_path("playerctrl.statectrl"))
local partnerctrl = import(service_path("playerctrl.partnerctrl"))
local titlectrl = import(service_path("playerctrl.titlectrl"))
local huodongctrl = import(service_path("playerctrl.huodongctrl"))
local handbookctrl = import(service_path("playerctrl.handbookctrl"))

function NewBaseCtrl(...)
    return basectrl.CPlayerBaseCtrl:New(...)
end

function NewActiveCtrl(...)
    return activectrl.CPlayerActiveCtrl:New(...)
end

function NewItemCtrl( ... )
    return itemctrl.CItemCtrl:New(...)
end

function NewWHCtrl( ... )
    return warehousectrl.CWareHouseCtrl:New(...)
end

function NewTimeCtrl( ... )
    return timectrl.CTimeCtrl:New(...)
end

function NewTodayCtrl(...)
    return timectrl.CToday:New(...)
end

function NewTodayMorningCtrl(...)
    return timectrl.CTodayMorning:New(...)
end

function NewWeekCtrl(...)
    return timectrl.CThisWeek:New(...)
end

function NewMonthCtrl(...)
    return timectrl.CThisMonth:New(...)
end

function NewWeekMorningCtrl( ... )
    return timectrl.CThisWeekMorning:New(...)
end

function NewThisTempCtrl( ... )
    return timectrl.CThisTemp:New(...)
end

function NewSeveralDayCtrl( ... )
    return timectrl.CSeveralDay:New(...)
end

function NewTaskCtrl( ... )
    return taskctrl.CTaskCtrl:New(...)
end

function NewSkillCtrl( ... )
    return skillctrl.CSkillCtrl:New(...)
end

function NewSummonCtrl( ... )
    return summonctrl.CSummonCtrl:New(...)
end

function NewScheduleCtrl( ... )
    return schedulectrl.CScheduleCtrl:New(...)
end

function NewStateCtrl( ... )
    return statectrl.CStateCtrl:New(...)
end

function NewPartnerCtrl( ... )
    return partnerctrl.CPartnerCtrl:New(...)
end

function NewTitleCtrl( ... )
    return titlectrl.CTitleCtrl:New(...)
end

function NewHuodongCtrl(...)
    return huodongctrl.CHuodongCtrl:New(...)
end

function NewHandBookCtrl(...)
    return handbookctrl.CHandBookCtrl:New(...)
end