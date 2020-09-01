--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"

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

function CPerform:Perform(oAttack,lVictim,mArgs)
    super(CPerform).Perform(self,oAttack,lVictim,mArgs)
    local oVictim = lVictim[1]
    local iVictim = oVictim:GetWid()
    local mArg = self:GetSkillArgsEnv()
    local iRatio = mArg["buff_ratio"] or 3000
    if oVictim:IsAlive()  and oAttack:Random(iRatio,10000) then
        local mFriend = oAttack:GetFriendList(false,true)
        local mTargetList = {}
        local iWid = oAttack:GetWid()
        for _,o in ipairs(mFriend) do
            if o:GetWid() ~= iWid and o:ValidAction() then
                table.insert(mTargetList,o)
            end
        end
        if #mTargetList > 0 then
            local oTarget = extend.Random.random_choice(mTargetList)
            if oTarget then 
                local iSkill = oTarget:GetNormalAttackSkillId()
                local oPerform = oTarget:GetPerform(iSkill)
                if oPerform then
                    self:ShowPerfrom(oTarget)
                    oPerform:Perform(oTarget,{oVictim,})
                end
            end
        end
    end
end






