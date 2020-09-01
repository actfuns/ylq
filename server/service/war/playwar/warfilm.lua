--import module

local interactive = require "base.interactive"
local global = require "global"

local gamedefines = import(lualib_path("public.gamedefines"))
local basewar = import(service_path("warobj"))

CWarFilm = {}
CWarFilm.__index = CWarFilm
inherit(CWarFilm, basewar.CWar)

function NewWar(...)
    local o = CWarFilm:New(...)
    o.m_sWarType = "warfilm"
    return o
end

function CWarFilm:New(id)
    local o = super(CWarFilm).New(self,id)
    o.m_mBoutCmd = {}
    o.m_mClientPacket = {}
    o.m_mBoutCmd = {}
    o.m_iBoutEnd = 0
    return o
end

function CWarFilm:Init(mData)
    mData = mData or {}
    self.m_mBoutCmd = mData.bout_cmd or self.m_mBoutCmd
    self.m_mClientPacket = mData.client_packet or self.m_mClientPacket
    self.m_mBoutTime = mData.bout_time or self.m_mBoutTime
    self.m_iBoutEnd = mData.bout_end or self.m_iBoutEnd
    self.m_iBout = 0
end

function CWarFilm:IsBoutEnd()
    if self.m_iBout < self.m_iBoutEnd then
        return false
    end
    return true
end

function CWarFilm:GetBoutStartTime(iBout)
    iBout = iBout or self.m_iBout
    if iBout == 0 then
        return 5 * 1000
    end
    return 60*1000
end

function CWarFilm:GetBoutClientPacketData(iBout)
    iBout = iBout or self.m_iBout
    iBout = tostring(iBout)
    return self.m_mClientPacket[iBout] or {}
end

function CWarFilm:GetBoutCmd(iBout)
    iBout = tostring(iBout)
    local mBoutCmd = self.m_mBoutCmd[iBout] or {}
    return mBoutCmd
end

function CWarFilm:WarStart()
    local mClientPacketData = self:GetBoutClientPacketData(self.m_iBout)
    self:BoutPlay(mClientPacketData)
end

--按记录时间播放一回合数据,暂时这样处理
function CWarFilm:BoutPlay(mClientPacketData)
    local oWarMgr = global.oWarMgr
    local iWarId = self:GetWarId()
    mClientPacketData = mClientPacketData or {}
    self:TrueBoutPlay(mClientPacketData)
    local iTime = self:GetBoutStartTime(self.m_iBout)
    if not self:IsBoutEnd() then
        if iTime <= 0 then
            self:BoutStart()
        else
            self:AddTimeCb("BoutStart",iTime,function ()
                local oWar = oWarMgr:GetWar(iWarId)
                oWar:BoutStart()
            end)
        end
    else
        self:WarEnd()
    end
end

function CWarFilm:TrueBoutPlay(mClientPacket)
    if #mClientPacket <= 0 then
        return
    end
    for _,mPacketInfo in ipairs(mClientPacket) do
        local sMessage,mData = table.unpack(mPacketInfo)
        for _,o in pairs(self.m_mObservers) do
            o:Send(sMessage,mData)
        end
    end
end

function CWarFilm:BoutProcess()
    self:DelTimeCb("BoutStart")
    self:DelTimeCb("BoutProcess")
    local mClientPacketData = self:GetBoutClientPacketData(self.m_iBout)
    self:BoutPlay(mClientPacketData)
end

function CWarFilm:BoutStart()
    self:DelTimeCb("BoutStart")
    self:DelTimeCb("BoutProcess")
    self.m_iBout = self.m_iBout + 1
    local mBoutCmd = self:GetBoutCmd(iBout)
    self:TruePlayBoutCmd(mBoutCmd)
    self:BoutProcess()
end

function CWarFilm:TruePlayBoutCmd(mClientPacket)
    if #mClientPacket <= 0 then
        return
    end
    for _,mPacketInfo in pairs(mClientPacket) do
        local sMessage,mData = table.unpack(mPacketInfo)
        for iPid, o in pairs(self.m_mObservers) do
            o:Send(sMessage,mData)
        end
    end
end

function CWarFilm:LeaveObserver(iPid)
    super(CWarFilm).LeaveObserver(self,iPid)
    if table_count(self.m_mObservers) <= 0 then
        self:WarEnd()
    end
end

function CWarFilm:WarEnd()
    self:DelTimeCb("BoutPlay")
    self:DelTimeCb("BoutStart")
    self:DelTimeCb("WarEnd")
    local l = table_key_list(self.m_mObservers)
    for _, iPid in ipairs(l) do
        self:LeaveObserver(iPid)
    end
    local mArgs = {
    }

    interactive.Send(".world", "war", "RemoteEvent", {event = "remote_end_warfilm", data = {
        war_id = self:GetWarId(),
        war_info = mArgs,
    }})
end

function CWarFilm:NextFilmBout(iBout)
    if iBout - 1 ~= self.m_iBout  or self:IsBoutEnd()then
        return
    end
    self:BoutStart()
end


