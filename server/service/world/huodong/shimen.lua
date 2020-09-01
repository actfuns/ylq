-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"
local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loadpartner = import(service_path("partner/loadpartner"))
local record = require "public.record"
local gsub = string.gsub

local SHIMEN_TASKITEM_ID = 11616

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "师门"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
end

function CHuodong:do_look(oPlayer,oNpc)
    self:GS2CDialog(oPlayer.m_iPid,oNpc,100)
end

function CHuodong:GetMaxTaskTime()
    local sValue = res["daobiao"]["global"]["shimen_maxtime"]["value"]
    return tonumber(sValue)
end

function CHuodong:GetLeftTaskTime(oPlayer)
    local iMaxTime = self:GetMaxTaskTime()
    local iDoneTime = oPlayer.m_oToday:Query("shimen_receive",0)
    return (iMaxTime - iDoneTime)
end

function CHuodong:TransString(iPid,oNpc,sContent,mArgs)
    if not sContent then
        return
    end
    if string.find(sContent,"$lefttime") then
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        local iLeftTime = self:GetLeftTaskTime(oPlayer)
        sContent = gsub(sContent,"$lefttime",iLeftTime)
    end
    return sContent
end

function CHuodong:GetDialogBaseData()
    local mData = res["daobiao"]["huodong"][self.m_sName]["dialog"]
    assert(mData,string.format("Not Dialog Config:%s",self.m_sName))
    return mData
end

function CHuodong:GetDialogInfo(iDialog)
    local mData = self:GetDialogBaseData()
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CHuodong:GS2CDialog(iPid,oNpc,iDialog)
    local mDialogInfo = self:GetDialogInfo(iDialog)
    if not mDialogInfo then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local m = {}
    m["dialog"] = {{
        ["type"] = mDialogInfo["type"],
        ["pre_id_list"] = mDialogInfo["pre_id_list"],
        ["content"] = self:TransString(iPid,oNpc,mDialogInfo["content"]),
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
    local iNpcId = oNpc.m_ID
    local sName = self.m_sName
    local func = function(oPlayer,mArgs)
        if mArgs.answer and mArgs.answer ~= 0 then
            local event = mDialogInfo["last_action"][mArgs.answer]["event"]
            if event then
                local oHuodongMgr = global.oHuodongMgr
                local oHuodong = oHuodongMgr:GetHuodong(sName)
                local oNpcMgr = global.oNpcMgr
                local obj = oNpcMgr:GetObject(iNpcId)
                if not obj then
                    return
                end
                oHuodong:DoScript(iPid,obj,{event})
            end
        end
    end
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(iPid,"GS2CDialog",m,nil,func)
end

function CHuodong:DoScript(iPid,oNpc,mEvent,mArgs)
    if type(mEvent) ~= "table" then
        return
    end
    for _,sEvent in pairs(mEvent) do
        self:DoScript2(iPid,oNpc,sEvent,mArgs)
    end
end

function CHuodong:DoScript2(iPid,oNpc,sEvent,mArgs)
    if string.sub(sEvent,1,3) == "_GT" then
        local bValid,iMsg,mParam = self:ValidGetTask(iPid)
        if not bValid then
            self:GS2CDialog(iPid,oNpc,iMsg)
            return
        end
        self:ReceiveTask(iPid)
        return
    elseif string.sub(sEvent,1,3) == "_WC" then
        local bValid,iMsg = self:ValidFinishTask(iPid)
        if not bValid then
            self:GS2CDialog(iPid,oNpc,iMsg)
            return
        end
        self:FinishTask(iPid)
        return
    end
    super(CHuodong).DoScript2(self,iPid,oNpc,sEvent,mArgs)
end

function CHuodong:ValidGetTask(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oTask = oPlayer.m_oTaskCtrl:GetShimenTask()
    if oTask then
        return false,101
    end
    if oPlayer.m_oToday:Query("shimen_receive",0) >= self:GetMaxTaskTime() then
        return false,103
    end
    if oPlayer:GetItemAmount(SHIMEN_TASKITEM_ID) > 0 then
        return false,105
    end
    local lGive = {{SHIMEN_TASKITEM_ID, 1}}
    if not oPlayer:ValidGive(lGive,{cancel_tip = 1}) then
        return false,104
    end
    return true
end

function CHuodong:ReceiveTask(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local lGive = {{SHIMEN_TASKITEM_ID, 1}}
    if oPlayer:ValidGive(lGive,{cancel_tip = 1}) then
        oPlayer:GiveItem(lGive, "师门任务道具", {cancel_tip=1, cancel_show = 1}, function(mRecord,mData)
            if mData.success then
                local oHuodong = global.oHuodongMgr:GetHuodong("shimen")
                oHuodong:AfterReceiveTask(iPid)
            else
                record.warning("liuwei-debug:add shimentask item failed:"..iPid)
            end
        end)
    end
end

function CHuodong:AfterReceiveTask(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iTaskId = self:RandomTask(oPlayer)
    oPlayer.m_oTaskCtrl:AddShimenTask(iTaskId,1)
    oPlayer.m_oToday:Add("shimen_receive",1)
    oPlayer.m_oTaskCtrl:UpdateShimenStatus()
    if not oPlayer.m_oToday:Query("record_cnt") then
        oPlayer:RecordPlayCnt("shimen",1)
        oPlayer.m_oToday:Set("record_cnt",1)
    end
    local iDoneTime = oPlayer.m_oTaskCtrl:GetShiMenRingTime()
    record.user("shimen","receivetask",{pid = iPid,cur_time = iDoneTime+1})
end

function CHuodong:GetTaskRatio(oPlayer)
    local mData = res["daobiao"]["huodong"][self.m_sName]["config"]
    assert(mData,"GetRatio failed,not config")
    local iGrade = oPlayer:GetGrade()
    for key,info in pairs(mData) do
        local mLevel = info["level"]
        if iGrade >= mLevel["min"] and iGrade <= mLevel["max"] then
            return info["task_ratio"]
        end
    end
    print("liuwei-debug:GetTaskRatio failed")
    return mData[1]["task_ratio"]
end

function CHuodong:GetTaskPool(iTaskType)
    local mData = res["daobiao"]["huodong"][self.m_sName]["taskpool"]
    assert(mData[iTaskType],"GetTaskPool failed:"..iTaskType)
    return mData[iTaskType]["task_pool"]
end

function CHuodong:RandomTask(oPlayer)
    local mRatio = self:GetTaskRatio(oPlayer)
    local iTotalWeight = 0
    for _,info in pairs(mRatio) do
        iTotalWeight = iTotalWeight + info["ratio"]
    end
    local iRandom = math.random(iTotalWeight)
    local iCurWeight = 0
    local iTaskType = mRatio[1]["tasktype"]
    for _,info in pairs(mRatio) do
        iCurWeight = iCurWeight + info["ratio"]
        if iCurWeight > iRandom then
            iTaskType = info["tasktype"]
            break
        end
    end
    local mTaskPool = self:GetTaskPool(iTaskType)
    local iTaskId = mTaskPool[math.random(#mTaskPool)]
    return iTaskId
end

function CHuodong:AfterTaskMissonDone(oPlayer,iRing)
    oPlayer:AddSchedule("shimen")
    if not oPlayer.m_oToday:Query("record_cnt") then
        oPlayer:RecordPlayCnt("shimen",1)
        oPlayer.m_oToday:Set("record_cnt",1)
    end
    if iRing >= gamedefines.SHIMEN_MAXRING then
        oPlayer.m_oToday:Add("shimen_finish",1)
        oPlayer.m_oTaskCtrl:UpdateShimenStatus()
        oPlayer:GS2CTodayInfo({"shimen_finish"})
        oPlayer.m_oToday:Delete("record_cnt",1)
        return
    end

    local iTaskId = self:RandomTask(oPlayer)
    oPlayer.m_oTaskCtrl:AddShimenTask(iTaskId,iRing + 1)
end

function CHuodong:ValidFinishTask(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iStatus = oPlayer.m_oTaskCtrl:GetShimenStatus()
    if iStatus == 0 or iStatus == 1 then
        return false,106
    elseif iStatus == 2 then
        return false,107
    end
    return true
end

function CHuodong:FinishTask(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iStatus = oPlayer.m_oTaskCtrl:GetShimenStatus()
    if iStatus ~= 3 then
        return
    end
    if not (oPlayer:GetItemAmount(SHIMEN_TASKITEM_ID) > 0) then
        return
    end
    local fFunc = function()
        local player = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        local oHuodong = global.oHuodongMgr:GetHuodong("shimen")
        oHuodong:AfterFinishTask(player)
    end
    oPlayer:RemoveItemAmount(SHIMEN_TASKITEM_ID,1,"交付任务",{},fFunc)
end

function CHuodong:AfterFinishTask(oPlayer)
    oPlayer.m_oTaskCtrl:UpdateShimenStatus()
    local iDoneTime = oPlayer.m_oTaskCtrl:GetShiMenRingTime()
    record.user("shimen","finishtask",{pid = oPlayer.m_iPid,cur_time = iDoneTime+1})
    self:GiveExtraReward(oPlayer)
end

function CHuodong:GiveExtraReward(oPlayer)
    local iRewardId = self:RandomReward(oPlayer)
    self:Reward(oPlayer.m_iPid,iRewardId,{reason = "护送任务额外奖励"})
end

function CHuodong:GetRewardRatio(oPlayer)
    local mData = res["daobiao"]["huodong"][self.m_sName]["config"]
    assert(mData,"GetRatio failed,not config")
    local iGrade = oPlayer:GetGrade()
    for key,info in pairs(mData) do
        local mLevel = info["level"]
        if iGrade >= mLevel["min"] and iGrade <= mLevel["max"] then
            return info["reward_ratio"]
        end
    end
end

function CHuodong:RandomReward(oPlayer)
    local mRatio = self:GetRewardRatio(oPlayer)
    local iTotalWeight = 0
    for _,info in pairs(mRatio) do
        iTotalWeight = iTotalWeight + info["ratio"]
    end
    local iRandom = math.random(iTotalWeight)
    local iCurWeight = 0
    local iRewardId = mRatio[1]["rewardid"]
    for _,info in pairs(mRatio) do
        iCurWeight = iCurWeight + info["ratio"]
        if iCurWeight > iRandom then
            iRewardId = info["rewardid"]
            break
        end
    end
    return iRewardId
end