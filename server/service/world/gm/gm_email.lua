local global = require "global"

local loaditem = import(service_path("item/loaditem"))
local loadpartner = import(service_path("partner/loadpartner"))


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

Helpers.sendmail = {
    "给自己发邮件",
    "sendmail {mailid=导表id, sys=是否系统, 货币={{货币id,货币数量}}},item=物品信息, partner=伙伴信息,mailcnt邮件数量}",
    "sendmail {mailid = 1, sys = 1,money = {{sid = 5,value = 1000}}, item={{sid=10001,cnt=1},{sid='1017(value=3)',cnt=1}}, partner={sid = 301,star = 1}, mailcnt=1,keeptime = 100}",
}
Opens["sendmail"] = true
function Commands.sendmail(oMaster,mSysInfo)
    local idx = mSysInfo.mailid
    local iSys = mSysInfo.sys
    local iteminfo = mSysInfo.item
    local partnerinfo = mSysInfo.partner
    local cnt = mSysInfo.mailcnt
    local mMoney = mSysInfo.money or {}
    local oMailMgr = global.oMailMgr
    local oNotifyMgr = global.oNotifyMgr
    local pid = 0
    local mData, name = oMailMgr:GetMailInfo(idx)
    if not mData then
        oNotifyMgr:Notify(oMaster:GetPid(), "邮件导表id错误")
        return
    end
    if iSys ~= 1 then
        pid, name = oMaster:GetPid(), oMaster:GetName()
    end
    cnt = cnt or 1
    for i=1,cnt do
        local items = {}
        if iteminfo and next(iteminfo) then
            for _,info in pairs(iteminfo) do
                local oTmpItem = loaditem.ExtCreate(info["sid"])
                if info["cnt"] then
                    oTmpItem:SetAmount(info["cnt"])
                end
                table.insert(items, oTmpItem)
            end
        end

        local partners = {}
        if partnerinfo and next(partnerinfo) then
            local res = require "base.res"
            local sid = partnerinfo["sid"]
            local istar = partnerinfo["star"]
            local loadpartner = import(service_path("partner/loadpartner"))
            local oPartner = loadpartner.CreatePartner(sid,{star = istar})
            table.insert(partners, oPartner)
        end
        mData.keeptime = tonumber(mSysInfo.keeptime)
        oMailMgr:SendMail(pid, name, oMaster:GetPid(), mData, mMoney, items,partners)
    end
    oNotifyMgr:Notify(oMaster:GetPid(), "发送邮件成功")
end