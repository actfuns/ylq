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

function CPerform:TargetList(oAttack)
    local iType = gamedefines.BUFF_TYPE.CLASS_ABNORMAL
    local mTarget = {}
    local mEnemyList = oAttack:GetFriendList()
    for _,o in ipairs(mEnemyList) do
        if o.m_oBuffMgr:ClassBuffCnt(iType) > 0 then
            table.insert(mTarget,o)
        end
    end
    return mTarget
end


function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local iType = gamedefines.BUFF_TYPE.CLASS_ABNORMAL
    oVictim.m_oBuffMgr:RemoveRandomBuff(iType)
end
