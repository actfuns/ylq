require("tableop")
local login = require("common/login")
local rank = require("common/equalarena")


if client then
    local iAccount =tostring(math.random(1, 9999999) + 10000000)
    client.account = client.account or iAccount
    client.server_request_handlers = login
    table_combine(client.server_request_handlers, login)
    table_combine(client.server_request_handlers, rank)
end

