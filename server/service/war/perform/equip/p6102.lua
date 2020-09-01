--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/equip/epfobj"))

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
    local iWid = oAction:GetWid()
    local iFuncNo = self:CampFuncNo(oAction:GetWid())
    local oCamp = oAction:GetCamp()
    local fCallback = function (oAction,oAttack,oPerform,iDamage) 
        local oWar = oAttack:GetWar()
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnReceivedDamage(oAction,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnReceivedDamage",self.m_ID,fCallback)

    local oCamp = oAction:GetEnemyCamp()

    local fCallback = function (oAttack,oVictim,mTarget,oPerform)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return 0
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnPerformTarget(oAction,oAttack,oVictim,mTarget,oPerform)
        end
        return 0
    end
    oCamp:AddFunction("OnPerformTarget",iFuncNo,fCallback)


    local fCallback = function (oAction,oAttack,oPerform) 
        local oWar = oAttack:GetWar()
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnPerformed(oAction,oAttack,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnPerformed",self.m_ID,fCallback)


end

function CPerform:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
    local iTarget = oVictim:QueryBoutArgs("p6102_protoect")
    if not iTarget then
        return 0
    end
    local oWar = oVictim:GetWar()
    local oProtoect = oWar:GetWarrior(iTarget)
    if not oProtoect then
        return 0
    end
    local mArgs = self:GetSkillArgsEnv()
    local iShareRatio =  mArgs["share_damage"] or 5000
    local iShareDamage = math.floor(iDamage * iShareRatio / 10000)
    return -iShareDamage
end


function CPerform:HasProtectTarget(oAction)
    local mFriend = oAction:GetFriendList()
    for _,o in ipairs(mFriend) do
        if o:QueryBoutArgs("p6102_protoect") then
            return true
        end
    end
    return false
end

function CPerform:OnPerformTarget(oAction,oAttack,oVictim,mTarget,oPerform)
    oAction:SetBoutArgs("p6102_protoect",nil)
    if oPerform:ActionType() ~= gamedefines.WAR_ACTION_TYPE.ATTACK then
        return
    end
    if oAction:HasKey("disable") or oAction:IsDead() then
        return
    end
    if self:HasProtectTarget(oAction) then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if not oAction:Random(iRatio) then
        return
    end

    local iWid = oAction:GetWid()
    local oWar = oAction:GetWar()
    local iTarget

    local mList = {}
    for _,wid in ipairs(mTarget) do
        if wid ~= iWid then
            table.insert(mList,wid)
        end
    end
    if #mList > 0 then
        local iPos = math.random(#mList)
        local wid = mList[iPos]
        if oWar:GetWarrior(wid) then
            iTarget = wid
        end
    end
    if iTarget then
        if not table_in_list(mTarget,iWid) then
            extend.Array.insert(mTarget,iWid)
        end
        if table_in_list(mTarget,iTarget) then
            extend.Array.remove(mTarget,iTarget)
        end

        oAction:SetBoutArgs("p6102_protoect",iTarget)
        self:ShowPerfrom(oAction)
        oWar:SendAll("GS2CWarProtect",{
            war_id = oWar:GetWarId(),
            action_wid = oAction:GetWid(),
            select_wid = iTarget,
            attack_wid = oAttack:GetWid(),
            })
        
    end

end


function CPerform:OnPerformed(oVictim,oAttack,oPerform)
    local oWar = oAttack:GetWar()
    local iWarId = oWar:GetWarId()
    if oVictim:QueryBoutArgs("p6102_protoect") then
        oVictim:SetBoutArgs("p6102_protoect",nil)
        oWar:SendAll("GS2CWarGoback", {
                    war_id = iWarId,
                    action_wid = oVictim:GetWid(),
         })
    end
end

