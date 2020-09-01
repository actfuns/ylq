local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local rewardmonitor = import(service_path("rewardmonitor"))

function NewAchievePush()
    return CAchievePush:New()
end

local mKey2Func={
}

CAchievePush = {}
CAchievePush.__index = CAchievePush
inherit(CAchievePush, logic_base_cls())

function CAchievePush:New()
    local o = super(CAchievePush).New(self)
    o.m_Info = {}
    return o
end

function CAchievePush:PushAchieve(iPid,sKey,mArgs)
    local sFuncName = mKey2Func[sKey]
    if sFuncName then
        local func = self[sFuncName]
        mArgs = func(self,iPid,mArgs)
    end
    interactive.Send(".achieve","common","PushAchieve",{
        pid = iPid , key= sKey , data=mArgs
    })
end
