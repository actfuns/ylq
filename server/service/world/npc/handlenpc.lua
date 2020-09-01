--import module

local global = require "global"

local mRespondList = {}

function ClearRespond(pid)
    mRespondList[pid] = nil
end

function SetRespond(pid,npcid,resfunc,func)
    mRespondList[pid] = {npcid,resfunc,func}
end

function GetRespond(pid)
    return mRespondList[pid]
end

function Respond(pid,npcid,iAnswer)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    assert(oPlayer,string.format("handlenpc Respond:%d player err",pid))
    local mRespond = GetRespond(pid)
    if not mRespond then
        return
    end
    ClearRespond(pid)
    local id,resfunc,func = table.unpack(mRespond)
    if npcid ~= id then
        return
    end
    if resfunc then
        if not resfunc() then
            return
        end
    end
    func(pid,iAnswer)
end