local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"
local res = require "base.res"

local loaditem = import(service_path("item.loaditem"))

local max = math.max
local min = math.min

function C2GSClickTask(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iTaskid = mData["taskid"]
    local bOpen = res["daobiao"]["global_control"]["task"]["is_open"]
    if iTaskid ~= 500 then      --修行任务和普通任务独立控制
        if bOpen ~= "y" then
            oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意官网相关信息。")
            return
        end
    end
    local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
    if not oTask then
        return
    end
    local oTeam = oPlayer:HasTeam()
    local iPid = oPlayer:GetPid()
    if oTeam and not (oTeam:IsLeader(iPid) or oTeam:IsShortLeave(iPid)) then
        oNotifyMgr:Notify(iPid,"您在队伍中，不能进行任务")
        return
    end
    oTask:Click(iPid)
end

function C2GSTaskEvent(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iTaskid = mData["taskid"]
    local bOpen = res["daobiao"]["global_control"]["task"]["is_open"]
    if iTaskid ~= 500 then      --修行任务和普通任务独立控制
        if bOpen ~= "y" then
            oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意官网相关信息。")
            return
        end
    end
    
    local iNpcid = mData["npcid"]
    local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
    if not oTask then
        return
    end
    oTask:DoNpcEvent(oPlayer.m_iPid,iNpcid)
end

function C2GSCommitTask(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iTaskid = mData["taskid"]
    local bOpen = res["daobiao"]["global_control"]["task"]["is_open"]
    if iTaskid ~= 500 then      --修行任务和普通任务独立控制
        if bOpen ~= "y" then
            oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意官网相关信息。")
            return
        end
    end
    
    local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
    if not oTask then
        return
    end
    oPlayer.m_oTaskCtrl:MissionDone(oTask,oPlayer:GetPid())
    --oTask:MissionDone()
end

function C2GSAbandonTask(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iTaskid = mData["taskid"]
    local bOpen = res["daobiao"]["global_control"]["task"]["is_open"]
    if iTaskid ~= 500 then      --修行任务和普通任务独立控制
        if bOpen ~= "y" then
            oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意官网相关信息。")
            return
        end
    end
    
    local oTask = oPlayer.m_oTaskCtrl:GetTask(iTaskid)
    if not oTask then
        return
    end
    oTask:Abandon()
end

function C2GSAcceptTask(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iTaskid = mData["taskid"]
    local bOpen = res["daobiao"]["global_control"]["task"]["is_open"]
    local bOpen_DailyTask = res["daobiao"]["global_control"]["dailytask"]["is_open"]
    if iTaskid >= 2000 and iTaskid <= 2999 then
        if bOpen_DailyTask ~= "y" then
            oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意官网相关信息。")
            return
        end
    end
    if iTaskid ~= 500 then      --修行任务和普通任务独立控制
        if bOpen ~= "y" then
            oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意官网相关信息。")
            return
        end
    end
    oPlayer.m_oTaskCtrl:AcceptTask(iTaskid)
end

function C2GSAcceptSideTask(oPlayer,mData)
    local iTaskid = mData["taskid"]
    oPlayer.m_oTaskCtrl:AcceptSideTask(iTaskid)
    -- body
end

function C2GSTaskItemChange(oPlayer,mData)
    local mChangeInfo = mData["change_info"]
    oPlayer.m_oTaskCtrl:TaskItemChange(mChangeInfo)
end

function C2GSGetTaskReward(oPlayer,mData)
    oPlayer.m_oTaskCtrl:GetTeachTaskReward(mData["id"])
end

function C2GSGetProgressReward(oPlayer,mData)
    oPlayer.m_oTaskCtrl:GetTeachProgressReward(mData["progress"])
end

function C2GSFinishGuidance(oPlayer,mData)
    local mGuidance = res["client_guidance"]
    for _,iServerKey in pairs(mData.key) do
        if mGuidance [iServerKey] then
            oPlayer.m_oActiveCtrl:SetGuideFlag(oPlayer,iServerKey)
        end
    end
end

function C2GSClearGuidance(oPlayer,mData)
    local m = oPlayer.m_oActiveCtrl:GetData("guidanceinfo",{["key"] = {}})
    local mKey = mData.key
    for _,sKey in pairs(mKey) do
        for iIndex,key in pairs(m["key"]) do
            if key == sKey then
                table.remove(m["key"],iIndex)
                oPlayer.m_oActiveCtrl:SetData("guidanceinfo",m)
                break
            end
        end
    end
end

function C2GSClickTaskInScene(oPlayer,mData)
    local iSceneId = mData.sceneid
    local iTaskid = mData.taskid
    oPlayer.m_oTaskCtrl:ClickTaskInScene(oPlayer,iTaskid,iSceneId)
end

function C2GSGetTaskBarrage(oPlayer,mData)
    local iShowId = mData.showid
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("dailytask")
    oHuodong:GetTaskBarrage(oPlayer,iShowId)
end

function C2GSSetTaskBarrage(oPlayer,mData)
    local iShowId = mData.showid
    local sMsg = mData.msg
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("dailytask")
    oHuodong:SetTaskBarrage(oPlayer,iShowId,sMsg)
end

function C2GSEnterShow(oPlayer,mData)
    local iIsShow = mData.is_show
    oPlayer.m_oActiveCtrl:SetData("task_show",iIsShow)
    local iReEnterScene = mData.reenter_scene
    if iReEnterScene == 1 then
        local oNowWar = oPlayer:GetNowWar()
        if oNowWar then
            local oPubMgr = global.oPubMgr
            oPubMgr:LeaveWatchWar(oPlayer)
        else
            local oSceneMgr = global.oSceneMgr
            local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
            local mNowPos = {
                pos = oPlayer.m_oActiveCtrl:GetNowPos(),
            }
            if oPlayer:IsSocialDisplay() then
                oPlayer:CancelSocailDisplay()
            end
            oSceneMgr:ReEnterScene(oPlayer,oNowScene:GetSceneId(),mNowPos)
        end
    end
end

function C2GSSyncTraceInfo(oPlayer,mData)
    local iTaskid = mData.taskid
    local iCurMap = mData.cur_mapid
    local iCurPosX = mData.cur_posx
    local iCurPosY = mData.cur_posy
    oPlayer.m_oTaskCtrl:SyncTraceInfo(iTaskid,iCurMap,iCurPosX,iCurPosY)
end

function C2GSGetAchieveTaskReward(oPlayer,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Forward("C2GSGetAchieveTaskReward",oPlayer:GetPid(),mData)
end

function C2GSTriggerPatrolFight(oPlayer,mData)
    local iTaskid = mData.taskid
    oPlayer.m_oTaskCtrl:TriggerPatrolFight(iTaskid)
end

local ClientAchieveTask = {
    ["查看成长手册"]=true,
}

function C2GSFinishAchieveTask(oPlayer,mData)
    local sKey = mData.key
    local iValue = mData.value
    if sKey ~= "" and iValue ~= 0 and ClientAchieveTask[sKey] then
        global.oAchieveMgr:PushAchieve(oPlayer.m_iPid,sKey,{value=iValue})
    end
end

function C2GSFinishShimenTask(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("shimen")
    if oHuodong then
        oHuodong:FinishTask(oPlayer.m_iPid)
    end
end

function C2GSAcceptShimenTask(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("shimen")
    if oHuodong then
        local bValid,iMsg,mParam = oHuodong:ValidGetTask(oPlayer.m_iPid)
        if not bValid then
            return
        end
        oHuodong:ReceiveTask(oPlayer.m_iPid)
    end
end