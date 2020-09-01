--import module
local global = require "global"
local interactive = require "base.interactive"
local gamedefines = import(lualib_path("public.gamedefines"))
local basewar = import(service_path("warobj"))
local partnerwarrior = import(service_path("partnerwarrior"))

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)


function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "terrawars"
    return o
end

function CWar:Init(mInit,mExtra)
    super(CWar).Init(self,mInit,mExtra)
    self.m_iDefender = mInit.defender
end

function CWar:Leave(oWarrior)
    if oWarrior:IsRomPartner() and not oWarrior:GetData("friend") and oWarrior:GetCampId() == 1 then
        local iWid = oWarrior:GetData("owner")
        local oOwner = self:GetWarrior(iWid)
        local iPid = oOwner:GetPid()
        local iParId = oWarrior:GetData("parid")
        local iRestHp = oWarrior:GetHp()
        local iWarId = self:GetWarId()
        interactive.Send(".world","terrawars","RecordRomPartnerHp",{pid=iPid,par_id=iParId,hp=iRestHp,war_id=iWarId})
    end
    super(CWar).Leave(self,oWarrior)
end

function CWar:LeaveRomPartner(oAction,bWin,iPid)
    local iRestHp = oAction:GetHp()
    local iWarId = self:GetWarId()
    local iParId = oAction:GetData("parid")
    interactive.Send(".world","terrawars","RecordRomPartnerHp",{pid=iPid,par_id=iParId,win=bWin,hp=iRestHp,war_id=iWarId})
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

-- function CWar:Enter(obj,iCamp)
--     super(CWar).Enter(self,obj,iCamp)
--     if obj:GetHp() <= 0 then
--         obj.m_oStatus:Set(gamedefines.WAR_WARRIOR_STATUS.DEAD)
--     end
-- end
function CWar:WarStartConfig(mInfo)
    for iWid,_ in pairs(self.m_mWarriors) do
        local oAction = self:GetWarrior(iWid)
        if oAction:GetHp() <= 0 then
            oAction.m_oStatus:Set(gamedefines.WAR_WARRIOR_STATUS.DEAD)
        end
    end
    self:SendWarStartWarrior()
    local iSecs = 20
    self.m_iWarStatus = gamedefines.WAR_STATUS.CONFIG
    self.m_iWarConfigTime = get_time() + 20
    local mExcule = {}
    if mInfo and mInfo["terrawars_defender"] then
        for k,_ in pairs(self.m_mWarriors) do
            local o = self:GetWarrior(k)
            if o:IsPlayer() and o:GetPid() == mInfo["terrawars_defender"] then
                mExcule[k] = true
                break
            end
        end
    end
    self:SendAll("GS2CWarConfig",{
        war_id = self.m_iWarId,
        secs = iSecs,
    },mExcule)
    self:DelTimeCb("WarStartConfig")
    local iWarId = self:GetWarId()
    local oWarMgr = global.oWarMgr
    self:AddTimeCb("WarStartConfig",iSecs*1000 + self:BaseOperateTime(),function ()
        local oWar = oWarMgr:GetWar(iWarId)
        oWar:DelTimeCb("WarStartConfig")
        oWar:WarStart(mInfo)
    end)
    self:CleanFightPartner()
end

function CWar:AddPartner(oPlayer,iPos,mPartnerData,mArgs)
    mArgs = mArgs or {}
    local iCamp = oPlayer:GetCampId()
    local iWid = oPlayer:GetWid()
    local mData = mPartnerData["partnerdata"]
    local iParId = mData["parid"]
    local mFightPartner = oPlayer:GetTodayFightPartner()
    if mFightPartner[iParId] then
        return
    end
    if mArgs["replace"] and self:IsConfig() then
        mFightPartner[mArgs["replace"]] = nil
    end
    mFightPartner[iParId] = 1
    oPlayer:Set("fight_partner",mFightPartner)
    local iPartnerWid = self:DispatchWarriorId()
    local oPartner = partnerwarrior.NewPartnerWarrior(iPartnerWid)
    if oPartner then
        oPartner:Init({
            camp_id = iCamp,
            war_id = self:GetWarId(),
            data = mData,
        })
        oPartner:SetData("owner",iWid)
        self.m_lCamps[iCamp]:EnterPartner(oPartner,iPos)
        self.m_mWarriors[oPartner:GetWid()] = iCamp

        if oPlayer:IsOpenAutoFight() and oPartner:GetData("auto_skill",0) == 0 then
            local iNormalAttack = oPartner:GetNormalAttackSkillId()
            oPartner:SetAutoSkill(iNormalAttack)
        end
        if oPartner:GetHp() <= 0 then
            oPartner.m_oStatus:Set(gamedefines.WAR_WARRIOR_STATUS.DEAD)
        end
        if mArgs.add_type == 1 then
            self:SendAll("GS2CWarAddWarrior", {
                war_id = self.m_iWarId,
                camp_id = iCamp,
                type = oPartner:Type(),
                partnerwarrior = oPartner:GetSimpleWarriorInfo(),
                add_type = mArgs.add_type,
            })
        end
    end
    return oPartner
end

function CWar:WarEnd()
    self:DelTimeCb("WarEndEffect")
    self:DelTimeCb("WarEnd")

    self:DelTimeCb("WarStartConfig")
    self:DelTimeCb("BoutProcess")

    local mWinWarrior = self:GetWarriorList(self.m_iWarResult) or {}
    local iFailPos = 1
    if self.m_iWarResult == 1 then
        iFailPos = 2
    end
    local mFailWarrior = self:GetWarriorList(iFailPos) or {}
    local mWinList = {}
    local mFailList = {}
    local mEscapeList = self:GetEscapeList()
    local mPlayerPartner = {}
    local f =function (mWarrior,bWin)
        for _,oAction in pairs(mWarrior) do
            if oAction:IsPlayer() then
                if bWin then
                    table.insert(mWinList,oAction:GetPid())
                else
                    table.insert(mFailList,oAction:GetPid())
                end
            elseif oAction:IsPartner() then
                local iWid = oAction:GetData("owner")
                local oWarrior = self:GetWarrior(iWid)
                if oWarrior and oWarrior:IsPlayer() then
                    local iPid = oWarrior:GetPid()
                    local mPartner = mPlayerPartner[iPid] or {}
                    mPartner[oAction:GetData("parid")] = oAction:PackInfo()
                    mPlayerPartner[iPid] = mPartner
                    if iPid == self.m_iDefender then
                        local iParId = oAction:GetData("parid")
                        local iRestHp = oAction:GetHp()
                        local iWarId = self:GetWarId()
                        interactive.Send(".world","terrawars","RecordRomPartnerHp",{pid=iPid,par_id=iParId,hp=iRestHp,war_id=iWarId})
                    end
                end
            elseif oAction:IsRomPlayer() then
                self:LeaveRomPlayer(oAction,bWin)
            elseif oAction:IsRomPartner() then
                local iWid = oAction:GetData("owner")
                local oWarrior = self:GetWarrior(iWid)
                if oWarrior and (oWarrior:IsPlayer() or oWarrior:IsRomPlayer())then
                    local iPid = oWarrior:GetPid()
                    local mPartner = mPlayerPartner[iPid] or {}
                    mPartner[oAction:GetData("parid")] = oAction:PackInfo()
                    mPlayerPartner[iPid] = mPartner
                    self:LeaveRomPartner(oAction,bWin,iPid)
                end
            end
        end
    end
    f(mWinWarrior,true)
    f(mFailWarrior,false)

    local mArgs = self:ExtendWarEndArg({
        win_side = self.m_iWarResult,
        win_list = mWinList,
        fail_list = mFailList,
        escape_list = mEscapeList,
        fight_partner = mPlayerPartner,
        current_wave = self:CurrentEnemyWave(),
        bout = self.m_iBout,
        star_time = self.m_iStarTime,
    })

    local l = table_key_list(self.m_mPlayers)
    for _, iPid in ipairs(l) do
        self:LeavePlayer(iPid)
    end
    local l = table_key_list(self.m_mObservers)
    for _, iPid in ipairs(l) do
        self:LeaveObserver(iPid)
    end
    mArgs.war_film_data = self.m_oRecord:PackFilmData()
    interactive.Send(".world", "war", "RemoteEvent", {event = "remote_war_end", data = {
        war_id = self:GetWarId(),
        war_info = mArgs,
    }})
end

function CWar:WarStart(mInfo)
    local mWarrior1 = self:GetWarriorList(1) or {}
    local mWarrior2 = self:GetWarriorList(2) or {}
    for _,oAction in pairs(mWarrior1) do
        oAction:SetPerform(1011,1)
    end
    for _,oAction in pairs(mWarrior2) do
        oAction:SetPerform(1011,1)
    end
    super(CWar).WarStart(self,mInfo)
end