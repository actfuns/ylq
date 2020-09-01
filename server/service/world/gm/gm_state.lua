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

Helpers.addstate = {
    "增加buff",
    "addstate 状态id",
    "addstate 1001",
}
function Commands.addstate(oMaster,iState,...)
    local mArgs = {}
    oMaster.m_oStateCtrl:AddState(iState,mArgs)
end

function Commands.clearstate(oMaster)
    for iState,oState in pairs(oMaster.m_oStateCtrl.m_List) do
        oMaster.m_oStateCtrl:RemoveState(iState)
    end
end

function Commands.cleartaskshow(oMaster)
    oMaster.m_oActiveCtrl:SetData("task_show",0)
end