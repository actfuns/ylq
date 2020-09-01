--import module

local global = require "global"
local skynet = require "skynet"

local buffbase = import(service_path("buff/buffbase"))
local pfload = import(service_path("perform/pfload"))

function NewBuff(...)
    local o = CBuff:New(...)
    return o
end

CBuff = {}
CBuff.__index = CBuff
inherit(CBuff, buffbase.CBuff)

function CBuff:CalInit(oWarrior,oBuffMgr)
    local iBuffID = self.m_ID
    local fCallback = function (oAction)
        local oBuff = oAction.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:OnActionEnd(oAction)
        end
    end
    oBuffMgr:AddFunction("OnActionEnd",self.m_ID,fCallback)

    local iBout = self:Bout()
    local fDead = function (oAction)
        local oBuff = oAction.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:OnDead(oAction,iBout)
        end
    end
    oBuffMgr:AddFunction("OnDead",self.m_ID,fDead)
end

function CBuff:OnActionEnd(oAction)
    local iAttack = self.m_mArgs["attack"]
    local oWar = oAction:GetWar()
    local oAttack = oWar:GetWarrior(iAttack)
    if not oAttack then
        return
    end
    local mArgs = self:GetBuffArgsEnv()
    local iHPRatio = mArgs["damage_ratio"] or 50
    local iDamage = math.floor(oAttack:QueryAttr("attack") * iHPRatio / 100 )
    if iDamage > 0 then
        self:ModifyHp(oAction,-iDamage)
    end
end

function CBuff:OnDead(oAction,iBout)
    local mFriend = oAction:GetFriendList()
    local pfobj =  pfload.GetPerform(40303)
    local mArg = pfobj:GetSkillArgsEnv()
    local iRatio = mArg["infect_ratio"] or 30
    if not in_random(iRatio,10000) then
        return
    end
    if #mFriend <= 0 then
        return
    end

    local oWar = oAction:GetWar()
    local iAttack = self.m_mArgs["attack"]

    local iBuffID = self.m_ID
    local bflag = false
    for _,oVictim in pairs(mFriend) do
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if not oBuff then
            oVictim.m_oBuffMgr:AddBuff(self.m_ID,iBout,{
                level = self.m_mArgs["level"],
                attack = iAttack,
                buff_bout = oWar.m_iBout,
            })
            bflag = true
            break
        end
    end

    local oAttack = oWar:GetWarrior(iAttack)
    if bflag and oAttack then
        local skobj = oAttack:GetPerform(40303)
        if skobj then
            skobj:ShowPerfrom(oAttack)
        end
    end
end