--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local serverinfo = import(lualib_path("public.serverinfo"))

local sPlayerTableName = "player"

function GetPlayer(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName, {pid = mData.pid}, {pid = true, account = true,channel = true,base_info = true, ban_time=true, deleted = true,born_server=true})
    return {
        data = m,
        pid = mData.pid
    }
end

function GetPlayerByName(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName, {name = mData.name}, {pid = true, account = true,channel=true,base_info = true, deleted = true})
    local iPid
    if m then
        iPid = m.pid
    end
    return {
        data = m,
        pid = iPid
    }
end

function CreatePlayer(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Insert(sPlayerTableName, mData.data)
end

function RemovePlayer(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName, {pid = mData.pid}, {["$set"] = {deleted = true}})
end

function GetPlayerListByAccount(mCond, mData)
    local oGameDb = global.oGameDb
    local sAccount = mData.account
    local iChannel = mData.channel
    local iPlatform = mData.platform
    local sPublisher = mData.publisher
    local sServerKey = get_server_key()
    local m = oGameDb:Find(sPlayerTableName, {account = sAccount,channel=iChannel}, {pid = true, account = true, base_info = true, deleted = true,platform=true})
    local mRet = {}
    while m:hasNext() do
        local mRoleData = m:next()
        if serverinfo.is_role_interflow(sPublisher,sServerKey) then
            table.insert(mRet, mRoleData)
        else
            if mRoleData.platform == iPlatform then
                table.insert(mRet,mRoleData)
            end
        end
    end
    return {
        data = mRet,
        account = mData.account,
        channel = mData.channel
    }
end

function LoadPlayerMain(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName, {pid = mData.pid}, {name = true,now_server=true})
    return {
        data = m,
        pid = mData.pid
    }
end

function SavePlayerMain(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName, {pid = mData.pid}, {["$set"]=mData.data})
end

function LoadPlayerBase(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName, {pid = mData.pid}, {base_info = true})
    return {
        data = m.base_info or {},
        pid = mData.pid
    }
end

function SavePlayerBase(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName, {pid = mData.pid}, {["$set"]={base_info = mData.data}})
end

function LoadPlayerActive(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName, {pid = mData.pid}, {active_info = true})
    return {
        data = m.active_info or {},
        pid = mData.pid
    }
end

function SavePlayerActive(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName, {pid = mData.pid}, {["$set"]={active_info = mData.data}})
end

function LoadPlayerItem(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{item_info = true})
    return {
        data = m.item_info or {},
        pid = mData.pid
    }
end

function SavePlayerItem(mCond,mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName,{pid=mData.pid},{["$set"]={item_info=mData.data}})
end

function LoadPlayerTimeInfo(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{time_info = true})
    return {
        data = m.time_info or {},
        pid = mData.pid
    }
end

function SavePlayerTimeInfo(mCond,mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName,{pid=mData.pid},{["$set"]={time_info=mData.data}})
end

function LoadPlayerTask(mCond,mData)
   local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{task_info = true})
    return {
        data = m.task_info or {},
        pid = mData.pid
    }
end

function SavePlayerTaskInfo(mCond,mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName,{pid=mData.pid},{["$set"]={task_info=mData.data}})
end

function LoadPlayerHuodongInfo(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{huodong_info = true})
    return {
        data = m.huodong_info or {},
        pid = mData.pid
    }
end

function SavePlayerHuodongInfo(mCond,mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName,{pid=mData.pid},{["$set"]={huodong_info=mData.data}})
end

function LoadSkillInfo(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{skill_info = true})
    return {
        data = m.skill_info or {},
        pid = mData.pid,
    }
end

function SaveSkillInfo(mCond,mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName,{pid=mData.pid},{["$set"]={skill_info=mData.data}})
end

function LoadPlayerSchedule(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{schedule_info = true})
    return {
        data = m.schedule_info or {},
        pid = mData.pid,
    }
end

function SavePlayerSchedule(mCond,mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName,{pid=mData.pid},{["$set"]={schedule_info=mData.data}})
end

function LoadPlayerState(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{state_info = true})
    return {
        data = m.state_info or {},
        pid = mData.pid,
    }
end

function SavePlayerState(mCond,mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName,{pid=mData.pid},{["$set"]={state_info=mData.data}})
end

function LoadPlayerPartner(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{partner_info = true})
    return {
        data = m.partner_info or {},
        pid= mData.pid
    }
end

function SavePlayerPartner(mCond,mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName,{pid=mData.pid},{["$set"]={partner_info=mData.data}})
end

function LoadPlayerTitle(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{title_info = true})
    return {
        data = m.title_info or {},
        pid = mData.pid
    }
end

function SavePlayerTitle(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName, {pid=mData.pid}, {["$set"]={title_info = mData.data}})
end


function LoadPlayerHandBook(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{handbook = true})
    return {
        data = m.handbook or {},
        pid = mData.pid
    }
end

function SavePlayerHandBook(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName, {pid=mData.pid},  {["$set"]={handbook = mData.data}})
end

function GetConflictNamePlayer(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:Find(sPlayerTableName, {}, {pid = true, name = true, now_server = true})
    local mPlayers = {}
    local mRet = {}
    while m:hasNext() do
        local mInfo = m:next()
        local sName = mInfo.name
        local mNameInfo = mPlayers[sName]
        if not mNameInfo then
            mPlayers[sName] = mInfo
        else
            if mNameInfo.now_server and mNameInfo.now_server ~= get_server_tag() then
                mPlayers[sName] = mInfo
                mRet[mNameInfo.pid] = sName
            elseif mInfo.now_server and mInfo.now_server ~= get_server_tag() then
                mRet[mInfo.pid] = sName
            end
        end
    end
    return mRet
end

function LoadParSoulPlan(mCond,mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sPlayerTableName,{pid = mData.pid},{parsoul_plan = true})
    return {
        data = m.parsoul_plan or {},
        pid= mData.pid
    }
end

function SaveParSoulPlan(mCond,mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sPlayerTableName,{pid=mData.pid},{["$set"]={parsoul_plan=mData.data}})
end