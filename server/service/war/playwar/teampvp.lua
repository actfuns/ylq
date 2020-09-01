--import module
local global = require "global"
local interactive = require "base.interactive"
local record = require "public.record"

local basewar = import(service_path("warobj"))

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)


function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "teampvp"
    return o
end


function CWar:CheckWarWarPartner(oPlayer,mPartner)
    if self:IsConfig() then
        return true
    end
    local mFightPartner = oPlayer:GetTodayFightPartner()
    if table_count(mFightPartner) >= 2 then
        oPlayer:Notify("同场最多可上阵2个伙伴")
        return false
    end
    return true
end

function CWar:BoutStart()
    if self.m_iBout == 0 then
        -- 收录伙伴信息
        local mWarrior1 = self:GetWarriorList(1) or {}
        local mWarrior2 = self:GetWarriorList(2) or {}

        local mWarrior= {}
        list_combine(mWarrior,mWarrior1)
        list_combine(mWarrior,mWarrior2)
        for _,oAction in pairs(mWarrior) do
            if oAction:IsPartner() then
                local iWid = oAction:GetData("owner")
                local oWarrior = self:GetWarrior(iWid)
                if oWarrior and oWarrior:IsPlayer() then
                    local iPid = oWarrior:GetPid()
                    local oPlayer = self:GetPlayerWarrior(iPid)
                    local mFightPartner = oPlayer:Query("today_fight",{})
                    mFightPartner[oAction:GetData("parid")] = 1
                    oPlayer:Set("today_fight",mFightPartner)
                end
            end
        end
    end
    super(CWar).BoutStart(self)
end

function CWar:WarStart(mInfo)
    super(CWar).WarStart(self,mInfo)
    local mWarrior1 = self:GetWarriorList(1) or {}
    local mWarrior2 = self:GetWarriorList(2) or {}

    local mWarrior= {}
    list_combine(mWarrior,mWarrior1)
    list_combine(mWarrior,mWarrior2)
    self.m_WarMessage = {}



    local f = function(mWarriorList)
        local mPlayer = {}
        local mResultMsg = {}
        for _,oAction in ipairs(mWarriorList) do
            if oAction:IsPlayer() then
                local iPid = oAction.m_iPid
                local sName = oAction:GetName()
                local iShape = oAction:GetData("model_info")["shape"]
                local iGrade = oAction:GetData("grade",0)
                local iCamp = oAction:GetCampId()
                local iLeader = oAction:GetData("is_team_leader")
                if not mPlayer[iPid] then
                    mPlayer[iPid] = {}
                    mPlayer[iPid]["parlist"] = {}
                end

                mPlayer[iPid].pid = iPid
                mPlayer[iPid].name = sName
                mPlayer[iPid].shape = iShape
                mPlayer[iPid].grade = iGrade
                mPlayer[iPid].leader = iLeader
                local info = {
                    pid = iPid,
                    name = sName,
                    shape = iShape,
                    camp = iCamp,
                    leader = iLeader,
                    }
                table.insert(mResultMsg,info)
            elseif oAction:IsPartner() then
            	   local iWid = oAction:GetData("owner")
                local oPlayer = self:GetWarrior(iWid)
                local iPid = oPlayer:GetPid()
                if not mPlayer[iPid] then
                    mPlayer[iPid] = {}
                    mPlayer[iPid]["parlist"] = {}
                end
                local mPack = oAction:PackInfo()
                local iShape = oAction:GetModelInfo()["shape"]
                local res = require "base.res"
                local iPar = res["daobiao"]["partner_item"]["shape2type"][iShape] or mPack["type"]
                local mPartner = {
                par = iPar,
                grade = mPack["grade"],
                shape = iShape,
                star = oAction:GetData("star",1)
                }
                table.insert(mPlayer[iPid]["parlist"],mPartner)
            end
        end
        local m = {}
        for pid,info in pairs(mPlayer) do
            table.insert(m,info)
        end
        return m,mResultMsg
    end
    local plist1,info1 = f(mWarrior1)
    local plist2,info2 = f(mWarrior2)
    self.m_WarMessage={info1,info2}
    local mNet = {plist1=plist1,plist2=plist2}
    self:SendAll("GS2CShowTeamPVPWarConfig",mNet)
end

function CWar:CleanFightPartner()
end


function CWar:ExtendWarEndArg(mArgs)
    mArgs["show_end"] = self.m_WarMessage
    return mArgs
end

function CWar:OnLeavePlayer(obj, bEscape)
    local mPartnerInfo = {}
    local mFightPar = {}
    for k,_ in pairs(self.m_mWarriors) do
        local oWarrior = self:GetWarrior(k)
        if oWarrior:IsPartner() and oWarrior:GetData("owner") == obj:GetWid() then
            mPartnerInfo[oWarrior:GetData("parid")] = oWarrior:GetData("auto_skill")
            mFightPar[oWarrior:GetData("parid")] = oWarrior:PackInfo()
        end
    end
    local mFightPartner = obj:GetTodayFightPartner()
    for iParId,_ in pairs(mFightPartner) do
        if not mPartnerInfo[iParId] then
            mPartnerInfo[iParId] = 0
        end
    end
    local iPid = obj:GetPid()
    self:RemoteWorldEvent("remote_leave_player",{
        war_id = self:GetWarId(),
        pid = iPid,
        escape = bEscape,
        is_dead = obj:IsDead(),
        auto_skill = obj:GetData("auto_skill",0),
        auto_skill_switch = obj:GetData("auto_skill_switch",0),
        partner_info = mPartnerInfo,
        fight_partner = {[iPid] = mFightPar},
        show_end = self.m_WarMessage,
        wind_side = obj:GetCampId() == 1 and 2 or 1
    })
end




function CWar:OperateTime()
    if self.m_iBout == 1 then
        return 44*1000
    else
        return 40*1000
    end
end

function CWar:OnWarStart()
    super(CWar).OnWarStart(self)
    local func = function (oWarrior)
        local oWar = oWarrior:GetWar()
        local iBout = oWar.m_iBout
        return (iBout//5)*500
    end
    for k,_ in pairs(self.m_mWarriors) do
        local o = self:GetWarrior(k)
        if o then
            o:AddFunction("OnCalDamageRatio","ClubarenaBout",func)
        end
    end
end