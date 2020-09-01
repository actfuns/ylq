--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))
local pfload = import(service_path("perform.pfload"))


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


function CPerform:Perform(oAttack,lVictim,mArgs)
    local iWid = oAttack:GetWid()
    super(CPerform).Perform(self,oAttack,lVictim,mArgs)
    local oTarget = lVictim[1]
    local mPfArg = self:GetSkillArgsEnv()
    local iRatio = mPfArg["ratio"] or 3000
    local mFriendList = oAttack:GetFriendList()
    for _,o in ipairs(mFriendList) do
        if oTarget:IsDead() then
            break
        end
        if o:GetWid() ~= iWid  and o:ValidAction() and oAttack:Random(iRatio,10000) then
            self:ShowPerfrom(o,{skill=5010})
            local iSkill = o:GetNormalAttackSkillId()
            local oPerform = o:GetPerform(iSkill)
            oPerform:Perform(o,{oTarget,})
        end
    end

    if oAttack:IsDead() then
        return
    end
    local iSkill = 5014
    local oPerform =  pfload.GetPerform(iSkill)
    if not oPerform then
        return
    end
    local oActionMgr = global.oActionMgr
    local mTarget = oAttack:GetEnemyList()
    if #mTarget > 0 then
        oPerform:Perform(oAttack,mTarget)
    end
end




