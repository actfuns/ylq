--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local imageobj = import(service_path("imageobj"))

function GetNoPassImages(mRecord, mData)
    local br, mRet = safe_call(imageobj.GetNoPassImages, mData,  function(mRet)
        interactive.Response(mRecord.source, mRecord.session, mRet)
    end)
    if not br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
            errmsg = "backend call failed",
        })
    end
end

function CheckImagePass(mRecord, mData)
    local br, mRet = safe_call(imageobj.CheckImagePass, mData,  function(mRet)
        interactive.Response(mRecord.source, mRecord.session, mRet)
    end)
    if not br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
            errmsg = "backend call failed",
        })
    end
end