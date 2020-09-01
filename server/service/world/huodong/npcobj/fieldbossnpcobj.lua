--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"
local templ = import(service_path("templ"))
local npcobj = import(service_path("npc/npcobj"))

CBoss = {}
CBoss.__index = CBoss
CBoss.m_sName = "fieldboss"
inherit(CBoss, npcobj.CNpc)

function NewBoss(mArgs)
    local o = CBoss:New(mArgs)
    return o
end

function CBoss:New(mArgs)
    local o = super(CBoss).New(self)
    o:Init(mArgs)
    return o
end

function CBoss:Init(mArgs)
    local mArgs = mArgs or {}
    self.m_bIsBoss = true
    self.m_iOwner = mArgs.owner or 0
    self.m_sSysName = mArgs.sys_name
    self.m_iType = mArgs["type"]
    self.m_iMapid = mArgs["map_id"] or 0
    self.m_mModel = mArgs["model_info"] or {}
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iEvent = mArgs["event"] or 0
    self.m_iReUse = mArgs["reuse"] or 0
    self.m_iBossId = mArgs["bossid"]
    self.m_iBossGrade = mArgs["boss_level"]
    self.m_iBornHp = mArgs["born_hp"] or 10000
    self.m_iCurHp = mArgs["curhp"] or self.m_iBornHp
end

function CBoss:Save()
    local mData = {}
    mData.curhp = self.m_iCurHp
    return mData
end

function CBoss:Load(mData)
    self.m_iCurHp = mData.curhp
end

function CBoss:GetGrade()
    return self.m_iBossGrade
end

function CBoss:GetBornHp()
    return self.m_iBornHp
end

function CBoss:GetCurHp()
    return self.m_iCurHp
end

function CBoss:GetCurHpRate()
    return (self.m_iCurHp/self.m_iBornHp)*100
end

function CBoss:SetCurHpRate(iRate)
    self.m_iCurHp = self.m_iBornHp*iRate/100
end

function CBoss:IsDead()
    return self.m_iCurHp <= 0
end

function CBoss:HPCHange(iHp)
    self.m_iCurHp = self.m_iCurHp-iHp
    if self.m_iCurHp < 0 then
        self.m_iCurHp = 0
        self:SetDeadTime(get_time())
    end
end

function CBoss:SetDeadTime(iTime)
    self.m_iDeadTime = iTime
end

function CBoss:GetDeadTime()
    return self.m_iDeadTime or 0
end

function CBoss:GetData(iNpcType)
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["npc"][iNpcType]
end

function CBoss:GetID()
    return self.m_iBossId
end

function CBoss:GetBossBaseData()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sSysName]["fieldboss_config"]
    assert(mData[self.m_iBossId],string.format("miss terra config:%s,%d",self.m_sSysName,self.m_iBossId))
    return mData[self.m_iBossId]
end

function CBoss:GetData(iNpcType)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sSysName]["npc"]
    assert(mData[iNpcType],string.format("miss npc config:%s,%d",self.m_sSysName,iNpcType))
    return mData[iNpcType]
end

function CBoss:GetBornMap()
    local mData = self:GetBossBaseData(self.m_iBossId)
    return mData["born_map"]
end

function CBoss:GetWarMap()
    local mData = self:GetBossBaseData(self.m_iBossId)
    return mData["war_mapid"]
end

function CBoss:do_look(oPlayer)
    if self.m_oHuodong then
        self.m_oHuodong:do_look(oPlayer, self)
    end
end

function CBoss:PackSceneInfo()
    local mNet = super(CBoss).PackSceneInfo(self)
    return mNet
end
