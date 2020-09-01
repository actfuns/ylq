--import module

local global = require "global"

local loaditem = import(service_path("item.loaditem"))
local gamedefines = import(lualib_path("public.gamedefines"))

Commands = {}
Helpers = {}
Opens = {}  --是否对外开放

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

Helpers.addpartner = {
    "添加伙伴  数量小于100",
    "addpartner 伙伴id 数量",
    "addpartner 1001",
}
function Commands.addpartner(oMaster, iPartnerType, iVal)
    iVal = iVal or 1
    local res = require "base.res"
    local mData = res["daobiao"]["partner"]["partner_info"][iPartnerType]
    if mData then
        oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "addpartner", {{iPartnerType, iVal}})
    else
        global.oNotifyMgr:Notify(oMaster:GetPid(), string.format("导表不存在:%s伙伴",iPartnerType))
    end
end

Helpers.addpartnerexp = {
    "添加伙伴经验",
    "addpartnerexp 伙伴服务id 数量",
    "addpartnerexp 1 1000000",
}
function Commands.addpartnerexp(oMaster, iPartner, iExp)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "addexp", {iPartner, iExp})
end

Helpers.addcurptnexp = {
    "添加当前伙伴经验",
    "addcurptnexp 数量",
    "addcurptnexp 1000000",
}

function Commands.addcurptnexp(oMaster, iExp)
    local oNotifyMgr = global.oNotifyMgr

    local oPartner = oMaster.m_oPartnerCtrl:GetMainPartner()
    if oPartner then
        oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "addexp", {oPartner:ID(), iExp})
    else
        oNotifyMgr:Notify(oMaster:GetPid(), "主伙伴不存在")
    end
end

Helpers.addpartnerstar = {
    "增加伙伴星级",
    "addpartnerstar 伙伴服务器id 增加星级",
    "addpartnerstar 1 2"
}
function Commands.addpartnerstar(oMaster, iPartner, iVal)
    if type(iVal) ~= "number" then
        global.oNotifyMgr:Notify(oMaster:GetPid(), "参数有误，星级需大于0")
        return
    end
    if iVal <= 0 then
        global.oNotifyMgr:Notify(oMaster:GetPid(), "参数有误，星级需大于0")
        return
    end
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "addpartnerstar", {iPartner, iVal})
end

Helpers.awakepartner = {
    "伙伴觉醒",
    "awakepartner 伙伴id",
    "awakepartner 1",
}
function Commands.awakepartner(oMaster, iPartner)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "awakepartner", {iPartner})
end

Helpers.clearpartner = {
    "清空伙伴",
    "clearpartner",
    "clearpartner",
}
function Commands.clearpartner(oMaster)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "clearpartner", {})
end

Helpers.removepartner = {
    "删除伙伴",
    "removepartner 伙伴服务器id",
    "removepartner 10",
}
function Commands.removepartner(oMaster, iPartner)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "removepartner", {iPartner})
end

Helpers.allpartner = {
    "添加导表所有伙伴",
    "添加导表所有伙伴",
    "添加导表所有伙伴"
}
function Commands.allpartner(oMaster)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "allpartner", {})
end

Helpers.partnercomment = {
    "伙伴评论",
    "伙伴评论指令",
    "伙伴评论指令",
}
function Commands.partnercomment(oMaster, ...)
    global.oPartnerCmtMgr:TestOP(oMaster, ...)
end

Helpers.countpartner = {
    "打印伙伴数量",
}

function Commands.countpartner(oMaster)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "countpartner", {})
end

function Commands.partner(oMaster,iCmd,...)
    local oNotifyMgr = global.oNotifyMgr
    local mArgs = {...}
    local iPid = oMaster.m_iPid
    if iCmd == 100 then
        --
    elseif iCmd == 101 then
        local iPartnerItem, iAmount = table.unpack(mArgs)
        if iAmount and iAmount > 0 then
            oPlayer.m_oItemCtrl:RemoveItemList({{iPartnerItem, iAmount}}, "gm测试", function()
                oNotifyMgr:Notify(oMaster:GetPid(), "扣除成功")
            end)
        end
    elseif iCmd == 102 then
        -- local iPartnerItem, iAmount = table.unpack(mArgs)
        -- if iAmount and iAmount > 0 then
        --     oMaster:RewardPartnerItem({{iPartnerItem, iAmount}}, "gm测试")
        -- end
    elseif iCmd == 112 then
        local testobj = import(service_path("testobj"))
        local iCount = mArgs[1] or 3000
        local list = {}
        local iClock = os.clock()
        for i = 1, iCount do
            list[i] = testobj.NewTestObj()
        end
        print("gtxie debug Create obj time:", os.clock() - iClock)
    elseif iCmd == 113 then
        oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "update_fight_partner", {})
    elseif iCmd == 114 then
        local f1
        f1 = function(oPlayer, mPartner)
            table_print(mPartner)
        end
        local mInfo = {
            grade = 1,
        }
        oMaster.m_oPartnerCtrl:GetAllPartnerInfo(iPid, mInfo, f1)
    end
end

function Commands.setpartnerattr(oMaster, ...)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "setpartnerattr", {...})
end

function Commands.testcpower(oMaster, iPartner)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "testcpower", iPartner)
end

function Commands.testpower(oMaster, iPartner)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "testpower", iPartner)
end

function Commands.fullpartner(oMaster,...)
    oMaster.m_oPartnerCtrl:TestCmd(oMaster:GetPid(), "fullpartner")
end

function Commands.partnershare(oMaster, ...)
    oMaster.m_oPartnerCtrl.m_oShareMgr.m_oPartnerShare:Update()
    print("gtxiedebug, sharepartner:", oMaster.m_oPartnerCtrl.m_oShareMgr.m_oPartnerShare.m_mPartner)
end