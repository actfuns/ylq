--import module
local global = require "global"
local interactive = require "base.interactive"

local baselink = import(service_path("link.linkobj"))


CLink = {}
CLink.__index = CLink
inherit(CLink, baselink.CLink)

function NewCLink(...)
    return CLink:New(...)
end

function CLink:SetLink(oPlayer,mNetData,mArgs)
    local fCallback = function (mRecord,mData)
        self:OnSetLink(oPlayer,mNetData,mData)
    end
    oPlayer.m_oItemCtrl:GetEquipLinkList(oPlayer,fCallback)
end

function CLink:PackLink(oPlayer,mData,mEquip)
    local lEquipInfo = {}
    for iPos, mEequipData in pairs(mEquip) do
        table.insert(lEquipInfo, {pos = iPos, equip = mEequipData})
    end
    local mInfo = {
        pid = oPlayer:GetPid(),
        grade = oPlayer:GetGrade(),
        name = oPlayer:GetName(),
        title_info = oPlayer:PackTitleInfo(),
        max_hp = oPlayer:GetMaxHp(),
        hp = oPlayer:GetHp(),
        attack = oPlayer:GetAttack(),
        defense = oPlayer:GetDefense(),
        speed = oPlayer:GetSpeed(),
        critical_ratio = oPlayer:GetCirticalRatio(),
        res_critical_ratio = oPlayer:GetResCriticalRatio(),
        critical_damage = oPlayer:GetCriticalDamage(),
        cure_critical_ratio = oPlayer:GetCureCriticalRatio(),
        abnormal_attr_ratio = oPlayer:GetAbnormalAttrRatio(),
        res_abnormal_ratio = oPlayer:GetResAbnormalRatio(),
        model_info = oPlayer:GetModelInfo(),
        school = oPlayer:GetSchool(),
        orgname = oPlayer:GetOrgName(),
        warpower = oPlayer:GetWarPower(),
        equip = lEquipInfo,
    }
    return  {player = mInfo}
end
