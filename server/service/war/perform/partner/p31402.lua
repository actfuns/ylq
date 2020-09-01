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
    local oActionMgr = global.oActionMgr
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 5000 
    local iCnt = 1
    if oAttack:IsAwake() and oAttack:QueryBoutArgs("p31402_cnt",0) < mArgs["awak_cnt"]  then
        iCnt = mArgs["awak_cnt"]
    end
    for i=1,100 do
        if in_random(iRatio,10000) then
            iCnt = iCnt + 1
        else
            break
        end
    end
    oAttack:SetBoutArgs("combo",true)
    local f = function (iCnt,oWar,iWid,iVictimWid,oPerform)
        if iCnt ~= 1 then
            oWar:SendAll("GS2CWarSkill", {
                    war_id = oWar:GetWarId(),
                    action_wlist = {iWid,},
                    select_wlist = {iVictimWid},
                    skill_id = oPerform.m_ID,
                    magic_id = iCnt == 1 and 1 or 2,
                })
        end
    end
    oActionMgr:NormalAttackOne(oAttack,oVictim,self,iDamageRatio,iCnt,{AttackOneWarSkill=f})

end



