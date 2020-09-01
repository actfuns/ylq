package.cpath = package.cpath .. ";../../build/clualib/?.so"
package.path = package.path .. ";../../lualib/base/?.lua;../../skynet/lualib/?.lua;../../skynet/examples/?.lua"..";../../daobiao/gamedata/server/?.lua"

local socket = require "clientsocket"
local tprint = require('extend').Table.print
local argparse = require "argparse"
local Robot = require 'robot'

local function init_argparse()
    local parser = argparse()
    parser:description("Cmd Client")

    parser:option("-a", "--host"):default("127.0.0.1"):description("Server IP")
    parser:option("-p", "--port"):default("7011"):description("Server Port"):convert(tonumber)
    parser:option("-s", "--script"):description("Script")
    parser:option("-c", "--concurrency"):default("100"):description("Concurrency"):convert(tonumber)
    parser:option("-f", "--flag"):default("default"):description("Robot Flag")

    return parser
end

local g_clients = {}
local function create_client(idx, host, port, script, flag)
    local client = Robot.Robot:new(host, port, {slient=true, shield = {["GS2CHeartBeat"] = true, ["C2GSHeartBeat"] = true,["GS2CMergePacket"]=true}})
    client.account = "Robot"..flag..idx
    client.client_idx = idx
    client:fork(client.run_script, client, script)
    local co = coroutine.create(
        function()
            client:start()
        end
    )
    g_clients[co] = true
end


local function main()
    local args = init_argparse():parse()
    if not args.script then
        assert(false,'no script!')
    end
    
    local host = args.host
    local ip = Robot.host2ip(args.host)
    if not ip then
        error("host to ip fail")
    end
    math.randomseed(os.time())
    math.random(1, 10000)

    local port = args.port
    local script = args.script
    for idx =1, args.concurrency do
        create_client(idx, ip, port, script, args.flag)
    end
    
    print(string.format("%d Robot%s start", args.concurrency, args.flag))

    while next(g_clients) do
        local removed = {}
        local n = 0
        for co, _ in pairs(g_clients) do
            if coroutine.status(co) == "dead" then
                removed[co] = true
            else
                local ok, err = coroutine.resume(co)
                if not ok then
                    print("client err:", err)
                    removed[co] = true
                end
                n = n + 1
            end
        end

        for co, _ in pairs(removed) do
            g_clients[co] = nil
        end

        socket.usleep(100000)
    end
end

main()
