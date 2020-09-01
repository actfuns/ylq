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
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end


function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVitim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnReceiveDamage(oAttack,oVitim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnReceiveDamage",self.m_ID,fCallback)

    local fCallback = function (oAttack,oVitim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnPerform(oAttack,oVitim,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnPerform",self.m_ID,fCallback)


end

function CPerform:OnReceiveDamage(oAttack,oVitim,oPerform,iDamage)
    if oAttack:IsPartner() and  not oAttack:IsAwake() then
        return 0
    end
    local mArg = self:GetSkillArgsEnv()
    local iCurHP = math.floor(mArg["hp_ratio"] / 10000 * iDamage)
    if iCurHP > 0 then
        local mArgs = oAttack:QueryBoutArgs("p41303_HP",{})
        local wid = oVitim:GetWid()
        if not mArgs[wid] then
            mArgs[wid] = {}
        end
        table.insert(mArgs[wid],iCurHP)
        oAttack:SetBoutArgs("p41303_HP",mArgs)
    end
    return 0
end

function CPerform:OnPerform(oAttack,lVictim,oPerform)
    local mArgs = oAttack:QueryBoutArgs("p41303_HP",{})
    oAttack:SetBoutArgs("p41303_HP",nil)
    if table_count(mArgs) > 0 then
        self:ShowPerfrom(oAttack)
    end
    local oFriendList = oAttack:GetFriendList()
    for i=1,3 do
        local iCurHP = 0
        for _,mW in pairs(mArgs) do
            iCurHP = iCurHP + (mW[i] or 0)
        end
        if iCurHP > 0 then
        local oTarget = oAttack
            for _,o in ipairs(oFriendList) do
                if o:GetHpRatio() < oTarget:GetHpRatio() then
                    oTarget = o
                end
            end
            self:ModifyHp(oTarget,oAttack,iCurHP,{attack_wid=oAttack:GetWid(),})
        end
    end


end

