
local skynet = require "skynet"

local M = {}

function M.Dispatch(textcmd)
    skynet.register_protocol {
        name = "text",
        id = skynet.PTYPE_TEXT,
        pack = function (...)
            local n = select ("#" , ...)
            if n == 0 then
                return ""
            elseif n == 1 then
                return tostring(...)
            else
                return table.concat({...}," ")
            end
        end,
        unpack = skynet.tostring
    }

    skynet.dispatch("text", function (session, address, message)
        if textcmd then
            local id, cmd , parm = string.match(message, "(%d+) (%w+) ?(.*)")
            id = tonumber(id)
            textcmd.Invoke(cmd, address, id, parm)
        end
    end)
end

return M
