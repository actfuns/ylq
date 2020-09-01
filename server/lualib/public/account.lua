-- import file

local res = require "base.res"

function get_channel_info(iChannel)
    return res["daobiao"]["demichannel"][iChannel]
end