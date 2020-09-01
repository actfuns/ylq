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
    o.m_sWarType = "equalarena"
    return o
end



function CWar:ExtendWarEndArg(mArgs)
    local mArg = super(CWar).ExtendWarEndArg(self,mArgs) or {}
     mArg.arena_partner = self.m_ArenaPartner or {}
    return  mArg
end

function CWar:OnWarEscape(oPlayer,iActionWid)
    local iCamp = oPlayer.m_iCamp
    if iCamp == 1 then
        self.m_iWarResult = 2
    else
        self.m_iWarResult = 1
    end
    if not self.m_mEscapePlayers[iCamp] then
        self.m_mEscapePlayers[iCamp] = {}
    end
    table.insert(self.m_mEscapePlayers[iCamp],oPlayer:GetPid())
    self:WarEndEffect()

end


function CWar:WarStart(mInfo)
    self.m_WarMessage = {}
    local mWarrior1 = self:GetWarriorList(1) or {}
    local mWarrior2 = self:GetWarriorList(2) or {}
    local mPlayerPartner = {}
    local mWarrior= {}
    list_combine(mWarrior,mWarrior1)
    list_combine(mWarrior,mWarrior2)
    for _,oAction in pairs(mWarrior) do
        if oAction:IsPlayer() or (oAction:IsNpc() and oAction:IsBoss()) then
            local iCamp = oAction:GetCampId()
            local info = {
                name = oAction:GetName(),
                shape = oAction:GetModelInfo()["shape"],
                camp = iCamp,
                }
            if oAction:IsPlayer() then
                info["pid"] = oAction:GetPid()
            else
                info["pid"] = 0
            end
            table.insert(self.m_WarMessage,info)
        elseif oAction:IsPartner() then
            local iShape = oAction:GetData("model_info").shape
            local iWid = oAction:GetData("owner")
            local oWarrior = self:GetWarrior(iWid)
            if oWarrior and oWarrior:IsPlayer() then
                local iPid = oWarrior:GetPid()
                local mPartner = mPlayerPartner[iPid] or {}
                mPartner[db_key(oAction:GetData("parid"))] = iShape
                mPlayerPartner[iPid] = mPartner
            end
        end
    end
    self.m_ArenaPartner = mPlayerPartner

    -- 机器人等级按照玩家来算
    local iRobotPartnerGrade = 1
    local iRobotGrade = 0
    local f = function(mWarriorList)
        local mPlayer = {}
        mPlayer.parlist = {}
        for _,oAction in ipairs(mWarriorList) do
            if oAction:IsPlayer() then
                mPlayer.pid = oAction.m_iPid
                mPlayer.name = oAction:GetName()
                mPlayer.shape = oAction:GetData("model_info")["shape"]
                mPlayer.grade = oAction:GetData("grade",0)
                iRobotGrade = oAction:GetData("grade",0)
            elseif oAction:IsPartner() then
                local mPack = oAction:PackInfo()
                local iShape = oAction:GetModelInfo()["shape"]
                local res = require "base.res"
                local iPar = res["daobiao"]["partner_item"]["shape2type"][iShape] or mPack["type"]
                local mPartner = {
                par = iPar,
                grade = mPack["grade"],
                shape = iShape,
                }
                iRobotPartnerGrade = iRobotPartnerGrade + mPack["grade"]
                table.insert(mPlayer.parlist,mPartner)
            end
        end
        return mPlayer
    end
    local mNet = {f(mWarrior1),f(mWarrior2)}
    self:SendAll("GS2CShowEqualArenaWarConfig",{plist=mNet})
    
    local iTimeOut = 3000
    local iWarId = self:GetWarId()
    if iTimeOut > 0 then
        self:DelTimeCb("Arenagame_WarStart")
        self:AddTimeCb("Arenagame_WarStart",iTimeOut,function ()
                   local oWar = global.oWarMgr:GetWar(iWarId)
                   if oWar then
                            super(CWar).WarStart(oWar,mInfo)
                    end
        end)
    else
        super(CWar).WarStart(oWar,mInfo)
    end
end


function CWar:WarEnd()
    if self.m_WarMessage then
        local mNet = {
            result = self.m_iWarResult,
            info = self.m_WarMessage,
            }
        local sMessage = "GS2CEqualArenaFightResult" 
        if self:IsWarRecord() then
            self.m_oRecord:AddClientPacket(sMessage,mNet)
        end
        self:SendObserver(sMessage,mNet)
    end
    super(CWar).WarEnd(self)
end

function CWar:GS2CWarWave(oAction)
    -- 竞技场不显示波数
end

function CWar:OperateTime()
    if self.m_iBout == 1 then
        return 44*1000
    else
        return 40*1000
    end
end

