local skynet = require "skynet"

local global = require "global"
local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))
local partnerwarrior = import(service_path("partnerwarrior"))

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


function CPerform:ValidResume(oAttack,oVictim)
    if not oVictim or not oVictim:IsDead() then return end
    return super(CPerform).ValidResume(self,oAttack,oVictim)
end


function CPerform:MaxRange(oAttack,oVictim)
    local oCamp = oAttack:GetCamp()
    local iRatio = oAttack:Query("double_call_ratio",500)
    if oAttack:IsAwake()  and in_random(iRatio,10000) then
        return 2
    end
    return 1
end

function CPerform:TargetList(oAttack)
    local mTarget = super(CPerform).TargetList(self,oAttack)
    local mRet = {}
    local oCamp = oAttack:GetCamp()
    local iCallCnt = oCamp:CallNpcAmount()
    for _,oTarget in pairs(mTarget) do
        if oTarget:IsPartner() and oTarget:IsDead() and not oTarget:GetData("call_partner") and #mRet + iCallCnt < 2 then
            table.insert(mRet,oTarget)
        end
    end
    return mRet
end

function CPerform:CallPartner(oAttack,oVictim)
    local oWar = oAttack:GetWar()
    local iCamp = oAttack:GetCampId()
    local iWid = oAttack:GetWid()
    local oCamp = oAttack:GetCamp()
    if not oCamp:ValidCallNpc() then
        return
    end
    local mPerform = table_deep_copy(oVictim:GetData("perform"))
    mPerform[1001] = 1
    local mData = {
        model_info = oVictim:GetData("model_info"),
        name = oVictim:GetData("name"),
        grade = oVictim:GetData("grade"),
        max_hp = oVictim:GetData("max_hp"),
        hp = math.floor(oVictim:GetData("max_hp")/2),
        attack = oVictim:GetData("attack"),
        defense = oVictim:GetData("defense"),
        critical_ratio = oVictim:GetData("critical_ratio"),
        res_critical_ratio = oVictim:GetData("res_critical_ratio"),
        critical_damage = oVictim:GetData("critical_damage"),
        cure_critical_ratio = oVictim:GetData("cure_critical_ratio"),
        abnormal_attr_ratio = oVictim:GetData("abnormal_attr_ratio"),
        res_abnormal_ratio = oVictim:GetData("res_abnormal_ratio"),
        speed = oVictim:GetData("speed"),
        perform = mPerform,
        awake = oVictim:GetData("awake"),
        auto_skill = oVictim:GetData("auto_skill"),
        double_attack_suspend = oVictim:GetData("double_attack_suspend"),
        partner_call = iWid,
    }
    local oActionMgr = global.oActionMgr
    local oPartner = oActionMgr:PerformSummonWarrior(oAttack,iCamp,mData)
    if oPartner then
        oPartner:SetAIType(gamedefines.AI_TYPE.COMMON)
        oPartner:SetData("IgnoreCmd",true)
    end
    oVictim:SetData("call_partner",true)
end

function CPerform:Perform(oAttack,lVictim)
    local oWar = oAttack:GetWar()
    local iWid = oAttack:GetWid()
    local iSkill = self.m_ID
    oAttack:SendAll("GS2CWarSkill", {
        war_id = oAttack:GetWarId(),
        action_wlist = {oAttack:GetWid(),},
        select_wlist = {},
        skill_id = iSkill,
        magic_id = 1,
    })
    local iTime = self:PerformMagicTime()
    oWar:AddAnimationTime(iTime,{skill=self:Type(),mgi=1})
    for _,oVictim in pairs(lVictim) do
        self:TruePerform(oAttack,oVictim)
    end
    local oNewAttack = oWar:GetWarrior(iWid)
    if oNewAttack and not oNewAttack:IsDead() then
        oAttack:OnPerform(lVictim,self)
        oAttack.m_oBuffMgr:CheckAttackBuff(oAttack)
        self:Effect_Condition_For_Attack(oAttack)
        if self:IsCD(oAttack) then
            self:SetCD(oAttack)
        end
    end
end

function CPerform:TruePerform(oAttack,oVictim)
    if oVictim:IsAlive() then
        return
    end
    if not oVictim:IsPartner() then
        return
    end
    local oCamp = oAttack:GetCamp()
    self:CallPartner(oAttack,oVictim)
end

--[[
function CPerform:OnNoChooseTarget(oAttack)
    if not oAttack:IsPartner() then
        return
    end
    local iOwner = oAttack:GetData("owner")
    if not iOwner then
        return
    end
    local oWar = oAttack:GetWar()
    local oPlayer = oWar:GetWarrior(iOwner)
    if oPlayer then
        oPlayer:Notify(string.format("对方无死亡单位，无法施放%s",self:Name()))
    end
end
]]