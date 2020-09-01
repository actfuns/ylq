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
    local mArgs = self:GetSkillArgsEnv()
    local mBuffType = mArgs["buff_type"] or {}
    local iClass = gamedefines.BUFF_TYPE.CLASS_ABNORMAL
    for _,iGroupType in pairs(mBuffType) do
        oVictim.m_oBuffMgr:RemoveGroupClassBuff(iClass,iGroupType)
    end
end

function CPerform:ChooseAITarget(oAttack)
    local iClass = gamedefines.BUFF_TYPE.CLASS_ABNORMAL
    local iCnt = oAttack.m_oBuffMgr:ClassBuffCnt(iClass)
    if iCnt > 0 then
        return oAttack:GetWid()
    end
    local mFriend = oAttack:GetFriendList()
    for _,w in pairs(mFriend) do
        local iCnt = w.m_oBuffMgr:ClassBuffCnt(iClass)
        if iCnt > 0 and not w:IsNpc() then
            return w:GetWid()
        end
    end
    return oAttack:GetWid()
end