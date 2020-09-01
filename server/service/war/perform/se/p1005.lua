local skynet = require "skynet"
local global = require "global"
local extend = require "base/extend"

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
    local fCallback = function (oAction)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnActionEnd(oAction)
        end
    end
    oAction:AddFunction("OnActionEnd",self.m_ID,fCallback)

    local oCamp = oAction:GetCamp()
    local iWid = oAction:GetWid()
    local fCallback = function(oAction)
        OnDead(iWid,oAction)
    end

    oCamp:AddFunction("OnDead",self:CampFuncNo(oAction:GetWid()),fCallback)

end

function CPerform:OnActionEnd(oAction)
    if oAction:IsDead() then
        return
    end

    --由于特殊需求,在结束的时候也要检查一下
    if self.m_Servent then
        if not oAction.m_oBuffMgr:HasBuff(1043) then
            local oFriend = oAction:GetFriendList()
            if #oFriend == 1 then
                local oBuffMgr = oAction.m_oBuffMgr
                local mArgs = {
                    level = 1,
                    attack = oAction:GetWid(),
                    buff_bout = 2,
                }
                local oBuff = oBuffMgr:AddBuff(1043,1,mArgs)
                if oBuff  then
                    oBuff.m_NoSubNowWar = 1
                end
            end
        end
        return
    end
    local oWar = oAction:GetWar()
    local mData =  oWar:GetExtData("servant_data")
    if not  mData then
        return
    end
    local oCamp =  oAction:GetCamp()
    local iCnt = 4
    local mKeys = table_key_list(mData)
    if #mKeys  == 0 then
        return
    end
    self.m_Servent = true

    for _,oWarrior in ipairs(oCamp:GetWarriorList()) do
        if oWarrior:GetWid() ~= oAction:GetWid() then
            oWar:KickOutWarrior(oWarrior)
        end
    end
    local oActionMgr = global.oActionMgr
    for i=1,iCnt do
        local  iKey   =  extend.Random.random_choice(mKeys)
        local  mMonster = table_deep_copy(mData[iKey])
        local obj = oActionMgr:PerformAddWarrior(oAction,oAction:GetCampId(),mMonster,i+1)
        if obj then
            obj:Set("is_call",true)
            obj:Set("is_BossCall",true)
        end
    end

end

function OnDead(wid,oAction)
    local oWar = oAction:GetWar()
    local oBoss = oWar:GetWarrior(wid)
    if not oBoss or wid == oAction:GetWid() then
        return
    end
    local oPerform = oBoss:GetPerform(5016)
    if oPerform and oPerform.m_NowTarget == oAction:GetWid() then
        return
    end

    local oCamp =  oAction:GetCamp()
    local oWarrioList = {}
    for _,oWarrior in ipairs(oCamp:GetWarriorList()) do
        if not oWarrior:IsDead() then
            table.insert(oWarrioList,oWarrior)
        end
    end
    if #oWarrioList == 1 then
        local oBuffMgr = oBoss.m_oBuffMgr
        local mArgs = {
            level = 1,
            attack = oBoss:GetWid(),
            buff_bout = 2,
        }
        local oBuff = oBuffMgr:AddBuff(1043,1,mArgs)
        if oBuff  then
            oBuff.m_NoSubNowWar = 1
        end
    end
end



