local global = require "global"

local loadtask = import(service_path("task/loadtask"))


Commands = {}
Helpers = {}
Opens = {}  --是否对外开放

Helpers.help = {
    "GM指令帮助",
    "help 指令名",
    "help 'clearall'",
}
function Commands.help(oMaster, sCmd)
    if sCmd then
        local o = Helpers[sCmd]
        if o then
            local sMsg = string.format("%s:\n指令说明:%s\n参数说明:%s\n示例:%s\n", sCmd, o[1], o[2], o[3])
            oMaster:Send("GS2CGMMessage", {
                msg = sMsg,
            })
        else
            oMaster:Send("GS2CGMMessage", {
                msg = "没查到这个指令"
            })
        end
    end
end

Helpers.addtask={
    "增加任务",
    "addtask 任务编号",
    "addtask 101"
}
function Commands.addtask(oMaster,taskid)
    if not taskid then
        return
    end
    taskid = tonumber(taskid)
    if not taskid then
        return
    end
    local oTask = loadtask.CreateTask(taskid)
    if not oTask then
        return
    end
    oMaster:AddTask(oTask)
end

Helpers.cleartask={
    "清除任务",
    "cleartask",
    "cleartask",
}
function Commands.cleartask(oMaster)
    for taskid,oTask in pairs(oMaster.m_oTaskCtrl.m_mList) do
        oMaster.m_oTaskCtrl:RemoveTask(oTask)
    end
end

Helpers.SetDailyTask={
    "设置考验任务概率",
    "SetDailyTask pid rate",
}
function Commands.SetDailyTask(oMaster,iPid,iRate)
    if iRate then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oPlayer then
            return
        end
        oPlayer:SetInfo("GMDailyTaskRate",iRate)
    else
        oMaster:SetInfo("GMDailyTaskRate",iPid)
    end
end

function Commands.PushAchieveTask(oMaster,sKey,iValue)
    if not sKey or not iValue then
        return
    end
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:PushAchieve(oMaster.m_iPid,sKey,{value = tonumber(iValue)})
end