--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))
local pfload = import(service_path("perform/pfload"))

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

function CPerform:HasSummon(oAction)
    local oWar = oAction:GetWar()
    local iCamp = oAction:GetCampId()
    local oWarriorList = oWar:GetWarriorList(iCamp)
    for _,oWarrior in pairs(oWarriorList) do
        if oWarrior:GetData("p31502_call") then
            return oWarrior
        end
    end
end

function CPerform:ValidUse(oAttack,oVictim)
    if self:HasSummon(oAttack) then
        return false
    end
    local oCamp = oAttack:GetCamp()
    if not oCamp:ValidCallNpc() then
        return false
    end
    return true
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    local iMonsterId = self.m_ID
    local mMonsterData = oActionMgr:PackWarriorInfo(iMonsterId)
    local mArgs = self:GetSkillArgsEnv()
    local iSkill =self:Type()
    local iHpRatio = mArgs["hp_ratio"] or 8000
    local iHp = math.floor(oAttack:GetMaxHp() * iHpRatio / 10000)
    local iBoutHp = mArgs["bout_hp"] or 2000
    local mNewShape = mMonsterData["shape_exchange"]
    local iShape = oAttack:GetModelInfo()["shape"]
    if mNewShape[iShape] then
        mMonsterData["model_info"]["shape"] = mNewShape[iShape]
    end
    mMonsterData["hp"] = iHp
    mMonsterData["max_hp"] = iHp
    local iCamp = oAttack:GetCampId()
    local oCamp = oAttack:GetCamp()
    local oEnemyCamp = oAttack:GetEnemyCamp()
    local obj = oActionMgr:PerformSummonWarrior(oAttack,iCamp,mMonsterData)
    if obj then
        local iSummonID = obj:GetWid()
        obj:SetData("p31502_call",1)
        obj:SetData("BoutHP",iBoutHp)
        obj:SetData("Call_Attack",oAttack:QueryAttr("attack"))
        local fcallback = function (oAction)
            local oWar = oAction:GetWar()
            local oSummon = oWar:GetWarrior(iSummonID)
            local oSkill = oAction:GetPerform(iSkill)
            if oSummon then
                OnActionStart(oSummon,oAction)
            end
        end
        oCamp:AddFunction("OnActionStart",self:CampFuncNo(iSummonID),fcallback)


        local oSKill = oAttack:GetPerform(31503)
        if oSKill then
            local mNewArg = oSKill:GetSkillArgsEnv()
            obj:SetData("DeadDamageRatio",mNewArg["damage_ratio"] or 5000 )
            obj:SetData("HitCnt",mNewArg["hit_cnt"] or 2 )
            obj:AddFunction("OnDead",self.m_ID,OnSummonDead)
        end

        local iFuncNo = self.m_ID * 100 + oAttack:GetWid()

        if oAttack:IsAwake() then
            local func = function (oAction)
                local oWar = oAction:GetWar()
                local oSummon = oWar:GetWarrior(iSummonID)
                if oSummon then
                    return OnValidRevive(oSummon,oAction)
                end
                return true
            end
            oEnemyCamp:AddFunction("OnValidRevive",iFuncNo,func)
        end
        oCamp.m_Auramgr:AddAura(obj,1001,{dead_remove=1})
    end
end



function OnActionStart(oSummon,oAction)
    if oSummon:IsDead() or oAction:IsDead() or  oSummon:GetWid() == oAction:GetWid() then
        return
    end
    local oPerform = pfload.GetPerform(31502)
    local iRatio = oSummon:GetData("BoutHP",2000)
    local iHp = math.floor(oSummon:GetMaxHp()*iRatio/10000)
    oPerform:ModifyHp(oAction,oSummon,iHp)
end


function OnSummonDead(oAction,mArg)
    if oAction:BanPassiveSkill() == 2 then
        return
    end

    local oFriendList = oAction:GetFriendList()
    if #oFriendList < 1 then
        return
    end
    local oWar = oAction:GetWar()
    local iAttack = oAction:GetData("Call_Attack") or oAction:QueryAttr("attack")
    local oOwner = oWar:GetWarrior(oAction:GetData("call_obj"))
    if oOwner then
        iAttack = oOwner:QueryAttr("attack")
    end
    local oWarriorList = oAction:GetEnemyList()
    local iAttackRatio = oAction:GetData("DeadDamageRatio",5000)

    local iDamage = (iAttack * iAttackRatio) / 10000
    local iMax = oAction:GetData("HitCnt",2)
    local iCnt = 0
    local mRanList  = extend.Random.sample_table(oWarriorList,iMax)
    local mTargetList = {}
    local lSelectWid = {}
    for _,oWarrior in pairs(oWarriorList) do
        if oWarrior:IsAlive() then
            iCnt  =  iCnt + 1
            table.insert(mTargetList,oWarrior)
            table.insert(lSelectWid,oWarrior:GetWid())
            if iCnt >= iMax then
                break
            end
        end
    end

    if iCnt > 0 then
        local oAttack = oWar:GetWarrior(oAction:GetData("call_obj",0))
        if oAttack then
            local oSkill = oAttack:GetPerform(31503)
            if oAttack and oSkill then
                oSkill:ShowPerfrom(oAction)
                oAttack:SendAll("GS2CWarSkill", {
                    war_id = oAttack:GetWarId(),
                    action_wlist = {oAction:GetWid(),},
                    select_wlist = lSelectWid,
                    skill_id = 31503,
                    magic_id = 1,
                })
                for _,oWarrior in ipairs(mTargetList) do
                    if oWarrior.m_oBuffMgr:HasBuff(1054) then
                        oWarrior:ModifyHp(iDamage,{attack_wid=oAction:GetWid()})
                    else
                        oWarrior:ModifyHp(-iDamage,{attack_wid=oAction:GetWid()})
                    end
                end
            end
        end
    end
end

function OnValidRevive(oSummon,oAction)
    if oSummon:IsDead() then
        return true
    end
    return false
end


