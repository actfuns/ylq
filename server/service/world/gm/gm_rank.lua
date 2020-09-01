local global = require "global"


Commands = {}
Helpers = {}
Opens = {}	--是否对外开放

Helpers.help = {
    "GM指令帮助",
    "help 指令名",
    "help 'clearall'",
}
function Commands.help(oMaster, sCmd)
    if sCmd then
        local o = Helpers[sCmd]
        if o then
            local sMsg = string.format("%s:\n指令说明:%s\n参数说明:%s\n示例:%s\n", sCmd, o[1], o[2], o[3])
            oMaster:Send("GS2CGMMessage", {
                msg = sMsg,
            })
        else
            oMaster:Send("GS2CGMMessage", {
                msg = "没查到这个指令"
            })
        end
    end
end

Helpers.rank = {
    "排行榜指令",
    "rank 榜名 指令编号",
    "rank grade  101"
}
Opens["rank"] = true
function Commands.rank(oMaster,sRankName,iCmd,...)
    local oRankMgr = global.oRankMgr
    oRankMgr:TestOP(oMaster,sRankName,iCmd,...)
end