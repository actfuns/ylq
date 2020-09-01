package.cpath = package.cpath .. ";../../build/clualib/?.so"
package.path = package.path .. ";../../lualib/base/?.lua;../../cs_common/proto/?.lua;../../skynet/lualib/?.lua;../../skynet/examples/?.lua"..";./?.lua"

local socket = require "clientsocket"
local tprint = require('extend').Table.print
local protobuf = require "protobuf"
local netdefines = require "netdefines"
local xor = require "xor"


local sProtoPath = "../../cs_common/proto/proto.pb"
protobuf.register_file(sProtoPath)

local function Trace(sMsg)
    print(debug.traceback(sMsg))
end

function safe_call (func, ...)
    return xpcall(func, Trace, ...)
end

local M = {}

local g_session = 0
local function new_session()
    g_session = g_session + 1
    return g_session
end


local function s2c_unpack_req(s)
    assert(#s >= 2, "s2c_unpack_req error")
    local iType = s:byte(1)*(2^8) + s:byte(2)
    local m = netdefines.GS2C[iType]
    assert(m, "s2c_unpack_req error")
    local args, sErr = protobuf.decode(m[2], string.sub(s, 3))
    assert(args, sErr)
    return m[2], args
end

local function c2s_pack_req(name, args, session)
    local iType = netdefines.C2GS_BY_NAME[name]
    assert(iType, "c2s_pack_req error")
    local sEncode = protobuf.encode(name, args)
    local iPow = 8
    local lst = {}
    for i = 1, 2 do
        table.insert(lst,  string.char((iType//(2^iPow))%256))
        iPow = iPow - 8
    end
    table.insert(lst, sEncode)
    sEncode = table.concat(lst, "")
    return sEncode
end

local function c2s_big_pack_req(name, args, session)
    local iType = netdefines.C2GS_BY_NAME[name]
    assert(iType, "c2s_big_pack_req error")
    local sEncode = protobuf.encode(name, args)

    local iLen = #sEncode
    local iSplit = 10*1024
    local iStart = 1
    local l = {}
    local lRet = {}
    while iStart <= iLen do
        local iNext = iStart + iSplit
        local s = string.sub(sEncode, iStart, iNext - 1)
        iStart = iNext
        table.insert(l, s)
    end
    for k, v in ipairs(l) do
        table.insert(lRet, c2s_pack_req("C2GSBigPacket", {
            type = iType,
            total = #l,
            index = k,
            data = v,
        }))
    end
    return lRet
end

local ip_regex = "([0-9]+.[0-9]+.[0-9]+.[0-9]+)"
function host2ip(host)
    local ip = string.match(host, ip_regex)
    if ip then
        return ip
    end

    local tmp_file = os.tmpname ()
    local cmd = string.format('host -4 %s|egrep -o "%s" > %s', host, ip_regex, tmp_file)
    os.execute(cmd)
    local fp = io.open(tmp_file)
    local ip = fp:read("*a")
    fp:close()
    os.remove(tmp_file)

    if #ip <= 0 then
        return nil
    end
    local ip = string.sub(ip, 1, #ip - 1)
    print("host to ip suc:", host, ip)

    return ip
end

local Robot = {}
function Robot:new(host, port, opts)
    local opts = opts or {}
    local obj = {
        host = host,
        port = port,
        fd = assert(socket.connect(host, port)),
        last = "",
        slient = opts.slient,
        shield = opts.shield or {},
        coroutines = {},
        timers = {},
        callers = {},
        server_request_handlers = {},
        running = true,
        bigpacket_cache = {},
    }
    setmetatable(obj, {__index = Robot})
    return obj
end

function Robot:fork(func, ...)
    local args = {...}
    local func_co = coroutine.create(
        function()
            safe_call(func, table.unpack(args))
        end
    )
    table.insert(self.coroutines, func_co)
end

function Robot:sleep(n)
    local waiter = {
        co = coroutine.running(),
        done = false,
        time = os.time() + n,
    }

    table.insert(self.timers, waiter)
    while true do
        if waiter.done then
            break
        end
        coroutine.yield()
    end
end

function Robot:send_client_request(name, args, session)
    if not self.slient and not self.shield[name] then
        print("[REQUEST]", name, session)
        if args then
            tprint(args)
        end
        print()
    end
    local s = c2s_pack_req(name, args, session)
    s= xor.code(s)
    socket.send(self.fd, string.pack(">s2", s))
end

function Robot:send_big_client_request(name, args, session)
    if not self.slient and not self.shield[name] then
        print("[REQUEST]", name, session)
        if args then
            tprint(args)
        end
        print()
    end
    local l = c2s_big_pack_req(name, args, session)
    for _, v in ipairs(l) do
        v= xor.code(v)
        socket.send(self.fd, string.pack(">s2", v))
    end
end

function Robot:handle_server_request(name, args)
    local bFlag = true
    if name == "GS2CBigPacket" then
        bFlag = false
        local ty = args.type
        local total = args.total
        local index = args.index
        local d = args.data

        if index == 1 then
            self.bigpacket_cache[ty] = nil
        end
        if not self.bigpacket_cache[ty] then
            self.bigpacket_cache[ty] = {}
        end
        table.insert(self.bigpacket_cache[ty], d)
        local l = self.bigpacket_cache[ty]
        if #l ~= index then
            self.bigpacket_cache[ty] = nil
            assert(false, "handle_server_request index error")
        else
            if index == total then
                bFlag = true
                self.bigpacket_cache[ty] = nil
                local sd = table.concat(l, "")

                local m = netdefines.GS2C[ty]
                assert(m, "handle_server_request error")
                local nargs, sErr = protobuf.decode(m[2], sd)
                assert(nargs, sErr)
                name = m[2]
                args = nargs
            end
        end
    end

    if bFlag then
        if not self.slient and not self.shield[name] then
            print("[NOTIFY]", name)
            if args then
                tprint(args)
            end
        end

        if name == "GS2CMergePacket" then
            local lPackets = args.packets
            self:fork(function ()
                for _,sPacket in pairs(lPackets) do
                    local name, args = s2c_unpack_req(sPacket)
                    self:handle_server_request(name, args)
                end
            end)
        else
            local func = self.server_request_handlers[name]
            if func then
                self:fork(func, self, args)
            end
            --extra
            if name == "GS2CLoginRole" then
                self:fork(function ()
                    while 1 do
                        self:sleep(10)
                        self:run_cmd("C2GSHeartBeat", {})
                    end
                end)
            end
        end
    end
end

function Robot:unpack_package(text)
    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = text:byte(1) * 256 + text:byte(2)
    if size < s+2 then
        return nil, text
    end

    return text:sub(3,2+s), text:sub(3+s)
end

function Robot:recv_package(lfd)
    local result
    result, self.last = self:unpack_package(self.last)
    if result then 
        return result
    end
    local r = socket.recv(lfd)
    if not r then
        return nil
    end
    if r == "" then
        error "Server closed"
    end

    result, self.last = self:unpack_package(self.last .. r)
    return result
end

function Robot:parse_cmd(s)
    if s == "" or s == nil then
        return false
    end

    local cmd = ""
    local args_data = nil
    local b, e = string.find(s, " ")
    if b then
        cmd = s:sub(0, b - 1)
        args_data = s:sub(e + 1)
    else
        cmd = s
    end

    if cmd == "script" then
        if not args_data then
            print("illegal cmd", s)
            return false
        end
        return true, cmd, args_data
    end

    local args
    if args_data then
        local f, err = load("return " .. args_data)
        if f == nil then
            print("illegal cmd", s)
            return false
        end

        local ok, _args = pcall(f)
        if (not ok) or (type(_args) ~= 'table') then
            print("illegal cmd", s)
            return false
        end
        args = _args
    end

    return true, cmd, args
end

function Robot:run_cmd(cmd, args)
    if not self.slient and not self.shield[cmd] then
        print('[COMMAND]', cmd, args)
    end
    local session = new_session()
    local ok, err
    if string.sub(cmd, 1, 3) == "big" then
        ok, err = pcall(self.send_big_client_request, self, string.sub(cmd, 5), args, session)
    else
        ok, err = pcall(self.send_client_request, self, cmd, args, session)
    end
    if not ok then
        print('run cmd fail', cmd, args, err)
        return false
    end
end

function Robot:run_script(script)
    if not self.slient then
        print('[script]', script)
    end
    local env = setmetatable(
        {
            client = self,
        },
        {__index = _ENV}
    )

    local func, err = loadfile(script, "bt", env)
    if not func then
        print('load script fail, err', err)
        return
    end
    safe_call(func)
end

function Robot:check_net_package()
    while true do
        -- check net package
        local v = self:recv_package(self.fd)
        if not v then
            return
        end
        v=xor.code(v)
        local name, args = s2c_unpack_req(v)
        self:handle_server_request(name, args)
    end
end

function Robot:check_console()
    local s = socket.readstdin()
    if s == "quit" then
        self.running = false
        return
    end

    if s == "." then
        s = [[C2GSGMCmd {cmd="runtest"}]]
    end
    if (s ~= nil and s ~= "") then
        local ok, cmd, args = self:parse_cmd(s)
        if ok then
            if cmd == "script" then
                self:fork(self.run_script, self, args)
            else
                self:fork(self.run_cmd, self, cmd, args)
            end
        end
    end
end

function Robot:check_io()
    local ok, err = pcall(
        function()
            while self.running do
                self:check_net_package()
                self:check_console()
                coroutine.yield() -- wait next
            end
        end
    )
    if not ok then
        print("[ERROR]:", err)
        self.running = false
    end
end

function Robot:start()
    self:fork(self.check_io, self)
    while self.running do
        -- check coroutine
        local co_list = {} -- copy before iter
        local removed = {}
        for idx, co in ipairs(self.coroutines) do
            if coroutine.status(co) == "dead" then
                removed[co] = true
            else
                table.insert(co_list, co)                    
            end
        end

        for _, co in ipairs(co_list) do
            -- double check co status
            if coroutine.status(co) ~= "dead" then
                coroutine.resume(co)
            end
        end
        for co, v in pairs(removed) do
            local target_idx
            for idx, co2 in ipairs(self.coroutines) do
                if co == co2 then
                    target_idx = idx
                    break
                end
            end
            if target_idx then
                table.remove(self.coroutines, target_idx)
            end
        end

        -- check timer
        local awake_list = {} -- copy before iter
        local t_now = os.time()
        for idx=#self.timers, 1, -1 do
            local item = self.timers[idx]
            if coroutine.status(item.co) == "dead" then
                table.remove(self.timers, idx)

            elseif item.time <= t_now then
                table.remove(self.timers, idx)
                table.insert(awake_list, item)
            end
        end

        for _, waiter in ipairs(awake_list) do
            if coroutine.status(waiter.co) ~= "dead" then
                waiter.done = true
                coroutine.resume(waiter.co)
            end
        end

        coroutine.yield()
    end
end

function Robot:stop()
    self.running = false
end

return {
    Robot = Robot,
    host2ip = host2ip,
}
