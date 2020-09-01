
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CWarrior = import(service_path("warrior")).CWarrior
local pfload = import(service_path("perform/pfload"))


function NewPartnerWarrior(...)
    return CPartnerWarrior:New(...)
end

function NewRomPartnerWarrior( ... )
    return CRomPartnerWarrior:New(...)
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


CPartnerWarrior = {}
CPartnerWarrior.__index = CPartnerWarrior
inherit(CPartnerWarrior, CWarrior)

function CPartnerWarrior:New(iWid)
    local o = super(CPartnerWarrior).New(self, iWid)
    o.m_iType = gamedefines.WAR_WARRIOR_TYPE.PARTNER_TYPE
    o.m_iAIType = gamedefines.AI_TYPE.AI_SMART
    return o
end

function CPartnerWarrior:GetSimpleWarriorInfo()
    return {
        wid = self:GetWid(),
        pos = self:GetPos(),
        pflist = self:GetPerformLevelList(),
        owner = self:GetData("owner"),
        parid = self:GetData("parid"),
        status = self:GetSimpleStatus()
    }
end

function CPartnerWarrior:GetSimpleStatus(m)
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

function CPartnerWarrior:StatusChange(...)
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

function CPartnerWarrior:GetNormalAttackSkillId()
    local mPerform = self:GetPerformList()
    for _,iPerform in pairs(mPerform) do
        if iPerform % 10 == 1 then
            return iPerform
        end
    end
    if not mPerform or #mPerform < 1 then
        local record = require "public.record"
        local iWid = self:GetData("owner")
        local oWar = self:GetWar()
        local oPlayer = self:GetWarrior(iWid)
        local sPlayer = ""
        if oPlayer then
            sPlayer = oPlayer:GetName()
        end
        record.error(string.format("null skill %s %s %s ",self:GetName(),mPerform,sPlayer))
    end
    return mPerform[math.random(#mPerform)]
end

function CPartnerWarrior:GetAutoSkill()
    local iWid = self:GetData("owner")
    local oWar = self:GetWar()
    local oPlayer = self:GetWarrior(iWid)
    local iAutoSkill = self:GetData("auto_skill")
    if not oPlayer then
        if not iAutoSkill or iAutoSkill == 0 then
            iAutoSkill = self:ChooseSkillAuto()
        end
        return iAutoSkill
    end
    if oPlayer:IsOpenAutoFight() then
        if not iAutoSkill or iAutoSkill == 0 then
            iAutoSkill = self:ChooseSkillAuto()
        end
        return iAutoSkill
    end
    return 0
end

function CPartnerWarrior:PackInfo()
    return {
        type = self:GetData("type"),
        parid = self:GetData("parid"),
        name = self:GetData("name"),
        effect_type = self:GetData("effect_type"),
        grade = self:GetData("grade"),
        exp = self:GetData("exp"),
        equip = self:GetData("equip"),
    }
end

function CPartnerWarrior:IsTestMan()
    local iWid = self:GetData("owner")
    local oWar = self:GetWar()
    local oPlayer = self:GetWarrior(iWid)
    if not oPlayer then
        return false
    end
    if oPlayer:GetData("testman") ==  99 then
        return true
    end
    return false
end

function CPartnerWarrior:GetFunction(sFunction)
    local mFunction = super(CPartnerWarrior).GetFunction(self,sFunction)
    local mCallback = {}
    for iNo,fCallback in pairs(mFunction) do
        local oPf = self.m_oPerformMgr:GetPerform(iNo)
        if oPf then
            if oPf:IsPassiveSkill() then
                local iRet = self:BanPassiveSkill()
                if not iRet then
                    mCallback[iNo] = fCallback
                elseif iRet == 1 then
                    if not pfload.IsPartnerESkill(iNo) then
                        mCallback[iNo] = fCallback
                    end
                end
            else
                mCallback[iNo] = fCallback
            end
        else
            mCallback[iNo] = fCallback
        end
    end
    return mCallback
end

function CPartnerWarrior:BanCampPassiveSkill(iNo)
    local oPf = self.m_oPerformMgr:GetPerform(iNo)
    if oPf then
        if oPf:IsPassiveSkill() then
            local iRet = self:BanPassiveSkill()
            if iRet and ((iRet == 2) or (iRet == 1 and pfload.IsPartnerESkill(iNo))) then
                return true
            else
                return false
            end
        else
            return false
        end
    else
        return true
    end
end

function CPartnerWarrior:GetMaster()
    local oWar = self:GetWar()
    return oWar:GetWarrior(self:GetData("owner"))
end

function CPartnerWarrior:AutoCommand()
    if self:GetActionCmd() then
        return
    end
    local oPlayer = self:GetMaster()
    if not oPlayer:IsOpenAutoFight() then
        oPlayer:SyncAutoFight()
    end
    super(CPartnerWarrior).AutoCommand(self)
end

function CPartnerWarrior:GetAutoFightTime()
    local oPlayer = self:GetMaster()
    local oWar = self:GetWar()
    if oPlayer:IsOpenAutoFight() and oWar.m_ActionId > 1 then
        return 0
    end
    if not self:ValidAction() then
        return 1
    end
    local oWar = self:GetWar()
    if oWar:IsSinglePlayer() then
        return 15
    else
        return 10
    end
end

function CPartnerWarrior:GetBoutAutoFightTime()
    local oPlayer = self:GetMaster()
    return oPlayer:GetBoutAutoFightTime()
end

function CPartnerWarrior:SpecialRatio(iPerform)
    local oPlayer = self:GetMaster()
    return oPlayer:SpecialRatio(iPerform)
end

function CPartnerWarrior:Send(sMessage, mData)
    local oPlayer = self:GetMaster()
    oPlayer:Send(sMessage,mData)
end

CRomPartnerWarrior = {}
CRomPartnerWarrior.__index = CRomPartnerWarrior
inherit(CRomPartnerWarrior, CPartnerWarrior)

function CRomPartnerWarrior:New(iWid)
    local o = super(CRomPartnerWarrior).New(self, iWid)
    o.m_iType = gamedefines.WAR_WARRIOR_TYPE.ROM_PARTNER_TYPE
    o.m_iAIType = gamedefines.AI_TYPE.ROM_AI_SMART
    return o
end

