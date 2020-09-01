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

function CPerform:Perform(oAttack,lVictim)
    local oActionMgr = global.oActionMgr
    local oWar = oAttack:GetWar()
    local mArgs = self:GetSkillArgsEnv()
    local iAttackCnt = mArgs["attackcnt"] or 3
    local iRatio = mArgs["ratio"] or 1000
    self:SetData("PerformAttackCnt",iAttackCnt)
    for i=1,iAttackCnt do
        if not oAttack or oAttack:IsDead() then
            break
        end
        local oVictim = lVictim[i]
        if not oVictim then
            local mEnemy = oAttack:GetEnemyList()
            if #mEnemy <= 0 then
                break
            end
            oVictim = mEnemy[math.random(#mEnemy)]
        end
        if not oVictim or oVictim:IsDead() then
            break
        end
        local iMagID = i
        if i> 1 then
            iMagID = 2
        end
        oActionMgr:DoPerform(oAttack,oVictim,self,100,iMagID)
        if (not oVictim or oVictim:IsDead()) and (oAttack and not oAttack:IsDead()) then
            if in_random(iRatio,10000) and not self:GetData("add_perform_cnt") then
                local mEnemy = oAttack:GetEnemyList()
                if #mEnemy <= 0 then
                    break
                end
                oVictim = mEnemy[math.random(#mEnemy)]
                oActionMgr:DoPerform(oAttack,oVictim,self,100,2)
            end
        end
    end
    self:SetData("add_perform_cnt",nil)
    self:SetData("PerformAttackCnt",nil)
    if oAttack and not oAttack:IsDead() then
        self:Effect_Condition_For_Attack(oAttack)
        oAttack.m_oBuffMgr:CheckAttackBuff(oAttack)
        if self:IsCD(oAttack) then
            self:SetCD(oAttack)
        end
        if self:IsNearAction() then
            oAttack:SendAll("GS2CWarGoback", {
                war_id = oAttack:GetWarId(),
                action_wid = oAttack:GetWid(),
            })
        end
    end
end

