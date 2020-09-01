local global = require "global"
local skynet = require "skynet"
local geometry = require "base.geometry"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

function NewTrapmineAI(...)
    return CTrapmineAI:New(...)
end

CTrapmineAI = {}
CTrapmineAI.__index = CTrapmineAI
inherit(CTrapmineAI,logic_base_cls())

function CTrapmineAI:New(iPid,mArgs)
    local o = super(CTrapmineAI).New(self)
    o.m_iPid = iPid
    o.m_iMapId = mArgs.map_id
    o.m_iScene = mArgs.scene_id
    o.m_iEid = mArgs.eid
    o.m_mPos = mArgs.pos_info or {}
    o.m_bInWar = mArgs.in_war or false
    o.m_iStep = 1
    o.m_mWalkPath = {}
    o.m_iWalkStep = 0
    o:CheckCurStep()
    return o
end

function CTrapmineAI:CheckCurStep()
    local res = require "base.res"
    local lPos = res["daobiao"]["patrol"][self.m_iMapId]
    local mNowPos = self:GetPos()
    local iCurStep = 0
    for _,mPos in ipairs(lPos) do
        iCurStep = iCurStep + 1
        if mNowPos.x == mPos.x and mNowPos.y == mPos.y then
            break
        end
    end
    if iCurStep > #lPos then
        record.warning(string.format("client ai pid:%d,map:%d,x:%d,y:%d",self.m_iPid,self.m_iMapId,mNowPos.x,mNowPos.y))
        return
    end
    self.m_iStep = iCurStep
end

function CTrapmineAI:GetMapRes()
    local res = require "base.res"
    local iMapRes = res["daobiao"]["map"][self.m_iMapId]["resource_id"]
    return iMapRes
end

function CTrapmineAI:GetPathData(sSrcPos,sDestPos)
    local res = require "base.res"
    local iMapRes = self:GetMapRes()
    local mData = res["client_trapmine"][iMapRes] or {}
    assert(mData,string.format("client ai err,map:%d",self.m_iMapId))
    mData = mData[sSrcPos][sDestPos]
    assert(mData,string.format("client ai err,map:%d,src:%s,dest:%s",self.m_iMapId,sSrcPos,sDestPos))
    return mData
end

function CTrapmineAI:GetPos()
    return self.m_mPos
end

function CTrapmineAI:SetPos(mNewPos)
    local mPos = self.m_mPos
    mPos.x = mNewPos.x or mPos.x
    mPos.y = mNewPos.y or mPos.y
end

function CTrapmineAI:GetNextStep()
    local res = require "base.res"
    local iCurStep = self.m_iStep
    local iMap = self.m_iMapId
    local lPos = res["daobiao"]["patrol"][iMap]
    if iCurStep == #lPos then
        return iCurStep - 1
    end
    if iCurStep == 1 then
        return iCurStep + 1
    end
    if math.random(100) < 50 then
        return iCurStep + 1
    else
        return iCurStep - 1
    end
end

function CTrapmineAI:AIStart()
    local oAIMgr = global.oAIMgr
    local iPid = self.m_iPid
    local fCallback
    fCallback = function ()
        local oAI = oAIMgr:GetOfflineTrapMineAI(iPid)
        if not oAI or oAI:InWar() then
            return
        end
        oAI:DelTimeCb("trapmine_run")
        local iTime = oAI:StartRun()
        if iTime > 0 then
            oAI:AddTimeCb("trapmine_run", iTime, fCallback)
        end
    end
    fCallback()
end

function CTrapmineAI:NewWalkPath()
    local res = require "base.res"
    local lPos = res["daobiao"]["patrol"][self.m_iMapId]
    local iCurStep = self.m_iStep
    local iNextStep = self:GetNextStep()
    local mNowPos = lPos[iCurStep]
    local mNextPos = lPos[iNextStep]
    local sCurPos = string.format("%s,%s",mNowPos.x,mNowPos.y)
    local sNextPos = string.format("%s,%s",mNextPos.x,mNextPos.y)
    local lPath = self:GetPathData(sCurPos,sNextPos)
    self.m_mWalkPath = lPath
    self.m_iWalkStep = 0
    self.m_iStep = iNextStep
end

function CTrapmineAI:StartRun()
    if #self.m_mWalkPath <= self.m_iWalkStep + 1 then
        self:NewWalkPath()
    end
    local lPos = {}
    local iTime = 1000
    local iLen = #self.m_mWalkPath
    local iStart = self.m_iWalkStep + 1
    local mPos = self.m_mWalkPath[iStart]
    table.insert(lPos, {
        time = 1000,
        pos = {x = mPos.x, y = mPos.y}
    })
    local iFinishWalk = math.min(self.m_iWalkStep+3,iLen)
    for i = iStart+1,iFinishWalk do
        local m1 = self.m_mWalkPath[i]
        local m2
        if i < iFinishWalk then
            m2 = self.m_mWalkPath[i+1]
        end
        if m2 then
            table.insert(lPos, {
                time = 1000,
                pos = {x = m1.x, y = m1.y}
            })
            iTime = iTime + 1000
        else
            table.insert(lPos, {
                time = 0,
                pos = {x = m1.x, y = m1.y}
            })
        end
        self.m_iWalkStep = self.m_iWalkStep + 1
    end
    self:C2GSSyncPosQueue(lPos)
    return iTime
end

function CTrapmineAI:C2GSSyncPosQueue(lPos)
    local mData = {
        pid = self.m_iPid,
        scene_id = self.m_iScene,
        poslist = lPos,
        eid = self.m_iEid
    }
    interactive.Send(".world", "client", "C2GSSyncPosQueue",mData)
end

function CTrapmineAI:AIStop()
    self:DelTimeCb("trapmine_run")
end

function CTrapmineAI:EnterWar()
    self.m_bInWar = true
    self:DelTimeCb("trapmine_run")
end

function CTrapmineAI:LeaveWar(oPlayer)
    self.m_bInWar = false
    self:AIStart()
end

function CTrapmineAI:InWar()
    return self.m_bInWar
end