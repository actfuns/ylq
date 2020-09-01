local skynet = require "skynet"

local global = require "global"
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
            oSkill:OnActionBeforeStart(oAction)
        end
    end
    oAction:AddFunction("OnActionBeforeStart",self.m_ID,fCallback)
end

function CPerform:OnActionBeforeStart(oAction)
    if not oAction or oAction:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 5000
    if in_random(iRatio,10000) then
        self:TriggerNormal(oAction)
    end
    local iExtraLevel = mArgs["extra_level"] or 3
    local iExtRatio = mArgs["extra_ratio"] or 2000
    if self:Level() >= iExtraLevel and in_random(iExtRatio,10000) then
        self:Effect_Condition_For_Attack(oAction,oAction)
    end
end

function CPerform:TriggerNormal(oAction)
    local bFlag = false
    local iClassType = gamedefines.BUFF_TYPE.CLASS_ABNORMAL
    local iClassCnt = oAction.m_oBuffMgr:ClassBuffCnt(iClassType)
    if iClassCnt > 0 then
        oAction.m_oBuffMgr:RemoveRandomBuff(iClassType)
        bFlag = true
    end
    if not bFlag then
        local mFriend = oAction:GetFriendList()
        for _,w in pairs(mFriend) do
            if w:GetWid() ~= oAction:GetWid() then
                local iClassCnt = w.m_oBuffMgr:ClassBuffCnt(iClassType)
                if iClassCnt > 0 then
                    w.m_oBuffMgr:RemoveRandomBuff(iClassType)
                    bFlag = true
                    break
                end
            end
        end
    end
    if bFlag then
        self:ShowPerfrom(oAction)
        self:Effect_Condition_For_Attack(oAction,oAction)
    end
end