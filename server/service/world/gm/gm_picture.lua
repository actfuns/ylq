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

Helpers.arenapoint = {
    "测试图鉴",
    "TestPicture",
}
function Commands.TestPicture(oMaster,mData)
    global.oAchieveMgr:PushAchieve(oMaster:GetPid(),"伙伴等级",{target = 1150,value=50})
    global.oAchieveMgr:PushAchieve(oMaster:GetPid(),"伙伴数量",{target = 1150,value=10})
    global.oAchieveMgr:PushAchieve(oMaster:GetPid(),"伙伴星级",{target = 1150,value=5})
end

Helpers.handbook = {
    "测试伙伴相关图鉴",
    "handbook",
}

function Commands.handbook(oPlayer, sCmd, ...)
    oPlayer.m_oHandBookCtrl:TestCmd(oPlayer, sCmd, ...)
end

function Commands.setroleday(oPlayer, iVal)
    global.oAchieveMgr:TestCmd()
end
