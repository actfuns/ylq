--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function MergeHuodong(mRecord, mData)
    local sHuodongName = mData.name
    local mFromData = mData.data

    local sErrMsg
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong(sHuodongName)
    if oHuodong then
        local r, msg = oHuodong:MergeFrom(mFromData)
        if not r then
            sErrMsg = string.format("huodong %s merge failed : %s", sHuodongName, msg)
        end
    else
        sErrMsg = string.format("huodong %s merge failed : no such huodong", sHuodongName)
    end
    interactive.Response(mRecord.source, mRecord.session, {
        err = sErrMsg,
    })
end

function MergeHongbao(mRecord, mData)
    local oHbMgr = global.oHbMgr
    local r, msg = oHbMgr:MergeFrom(mData)
    local errmsg
    if not r then
        errmsg = "global redpacket merge failed : "..msg
    end
    interactive.Response(mRecord.source, mRecord.session, {
        err = errmsg,
    })
end

function MergeGlobalAccount(mRecord, mData)
    local oAccountMgr = global.oAccountMgr
    local r, msg = oAccountMgr:MergeFrom(mData)
    local errmsg
    if not r then
        errmsg = "global player_account merge failed : "..msg
    end
    interactive.Response(mRecord.source, mRecord.session, {
        err = errmsg,
    })
end

function MergeWelfarecenter(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local r, msg = oFuliMgr:MergeFrom(mData)
    local errmsg
    if not r then
        errmsg = "global welfarecenter failed : "..msg
    end
    interactive.Response(mRecord.source, mRecord.session, {
        err = errmsg,
    })
end

function MergePartnerCmt(mRecord,mData)
    local oPartnerCmtMgr = global.oPartnerCmtMgr
    local r, msg = oPartnerCmtMgr:MergeFrom(mData)
    local errmsg
    if not r then
        errmsg = "global welfarecenter failed : "..msg
    end
    interactive.Response(mRecord.source, mRecord.session, {
        err = errmsg,
    })
end

function MergeWorld(mRecord, mData)
    local oWorldMgr = global.oWorldMgr
    local r, msg = oWorldMgr:MergeFrom(mData)
    local errmsg
    if not r then
        errmsg = "world merge failed : "..msg
    end
    interactive.Response(mRecord.source, mRecord.session, {
        err = errmsg,
    })
end