local skynet = require "skynet"
local interactive = require "base.interactive"

LOG_BASE_PATH = "/home/nucleus-n1/log"
mFilePath = mFilePath or {}
mFileFd = mFileFd or {}

function log_data(sName, sData)
    interactive.Send(".logfile", "common", "WriteData",  {sName = sName, data = sData})
end

function write_data(sName,sData)
    local sFile = string.format("%s/%s/%s",LOG_BASE_PATH,MY_SERVER_KEY,sName)
    if mFilePath[sName] or create_folder(sFile) then
        local m = os.date("*t", get_time())
        local sFile = string.format("%s/%s_%04d-%02d-%02d",sFile,sName,m.year,m.month,m.day)
        local fd = mFileFd[sName]
        if not fd or mFilePath[sName] ~= sFile then
            if fd then
                fd:close()
            end
            fd = io.open(sFile,"a")
        end
        write_file_byfd(fd,sData)
        mFileFd[sName] = fd
        mFilePath[sName] = sFile
    end
end

function datajoin(mList)
    mList = mList or {}
    local str = ""
    for k,v in pairs(mList) do
        if str == "" then
            str = str .. k .. "+" .. v
        else
            str = str.. "&" .. k .. "+" .. v
        end
    end
    return str
end