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

function CPerform:Perform(oAttack,lVictim,mArgs)
    if self:GetData("ScendAttack") then
        super(CPerform).Perform(self,oAttack,lVictim,mArgs)
        return
    end
    super(CPerform).Perform(self,oAttack,lVictim,mArgs)
    local mWarriorList = {}
    for _, o in ipairs(lVictim) do
        if not o:IsDead() then
            table.insert(mWarriorList,o)
        end
    end
    if #mWarriorList > 0 and not oAttack:IsDead() then
        self:SetData("ScendAttack",1)
        self:Perform(oAttack,mWarriorList,mArgs)
        self:SetData("ScendAttack",nil)
    end
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    if not self:GetData("ScendAttack") then
        local oActionMgr = global.oActionMgr
        local mArgs = self:GetSkillArgsEnv()
        local iBase = mArgs["attack_base"] or 3
        local iRan = mArgs["add_cnt"] or 3
        local iCnt = iBase + math.random(iRan)
        oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,iCnt)
    else
        super(CPerform).TruePerform(self,oAttack,oVictim,iDamageRatio)
    end
end

function CPerform:DamageRatio(oAttack,oVictim)
    if self:GetData("ScendAttack") then
        local mArgs = self:GetSkillArgsEnv()
        return mArgs["last_ratio"] or 10000
    end
    return super(CPerform).DamageRatio(self,oAttack,oVictim)
end


