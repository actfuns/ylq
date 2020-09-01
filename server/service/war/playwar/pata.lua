--import module
local global = require "global"
local interactive = require "base.interactive"

local basewar = import(service_path("warobj"))

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)


function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "pata"
    return o
end

function CWar:LeavePlayer(iPid,bEscape)
    local oPlayer = self:GetPlayerWarrior(iPid)
    local iWid = oPlayer:GetWid()
    local lFriend = oPlayer:GetFriendList(true)
    for _,oFriend in pairs(lFriend) do
        if oFriend:IsPartner() and oFriend:GetData("owner") == iWid and not oFriend:GetData("friend") then
            local iRestHp = oFriend:GetHp()
            local iParId = oFriend:GetData("parid")
            interactive.Send(".world","pata","RecordPtnHp",{pid=iPid,parid=iParId,hp=iRestHp})
        end
    end
    super(CWar).LeavePlayer(self,iPid,bEscape)
end

function CWar:Leave(oWarrior)
    if oWarrior:IsPartner() and not oWarrior:GetData("friend") then
        local iWid = oWarrior:GetData("owner")
        local oOwner = self:GetWarrior(iWid)
        local iPid = oOwner:GetPid()
        local iParId = oWarrior:GetData("parid")
        local iRestHp = oWarrior:GetHp()
        interactive.Send(".world","pata","RecordPtnHp",{pid=iPid,parid=iParId,hp=iRestHp})
    end
    super(CWar).Leave(self,oWarrior)
end

function CWar:CheckWarWarPartner(oPlayer,mPartner)
    for _,mFightData in pairs(mPartner) do
        local mPartnerData = mFightData["partnerdata"]["partnerdata"]
        if mPartnerData and mPartnerData["hp"] <= 0 then
            oPlayer:Notify("该伙伴阵亡")
            return false
        end
    end
    return true
end

function CWar:Enter(obj, iCamp)
    local oParWarrior = super(CWar).Enter(self,obj, iCamp)
    if oParWarrior:IsPartner() and not oParWarrior:GetData("friend") then
        local fCallback = function (oWarrior,iHP)
            if oWarrior:IsPartner() and not oWarrior:GetData("friend") then
                local iWid = oWarrior:GetData("owner")
                local oOwner = self:GetWarrior(iWid)
                local iPid = oOwner:GetPid()
                local iParId = oWarrior:GetData("parid")
                local iRestHp = oWarrior:GetHp()
                interactive.Send(".world","pata","RecordPtnHp",{pid=iPid,parid=iParId,hp=iRestHp})
            end
        end
        oParWarrior:AddFunction("OnAddHp",99999,fCallback)
        oParWarrior:AddFunction("OnSubHp",99999,fCallback)
    end
    return oParWarrior
end

function CWar:OnLeavePlayer(obj, bEscape)
    if bEscape then
        obj:Send("GS2CWarResult", {
            war_id = self:GetWarId(),
            win_side = 2,
            })
    end
    super(CWar).OnLeavePlayer(self,obj,bEscape)
end