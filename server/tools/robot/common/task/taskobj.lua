local tprint = require('extend').Table.print
local res = require("data")
function NewTaskObj(...)
    return CTaskObj:New(...)
end

local CTaskObj = {}
CTaskObj.__index = CTaskObj

function CTaskObj:New(iTaskType)
    local o = setmetatable({}, CTaskObj)
    o.m_iTaskType = iTaskType
    return o
end

function CTaskObj:GS2CDialog(oPlayer,mTaskInfoTbl,mArgs)
    local iSessionIdx = mArgs.sessionidx
    oPlayer:sleep(1)
    oPlayer:run_cmd("C2GSCallback",{sessionidx = iSessionIdx})
end

function CTaskObj:GS2CNpcSay(oPlayer,mTaskInfoTbl,mArgs)
    local iSessionIdx = mArgs.sessionidx
    oPlayer:sleep(1)
    oPlayer:run_cmd("C2GSCallback",{answer = 1,sessionidx = iSessionIdx})
end

function CTaskObj:GS2COpenShop(oPlayer,mTaskInfoTbl,mArgs)
    local mItemtbl = mTaskInfoTbl.needitem
    local mShopData = res["npcstore"]["data"]
    local iSuccessBuyCount  = 0
    for i = 1,#mItemtbl do
        local iItemId,iAmount = mItemtbl[i].itemid,mItemtbl[i].amount
        for key,value in pairs(mShopData) do
            if value.item_id == iItemId then
                oPlayer:run_cmd("C2GSNpcStoreBuy",{buy_count = iAmount,buy_id = key})
                iSuccessBuyCount = iSuccessBuyCount + 1
                oPlayer:sleep(1)
                break
            end
        end
    end
    assert(iSuccessBuyCount == #mItemtbl,"有东西没买到")
    oPlayer:run_cmd("C2GSClickTask", {taskid = mTaskInfoTbl.taskid})
end

function CTaskObj:GS2CShowWar(oPlayer,mTaskInfoTbl,mArgs)
    oPlayer:sleep(1)
    oPlayer:run_cmd("C2GSGMCmd",{cmd = "warend"})
end

function CTaskObj:GS2CAutoFindPath(oPlayer,mTaskInfoTbl,mArgs)
    oPlayer:run_cmd("C2GSTaskEvent",{npcid = mArgs.npcid,taskid = mTaskInfoTbl.taskid})
end

return CTaskObj