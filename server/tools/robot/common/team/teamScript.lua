require("tableop")
local login = require("common/team/login")
local scene = require("common/team/scene")
local team = require("common/team/team")

if client then
    client.account = client.account or tostring(math.random(1, 9999999) + 10000000)
    local shield = client.shield
    table.insert(shield,{["GS2CEnterAoi"] = true,["GS2CPropChange"] = true})
    table_combine(client.server_request_handlers, login)
    table_combine(client.server_request_handlers, scene)
    table_combine(client.server_request_handlers, team)
end