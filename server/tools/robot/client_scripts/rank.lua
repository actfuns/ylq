require("tableop")
local login = require("common/login")
local rank = require("common/rank")

if client then
    client.account = client.account or tostring(math.random(1, 9999999) + 10000000)
    table_combine(client.server_request_handlers, login)
    table_combine(client.server_request_handlers, rank)
end