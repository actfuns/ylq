--import module

local global = require "global"
local extend = require "base.extend"
local npcobj = import(service_path("npc/npcobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
local geometry = require "base.geometry"
local record = require "public.record"

local WinEvent = {
    [1] = 3,
    [2] = 1,
    [3] = 2,
}

CCaiQuanNpc = {}
CCaiQuanNpc.__index = CCaiQuanNpc
inherit(CCaiQuanNpc, npcobj.CNpc)

function NewClientNpc(mArgs)
    local o = CCaiQuanNpc:New(mArgs)
    return o
end

function CCaiQuanNpc:New(mArgs)
    local o = super(CCaiQuanNpc).New(self)
    o:Init(mArgs)
    return o
end

function CCaiQuanNpc:Init(mArgs)
    local mArgs = mArgs or {}
    self.m_iType = mArgs["type"]
    self.m_sSysName = mArgs["sys_name"]
    self.m_iMapid = mArgs["map_id"] or 0
    self.m_mModel = mArgs["model_info"] or {}
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iEvent = mArgs["event"] or 0
    self.m_iReUse = mArgs["reuse"]
    self.m_iDialog = mArgs["dialogId"]
    self.m_iGameID = mArgs["game_id"]
    self.m_PlayerStatus = {}
    self.m_mRecord = {}
end

function CCaiQuanNpc:Save()
    local data = {}
    data["type"] = self.m_iType
    data["name"] = self.m_sName
    data["title"] = self.m_sTitle
    data["map_id"] = self.m_iMapid
    data["model_info"] = self.m_mModel
    data["pos_info"] = self.m_mPosInfo
    data["sys_name"] = self.m_sSysName
    data["reuse"]  = self.m_iReUse
    data["event"] = self.m_iEvent
    data["dialogId"] = self.m_iDialog
    return data
end

function CCaiQuanNpc:SetEvent(iEvent)
    self:Dirty()
    self.m_iEvent = iEvent
end

function CCaiQuanNpc:CheckTimeOut()
    return false
end

function CCaiQuanNpc:CountDown()
end

function CCaiQuanNpc:TimeOut()
end

function CCaiQuanNpc:PackInfo()
    local mData = {
            npctype = self.m_iType,
            npcid      = self.m_ID,
            name = self:Name(),
            title = self:Title(),
            map_id = self.m_iMapid,
            pos_info = self:GetPos(),
            model_info = self.m_mModel,
    }
    return mData
end

function CCaiQuanNpc:GetPos()
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

function CCaiQuanNpc:DoScript(pid,s,mArgs)
    if type(s) ~= "table" then
        return
    end
    for _,ss in pairs(s) do
        self:DoScript2(pid,ss,mArgs)
    end
end

function CCaiQuanNpc:DoScript2(pid,s,mArgs)
    if string.sub(s,1,2) == "DI" then
        local iDialog = string.sub(s,3,-1)
        iDialog = tonumber(iDialog)
        self:GS2CDialog(pid,iDialog)
    elseif string.sub(s,1,4) == "PLAY" then
        self:StartGame(pid)
    end
end

function CCaiQuanNpc:GetEventData(iEvent)
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"]["treasure"]["event"][iEvent]
    assert(mData,string.format("Not Event Config:%s",self.m_sName))
    return mData
end

function CCaiQuanNpc:GetDialogBaseData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"]["treasure"]["dialog"]
    assert(mData,string.format("Not PlayBoyDialog Config:%s",self.m_sName))
    return mData
end

function CCaiQuanNpc:GetDialogInfo(iDialog)
    local mData = self:GetDialogBaseData()
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CCaiQuanNpc:do_look(oPlayer)
    local mEvent = self:GetEventData(self.m_iEvent)
    self:DoScript(oPlayer.m_iPid,mEvent["look"])
end

function CCaiQuanNpc:GS2CDialog(iPid,iDialog)
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
    local iNpcId = self.m_ID
    local iGameID = self.m_iGameID
    local func = function(oPlayer,mArgs)
        if mArgs.answer and mArgs.answer ~= 0 then
            local event = mDialogInfo["last_action"][mArgs.answer]["event"]
            if event then
                local oHuodongMgr = global.oHuodongMgr
                local oHuodong = oHuodongMgr:GetHuodong("game")
                local oGame = oHuodong:GetGame(iGameID)
                if oGame then
                    local oNpc = oGame:GetNpcObj(iNpcId)
                    if oNpc then
                        oNpc:DoScript(iPid,{event})
                    end
                else
                    local oNotifyMgr = global.oNotifyMgr
                    oNotifyMgr:Notify(oPlayer.m_iPid,"游戏已结束")
                end
            end
        end
    end
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iSessionidx = oCbMgr:SetCallBack(iPid,"GS2CDialog",m,nil,func)
    oPlayer.m_oHuodongCtrl:AddNpcSessionId(self.m_ID,iSessionidx)
end

function CCaiQuanNpc:StartGame(iPid)
    if self.m_bDefeated then
        self:DoScript(iPid,{"DI500"})
        return
    end
    self.m_mPlayer = self.m_mPlayer or {}
    self.m_mPlayer[iPid] = true
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iNpcId = self.m_ID
    local iGameID = self.m_iGameID
    local func = function(oPlayer,mData)
        local iChoice = mData.answer
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("game")
        local oGame = oHuodong:GetGame(iGameID)
        if oGame then
            local oNpc = oGame:GetNpcObj(iNpcId)
            if oNpc then
                oNpc:EndGame(oPlayer.m_iPid,iChoice)
            else
                oPlayer:Send("GS2CNpcBeenDefeate",{npcid = iNpcId})
            end
        else
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(oPlayer.m_iPid,"游戏已结束")
        end
    end
    local oCbMgr = global.oCbMgr
    local mNet = {["npcid"] = self.m_ID,record = self.m_mRecord[iPid] or {{result=3}}}
    local iSessionidx = oCbMgr:SetCallBack(iPid,"GS2CShowCaiQuanWnd",mNet,nil,func)
    oPlayer.m_oHuodongCtrl:AddNpcSessionId(self.m_ID,iSessionidx)
    local iTimes=(self.m_PlayerStatus[iPid] or 0)+1
    record.user("treasure","caiquannpc_event",{gameid=self.m_iGameID,pid=iPid,npcid=self.m_ID,event="start game",times=iTimes})
end

function CCaiQuanNpc:EndGame(iPid,iChoice)
    local iNpcId = self.m_ID
    local iGameID = self.m_iGameID
    self.m_PlayerStatus[iPid] = self.m_PlayerStatus[iPid] or 0
    local oWorldMgr = global.oWorldMgr
    local iSysChoice = math.random(3)
    if self.m_PlayerStatus[iPid] == 2 then
        iSysChoice = WinEvent[iChoice]
    end
    self.m_PlayerStatus[iPid] = self.m_PlayerStatus[iPid] + 1
    self.m_mRecord[iPid] = self.m_mRecord[iPid] or {}
    local iTimes=self.m_PlayerStatus[iPid]
    local iResult = 0
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if iSysChoice == WinEvent[iChoice] then
        iResult = 1
        table.insert(self.m_mRecord[iPid],{player_choice = iChoice,sys_choice = iSysChoice,result = 1})
    elseif iSysChoice == iChoice then
        table.insert(self.m_mRecord[iPid],{player_choice = iChoice,sys_choice = iSysChoice,result = 2})
        iResult = 2
    else
        table.insert(self.m_mRecord[iPid],{player_choice = iChoice,sys_choice = iSysChoice,result = 0})
        iResult = 0
    end

    local sEvent=(iResult==1 and "胜利" or (iResult==2 and "平局" or "失败"))
    sEvent=sEvent..",玩家出拳："..iChoice.."，系统出拳："..iSysChoice
    record.user("treasure","caiquannpc_event",{gameid=iGameID,pid=iPid,npcid=iNpcId,event="sEvent",times=iTimes})

    local func = function(oPlayer,mData)
        if mData.answer and mData.answer == 1 then
            local oHuodongMgr = global.oHuodongMgr
            local oHuodong = oHuodongMgr:GetHuodong("game")
            local oGame = oHuodong:GetGame(iGameID)
            if not oGame then
                global.oNotifyMgr:Notify(oPlayer.m_iPid,"游戏已结束")
                return
            end
            local oNpc = oGame:GetNpcObj(iNpcId)
            if oNpc then
                oNpc:StartGame(iPid)
            else
                oPlayer:Send("GS2CNpcBeenDefeate",{npcid = iNpcId})
            end
        end
    end
    local oCbMgr = global.oCbMgr
    local iSessionidx = oCbMgr:SetCallBack(iPid,"GS2CShowCaiQuanResult",{syschoice = iSysChoice,result = iResult},nil,func)
    if not (iResult == 1) then
        oPlayer.m_oHuodongCtrl:AddNpcSessionId(self.m_ID,iSessionidx)
    end

    if iResult == 1 then
        self:Win(iPid)
    elseif iResult == 2 then
        self:Pingju(iPid)
    elseif iResult == 0 then
        self:Failed(iPid)
    end
end

function CCaiQuanNpc:Win(iPid)
    self.m_mPlayer[iPid] = nil
    local oWorldMgr = global.oWorldMgr
    for pid,_ in pairs(self.m_mPlayer) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            oPlayer:Send("GS2CNpcBeenDefeate",{npcid = self.m_ID})
            oPlayer.m_oHuodongCtrl:RemoveNpcSession(self.m_ID)
        end
    end
    local oGame = self:GetGame()
    oGame:WinNpc(self.m_ID)
end

function CCaiQuanNpc:Failed(iPid)
    self.m_mPlayer[iPid] = nil
end

function CCaiQuanNpc:Pingju(iPid)
    self.m_mPlayer[iPid] = nil
end

function CCaiQuanNpc:GetGame()
    local oHuodongMgr = global.oHuodongMgr
    local oGameMgr = oHuodongMgr:GetHuodong("game")
    local oGame = oGameMgr:GetGame(self.m_iGameID)
    return oGame
end

function CCaiQuanNpc:ClearSession()
    if not self.m_mPlayer then
        return
    end
    local oWorldMgr = global.oWorldMgr
    for iPid,_ in pairs(self.m_mPlayer) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer.m_oHuodongCtrl:RemoveNpcSession(self.m_ID)
        end
    end
end


function CCaiQuanNpc:GetData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"][self.m_sSysName] or {}
    assert(mData["npc"],string.format("miss %s npc config :%s",self.m_sSysName,self.m_iType))
    return mData["npc"][self.m_iType]
end

function CCaiQuanNpc:Name()
    local mNpcInfo = self:GetData()
    return mNpcInfo["name"]
end

function CCaiQuanNpc:Title()
    local mNpcInfo=self:GetData()
    return mNpcInfo["title"]
end