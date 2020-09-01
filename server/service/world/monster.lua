--import module
local global = require "global"

function NewMonster(...)
    return CMonster:New(...)
end


CMonster = {}
CMonster.__index = CMonster
inherit(CMonster,logic_base_cls())

function CMonster:New(mData)
    local o = super(CMonster).New(self)
    o.m_mData = mData
    return o
end

function CMonster:GetAttr(sAttr)
    return self.m_mData[sAttr]
end

function CMonster:SetAttr(sAttr,val)
    self.m_mData[sAttr] = val
end

function CMonster:PackAttr()
    local mRet = {}
    --mRet.id = self.m_ID
    mRet.grade = self:GetAttr("grade")
    mRet.name = self:GetAttr("name")
    mRet.hp = self:GetAttr("hp") or self:GetAttr("maxhp")
    mRet.max_hp = self:GetAttr("maxhp")
    mRet.model_info = self:GetAttr("model_info")
    mRet.attack = self:GetAttr("attack")
    mRet.defense = self:GetAttr("defense")
    mRet.critical_ratio = self:GetAttr("critical_ratio")
    mRet.res_critical_ratio = self:GetAttr("res_critical_ratio")
    mRet.critical_damage = self:GetAttr("critical_damage")
    mRet.cure_critical__ratio = self:GetAttr("cure_critical_ratio")
    mRet.abnormal_attr_ratio = self:GetAttr("abnormal_attr_ratio")
    mRet.res_abnormal_ratio = self:GetAttr("res_abnormal_ratio")
    mRet.speed = self:GetAttr("speed")
    mRet.perform = self:GetAttr("perform")
    mRet.perform_ai = self:GetAttr("perform_ai")
    mRet.double_attack_suspend = self:GetAttr("double_attack_suspend")
    mRet.data = self:GetAttr("extra_data")
    mRet.special_skill = self:GetAttr("special_skill")
    mRet.boss = self:GetAttr("boss")
    mRet.show_skil = self:GetAttr("show_skill")
    mRet.pos = self:GetAttr("pos")
    mRet.monsterid = self:GetAttr("type")
    mRet.ai = self:GetAttr("ai")
    mRet.show_lv = self:GetAttr("show_lv")
    return mRet
end