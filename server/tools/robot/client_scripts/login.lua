require("tableop")
local login = require("common/login")

if client then
    client.account = client.account or tostring(math.random(1, 9999999) + 10000000)
    client.server_request_handlers = login
end

