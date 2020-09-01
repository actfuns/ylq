local skynet = require "skynet"
local sharedata = require "sharedata"

local M = {}

skynet.init(function()
    local box = sharedata.query("res")
    setmetatable(M, {__index = box})
end, "res")

return M
