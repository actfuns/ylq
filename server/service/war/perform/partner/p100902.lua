--import module

local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))

function NewCPerform(...)
    local o = CPerform:New(...)
    return o
end

CPerform = {}
CPerform.__index = CPerform
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:PerformTarget(oAttack,oVictim)
    local mTarget = {}
    for i = 1,5 do
        local mEnemyList = oAttack:GetEnemyList(false,true)
        if #mEnemyList == 0 then
            break
        end
        table.insert(mTarget,mEnemyList[1]:GetWid())
    end
    oAttack:OnPerformTarget(oVictim,mTarget,self)
    return mTarget
end



