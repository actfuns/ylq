require("tableop")
local login = require("common/login")
local item = require("common/item")

if client then
   client.account = client.account or tostring(math.random(1, 9999999) + 10000000)
    local shield = client.shield
    table.insert(shield,{["GS2CEnterAoi"] = true,["GS2CPropChange"] = true})
    table_combine(client.server_request_handlers, login)
    table_combine(client.server_request_handlers, item)
end