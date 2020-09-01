
local skynet = require "skynet"
local lfs = require "lfs"

function exist_file(sFile)
    local f = io.open(sFile)
    if not f then
        return false
    end
    f:close()
    return true
end

function write_file(sFile,content)
    local f = io.open(sFile,"a")
    if not f then
        return false
    end
    f:write(content.."\n")
    f:close()
    return true
end

function rename_file(sOldFile,sNewFile)
    if not exist_file(sOldFile) then
        return false
    end
    local statu,err = os.rename(sOldFile,sNewFile)
    if not statu then
        return false,err
    end
    return true
end

function file_last_changetime(sFile)
    if not exist_file(sFile) then
        return
    end
    local time = lfs.attributes(sFile,"change")
    return time
end

function create_folder(sFold)
    if exist_file(sFold) then
        return true
    end
    local bSuc,err = lfs.mkdir(sFold)
    if not bSuc then
        skynet.error("mkdir err "..sFold.." Msg: "..err)
    end
    return bSuc
end

function get_all_folders(sPath)
    local list = {}
    for file in lfs.dir(sPath) do
        local f = sPath .. '/' .. file
        local attr = lfs.attributes(f)
        if attr.mode == "directory" then
            table.insert(list,file)
        end
    end
    return list
end

function get_all_files(sPath)
    local list = {}
    for file in lfs.dir(sPath) do
        if file == "." or file == ".." then
            goto continue
        end
        local f = sPath .. '/' .. file
        local attr = lfs.attributes(f)
        if attr.mode == "file" then
            table.insert(list,file)
        end
        ::continue::
    end
    return list
end

function write_file_byfd(f,content)
    if not f then
        return false
    end
    f:write(content.."\n")
    f:flush()
    return true
end