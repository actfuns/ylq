--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"
local templ = import(service_path("templ"))
local npcobj = import(service_path("npc/npcobj"))

CItemObj = {}
CItemObj.__index = CItemObj
CItemObj.m_sName = "fieldboss"
inherit(CItemObj, npcobj.CNpc)

function NewItem(mArgs)
    local o = CItemObj:New(mArgs)
    return o
end

function CItemObj:New(mArgs)
    local o = super(CItemObj).New(self)
    o:Init(mArgs)
    return o
end

function CItemObj:Init(mArgs)
    local mArgs = mArgs or {}
    self.m_iOwner = mArgs.owner or 0
    self.m_sSysName = mArgs.sys_name
    self.m_iType = mArgs["type"]
    self.m_iMapid = mArgs["map_id"] or 0
    self.m_mModel = mArgs["model_info"] or {}
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iEvent = mArgs["event"] or 0
    self.m_iReUse = mArgs["reuse"] or 0
    self.m_iBossId = mArgs["bossid"]
    self.m_iSceneId = mArgs["scene"]
    self.m_iRewardId = mArgs["rewardid"]
    self.m_iPickStatus = 0
    self.m_iCanPick = 0
end

function CItemObj:GetData(iNpcType)
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["npc"][iNpcType]
end

function CItemObj:GetBossID()
    return self.m_iBossId
end

function CItemObj:GetBossBaseData()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sSysName]["fieldboss_config"]
    assert(mData[self.m_iBossId],string.format("miss terra config:%s,%d",self.m_sSysName,self.m_iBossId))
    return mData[self.m_iBossId]
end

function CItemObj:GetData(iNpcType)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sSysName]["npc"]
    assert(mData[iNpcType],string.format("miss npc config:%s,%d",self.m_sSysName,iNpcType))
    return mData[iNpcType]
end

function CItemObj:do_look(oPlayer)
    if self.m_iPickStatus ~= 0 then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"宝箱正在被拾取中……")
        return
    end
    local iNpcId = self.m_ID
    self.m_iPickStatus = oPlayer.m_iPid
    local iBossId = self.m_iBossId
    local func  =function(oP,mData)
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        local oBossBattle = oHuodong.m_mBossBattle[iBossId]
        if oBossBattle then
            local oNpc = oBossBattle:GetNpcObj(iNpcId)
            if oNpc then
                if oNpc.m_iPickStatus == oP.m_iPid then
                    if mData.answer == 0 then
                        oNpc:ClearStatus()
                    elseif oNpc.m_iCanPick == 1 then
                        oNpc:ClearStatus()
                        oBossBattle:Pick(oP,oNpc)
                    end
                else
                    return
                end
            end
        end
    end
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(oPlayer.m_iPid,"GS2CStartPick",{time = 5},nil,func)

    local func1 = function()
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        local oBossBattle = oHuodong.m_mBossBattle[iBossId]
        if oBossBattle then
            local oNpc = oBossBattle:GetNpcObj(iNpcId)
            if oNpc then
                oNpc:SetCanPick()
            end
        end
    end
    self:DelTimeCb("SetCanPick")
    self:AddTimeCb("SetCanPick",5*990,func1)

    local func2 = function()
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        local oBossBattle = oHuodong.m_mBossBattle[iBossId]
        if oBossBattle then
            local oNpc = oBossBattle:GetNpcObj(iNpcId)
            if oNpc then
                oNpc:ClearStatus()
            end
        end
    end
    self:DelTimeCb("ClearStatus")
    self:AddTimeCb("ClearStatus",8*1000,func2)
end

function CItemObj:SetCanPick()
    self:DelTimeCb("SetCanPick")
    self.m_iCanPick = 1
end

function CItemObj:PackSceneInfo()
    local mNet = super(CItemObj).PackSceneInfo(self)
    return mNet
end

function CItemObj:ClearStatus()
    self:DelTimeCb("SetCanPick")
    self:DelTimeCb("ClearStatus")
    self.m_iPickStatus = 0
    self.m_iCanPick = 0
end