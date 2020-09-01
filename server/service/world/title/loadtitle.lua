--import module

local global = require "global"

function GetTitlePath(iTid)
    if global.oDerivedFileMgr:ExistFile("title","custom","t"..iTid) then
        return string.format("title/custom/t%d",iTid)
    end
    return "title.titleobj"
end

function NewTitle(iPid,iTid,...)
    local sPath = GetTitlePath(iTid)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("loadtitle err:%d",iTid))
    local o = oModule.NewTitle(iPid,iTid,...)
    o:Init()
    return o
end

function GetTitleDataByTid(iTid)
    local res = require "base.res"
    local mData = res["daobiao"]["title"]["title"][iTid]
    assert(mData,string.format("loadtitle GetTitleDataByTid err: %d", iTid))
    return mData
end

function HasTitle(iTid)
    local res = require "base.res"
    local mData = res["daobiao"]["title"]["title"][iTid]
    if mData then
        return true
    end
    return false
end