--import module
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local gamedb = import(lualib_path("public.gamedb"))
local templ = import(service_path("templ"))
local npcobj = import(service_path("npc.npcobj"))
local loaditem = import(service_path("item/loaditem"))
local rewardmonitor = import(service_path("rewardmonitor"))

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "huodong"
CHuodong.m_sTempName = "神秘活动"
inherit(CHuodong, templ.CTempl)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_iScheduleID = nil
    o.m_sName = sHuodongName
    o.m_mNpcList = {}
    o.m_mSceneList = {}
    o.m_mSceneIdx2Obj = {}
    o.m_bLoading = true
    return o
end

function CHuodong:Init()
    -- body
end

function CHuodong:Load(mData)
    -- body
end

function CHuodong:Save()
    -- body
end

function CHuodong:MergeFrom(mFromData)
    return false, "merge function is not implemented"
end

function CHuodong:IsLoading()
    if not self:NeedSave() then
        return false
    end
    return self.m_bLoading
end

function CHuodong:NeedSave()
    return false
end

function CHuodong:LoadDb()
    if not self:NeedSave() then
        return
    end
    local mData = {
        name = self.m_sName
    }
    local mArgs = {
        module = "global",
        cmd = "LoadGlobal",
        data = mData
    }
    gamedb.LoadDb(self.m_sName,"common", "LoadDb",mArgs, function (mRecord, mData)
        if not is_release(self) then
            local m = mData.data or {}
            self:Load(m)
            self:LoadFinish()
            self.m_bLoading = false
            self:OnLoaded()
        end
    end)
end

function CHuodong:LoadFinish()
end

function CHuodong:ConfigSaveFunc()
    local sName = self.m_sName
    self:ApplySave(function ()
        local oHuodongMgr = global.oHuodongMgr
        local obj = oHuodongMgr:GetHuodong(sName)
        if not obj then
            record.warning(string.format("huodong %s save err: no obj", sName))
            return
        end
        obj:_CheckSaveDb()
    end)
end

function CHuodong:_CheckSaveDb()
    assert(not is_release(self), string.format("huodong %s save err: release", self.m_sName))
    assert(not self:IsLoading(), string.format("huodong %s save err: loading", self.m_sName))
    self:SaveDb()
end

function CHuodong:SaveDb()
    if self:IsLoading() then
        return
    end
    if is_release(self) then
        return
    end
    if not self:IsDirty() then
        return
    end
    local mData = {
        name = self.m_sName,
        data = self:Save()
    }
    gamedb.SaveDb(self.m_sName,"common","SaveDb",{module="global",cmd="SaveGlobal",data=mData})
    self:UnDirty()
end

function CHuodong:ScheduleID()
    return self.m_iScheduleID
end

function CHuodong:AddSchedule(oPlayer)
    oPlayer:AddSchedule(self:ScheduleID())
end

function CHuodong:SetHuodongState(iState)
    global.oHuodongMgr:SetHuodongState(self.m_sName, self:ScheduleID(), iState)
    --[[
    local mNet = {
        hd_id = iScheduleID,
        status = iState,
        }
    local mData = {
        message = "GS2CHuoDongStatus",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = mNet,
        exclude = {}
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
    ]]
end

function CHuodong:GetScheduleTimeDesc(iState)
    if iState == gamedefines.SCHEDULE_TYPE.GAME_START then
        return "正在进行"
    elseif iState == gamedefines.SCHEDULE_TYPE.GAME_OVER then
        return "结束"
    else
        return "未开启"
    end
end


function CHuodong:NewHour(iWeekDay, iHour)
    -- body
end

function CHuodong:NewDay(iWeekDay)
    -- body
end

function CHuodong:OnUpGrade(oPlayer, iGrade)
end

function CHuodong:IsOpenDay(iTime)
    return false
end

function CHuodong:ResName()
    return self.m_sName
end

function CHuodong:GetTollGateData(iFight)
    local res = require "base.res"
    local mData = res["daobiao"]["tollgate"][self:ResName()][iFight]
     assert(mData,string.format("CHuodong GetTollGateData err: %s %d", self.m_sName, iFight))
    return mData
end


function CHuodong:GetMonsterData(iMonsterIdx)
    local res = require "base.res"
    local mData = res["daobiao"]["monster"][self:ResName()][iMonsterIdx]
    assert(mData,string.format("CHuodong GetMonsterData err: %s %d", self.m_sName, iMonsterIdx))
    return mData
end

function CHuodong:GetEventData(iEvent)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["event"][iEvent]
    assert(mData,string.format("CHuodong GetEventData err: %s %d", self.m_sName, iEvent))
    return mData
end

function CHuodong:GetTempNpcData(iTempNpc)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["npc"][iTempNpc]
    assert(mData,string.format("CHuodong GetTempNpcData err: %s %d", self.m_sName, iTempNpc))
    return mData
end

function CHuodong:GetTextData(iText)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["text"][iText]
    mData = mData["content"]
    assert(mData,string.format("CHuodong:GetTextData err:%s %d", self.m_sName, iText))
    return mData
end

function CHuodong:GetRewardData(iReward)
    local res = require "base.res"
    local mData = res["daobiao"]["reward"][self:ResName()]["reward"][iReward]
    assert(mData,string.format("CHuodong:GetRewardData err:%s %d", self.m_sName, iReward))
    return mData
end

function CHuodong:GetItemRewardData(iItemReward)
    local res = require "base.res"
    local mData = res["daobiao"]["reward"][self:ResName()]["itemreward"][iItemReward]
    assert(mData,string.format("CHuodong:GetItemRewardData err:%s %d", self.m_sName, iItemReward))
    return mData
end

function CHuodong:GetConfigValue(sName)
    local res = require "base.res"
    local val = res["daobiao"]["playconfig"][self:ResName()][sName]
    assert(val,string.format("CHuodong:GetConfigValue %s",sName))
    return val
end

function CHuodong:DoScript(pid,npcobj,s,mArgs)
    if type(s) ~= "table" then
        return
    end
    for _,ss in pairs(s) do
        self:DoScript2(pid,npcobj,ss, mArgs)
    end
end

function CHuodong:DoScript2(pid,npcobj,s,mArgs)
    super(CHuodong).DoScript2(self,pid,npcobj,s,mArgs)
    local s1to2 = string.sub(s,1,2)
    local s1to1 = string.sub(s,1,1)
    if s1to2 == "CN" then
        local npctype = string.sub(s,3,-1)
        npctype = tonumber(npctype)
        self:CreateTempNpc(npctype)
    elseif s1to2 == "DI" then
        local iDialog = string.sub(s,3,-1)
        iDialog = tonumber(iDialog)
        self:GS2CDialog(pid,npcobj,iDialog, mArgs)
    elseif s1to1 == "E" then
        local sArgs = string.sub(s,2,-1)
        local npctype,iEvent = string.match(sArgs,"(.+):(.+)")
        npctype = tonumber(npctype)
        iEvent = tonumber(iEvent)
        self:SetEvent(npctype, iEvent)
    elseif s1to1 == "D" then
        local iText = string.sub(s,2,-1)
        iText = tonumber(iText)
        if not iText then
            return
        end
        local sText = self:GetTextData(iText)
        if sText then
            self:SayText(pid,npcobj,sText)
        end
    elseif s1to2 == "RN" then
        if npcobj then
            self:RemoveTempNpc(npcobj)
        end
    end
    self:OtherScript(pid,npcobj,s,mArgs)
end

function CHuodong:OtherScript(pid,npcobj,s,mArgs)
    -- body
end

-- Scene ---
function CHuodong:CreateVirtualScene(iIdx)
    local mRes = self:GetSceneData(iIdx)
    local oSceneMgr = global.oSceneMgr
    local mArgs = {
    map_id = mRes["map_id"],
    scene_name = mRes["scene_name"],
    transfers = mRes["transfers"],
    has_anlei = mRes["anlei"] == 1 and true or false,
    }
    local oScene = oSceneMgr:CreateVirtualScene(mArgs)
    oScene.m_iIdx = iIdx
    self.m_mSceneList[oScene:GetSceneId()] = oScene
    self:InsertScene2IdxTable(oScene)
    return oScene
end

function CHuodong:GetHDScene(iScene)
    return self.m_mSceneList[iScene]
end

function CHuodong:GetSceneData(iScene)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]
    return mData["scene"][iScene]
end

function CHuodong:InsertScene2IdxTable(oScene)
    local iIdx = oScene.m_iIdx
    if not iIdx then return end
    local mData = self.m_mSceneIdx2Obj[iIdx] or {}
    table.insert(mData, oScene:GetSceneId())
    self.m_mSceneIdx2Obj[iIdx] = mData
end

function CHuodong:GetSceneListByIdx(iIdx)
    return self.m_mSceneIdx2Obj[iIdx] or {}
end

function CHuodong:GetSceneObjByIdx(iIdx, iPos)
    local lSceneObj = self:GetSceneListByIdx(iIdx)
    local iLen = #lSceneObj
    if iLen > 0 then
        iPos = iPos or math.random(iLen)
        return lSceneObj[iPos]
    end
end

function CHuodong:RemoveNpcByScene(id)
    local oScene = self.m_mSceneList[id]
    if not oScene then return end

    local oNpcMgr = global.oNpcMgr
    for iNpc, _ in pairs(oScene.m_mNpc) do
        local oNpc = oNpcMgr:GetObject(iNpc)
        if oNpc and not is_release(oNpc) then
            self:RemoveTempNpc(oNpc)
        end
    end
end

function CHuodong:TransferPlayerBySceneID(iPid, iScene, iX, iY,func)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end

    local oSceneMgr = global.oSceneMgr
    oSceneMgr:TransferPlayerBySceneID(iPid, iScene, iX, iY,func)
end


function CHuodong:GobackRealScene(pid)
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then return end
    local mData = oPlayer.m_oActiveCtrl:GetDurableSceneInfo()
    local iMapId = mData.map_id
    local mPos = mData.pos
    local oScene = oSceneMgr:SelectDurableScene(iMapId)
    if oPlayer:IsTeamLeader() then
        oSceneMgr:TeamEnterScene(oPlayer, oScene:GetSceneId(), {pos=mPos}, true)
    else
        if not oPlayer:IsSingle() then return end
        oSceneMgr:EnterScene(oPlayer, oScene:GetSceneId(), {pos=mPos}, true)
    end
end


function CHuodong:RemoveSceneById(id)
    local oScene = self.m_mSceneList[id]
    if oScene then
        local oSceneMgr = global.oSceneMgr
        local iIdx = oScene.m_iIdx
        self:RemoveNpcByScene(id)
        oSceneMgr:RemoveScene(id)
        self.m_mSceneList[id] = nil
        if iIdx and self.m_mSceneIdx2Obj[iIdx] then
            extend.Array.remove(self.m_mSceneIdx2Obj[iIdx],id)
        end
    end
end

function CHuodong:RemoveSceneByIdx(iIdx)
    local lScene = self:GetSceneListByIdx(iIdx)
    for _, iScene in ipairs(lScene) do
        self:RemoveSceneById(iScene)
    end
    self.m_mSceneIdx2Obj[iIdx] = nil
end

-- NPC

function CHuodong:GetNpcName(iTempNpc)
    return ""
end

function CHuodong:GetMonsterFlag(iTempNpc)
    return false
end

function CHuodong:PacketNpcInfo(iTempNpc)
    local mData = self:GetTempNpcData(iTempNpc)
    local iNameType = mData["nameType"]
    local sName
    if iNameType == 2 then
        sName = self:GetNpcName(iTempNpc)
    else
        sName = mData["name"]
    end
    local mArgs = {}
    mArgs["name"] = sName

    local mModel = {
        shape = mData["modelId"],
        scale = mData["scale"],
        adorn = mData["ornamentId"],
        weapon = mData["wpmodel"],
        color = mData["mutateColor"],
        mutate_texture = mData["mutateTexture"],
    }
    local mPosInfo = {
        x = mData["x"],
        y = mData["y"],
        z = mData["z"],
        face_x = mData["face_x"] or 0,
        face_y = mData["face_y"] or  0,
        face_z = mData["face_z"] or 0,
    }
    local bMonsterFlag = self:GetMonsterFlag(iTempNpc)
    local mArgs = {
        type = mData["id"],
        name = sName,
        title = mData["title"],
        map_id = mData["sceneId"],
        model_info = mModel,
        pos_info = mPosInfo,
        event = mData["event"] or 0,
        sys_name = self.m_sName,
        monster_flag = bMonsterFlag
    }

    return mArgs
end

function CHuodong:CreateTempNpc(iTempNpc)
    local mArgs = self:PacketNpcInfo(iTempNpc)
    local oTempNpc = self:NewHDNpc(mArgs,iTempNpc)
    oTempNpc.m_oHuodong = self
    self.m_mNpcList[oTempNpc.m_ID] = oTempNpc
    return oTempNpc
end


function CHuodong:NewHDNpc(mArgs,iTempNpc)
    return NewHDNpc(mArgs)
end

function CHuodong:Npc_Enter_Map(oTempNpc, iMapid, mPosInfo)
    iMapid = iMapid or oTempNpc.m_iMapid
    if not iMapid then
        return
    end
    local oSceneMgr = global.oSceneMgr
    local mScene = oSceneMgr:GetSceneListByMap(iMapid)
    local oNpc = oTempNpc
    for k, oScene in ipairs(mScene) do
        if k ~= 1 then
            oNpc = self:CreateTempNpc(oTempNpc:Type())
        end
        oNpc.m_mPosInfo = mPosInfo
        oNpc.m_iMapid = oScene:MapId()
        oNpc:SetScene(oScene:GetSceneId())
        oScene:EnterNpc(oNpc)
    end
end

function CHuodong:Npc_Enter_Scene(oTempNpc, iScene, mPosInfo)
    if not iScene then
        return
    end
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(iScene)
    if oScene then
        oTempNpc.m_mPosInfo = mPosInfo
        oTempNpc.m_iMapid = oScene:MapId()
        oTempNpc:SetScene(oScene:GetSceneId())
        oScene:EnterNpc(oTempNpc)
    end
end



function CHuodong:GetNpcObj(nid)
    return self.m_mNpcList[nid]
end

function CHuodong:GetNpcListByMap(iMap)
    local lNpcList = {}
    for nid, oNpc in pairs(self.m_mNpcList) do
        if oNpc:MapId() == iMap then
            table.insert(lNpcList, oNpc)
        end
    end
    return lNpcList
end

function CHuodong:GetNpcListByScene(iScene)
    local lNpcList = {}
    for nid, oNpc in pairs(self.m_mNpcList) do
        if oNpc.m_Scene == iScene then
            table.insert(lNpcList, oNpc)
        end
    end
    return lNpcList
end

function CHuodong:RemoveTempNpc(oNpc)
    local npcid = oNpc.m_ID
    local oNpcMgr = global.oNpcMgr
    self.m_mNpcList[npcid] = nil
    oNpcMgr:RemoveSceneNpc(npcid)
end

function CHuodong:RemoveTempNpcById(npcid)
    if self.m_mNpcList[npcid] then
        self.m_mNpcList[npcid] = nil
        global.oNpcMgr:RemoveSceneNpc(npcid)
    end
end

function CHuodong:RemoveTempNpcByType(npctype)
    local lNpcIdxs = {}
    for nid, oNpc in pairs(self.m_mNpcList) do
        if oNpc:Type() == npctype then
            table.insert(lNpcIdxs, oNpc)
        end
    end
    for nid, oNpc in pairs(lNpcIdxs) do
        self:RemoveTempNpc(oNpc)
    end
end

function CHuodong:SetEvent(npctype, iEvent)
    for nid, oNpc in pairs(self.m_mNpcList) do
        if oNpc:Type() == npctype then
            oNpc.SetEvent(iEvent)
        end
    end
end

function CHuodong:GetEvent(nid)
    local npcobj = self:GetNpcObj(nid)
    if not npcobj then
        return
    end
    return npcobj.m_iEvent
end

function CHuodong:SayText(pid,npcobj,sText,func)
    if not npcobj then
        local mNet = {}
        mNet["text"] = sText
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer then
            if not func then
                oPlayer:Send("GS2CNpcSay",mNet)
            else
                local oCbMgr = global.oCbMgr
                oCbMgr:SetCallBack(pid,"GS2CNpcSay",mNet,nil,func)
            end
        end
    else
        local npcid = npcobj.m_ID
        local sName = self.m_sName
        if self.m_NeedAnswer then
            local func = function (oPlayer,mData)
                local iAnswer = mData["answer"]
                local oHuodongMgr = global.oHuodongMgr
                local oHuodong = oHuodongMgr:GetHuodong(sName)
                oHuodong:RespondLook(oPlayer, npcid, iAnswer)
            end
            npcobj:SayRespond(pid,sText,nil,func)
        elseif not func then
            npcobj:Say(pid,sText)
        else
            npcobj:SayRespond(pid,sText,nil,func)
        end
    end
end

function CHuodong:do_look(oPlayer, npcobj)
    if not npcobj or not npcobj.m_iEvent then
        return
    end
    local mEvent = self:GetEventData(npcobj.m_iEvent)
    if not mEvent then
        return
    end
    if mEvent["answer"] and next(mEvent["answer"]) then
        self.m_NeedAnswer = true
    end
    self:DoScript(oPlayer:GetPid(),npcobj,mEvent["look"])
    if self.m_NeedAnswer then
        self.m_NeedAnswer = nil
    end
end

function CHuodong:RespondLook(oPlayer, nid, iAnswer)
    local npcobj = self:GetNpcObj(nid)
    if not npcobj then
        return
    end
    local mEvent = self:GetEventData(npcobj.m_iEvent)
    if not mEvent then
        return
    end
    local mAnswer = mEvent["answer"]
    if not mAnswer or not next(mAnswer) then
        return
    end
    local s = mAnswer[iAnswer] or ""
    if self:CheckAnswer(oPlayer, npcobj, iAnswer) then
        self:DoScript2(oPlayer:GetPid(),npcobj,s)
    end
end

function CHuodong:CheckAnswer(oPlayer, npcobj, iAnswer)
    return true
end

function CHuodong:TestOP(oPlayer,iCmd,...)
end

function CHuodong:GS2CDialog(iPid,oNpc,iDialog)
    -- body
end

function CHuodong:DefaultNpcDialog(oPlayer,oNpc,iDialog,func)
    local mDialogInfo = self:GetDialogInfo(iDialog)
    if not mDialogInfo then
        return
    end
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr

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
    m["npc_id"] = oNpc.m_ID
    m["npc_name"] = oNpc:Name()
    m["shape"] = oNpc:Shape()
    if func then
        local oCbMgr = global.oCbMgr
        oCbMgr:SetCallBack(iPid,"GS2CDialog",m,nil,func)
    else
        oPlayer:Send("GS2CDialog",m)
    end

end

function CHuodong:GetDialogInfo(iDialog)
    local res = require "base.res"
    local mData = assert(res["daobiao"]["huodong"][self.m_sName]["dialog"])
    return assert(mData[iDialog])
end



function CHuodong:GetSelfCallback()
    local sHuodongName = self.m_sName
    return function()
        return global.oHuodongMgr:GetHuodong(sHuodongName)
    end
end

function CHuodong:CheckRewardMonitor(oPlayer, iRewardId, iCnt, mArgs)

    if self.m_oRewardMonitor then
        if not self.m_oRewardMonitor:CheckRewardGroup(oPlayer, iRewardId, iCnt, mArgs) then
            return false
        end
    end
    return true
end

function CHuodong:TryStartRewardMonitor()
    if not self.m_oRewardMonitor then
        local lUrl = {"reward", self.m_sName}
        local o = rewardmonitor.NewMonitor(self.m_sName, lUrl)
        self.m_oRewardMonitor = o
    end
    self.m_oRewardMonitor:Start()
end

function CHuodong:TryStopRewardMonitor()
    if self.m_oRewardMonitor then
        self.m_oRewardMonitor:ClearRecordInfo()
        self.m_oRewardMonitor:Stop()
    end
end

function CHuodong:GetRewardMonitor()
    return self.m_oRewardMonitor
end

function CHuodong:OnLogin(oPlayer)
end

function CHuodong:OnLogout(oPlayer)
end

function CHuodong:FindNpcPath(oPlayer,iType)
    for iNpcId,npc in pairs(self.m_mNpcList) do
        if npc:Type() == iType then
            local sHuodongName = self.m_sName
            local oCbMgr = global.oCbMgr
            local mPosInfo = npc:PosInfo()
            local mData = {["iMapId"] = npc:MapId(),["iPosx"] = mPosInfo.x,["iPosy"] = mPosInfo.y,["iAutoType"] = 1}
            local func = function(oPlayer,mData)
                local oHuodong = global.oHuodongMgr:GetHuodong(sHuodongName)
                local oNpc = oHuodong:GetNpcObj(iNpcId)
                oHuodong:do_look(oPlayer,oNpc)
            end
            oCbMgr:SetCallBack(oPlayer.m_iPid,"AutoFindTaskPath",mData,nil,func)
            break
        end
    end
end
------------------------------------------------------------

CHDNpc = {}
CHDNpc.__index = CHDNpc
inherit(CHDNpc, npcobj.CNpc)

function NewHDNpc(mArgs)
    local o = CHDNpc:New(mArgs)
    return o
end

function CHDNpc:New(mArgs)
    local o = super(CHDNpc).New(self)
    o:Init(mArgs)
    return o
end

function CHDNpc:Init(mArgs)
    local mArgs = mArgs or {}

    self.m_sName = mArgs["name"]
    self.m_sSysName = mArgs.sys_name
    self.m_iType = mArgs["type"]
    self.m_iMapid = mArgs["map_id"] or 0
    self.m_mModel = mArgs["model_info"] or {}
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iEvent = mArgs["event"]
    self.m_bMonsterFlag = mArgs["monster_flag"] or false
    self.m_sTitle = mArgs["title"]
end

function CHDNpc:GetMonsterFlag()
    return self.m_bMonsterFlag
end

function CHDNpc:Title()
    local mNpcInfo = self:GetData()
    if not self.m_sTitle then
        return mNpcInfo["title"]
    end
    return self.m_sTitle
end

function CHDNpc:SetEvent(iEvent)
    self.m_iEvent = iEvent
end

function CHDNpc:do_look(oPlayer)
    if self.m_oHuodong then
        self.m_oHuodong:do_look(oPlayer, self)
    end
end

function CHDNpc:GetData()
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sSysName]["npc"][self.m_iType]
end

function CHDNpc:Name()
    if self.m_sName then
        return self.m_sName
    end
    local mNpcInfo = self:GetData()
    return mNpcInfo["name"]
end