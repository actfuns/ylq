local global = require "global"

local mTaskDir = {
    ["test"] = {1,200},
    ["lilian"] = {500,501},
    ["dailytrain"] = {502,503},
    ["practice"] = {1000,1999},
    ["daily"] = {2000,2999},
    ["huodong"] = {5000,5999},
    ["plot"] = {6000,9999},
    ["story"] = {10000,29999},
    ["teach"] = {30000,31000},
    --["achieve"] = {31001,31999},
    ["shimen"] = {60000,61999},
    ["partner"] = {62000,69999},
}

local mTaskList = {}

function GetDir(taskid)
    for sDir,mPos in pairs(mTaskDir) do
        local iStart,iEnd = table.unpack(mPos)
        if iStart <= taskid and taskid <= iEnd then
            return sDir
        end
    end
end

function CreateTask(taskid)
    local sDir = GetDir(taskid)
    local sPath
    if global.oDerivedFileMgr:ExistFile("task", sDir, "t" .. taskid) then
        sPath = string.format("task/%s/t%s",sDir,taskid)
    else
        sPath = string.format("task/%s/%sbase",sDir,sDir)
    end
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("Create Task err:%d %s",taskid,sPath))
    local res = require "base.res"
    if not res["daobiao"]["task"][sDir] or not res["daobiao"]["task"][sDir]["task"] or not res["daobiao"]["task"][sDir]["task"][taskid] then
        print("liuwei-debug,CreateTask failed:"..taskid)
        return nil
    end
    local oTask = oModule.NewTask(taskid)
    return oTask
end

function GetTask(taskid)
    local oTask = mTaskList[taskid]
    if not oTask then
        oTask = CreateTask(taskid)
        mTaskList[taskid] = oTask
    end
    return oTask
end

function LoadTask(taskid,mArgs)
    local sDir = GetDir(taskid)
    local sPath
    if global.oDerivedFileMgr:ExistFile("task", sDir, "t" .. taskid) then
        sPath = string.format("task/%s/t%s",sDir,taskid)
    else
        sPath = string.format("task/%s/%sbase",sDir,sDir)
    end
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("Create Task err:%d %s",taskid,sPath))
    local res = require "base.res"
    if not res["daobiao"]["task"][sDir] or not res["daobiao"]["task"][sDir]["task"] or not res["daobiao"]["task"][sDir]["task"][taskid] then
        print("liuwei-debug,LoadTask failed:"..taskid)
        return nil
    end
    local oTask = oModule.NewTask(taskid)
    oTask:Load(mArgs)
    oTask:Setup()
    return oTask
end