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
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:ValidUse(oAttack,oVictim)
    if oVictim and oVictim:IsDead() and not oVictim:ValidRevive({}) then
        return false
    end
    return true
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fDead = function (oAction)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnDead(oAction)
        end
    end
    oAction:AddFunction("OnDead",self.m_ID,fDead)
end

function CPerform:OnDead(oAction)
    local mFriend = oAction:GetFriendList(true,true)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["hp_ratio"] or 3000
    local mArgs = {
        attack_wid = oAction:GetWid()
    }
    local oWar = oAction:GetWar()
    local iWid = oAction:GetWid()
    for _,w in ipairs(mFriend) do
        if w:IsDead() and w:GetWid() ~= oAction:GetWid() and ( not oAction:IsPartner() or oAction:GetData("type",0) ~= w:GetData("type",0))
         and ( not oAction:IsNpc() or   oAction:GetModelInfo()["shape"] ~= w:GetModelInfo()["shape"]) then
            self:ShowPerfrom(oAction)
            local iAddHp = math.floor(w:GetMaxHp() * iRatio / 10000)
            oWar:SendAll("GS2CWarSkill", {
                war_id = oWar:GetWarId(),
                action_wlist = {iWid,},
                select_wlist = {w:GetWid()},
                skill_id = 40703,
                magic_id = 1,
            })
            self:ModifyHp(w,oAction,iAddHp,mArgs)
            return
        end
    end
end