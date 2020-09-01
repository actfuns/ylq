local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local achieveobj = import(service_path("achieveobj"))

function NewSevenDay(iAchieveID)
    local o = CSevenDay:New(iAchieveID)
    return o
end

CSevenDay = {}
CSevenDay.__index = CSevenDay
inherit(CSevenDay, achieveobj.CAchieve)

function CSevenDay:Direction()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][self:ID()]["day"]
end

function CSevenDay:Name()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][self:ID()]["name"]
end

function CSevenDay:SubDirection()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][self:ID()]["sub_direction"]
end

function CSevenDay:GetBelong()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][self:ID()]["belong"]
end

function CSevenDay:Desc()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][self:ID()]["desc"]
end

function CSevenDay:Point()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][self:ID()]["point"]
end

function CSevenDay:GetKey()
    local res = require "base.res"
    local sCondition = res["daobiao"]["achieve"]["sevenday"][self:ID()]["condition"]
    local value = split_string(sCondition,"=")
    return value[1]
end

function CSevenDay:ReachDegree()
    local res = require "base.res"
    local sCondition = res["daobiao"]["achieve"]["sevenday"][self:ID()]["condition"]
    local value = split_string(sCondition,"=")
    return tonumber(value[2]) or 1000000
end

function CSevenDay:Day()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][self:ID()]["day"]
end

function CSevenDay:GetAchieveDegreeType()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][self:ID()]["degreetype"]
end