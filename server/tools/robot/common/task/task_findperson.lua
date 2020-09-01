--寻人任务
local taskobj = require("taskobj")

local CTaskObj = {m_iTaskType = 0}
CTaskObj.__index = CTaskObj
setmetatable(CTaskObj,taskobj)

function CTaskObj:New(iTaskType)
    local o = setmetatable({}, CTaskObj)
    o.m_iTaskType = iTaskType
    return o
end

function CTaskObj:GS2CAutoFindPath(oPlayer,mTaskInfoTbl,mArgs)
    oPlayer:run_cmd("C2GSTaskEvent",{npcid = mArgs.npcid,taskid = mTaskInfoTbl.taskid})
end
return CTaskObj