local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local res = require "base.res"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"

require "skynet.manager"

local logiccmd = import(service_path("logiccmd.init"))
local serverinfo = import(lualib_path("public.serverinfo"))
local slavedbmgr = import(service_path("slavedbmgr"))

local iNo = ...

skynet.start(function()
    interactive.Dispatch(logiccmd)
    net.Dispatch()

    local m = serverinfo.get_local_dbs()

    local oClient = mongoop.NewMongoClient({
        host = m.game.host,
        port = m.game.port,
        username = m.game.username,
        password = m.game.password,
    })
    global.oGameDb = mongoop.NewMongoObj()
    global.oGameDb:Init(oClient, "game")
    global.oSlaveDbMgr = slavedbmgr.NewSlaveDbMgr()

    local oGameDb = global.oGameDb
    if is_bs_server() then
        local sGlobalTableName = "global"
        oGameDb:CreateIndex(sGlobalTableName, {name = 1}, {unique=true, name="global_name_index"})
        local mSlaveDb = serverinfo.get_slave_dbs()
        for k, v in pairs(mSlaveDb) do
            global.oSlaveDbMgr:AddNewServer(k, v.game, v.gamelog, v.gameumlog, v.chatlog)
        end
        local sYYBaoTable = "yybao"
        oGameDb:CreateIndex(sYYBaoTable, {pid = 1}, {unique=true, name="yybao_pid_index"})
    elseif is_cs_server() then
        local sIdCounterTableName = "idcounter"
        oGameDb:CreateIndex(sIdCounterTableName,{type = 1},{unique=true,name="idcounter_type_index"})

        local sShowIdTableName = "showid"
        oGameDb:CreateIndex(sShowIdTableName, {show_id = 1}, {unique=true, name="show_id_index"})

        local sGlobalTableName = "global"
        oGameDb:CreateIndex(sGlobalTableName, {name = 1}, {unique=true, name="global_name_index"})

        local sPayRequestTableName = "requestpay"
        oGameDb:CreateIndex(sPayRequestTableName, {orderId = 1}, {unique=true, name="request_orderid_index"})

        local sPayTableName = "pay"
        oGameDb:CreateIndex(sPayTableName, {orderid = 1}, {unique=true, name="pay_orderid_index"})
        oGameDb:CreateIndex(sPayTableName, {pid = 1}, {name="pay_pid_index"})
        
        local sFuliTableName = "fuli"
        oGameDb:CreateIndex(sFuliTableName, {name = 1}, {unique=true, name="fuli_name_index"})
    elseif is_gs_server() then
        local sPlayerTableName = "player"
        oGameDb:CreateIndex(sPlayerTableName, {pid = 1}, {unique = true, name = "player_pid_index"})
        oGameDb:CreateIndex(sPlayerTableName, {"account", "channel", name = "player_account_index"})

        local sOfflineTableName = "offline"
        oGameDb:CreateIndex(sOfflineTableName,{pid = 1},{unique=true,name="offline_pid_index"})

        local sNameCounterTableName = "namecounter"
        oGameDb:CreateIndex(sNameCounterTableName,{name = 1},{unique=true,name="namecounter_name_index"})

        local sOrgTableName = "org"
        oGameDb:CreateIndex(sOrgTableName, {orgid = 1}, {unique = true, name = "org_orgid_index"})
        oGameDb:CreateIndex(sOrgTableName, {name = 1}, {name="org_name_index"})

        local sRankTableName = "rank"
        oGameDb:CreateIndex(sRankTableName, {name = 1}, {unique=true, name="rank_name_index"})

        local sPartnerTableName = "partner"
        oGameDb:CreateIndex(sPartnerTableName, {pid = 1}, {unique=true, name="partner_pid_index"})

        local sInviteCodeTableName = "invitecode"
        oGameDb:CreateIndex(sInviteCodeTableName, {account = 1}, {unique=true, name="invitecode_index"})
        oGameDb:CreateIndex(sInviteCodeTableName, {invitecode = 1}, {unique=true, name="invitecode_index"})

        local sHouseTableName = "house"
        oGameDb:CreateIndex(sHouseTableName, {pid = 1}, {unique=true, name="house_pid_index"})

        local sWarFilmTableName = "warfilm"
        oGameDb:CreateIndex(sWarFilmTableName,{film_id = 1},{unique=true,name="warfilm_id_index"})

        local sAchieveTableName = "achieve"
        oGameDb:CreateIndex(sAchieveTableName, {pid = 1}, {unique=true, name="achieve_pid_index"})

        local sImageTableName = "image"
        oGameDb:CreateIndex(sImageTableName, {key = 1}, {unique=true, name="image_key_index"})
        oGameDb:CreateIndex(sImageTableName, {pid = 1}, {name="image_pid_index"})
        oGameDb:CreateIndex(sImageTableName, {create_time = 1}, {name="image_time_index"})

        local sGlobalTableName = "global"
        oGameDb:CreateIndex(sGlobalTableName, {name = 1}, {unique=true, name="global_name_index"})

        local sGamePushTableName = "gamepush"
        oGameDb:CreateIndex(sGamePushTableName,{pid = 1},{unique=true,name="gamepush_pid_index"})
        oGameDb:CreateIndex(sGamePushTableName,{token = 1},{name="gamepush_token_index"})
        oGameDb:CreateIndex(sGamePushTableName,{platform = 1},{name="gamepush_platform_index"})
    end

    skynet.register(".gamedb"..iNo)
    interactive.Send(".dictator", "common", "Register", {
        type = ".gamedb",
        addr = MY_ADDR,
    })

    record.info("gamedb service booted")
end)
