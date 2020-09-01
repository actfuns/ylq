
local skynet = require "skynet"
local interactive = require "base.interactive"

local M = {}

function M.check_log_db(sType, sSubType, mLog)
    local res = require "base.res"
    local mFormat = table_get_depth(res, {"daobiao", "log", sType, sSubType, "log_format"})
    assert(mFormat, string.format("check_log err: type err %s %s", sType, sSubType))
    for k, _ in pairs(mLog) do
        if not mFormat[k] and k ~= "_time" then
            assert(false, string.format("check_log err: %s %s undefined key %s", sType, sSubType, k))
            return
        end
    end
    for k, _ in pairs(mFormat) do
        if nil == mLog[k] then
            assert(false, string.format("check_log err: %s %s unformat key %s", sType, sSubType, k))
            return
        end
    end
end

function M.log_db(sType, sSubType, mLog)
    if not is_production_env() then
        safe_call(M.check_log_db, sType, sSubType, mLog)
    end
    mLog.subtype = sSubType
    interactive.Send(".logdb", "common", "PushLog",  {type = sType, data = mLog})
end

function M.log_unmovedb(sType, sSubType, mLog)
    if not is_production_env() then
        safe_call(M.check_log_db, sType, sSubType, mLog)
    end
    mLog.subtype = sSubType
    interactive.Send(".logdb", "common", "PushUnmoveLog",  {type = sType, data = mLog})
end

function M.log_chatdb(sType,sSubType,mLog)
    safe_call(M.check_log_db, sType, sSubType, mLog)
    mLog.subtype = sSubType
    interactive.Send(".logdb", "common", "PushChatLog",  {type = sType, data = mLog})
end

function M.log_file(sSubType, sMsg, ...)
    local s = string.format("[%s] %s", sSubType, string.format(sMsg, ...))
    skynet.error(s)
end

function M.user(sType, sSubType, mLog)
    M.log_db(sType, sSubType, mLog)
end

function M.unmove(sType, sSubType, mLog)
    M.log_unmovedb(sType, sSubType, mLog)
end

function M.chat(sType,sSubType,mLog)
    M.log_chatdb(sType, sSubType, mLog)
end

function M.error(sMsg, ...)
    M.log_file("ERROR", sMsg, ...)
end

function M.info(sMsg, ...)
    M.log_file("INFO", sMsg, ...)
end

function M.warning(sMsg, ...)
    M.log_file("WARNING", sMsg, ...)
end

function M.debug(sMsg, ...)
    M.log_file("DEBUG", sMsg, ...)
end

return M
