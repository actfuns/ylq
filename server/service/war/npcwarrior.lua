
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CWarrior = import(service_path("warrior")).CWarrior

function NewNpcWarrior(...)
    return CNpcWarrior:New(...)
end


StatusHelperFunc = {}

function StatusHelperFunc.hp(o)
    return o:GetHp()
end

function StatusHelperFunc.max_hp(o)
    return o:GetMaxHp()
end

function StatusHelperFunc.model_info(o)
    return o:GetModelInfo()
end

function StatusHelperFunc.name(o)
    return o:GetName()
end

function StatusHelperFunc.status(o)
    return o.m_oStatus:Get()
end

function StatusHelperFunc.auto_skill(o)
    return o:GetAutoSkill()
end


CNpcWarrior = {}
CNpcWarrior.__index = CNpcWarrior
inherit(CNpcWarrior, CWarrior)

function CNpcWarrior:New(iWid)
    local o = super(CNpcWarrior).New(self, iWid)
    o.m_iType = gamedefines.WAR_WARRIOR_TYPE.NPC_TYPE  
    return o
end

--召唤物可以选招
function CNpcWarrior:GetSimpleWarriorInfo()
    local iBoss = 0
    if self:IsBoss() then
        iBoss = 1
    end
    if not self:GetData("owner") then
        return {
            wid = self:GetWid(),
            pos = self:GetPos(),
            special_skill = self:GetSpecialSkillInfo(),
            status = self:GetSimpleStatus(),
            w_type = iBoss,
            show_skill = self:GetData("show_skil",{}),
            show_lv = self:GetData("show_lv",0),
        }
    else
        return {
            wid = self:GetWid(),
            pos = self:GetPos(),
            pflist = self:GetPerformList(),
            owner = self:GetData("owner"),
            special_skill = self:GetSpecialSkillInfo(),
            status = self:GetSimpleStatus(),
            w_type = iBoss,
            show_skill = self:GetData("show_skil",{}),
            show_lv = self:GetData("show_lv",0),
        }
    end
end

function CNpcWarrior:GetSimpleStatus(m)
    local mRet = {}
    if not m then
        m = StatusHelperFunc
    end
    for k, _ in pairs(m) do
        local f = assert(StatusHelperFunc[k], string.format("GetSimpleStatus fail f get %s", k))
        mRet[k] = f(self)
    end
    return net.Mask("base.WarriorStatus", mRet)
end

function CNpcWarrior:StatusChange(...)
    local l = table.pack(...)
    local m = {}
    for _, v in ipairs(l) do
        m[v] = true
    end
    local mStatus = self:GetSimpleStatus(m)
    self:SendAll("GS2CWarWarriorStatus", {
        war_id = self:GetWarId(),
        wid = self:GetWid(),
        type = self:Type(),
        status = mStatus,
    })
end

function CNpcWarrior:GetNormalAttackSkillId()
    local mPerform = self:GetPerformList()
    for _,iPerform in pairs(mPerform) do
        if iPerform % 10 == 1 then
            return iPerform
        end
    end
    return mPerform[math.random(#mPerform)]
end

function CNpcWarrior:ValidAddBoutCmd()
    if self:GetData("owner") and not self:GetData("IgnoreCmd") then
        return true
    end
    return false
end

function CNpcWarrior:GetAutoSkill()
    local iWid = self:GetData("owner")
    if not iWid then
        return 0
    end
    local oWar = self:GetWar()
    local oPlayer = self:GetWarrior(iWid)
    if not oPlayer:IsPlayer() then
        return self:GetData("auto_skill")
    end
    if oPlayer:IsOpenAutoFight() then
        return self:GetData("auto_skill")
    end
    return 0
end

function CNpcWarrior:GetSpecialSkillInfo()
    local mSpecialSkill = self:GetData("special_skill")
    if not mSpecialSkill then
        return {}
    end
    local mData = {
        skill_id = mSpecialSkill["skill_id"],
        sum_grid = mSpecialSkill["sum_grid"],
        cur_grid = mSpecialSkill["cur_grid"],
    }
    return mData
end

function CNpcWarrior:GetSpecialSkill()
    local mSpecialSkill = self:GetData("special_skill",{})
    local iSpecial = mSpecialSkill["skill_id"] or 0
    return iSpecial
end

function CNpcWarrior:IsSpecialSkill(iSkill)
    local iSpecialSkill = self:GetSpecialSkill()
    if iSpecialSkill ~= iSkill then
        return false
    end
    return true
end

function CNpcWarrior:OnBoutEnd()
    super(CNpcWarrior).OnBoutEnd(self)
    local iSpecial = self:GetSpecialSkill()
    if iSpecial and not self:IsDead() then
        self:AddSpecialSkillGrid()
    end
end

function CNpcWarrior:AddSpecialSkillGrid(iGrid)
    iGrid = iGrid or 1
    local iSpecialSkill = self:GetSpecialSkill()
    if iSpecialSkill == 0 then
        return
    end
    local mSpecialSkill = self:GetData("special_skill",{})
    mSpecialSkill["cur_grid"] = (mSpecialSkill["cur_grid"] or 0) + 1
    self:SetData("special_skill",mSpecialSkill)
end

function CNpcWarrior:ResetSpecialSkillGrid()
    local mSpecialSkill = self:GetData("special_skill",{})
    mSpecialSkill["cur_grid"] = 0
    self:SetData("special_skill",mSpecialSkill)
end

--特殊技能是否在cd中
function CNpcWarrior:IsSpecialSkillCD()
    local mSpecialSkill = self:GetData("special_skill",{})
    if not mSpecialSkill["skill_id"] then
        return true
    end
    local iSumGrid = mSpecialSkill["sum_grid"]
    if not iSumGrid then
        return true
    end
    local iCurGrid = mSpecialSkill["cur_grid"]
    if not iCurGrid then
        return true
    end
    if iCurGrid < iSumGrid then
        return true
    end
    return false
end

function CNpcWarrior:IsAwake()
    return true
end




