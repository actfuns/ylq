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


function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,2)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["spot_ratio"] or 4000
    iDamageRatio = mArgs["spot_damage_ratio"] or 5000
    iDamageRatio = math.floor(iDamageRatio/100)
    if math.random(10000) <= iRatio then
        self:DoAttackEnemy(oAttack,{oVictim},iDamageRatio)
    end
end

function CPerform:DoAttackEnemy(oAttack,lVictim,iDamageRatio)
    local mEnemy = oAttack:GetEnemyList()
    local mAttack = {}
    for _,oWarrior in pairs(mEnemy) do
        if not table_in_list(lVictim,oWarrior) then
            table.insert(mAttack,oWarrior)
        end
    end
    if #mAttack <= 0 then
        return
    end
    local oActionMgr = global.oActionMgr
    local iCnt = 0
    for _,w in pairs(mAttack) do
        if iCnt >= 2 then
            break
        end
        if w:IsDead() or oAttack:IsDead() then
            break
        end
        iCnt = iCnt + 1
        oActionMgr:DoAttack(oAttack,w,self,iDamageRatio)
    end
end