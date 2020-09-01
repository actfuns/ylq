local global = require "global"
local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local interactive = require "base.interactive"
local record = require "public.record"
require "skynet.manager"
local serverdefines = require "public.serverdefines"

local logiccmd = import(service_path("logiccmd.init"))
local dictatorcmd = import(service_path("dictatorcmd"))
local dictatorobj = import(service_path("dictatorobj"))

local function FormatTable(t)
    local l = {}
    for k in pairs(t) do
        table.insert(l, k)
    end
    table.sort(l)
    local lRes = {}
    for _, v in ipairs(l) do
        table.insert(lRes, string.format("%s:%s", v, tostring(t[v])))
    end
    return table.concat(lRes, "\t")
end

local function DumpLine(print_back, k, v)
    if type(v) == "table" then
        print_back(k, FormatTable(v))
    else
        print_back(k, tostring(v))
    end
end

local function DumpList(print_back, list)
    local l = {}
    for k in pairs(list) do
        table.insert(l, k)
    end
    table.sort(l)
    for _,v in ipairs(l) do
        DumpLine(print_back, v, list[v])
    end
    print_back("ok")
end

local function SplitCmd(sLine)
    local lSplit = {}
    for _, v in ipairs(split_string(sLine, " ")) do
        table.insert(lSplit, v)
    end
    return lSplit
end

local function DoCmd(sLine, print_back, fd)
    local lSplit = SplitCmd(sLine)
    local sCmd = lSplit[1]
    local funcCmd = dictatorcmd[sCmd]
    local ok, list
    if funcCmd then
        ok, list = pcall(funcCmd, fd, print_back, select(2, table.unpack(lSplit)))
    else
        print_back("invalid command")
    end

    if ok then
        if list then
            if type(list) == "string" then
                print_back(list)
            else
                DumpList(print_back, list)
            end
        else
            print_back("ok")
        end
    else
        print_back("error:", list)
    end
end

local function ReceiveDictatorCmd(stdin, print_back)
    print_back("welcome to skynet dictator console")

    local f = function ()
        while true do
            local sLine = socket.readline(stdin, "\n")
            if not sLine then
                break
            end
            if sLine:sub(1,4) == "GET " then
                local sCode, sUrl = httpd.read_request(sockethelper.readfunc(stdin, sLine.. "\n"), 8192)
                local sLine = sUrl:sub(2):gsub("/"," ")
                DoCmd(sLine, print_back, stdin)
                break
            end
            if sLine ~= "" then
                DoCmd(sLine, print_back, stdin)
            end
        end
    end

    safe_call(f)

    socket.close(stdin)
end

skynet.start(function()
    interactive.Dispatch(logiccmd)

    global.oDictatorObj = dictatorobj.NewDictatorObj()
    global.oDictatorObj:Init()

    local iDictatorPort = assert(serverdefines.get_dictator_port())
    local iListenSocket = socket.listen ("127.0.0.1", iDictatorPort)
    skynet.error("start dictator at 127.0.0.1 " .. iDictatorPort)
    socket.start(iListenSocket , function(id, addr)
        local function print_back(...)
            local t = { ... }
            for k,v in ipairs(t) do
                t[k] = tostring(v)
            end
            socket.write(id, table.concat(t,"\t"))
            socket.write(id, "\n")
        end
        socket.start(id)
        skynet.fork(ReceiveDictatorCmd, id , print_back)
    end)

    skynet.register ".dictator"

    record.info("dictator service booted")
end)
