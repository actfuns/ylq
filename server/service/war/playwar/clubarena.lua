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
    o.m_sWarType = "clubarena"
    return o
end


function CWar:WarStart(mInfo)
    local mWarrior1 = self:GetWarriorList(1) or {}
    local mWarrior2 = self:GetWarriorList(2) or {}

    local mWarrior= {}
    list_combine(mWarrior,mWarrior1)
    list_combine(mWarrior,mWarrior2)
    self.m_WarMessage = {}
    self.m_RecordMessage = {}
    -- 机器人等级按照玩家来算
    local iRobotPartnerGrade = 1
    local iRobotGrade = 1
    local f = function(mWarriorList)
        local mPlayer = {}
        local mInfo = {
            player = {},
            club = 1,
            upordown = 0,
            }
        mPlayer.parlist = {}
        for _,oAction in ipairs(mWarriorList) do
            if oAction:IsPlayer() or oAction:IsRomPlayer() then
                local iPid = oAction.m_iPid
                local iShape = oAction:GetData("model_info")["shape"]
                local sName = oAction:GetName()
                local iGrade = oAction:GetData("grade",0)
                local iCamp = oAction:GetCampId()
                self.m_RecordMessage[iPid] = {
                    target = iPid,
                    name = sName,
                    shape = iShape,
                    grade = iGrade,
                    }

                mInfo["player"] = {
                    pid = iPid,
                    name = sName,
                    shape = iShape,
                    camp = iCamp,
                    }
                mPlayer.pid = oAction.m_iPid
                mPlayer.name = oAction:GetName()
                mPlayer.shape = oAction:GetData("model_info")["shape"]
                mPlayer.grade = oAction:GetData("grade",0)
                mPlayer.camp = oAction:GetCampId()
                iRobotGrade = iGrade
                iRobotPartnerGrade = iGrade
            elseif oAction:IsPartner() or oAction:IsRomPartner() then
                local mPack = oAction:PackInfo()
                local iShape = oAction:GetModelInfo()["shape"]
                local res = require "base.res"
                local iPar = res["daobiao"]["partner_item"]["shape2type"][iShape] or mPack["type"]
                local mPartner = {
                par = iPar,
                grade = mPack["grade"],
                shape = iShape,
                }
                table.insert(mPlayer.parlist,mPartner)
            elseif oAction:IsNpc() then
                if oAction:IsBoss() then
                    local sName = oAction:GetName()
                    local iShape = oAction:GetData("model_info")["shape"]
                    local iCamp = oAction:GetCampId()
                    mPlayer.pid = 0
                    mPlayer.name = sName
                    mPlayer.shape = iShape
                    mPlayer.grade = oAction:GetData("show_lv",0)
                    mInfo["player"] = {
                        pid = 0,
                        name = sName,
                        shape = iShape,
                        camp = iCamp,
                        }
                    self.m_RecordMessage[0] = {
                        target = 0,
                        name = sName,
                        shape = iShape,
                        grade = iRobotGrade,
                        }
                else
                    local iGrade = oAction:GetData("show_lv",0)
                    local iShape = oAction:GetModelInfo()["shape"]
                    local res = require "base.res"
                    local iPar = res["daobiao"]["partner_item"]["shape2type"][iShape] or 0
                    local mPartner = {
                    par = iPar,
                    grade = iGrade,
                    shape = iShape,
                    }
                    table.insert(mPlayer.parlist,mPartner)
                end
            end
        end
        return mPlayer,mInfo
    end
    local plist1,mInfo1 = f(mWarrior1)
    local plist2,mInfo2 = f(mWarrior2)
    local mNet = {plist={plist1,plist2},}
    self.m_WarMessage ={info1=mInfo1,info2 = mInfo2,}
    self:SendAll("GS2CShowClubArenaWarConfig",mNet)
    local iTimeOut = 4000
    local iWarId = self:GetWarId()
    self:DelTimeCb("Arenagame_WarStart")
    self:AddTimeCb("Arenagame_WarStart",iTimeOut,function ()
               local oWar = global.oWarMgr:GetWar(iWarId)
               if oWar then
                        super(CWar).WarStart(oWar,mInfo)
                end
    end)
end

function CWar:OnWarEscape(oPlayer,iActionWid)
    local iCamp = oPlayer.m_iCamp
    if iCamp == 1 then
        self.m_iWarResult = 2
    else
        self.m_iWarResult = 1
    end
    self:WarEndEffect()
end


function CWar:ExtendWarEndArg(mArgs)
    mArgs["show_end"] = self.m_WarMessage
    mArgs["record"] = self.m_RecordMessage
    return mArgs
end


function CWar:WarEnd()
    if self.m_WarMessage then
        local mNet = {
            result = self.m_iWarResult,
            info1 = self.m_WarMessage["info1"],
            info2 = self.m_WarMessage["info2"],
            }
        local sMessage = "GS2CClubArenaFightResult"
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