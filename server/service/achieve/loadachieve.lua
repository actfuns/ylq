local global = require "global"

local achieveobj = import(service_path("achieveobj"))
local pictureobj = import(service_path("pictureobj"))
local sevendayobj = import(service_path("sevendayobj"))
local achievetaskobj = import(service_path("achievetaskobj"))

function CreateAchieve(iAchieveID)
    return achieveobj.NewAchieve(iAchieveID)
end

function LoadAchieve(iAchieveID,mData)
    local oAchieve = achieveobj.NewAchieve(iAchieveID)
    oAchieve:Load(mData)
    return oAchieve
end

function CreatePicture(iPictureID)
    return pictureobj.NewPicture(iPictureID)
end

function LoadPicture(iPictureID,mData)
    local oPicture = pictureobj.NewPicture(iPictureID)
    oPicture:Load(mData)
    return oPicture
end

function CreateAchieveTask(iTaskId)
    return achievetaskobj.NewAchieveTask(iTaskId)
end

function LoadAchieveTask(iTaskId,mData)
    local oTask = achievetaskobj.NewAchieveTask(iTaskId)
    oTask:Load(mData)
    return oTask
end

function GetAchieveTaskInfo(iTaskId)
    local res = require "base.res"
    local mData = res["daobiao"]["achieve"]["achievetask"]
    assert(mData[iTaskId],"GetAchieveTaskInfo:"..iTaskId)
    return mData[iTaskId]
end

function IsExistAchieve(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][iAchieveID]
end

function CreateSevenDay(iAchieveID)
    return sevendayobj.NewSevenDay(iAchieveID)
end

function LoadSevenDay(iAchieveID, mData)
    local oSevenDay = sevendayobj.NewSevenDay(iAchieveID)
    oSevenDay:Load(mData)
    return oSevenDay
end
