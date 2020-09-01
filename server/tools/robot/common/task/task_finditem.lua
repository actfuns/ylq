--寻物任务
local taskobj = require("taskobj")

local CTaskObj = {m_iTaskType = 0}
CTaskObj.__index = CTaskObj
setmetatable(CTaskObj,taskobj)

function CTaskObj:New(iTaskType)
    local o = setmetatable({}, CTaskObj)
    o.m_iTaskType = iTaskType
    return o
end

function CTaskObj:GS2CNpcSay(oPlayer,mCurTaskInfo,mArgs)
    local iSessionIdx = mArgs.sessionidx
    oPlayer:sleep(1)
    oPlayer:run_cmd("C2GSTaskEvent",{npcid = mArgs.npcid,taskid = mCurTaskInfo.taskid})
end

function CTaskObj:GS2CAutoFindPath(oPlayer,mTaskInfoTbl,mArgs)
    local iNpcId = mArgs.npcid
    oPlayer:run_cmd("C2GSClickNpc",{npcid = iNpcId})
end

return CTaskObj