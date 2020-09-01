--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function GetPlayerAdminInfo(mRecord, mData)
    -- 无用方法
    interactive.Response(mRecord.source, mRecord.session, {
        errcode = 0,
        data = {},
    })
end

function GetPlayerDetailInfo(mRecord, mData)
    local oBusinessObj = global.oBusinessObj
    local br,m = safe_call(oBusinessObj.GetPlayerDetailInfo,oBusinessObj,mData,function(mRet)
            interactive.Response(mRecord.source, mRecord.session, mRet)
    end)
    if not br then
        interactive.Response(mRecord.source, mRecord.session, {
                errcode = 2,
                errmsg = "world service call error",
        })
    end
end

function SearchPartnerDetail(mRecord, mData)
    local oBusinessObj = global.oBusinessObj
    local br,m = safe_call(oBusinessObj.SearchPartnerDetail,oBusinessObj,mData,function(mRet)
            interactive.Response(mRecord.source, mRecord.session, mRet)
    end)
    if not br then
        interactive.Response(mRecord.source, mRecord.session, {
                errcode = 2,
                errmsg = "world service call error",
        })
    end
end

function SearchFuWenDetail(mRecord, mData)
    local oBusinessObj = global.oBusinessObj
    local br,m = safe_call(oBusinessObj.SearchFuWenDetail,oBusinessObj,mData,function(mRet)
            interactive.Response(mRecord.source, mRecord.session, mRet)
    end)
    if not br then
        interactive.Response(mRecord.source, mRecord.session, {
                errcode = 2,
                errmsg = "world service call error",
        })
    end
end




function rankPlayer(mRecord, mData)
    local oBusinessObj = global.oBusinessObj

    local br, m = safe_call(oBusinessObj.RankPlayer, oBusinessObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function currencyQuery(mRecord, mData)
    local oBusinessObj = global.oBusinessObj

    local br, m = safe_call(oBusinessObj.CurrencyQuery, oBusinessObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end