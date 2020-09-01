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


function CPerform:Effect_Condition_For_Victim(oVictim,oAttack,mExArg)
    if self.m_InBuffEffect == oVictim:GetWid() then
        self.m_InBuffEffect = nil
        super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack,{NoSubNow=1})
    end
end


function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    if oAttack:IsDead() or oVictim:IsDead() then
        return
    end
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,100,2)
end

function CPerform:Perform(oAttack,lVictim)
    super(CPerform).Perform(self,oAttack,lVictim)
    if oAttack:IsDead() then
        return
    end
    local oActionMgr = global.oActionMgr
    local mEnemyList = oAttack:GetEnemyList()
    if #mEnemyList > 0 then
        local oVictim = extend.Random.random_choice(mEnemyList)
        self.m_InBuffEffect = oVictim:GetWid()
        oActionMgr:DoPerform(oAttack,oVictim,self,130)
    end
end

--效率
function CPerform:DamageRatio(oAttack,oVictim)
    if self.m_InBuffEffect then
        local mData = self:GetSkillArgsEnv()
        return mData["damage_ratio"] or 13000
    end
    return super(CPerform).DamageRatio(self,oAttack,oVictim)
end




