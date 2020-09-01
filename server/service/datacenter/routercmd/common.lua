--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"

function TestRouterSend(mRecord, mData)
    print("lxldebug datacenter TestRouterSend")
    print("show record")
    print(mRecord)
    print("show data")
    print(#mData.b)
end

function TestRouterRequest(mRecord, mData)
    print("lxldebug datacenter TestRouterRequest")
    print("show record")
    print(mRecord)
    print("show data")
    print(#mData.b)
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {
        errcode = 1,
    })
end

function TryCreateRole(mRecord, mData)
    local sServerTag = mData.server
    local sAccount = mData.account
    local iChannel = mData.channel
    local mInfo = {
        name = mData.name,
        school = mData.school,
        icon = mData.icon,
        platform = mData.platform,
        publisher = mData.publisher,
    }
    local oDataCenter = global.oDataCenter
    oDataCenter:TryCreateRole(sServerTag, sAccount, iChannel,mInfo, function (iNewId)
        if iNewId then
            router.Response(mRecord.srcsk,mRecord.src,mRecord.session,{
                errcode = 0,
                id = iNewId,
            })
        else
            router.Response(mRecord.srcsk,mRecord.src,mRecord.session,{
                errcode = 1
            })
        end
    end)
end

function UpdateRoleInfo(mRecord, mData)
    local iPid = mData.pid
    local mInfo = {
        icon = mData.icon,
        grade = mData.grade,
        school = mData.school,
        name = mData.name,
    }

    local oDataCenter = global.oDataCenter
    oDataCenter:UpdateRoleInfo(iPid, mInfo)
end
