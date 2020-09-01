--import module
local global  = require "global"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))

function NewSchedule(id)
    return CSchedule:New(id)
end

CSchedule = {}
CSchedule.__index = CSchedule
inherit(CSchedule,datactrl.CDataCtrl)

function CSchedule:New(scheduleid)
    local o = super(CSchedule).New(self)
    o:SetData("id", scheduleid)
    return o
end

function CSchedule:Init(mArg)
    self:SetData("pid",mArg.pid)
end

function CSchedule:QueryInfo(key,default)
    local res = require "base.res"
    local mData = res["daobiao"]["schedule"]["public"][self:GetData("id")]
    return mData[key] or default
end

function CSchedule:Load(mData)
    local mData = mData or {}
    self:SetData("id", mData.id)
    self:SetData("times", mData.times)
    self:SetData("point", mData.point)
end

function CSchedule:Save()
    local mData = {}
    mData.id = self:GetData("id")
    mData.times = self:GetData("times")
    mData.point = self:GetData("point")
    return mData
end

function CSchedule:ID()
    return self:GetData("id")
end

function CSchedule:Type()
    return self:QueryInfo("type",1)
end

function CSchedule:GetMaxTimes()
    return self:QueryInfo("maxfinish")
end

function CSchedule:GetMaxPoints()
    return self:QueryInfo("maxactive",0)
end

function CSchedule:GetActivePoint()
    return self:GetData("point",0)
end

function CSchedule:GetPerPoints()
    return self:QueryInfo("active",0)
end

function CSchedule:PlayName()
    return self:QueryInfo("huodong")
end


function CSchedule:HuoDong()
    return global.oHuodongMgr:GetHuodong(self:PlayName())
end

function CSchedule:Player()
    return global.oWorldMgr:GetOnlinePlayerByPid(self:GetData("pid"))
end

function CSchedule:AddActivePoint(mArgs)
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local iMaxPoint = self:GetMaxPoints()
    local iPoint = self:GetActivePoint()
    if iPoint >= iMaxPoint then
        return
    end
    local iTimes = self:GetDoneTimes()

    if iTimes <= 0 or iTimes%self:QueryInfo("addlimit") ~= 0 then
        return
    end
    local iAdd = self:GetPerPoints()
    if iPoint + iAdd > iMaxPoint then
        iAdd = math.max(iMaxPoint - iPoint,0)
    end
    self:SetData("point", iPoint + iAdd)

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetData("pid"))
    if oPlayer then
        local  mLog=  {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        add = iAdd,
        schedule = self:GetData("id"),
        point = self:GetData("point"),
        }
        record.user("schedule","add_active",mLog)
        oPlayer:RewardActive(iAdd,string.format("日程 %d",self:GetData("id")),mArgs)
    end
end

function CSchedule:AddDoneTimes()
    local iMaxTimes = self:GetMaxTimes()
    if not iMaxTimes then
        return
    end
    if self:GetDoneTimes() >= iMaxTimes then
        return
    end
    local oWorldMgr  = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetData("pid"))
    local  mLog=  {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        add = iAdd,
        schedule = self:GetData("id"),
        done = self:GetDoneTimes() + 1,
        }
    record.user("schedule","schedule_change",mLog)
    local iTimes = self:GetDoneTimes() + 1
    self:SetData("times", iTimes)
    return iTimes
end

function CSchedule:GetDoneTimes()
    return self:GetData("times",0)
end


function CSchedule:GetLeftTime(oPlayer)
    return nil
end

function CSchedule:GetBuyTime(oPlayer)
    return nil
end

function  CSchedule:GetFlag(oPlayer)
    return nil
end

function CSchedule:GetSum(oPlayer)
    return nil
end

function CSchedule:GetCount(oPlayer)
    return nil
end

function CSchedule:Add(mArgs)
    if not self:CheckGradeLimit() and not  mArgs["today"] then
        return
    end
    local iResult = self:AddDoneTimes()
    self:AddActivePoint(mArgs)
    return iResult
end


function CSchedule:IsDone()
    return self:GetActivePoint() >= self:GetMaxPoints()
end


function CSchedule:PackData()
    return {
        scheduleid = self:GetData("id"),
        done_cnt = self:GetDoneTimes(),
        maxtimes = self:GetMaxTimes(),
    }
end

function CSchedule:PackState(oPlayer)
    local oHuodongMgr = global.oHuodongMgr
    local mHDState = oHuodongMgr:GetHuodongState(self:PlayName())
    local m = {}
    m["scheduleid"] = self:GetData("id")
    m["done_cnt"] = self:GetDoneTimes()
    m["maxtimes"] = self:GetMaxTimes()
    m["activepoint"] = self:GetActivePoint()
    if mHDState then
        m["state"] = mHDState["state"]
    end
    local iBuy = self:GetBuyTime(oPlayer)
    if iBuy then
        m["buy"] = iBuy
    end
    local iFlag = self:GetFlag(oPlayer)
    if iFlag then
        m["flag"] = iFlag
    end
    local iSum = self:GetSum(oPlayer)
    if iSum then
        m["sum"] = iSum
    end
    local iCount = self:GetCount(oPlayer)
    if iCount then
        m["count"] = iCount
    end
    local iLeft = self:GetLeftTime(oPlayer)
    if iLeft then
        m["left"] = iLeft
    end
    return m
end


function CSchedule:CheckGradeLimit()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetData("pid"))
    if oPlayer then
        local mGrade = self:QueryInfo("grade")
        return mGrade["min"] <= oPlayer:GetGrade() and oPlayer:GetGrade() <= mGrade["max"]
    end
    return false
end

function CSchedule:ClickSchedule(oPlayer)
    
end

function CSchedule:GameStart(oPlayer)
    oPlayer:Send("GS2COpenScheuleUI",{scheduleid = self:ID()})
end

function CSchedule:SetScheduleStatus(oPlayer,iStatus)
    -- body
    if iStatus == gamedefines.SCHEDULE_TYPE.GAME_START then
        self:GameStart(oPlayer)
    elseif iStatus == gamedefines.SCHEDULE_TYPE.GAME_OVER then
        self:GameOver(oPlayer)
    end
end

function  CSchedule:GameOver(oPlayer)
    -- body
    oPlayer:Send("GS2CCloseScheuleUI",{scheduleid = self:ID()})
end
