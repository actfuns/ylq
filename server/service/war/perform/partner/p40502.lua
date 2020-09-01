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
    super(CPerform).TruePerform(self,oAttack,oVictim,iDamageRatio)
    if not oAttack or oAttack:IsDead() then
        return
    end
    local oWar = oAttack:GetWar()
    if not oWar then
        return
    end
    local iCamp = oAttack:GetCampId()
    local iEnemyCamp = oVictim:GetCampId()
    local oActionMgr = global.oActionMgr
    local mArgs = self:GetSkillArgsEnv()
    local iCnt = mArgs["attack_cnt"] or 3
    local iActionWid = oVictim:GetWid()
    local iSelectWid
    self:SetData("PerformAttackMaxCnt",iCnt)
    local iTotalCnt = 1
    for iCurrentCnt=1,iCnt do
        local mEnemy = oAttack:GetEnemyList()
        local m = {}
        for _,w in pairs(mEnemy) do
            if w:GetWid() ~= iActionWid then
                table.insert(m,w)
            end
        end
        if #m <= 0 then
            return
        end
        local oNewVictim = m[math.random(#m)]
        iSelectWid = oNewVictim:GetWid()
        oAttack:SendAll("GS2CWarSkill", {
            war_id = oAttack:GetWarId(),
            action_wlist = {iActionWid,},
            select_wlist = {iSelectWid,},
            skill_id = self.m_ID,
            magic_id = 2,
        })
        local iTime = self:PerformMagicTime(i)
        if oWar then
            oWar:AddAnimationTime(iTime,{skill=self:Type(),mgi=i})
        end

        local iAttackCnt = self:GetData("PerformAttackCnt",0)
        iAttackCnt = iAttackCnt + 1
        self:SetData("PerformAttackCnt",iAttackCnt)
        local iRatio = 100 - 20 * iCurrentCnt
        oActionMgr:DoAttack(oAttack,oNewVictim,self,iRatio)
        iActionWid = iSelectWid
        iTotalCnt = iCurrentCnt
    end
    local iRatio = mArgs["ratio"] or 1000
    local iSP = mArgs["sp"] or 10
    if in_random(iRatio,10000) then
        oWar:AddSP(iEnemyCamp,-iSP)
        if oAttack:IsAwake() then
            oWar:AddSP(iCamp,iSP,{skiller=oAttack:GetWid()})
        end
    end
    self:XiuZhengMagicTime(oWar,iTotalCnt)
end

function CPerform:XiuZhengMagicTime(oWar,iAttackCnt)
    local iCorrectTime = self:PerformCorrectMagicTime(iAttackCnt) or 0
    local iMagicTime = self:PerformMagicTime(iAttackCnt) or 0
    local iAddTime = math.max(iCorrectTime-iMagicTime,0)
    if iAddTime > 0 then
        oWar:AddAnimationTime(iAddTime,{skill=self:Type(),mgi=-1,ext="xiuzheng"})
    end
end