local global = require "global"

local statebase = import(service_path("state/statebase"))

--[[
    匹配标记
]]

CState = {}
CState.__index = CState
inherit(CState,statebase.CState)

function CState:New(iState)
    local o = super(CState).New(self,iState)
    return o
end


function NewState(iState)
    local o = CState:New(iState)
    return o
end


function CState:IsTempState()
    return true
end

function CState:PlayName()
    return self:GetData("play","")
end



