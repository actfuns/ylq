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
    self.m_NowTarget = oVictim:GetWid()
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,2)
    if oVictim:IsDead() then
        self.m_DeadCnt = self.m_DeadCnt + 1
    end
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    self.m_DeadCnt = 0
    local iSkill = self:Type()
    local fCallback = function (oAttack,lVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnPerform(oAttack,lVictim,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnPerform",self.m_ID,fCallback)
end

function CPerform:OnPerform(oAttack,lVictim,oPerform)
    if self:Type() ~= oPerform:Type() or self.m_DeadCnt == 0 then
        return
    end
    local iCnt = self.m_DeadCnt
    self.m_DeadCnt = 0
    local mArgs = self:GetSkillArgsEnv()
    local iHit = math.max(math.floor(oAttack:QueryAttr("attack") * ( mArgs["damageratio"] or 3000) / 10000),1)
    for i=1,iCnt do
        local oEnemyList = oAttack:GetEnemyList()
        for _,o in ipairs(oEnemyList) do
            o:FixedDamage(oAttack,iHit,{perform=self})
        end
    end
end





