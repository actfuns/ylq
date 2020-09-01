--import module

local global = require "global"
local skynet = require "skynet"

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
    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnActionBeforeStart(oAttack)
        end
    end
    oAction:AddFunction("OnActionBeforeStart",self.m_ID,fCallback)
end

function CPerform:OnActionBeforeStart(oAttack)
    if oAttack:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if not in_random(iRatio,10000) then
        return
    end
    self:ShowPerfrom(oAttack)
    local mData = self:GetSkillData()
    local oWar = oAttack:GetWar()
    local mBuff = mData["attackBuff"] or {}
    local iAttack = math.floor(((mArgs["attr_ratio"] or 10000) * oAttack:QueryAttr("defense") ) / 10000)
    local mArgs = {
        level = self:Level(),
        attack = oAttack:GetWid(),
        buff_bout = oWar.m_iBout - 1,
        attrvaluelist = string.format("{attack=%s}",iAttack)
    }
    local oBuffMgr = oAttack.m_oBuffMgr
    for _,mData in pairs(mBuff) do
        local iBuffID = mData["buffid"]
        local iBout = mData["bout"]
        oBuffMgr:AddBuff(iBuffID,iBout,mArgs)
    end

end


