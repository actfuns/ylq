--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"

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
    if oAttack:IsDead() or oVictim:IsDead() then
        return
    end
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,100,3)
end

function CPerform:CalWarrior(oAction,oPerformMgr)
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

    for _,o in ipairs(lVictim) do
        self:Effect_Condition_For_Victim(o,oAttack,{effect=1})
    end


    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000

    if not oAttack:Random(iRatio,10000) then
        return
    end

    local iSleep = mArgs["sleep"] or 1
    local mFriend = oAttack:GetFriendList(false,true)
    local iCnt = 0
    for _,o in ipairs(mFriend) do
        if iCnt >= iSleep then
            break
        end
        if o:GetWid() ~= oAttack:GetWid() then
            iCnt = iCnt + 1
            self:Effect_Condition_For_Attack(o,{NoSubNow=1,buff=1})
        end
    end

end


function CPerform:Effect_Condition_For_Attack(oAttack,mExArg)
    mExArg = mExArg or {}
    if not mExArg["buff"] then
        return
    end
    super(CPerform).Effect_Condition_For_Attack(self,oAttack,mExArg)
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack,mExArg)
    mExArg = mExArg or {}
    if not mExArg["effect"] then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    local iMinRatio = mArgs["min_ratio"] or 1000
    local iMaxRatio = mArgs["max_ratio"] or 5000
    iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
    if oAttack:Random(iRatio,10000) then
        mExArg["NoSubNow"]=1
        super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack,mExArg)
    end
end





