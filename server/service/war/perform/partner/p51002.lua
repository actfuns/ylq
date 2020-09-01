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


function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local oCamp = oAction:GetEnemyCamp()
    local iWid = oAction:GetWid()
    local fCallback = function (oVictim,iHP,mArg)
        local oWar = oVictim:GetWar()
        local oAttack = oWar:GetWarrior(iWid)
        if not oAttack then
            return 0
        end
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnModifyHp(oAttack,oVictim,iHP,mArg)
        end
        return 0
    end
    oCamp:AddFunction("OnModifyHp",self:CampFuncNo(oAction:GetWid()),fCallback)
end

function CPerform:OnModifyHp(oAttack,oVictim,iHP,mArgs)
    if iHP < 0 and oAttack:QueryBoutArgs("p51002_target",0) == oVictim:GetWid() and  ( not oVictim:IsCallNpc() or oVictim:Query("is_BossCall") ) then
        oAttack:AddBoutArgs("p51002_damage",-iHP)
    end
    return 0
end

function CPerform:Perform(oAttack,lVictim)
    local oVictim = lVictim[1]
    local iSelectWid = oVictim:GetWid()
    local iNowHP = oVictim:GetHp()
    oAttack:SetBoutArgs("p51002_target",iSelectWid)
    super(CPerform).Perform(self,oAttack,lVictim)
    local iDamage = oAttack:QueryBoutArgs("p51002_damage",0)
    oAttack:SetBoutArgs("p51002_damage",nil)
    oAttack:SetBoutArgs("p51002_target",nil)
    local iHit = iDamage - iNowHP
    if not oAttack:IsAwake() then
        iHit = math.floor(iHit / 2)
    end
    if iHit < 1 then
        return
    end
    local mEnemy = oAttack:GetEnemyList()
    local lSelectWid = {}
    for _,w in pairs(mEnemy) do
        if w:GetWid() ~= iSelectWid and not oAttack:IsDead()  then
            table.insert(lSelectWid,w:GetWid())
        end
    end
    if #lSelectWid == 0 then
        return
    end

    oAttack:SendAll("GS2CWarSkill", {
        war_id = oAttack:GetWarId(),
        action_wlist = {oAttack:GetWid(),},
        select_wlist = lSelectWid,
        skill_id = 51002,
        magic_id = 2,
    })
    local oWar = oAttack:GetWar()
    for _,wid in ipairs(lSelectWid) do
        local w = oWar:GetWarrior(wid)
        w:FixedDamage(oAttack,iHit)
    end
end
