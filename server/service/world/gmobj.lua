--import module
local global = require "global"
local extend = require "base/extend"
local record = require "public.record"

local auth = import(service_path("gm/gm_auth"))

function NewGMMgr(...)
    local o = CGMMgr:New(...)
    return o
end

CGMMgr = {}
CGMMgr.__index = CGMMgr
inherit(CGMMgr, logic_base_cls())

function CGMMgr:New()
    local o = super(CGMMgr).New(self)
    return o
end

function CGMMgr:GetGmFile()
    return {
        "gm_email",
        "gm_house",
        "gm_huodong",
        "gm_item",
        "gm_org",
        "gm_partner",
        "gm_rank",
        "gm_reward",
        "gm_scene",
        "gm_server",
        "gm_state",
        "gm_task",
        "gm_title",
        "gm_user",
        "gm_war",
        "gm_picture",
        "gm_test",
    }
end

function CGMMgr:ValidUseCommand(oMaster,sCommand)
    if not auth.ValidUseCommand(oMaster,sCommand) then
        return false
    end
    return true
end

function CGMMgr:IsGM(iPid)
    if auth.IsGM(iPid) then
        return true
    end
    return false
end

function CGMMgr:DoCommand(oMaster,sCommand,lCommandArgs)
    if not self:ValidUseCommand(oMaster,sCommand) then
        return
    end
    local mFile = self:GetGmFile()
    local bFlag = false
    local oNotifyMgr = global.oNotifyMgr
    for _,sFile in pairs(mFile) do
        local oFile = import(service_path(string.format("gm/%s",sFile)))
        local f = oFile.Commands[sCommand]
        if f then
            if is_production_env() and not oFile.Opens[sCommand] and sCommand ~= "help" then
                oNotifyMgr:Notify(oMaster:GetPid(),"该指令暂未开放")
                return
            end
            f(oMaster,table.unpack(lCommandArgs))
            bFlag = true
        end
    end
    assert(bFlag, string.format("ReceiveCmd fail cmd:%s", sCommand))
end

function CGMMgr:ReceiveCmd(oMaster, sCmd)
    local mMatch = {}
    mMatch["{"] = "}"
    mMatch["\""] = "\""

    local iState = 1
    local iBegin = 1
    local iEnd = 0

    local sMatch = nil
    local iMatch = 0

    local lArgs = {}
    for i = 1, #sCmd do
        local c = index_string(sCmd, i)
        if iState == 1 then
            if c == " " then
                iEnd = i-1
                iState = 3
                if iEnd>=iBegin then
                    table.insert(lArgs, string.sub(sCmd, iBegin, iEnd))
                end
            elseif mMatch[c] then
                assert(false, string.format("ReceiveCmd fail %d %s %s", iState, c, mMatch[c]))
            end
        elseif iState == 2 then
            if iMatch <= 0 then
                if c == " " then
                    iEnd = i-1
                    iState = 3
                    if iEnd>=iBegin then
                        table.insert(lArgs, string.sub(sCmd, iBegin, iEnd))
                    end
                else
                    assert(false, string.format("ReceiveCmd fail %d %s %s", iState, c, mMatch[c]))
                end
            else
                if index_string(sCmd, i-1) == "\\" then
                    -- pass
                elseif c == mMatch[sMatch] then
                    iMatch = iMatch - 1
                elseif c == sMatch then
                    iMatch = iMatch + 1
                end
            end
        else
            -- 单词开始
            if mMatch[c] then
                iState = 2
                iBegin = i
                sMatch = c
                iMatch = 1
            elseif c ~= " " then
                iBegin = i
                iState = 1
            end
        end
    end

    if iState == 1 then
        iEnd = #sCmd
        if iEnd>=iBegin then
            table.insert(lArgs, string.sub(sCmd, iBegin, iEnd))
        end
    elseif iState == 2 then
        if iMatch <= 0 then
            iEnd = #sCmd
            if iEnd>=iBegin then
                table.insert(lArgs, string.sub(sCmd, iBegin, iEnd))
            end
        end
    end
    local sCommand = lArgs[1]
    local lCommandArgs = {}
    for k = 2, #lArgs do
        local v = lArgs[k]
        local ff, sErr = load(string.format("return %s", v), "", "bt", {})
        assert(ff, string.format("ReceiveCmd fail [%s] index:%d value:%s", sErr, k, v))
        local b, r = xpcall(ff, function ()
            --ignore
        end)
        if not b or r == nil then
            r = v
        end
        table.insert(lCommandArgs, r)
    end
    local mLog = {
        pid = oMaster:GetPid(),
        name = oMaster:GetName(),
        cmd = sCommand,
        arg = extend.Table.serialize(lCommandArgs)
    }
    record.user("test","gm",mLog)

    self:DoCommand(oMaster,sCommand,lCommandArgs)
end
