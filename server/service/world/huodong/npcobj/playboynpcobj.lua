--import module

local global = require "global"
local extend = require "base.extend"
local npcobj = import(service_path("npc/npcobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
local geometry = require "base.geometry"
local record = require "public.record"

CPlayBoyNpc = {}
CPlayBoyNpc.__index = CPlayBoyNpc
inherit(CPlayBoyNpc, npcobj.CNpc)

function NewClientNpc(mArgs)
    local o = CPlayBoyNpc:New(mArgs)
    return o
end

function CPlayBoyNpc:New(mArgs)
    local o = super(CPlayBoyNpc).New(self)
    o:Init(mArgs)
    return o
end

function CPlayBoyNpc:Init(mArgs)
    local mArgs = mArgs or {}
    self.m_sSysName = mArgs.sys_name
    self.m_iType = mArgs["type"]
    self.m_sSysName = mArgs["sys_name"]
    self.m_iMapid = mArgs["map_id"] or 0
    self.m_mModel = mArgs["model_info"] or {}
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iEvent = mArgs["event"] or 0
    self.m_iReUse = mArgs["reuse"]

    self.m_iOwner = mArgs.owner
    self.m_mReward = mArgs.reward
    self.m_iHasChangePos = mArgs.haschangepos or 0
    self.m_iCreateTime = mArgs.createtime or get_time()
    self.m_iDoneTime = mArgs.donetime or 0
    if not self.m_mReward then
        self:InitReward()
    end
    self:CountDown()
end

function CPlayBoyNpc:Save()
    local data = {}
    data["type"] = self.m_iType
    data["map_id"] = self.m_iMapid
    data["model_info"] = self.m_mModel
    data["pos_info"] = self.m_mPosInfo

    data["reuse"]  = self.m_iReUse
    data["event"] = self.m_iEvent
    data.owner = self.m_iOwner
    data.reward = self.m_mReward
    data.haschangepos = self.m_iHasChangePos
    data.createtime = self.m_iCreateTime
    data.donetime = self.m_iDoneTime
    data.sys_name = self.m_sSysName
    return data
end

function CPlayBoyNpc:SetEvent(iEvent)
    self.m_iEvent = iEvent
end

function CPlayBoyNpc:CheckTimeOut()
    local iCurTime = get_time()
    if (iCurTime - self.m_iCreateTime) >= 10*60*1000 then
        return true
    end
    return false
end

function CPlayBoyNpc:CountDown()
    local iNpcId = self.m_ID
    local iOwner = self.m_iOwner

    local iTime = self:Timer()
    if iTime <= 0 then
        self:TimeOut()
        return
    end
    self:DelTimeCb("timeout")
    self:AddTimeCb("timeout",iTime, function()
        local oWorldMgr = global.oWorldMgr
        local oP = oWorldMgr:GetOnlinePlayerByPid(iOwner)
        if not oP then
            return
        end
        local oNpc = oP.m_oHuodongCtrl:GetNpcByID("playboynpc",iNpcId)
        if not oNpc then
            return
        end
        oNpc:TimeOut()
    end)
end

function CPlayBoyNpc:Timer()
    local iCurTime = get_time()
    return (10*60 - (iCurTime - self.m_iCreateTime))*1000
end

function CPlayBoyNpc:TimeOut()
    self:DelTimeCb("timeout")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    if oPlayer then
        oPlayer.m_oHuodongCtrl:RemoveClientNpc("playboynpc",self.m_ID,"timeout")
    end
end

function CPlayBoyNpc:PackInfo()
    local mData = {
            npctype = self.m_iType,
            npcid      = self.m_ID,
            name = self:GetName(),
            title = self:GetTitle(),
            map_id = self.m_iMapid,
            pos_info = self:GetPos(),
            model_info = self.m_mModel,
            createtime = self.m_iCreateTime,
            sceneid = self.m_iScene,
    }
    return mData
end

function CPlayBoyNpc:GetPos()
    local mPos = self.m_mPosInfo
    local pos_info = {
            x = math.floor(geometry.Cover(mPos.x)),
            y = math.floor(geometry.Cover(mPos.y)),
            z = math.floor(geometry.Cover(mPos.z)),
            face_x = math.floor(geometry.Cover(mPos.face_x)),
            face_y = math.floor(geometry.Cover(mPos.face_y)),
            face_z = math.floor(geometry.Cover(mPos.face_z)),
        }
     return pos_info
end

function CPlayBoyNpc:InitReward()
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("treasure")
    local mReward = oHuodong:RandomPlayBoyReward()
    self.m_mReward = mReward
end

function CPlayBoyNpc:DoScript(pid,s,mArgs)
    if type(s) ~= "table" then
        return
    end
    for _,ss in pairs(s) do
        self:DoScript2(pid,ss,mArgs)
    end
end

function CPlayBoyNpc:DoScript2(pid,s,mArgs)
    if string.sub(s,1,2) == "DI" then
        local iDialog = string.sub(s,3,-1)
        iDialog = tonumber(iDialog)
        self:GS2CDialog(pid,iDialog)
    elseif string.sub(s,1,7) == "PLAYBOY" then
        self:ShowPlayBoyDialog()
    end
end

function CPlayBoyNpc:GetEventData(iEvent)
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"]["treasure"]["event"][iEvent]
    assert(mData,string.format("Not Event Config:%s",self.m_iType))
    return mData
end

function CPlayBoyNpc:GetCostBaseData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"]["treasure"]["playboy_cost"]
    assert(mData,string.format("Not PlayBoyCost Config:%s",self.m_iType))
    return mData
end

function CPlayBoyNpc:GetDialogBaseData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"]["treasure"]["dialog"]
    assert(mData,string.format("Not PlayBoyDialog Config:%s",self.m_iType))
    return mData
end

function CPlayBoyNpc:GetDialogInfo(iDialog)
    local mData = self:GetDialogBaseData()
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CPlayBoyNpc:do_look(oPlayer)
    local mEvent = self:GetEventData(self.m_iEvent)
    self:DoScript(self.m_iOwner,mEvent["look"])
end

function CPlayBoyNpc:GetCostInfo()
    local mCostData = self:GetCostBaseData()
    for _,info in pairs(mCostData) do
        if info.times == (self.m_iDoneTime + 1) then
            return table_deep_copy(info)
        end
    end
end

function CPlayBoyNpc:GS2CDialog(iPid,iDialog)
    local mDialogInfo = self:GetDialogInfo(iDialog)
    if not mDialogInfo then
        return
    end
    local m = {}
    m["dialog"] = {{
        ["type"] = mDialogInfo["type"],
        ["pre_id_list"] = mDialogInfo["pre_id_list"],
        ["content"] = mDialogInfo["content"],
        ["voice"] = mDialogInfo["voice"],
        ["last_action"] = mDialogInfo["last_action"],
        ["next"] = mDialogInfo["next"],
        ["ui_mode"] = mDialogInfo["ui_mode"],
        ["status"] = mDialogInfo["status"],
    }}
    m["dialog_id"] = iDialog
    m["npc_id"] = self.m_ID
    m["npc_name"] = self.m_sName
    m["shape"] = self:Shape()
    m["playboyinfo"] = {endtime = self:Timer()/1000}
    local iNpcId = self.m_ID
    local iOwner = self.m_iOwner
    local func = function(oPlayer,mArgs)
        if mArgs.answer and mArgs.answer ~= 0 then
            local oWorldMgr = global.oWorldMgr
            local oP = oWorldMgr:GetOnlinePlayerByPid(iOwner)
            if not oP then
                return
            end
            local oNpc = oP.m_oHuodongCtrl:GetNpcByID("playboynpc",iNpcId)
            if not oNpc then
                return
            end
            local m = oNpc:GetDialogInfo(iDialog)
            local event = m["last_action"][mArgs.answer]["event"]
            if event then
                local oWorldMgr = global.oWorldMgr
                oNpc:DoScript(iOwner,{event})
            end
        end
    end
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    local iSessionidx = oCbMgr:SetCallBack(self.m_iOwner,"GS2CDialog",m,nil,func)
    oPlayer.m_oHuodongCtrl:AddNpcSessionId(self.m_ID,iSessionidx)
end

function CPlayBoyNpc:ShowPlayBoyDialog()
    local mCostInfo = self:GetCostInfo()
    local mNet = {}
    local text = "准备好了吗"
    mNet["createtime"] = self.m_iCreateTime
    mNet["haschangepos"] = self.m_iHasChangePos
    if self.m_iHasChangePos == 1 then
        text = mCostInfo["text"]
    end
    mNet["dialog"] = text
    mNet["cost"] = {type = mCostInfo["cost"]["type"],value = mCostInfo["cost"]["value"]}
    mNet["rewardinfo"] = table_deep_copy(self.m_mReward)
    for _,info in pairs(mNet["rewardinfo"]) do
        if info["text"] then
            info["text"] = nil
        end
    end
    local iNpcId = self.m_ID
    local iOwner = self.m_iOwner
    local func = function(oPlayer,mData)
        local iChoice = mData.answer
        if iChoice and iChoice ~= 0 then
            local oWorldMgr = global.oWorldMgr
            local oP = oWorldMgr:GetOnlinePlayerByPid(iOwner)
            if not oP then
                return
            end
            local oNpc = oP.m_oHuodongCtrl:GetNpcByID("playboynpc",iNpcId)
            if not oNpc then
                return
            end
            if oNpc.m_mReward[iChoice]["has_get"] and oNpc.m_mReward[iChoice]["has_get"] == 1 then
                return
            end
            oNpc:StartPlay(iChoice)
        end
    end
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    local iSessionidx = oCbMgr:SetCallBack(self.m_iOwner,"GS2CShowPlayBoyWnd",mNet,nil,func)
    oPlayer.m_oHuodongCtrl:AddNpcSessionId(self.m_ID,iSessionidx)
end

function CPlayBoyNpc:StartPlay(iChoice)
    if not (self.m_iHasChangePos == 1) then
        self:ChangeRewardPos()
        self:ShowPlayBoyDialog()
        return
    end
    local oCbMgr = global.oCbMgr
    local mCostInfo = self:GetCostInfo()
    local type = mCostInfo["cost"]["type"]
    local value = mCostInfo["cost"]["value"]
    if value > 0 then
        local sContent = string.format("你将花费 #w2 %d开启该宝箱\n是否确认？",value)
        local mNet = {
            sContent = sContent,
            sConfirm = "确认",
            sCancle = "取消",
            default = 0,
            time = 30,
        }
        mNet = oCbMgr:PackConfirmData(nil, mNet)
        local iNpcId = self.m_ID
        local func = function(oPlayer,mData)
            local oNpc = oPlayer.m_oHuodongCtrl:GetNpcByID("playboynpc",iNpcId)
            if not oNpc then
                return
            end
            if mData.answer and mData.answer == 1 then
                oNpc:_TruePlay(iChoice)
            else
                oNpc:ShowPlayBoyDialog()
            end
        end
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
        local iSessionidx = oCbMgr:SetCallBack(self.m_iOwner,"GS2CConfirmUI",mNet,nil,func)
        oPlayer.m_oHuodongCtrl:AddNpcSessionId(self.m_ID,iSessionidx)
    else
        self:_TruePlay(iChoice)
    end
end

function CPlayBoyNpc:_TruePlay(iChoice)
    local mCostInfo = self:GetCostInfo()
    local type = mCostInfo["cost"]["type"]
    local value = mCostInfo["cost"]["value"]
    local oCbMgr = global.oCbMgr
    if value > 0 then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
        if oPlayer:ValidGoldCoin(value) then
            oPlayer:ResumeGoldCoin(value,"贪玩童子开启宝箱")
            self:GiveReward(iChoice)
        else
            local sContent = string.format("你的水晶不足，是否立即前往补充？")
            local mNet = {
                sContent = sContent,
                sConfirm = "确认",
                sCancle = "取消",
                default = 0,
                time = 30,
            }
            mNet = oCbMgr:PackConfirmData(nil, mNet)
            local func = function(oPlayer,mData)
                if mData.answer and mData.answer == 1 then
                    --TODO
                end
            end
            local iSessionidx = oCbMgr:SetCallBack(self.m_iOwner,"GS2CConfirmUI",mNet,nil,func)
            oPlayer.m_oHuodongCtrl:AddNpcSessionId(self.m_ID,iSessionidx)
        end
            self:ShowPlayBoyDialog()
            return
    end
    self:GiveReward(iChoice)
    self:ShowPlayBoyDialog()
end

function CPlayBoyNpc:ChangeRewardPos()
    self:Dirty()
    local mTemp = table_deep_copy(self.m_mReward)
    local k= #self.m_mReward
    local m = {}
    for i = 1,k do
        local t = math.random(#self.m_mReward)
        table.insert(m,table_deep_copy(self.m_mReward[t]))
        table.remove(self.m_mReward,t)
    end
    self.m_mReward = m
    self.m_iHasChangePos = 1
    record.user("treasure","playerboy_changepos",{pid=self.m_iOwner,npcid=self.m_ID,oldinfo=ConvertTblToStr(mTemp),newinfo=ConvertTblToStr(self.m_mReward)})
end

function CPlayBoyNpc:RandomTbl()
end

function CPlayBoyNpc:GiveReward(iChoice)
    self:Dirty()
    local iReward = self.m_mReward[iChoice]["idx"]
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("treasure")
    oHuodong:GivePlayBoyReward(self.m_iOwner,iReward,self.m_mReward[iChoice]["text"])
    self.m_mReward[iChoice]["has_get"] = 1
    self.m_iDoneTime = self.m_iDoneTime + 1
    record.user("treasure","playerboy_getreward",{pid=self.m_iOwner,npcid=self.m_ID,times=self.m_iDoneTime,index=iChoice,rewardidx=iReward})
end

function CPlayBoyNpc:Release()
    self:DelTimeCb("timeout")
    super(CPlayBoyNpc).Release(self)
end

function CPlayBoyNpc:GetNpcData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"][self.m_sSysName] or {}
    assert(mData["npc"],string.format("miss %s npc config :%s",self.m_sSysName,self.m_iType))
    return mData["npc"][self.m_iType]
end

function CPlayBoyNpc:GetName()
    local mNpcInfo = self:GetNpcData()
    return mNpcInfo["name"]
end

function CPlayBoyNpc:GetTitle()
    local mNpcInfo=self:GetNpcData()
    return mNpcInfo["title"]
end