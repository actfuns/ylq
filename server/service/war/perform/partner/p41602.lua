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


function CPerform:ValidResume(oAttack,oVictim)
    local oWar = oAttack:GetWar()
    if self.m_CallSummoner and oWar:GetWarrior(self.m_CallSummoner) then
        return
    end
    return super(CPerform).ValidResume(self,oAttack,oVictim)
end


function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    local iMonsterId = self.m_ID
    local mMonsterData = oActionMgr:PackWarriorInfo(iMonsterId)
    local mArgs = self:GetSkillArgsEnv()
    local iHpRatio = mArgs["hp_ratio"] or 20
    local iHp = math.floor(oAttack:GetMaxHp() * iHpRatio/100)
    mMonsterData["hp"] = iHp
    mMonsterData["max_hp"] = iHp
    local oWar = oAttack:GetWar()
    if self.m_CallSummoner and oWar:GetWarrior(self.m_CallSummoner) then
        return
    end
    local obj =oActionMgr:PerformSummonWarrior(oAttack,oAttack:GetCampId(),mMonsterData)
    if obj then
        local iTarget = obj:GetWid()
        self.m_CallSummoner = obj:GetWid()
        local iCamp = oAttack:GetEnemyCampId()
        local oCamp = oWar:GetCamp(iCamp)
        local mArg = self:GetSkillArgsEnv()
        local bAwake = oAttack:IsAwake()
        local iFuncNo = self.m_ID * 100 + iTarget
        local fCallback = function (oAction)
            OnActionEnd(oAction,iTarget,mArg,bAwake,self:Level())
        end
        oCamp:AddFunction("OnActionEnd",iFuncNo,fCallback)
    end
end



function OnActionEnd(oAction,iTarget,mArg,bAwake,iPFLV)
    if oAction:IsDead() then
        return
    end
    local oWar = oAction:GetWar()

    local oWarrior = oWar:GetWarrior(iTarget)
    if not oWarrior then
        return
    end

    local iRatio = mArg["ratio"] or 1000
    local iMinRatio = mArg["min_ratio"] or 1000
    local iMaxRatio = mArg["max_ratio"] or 6000
    local mBuffList = oAction.m_oBuffMgr:GetClassBuff(gamedefines.BUFF_TYPE.CLASS_ABNORMAL)
    local mCountBuff = {}
    for _,oBuff in ipairs(mBuffList) do
        local id = oBuff.m_ID
        if not mCountBuff[id] then
            mCountBuff[id] =true
        end
    end
    local iClassCnt = table_count(mCountBuff)
    if bAwake then
        iRatio = iRatio + ( mArg["alive_ratio"] or 0 ) * iClassCnt
    end
    
    iRatio = oWarrior:AbnormalRatio(oAction,iRatio,iMaxRatio,iMinRatio)
    if in_random(iRatio,10000)  then
        local mArgs = {
            level = iPFLV,
            attack = oWarrior:GetWid(),
            buff_bout = oWar.m_iBout,
        }
        oAction.m_oBuffMgr:AddBuff(1019,1,mArgs)
    end
end

