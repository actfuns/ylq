local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local basehook = require "base.basehook"
local servicetimer = require "base.servicetimer"
local texthandle = require "base.texthandle"
local router = require "base.router"
local res = require "base.res"
local record = require "public.record"
local serverdefines = require "public.serverdefines"


require "skynet.manager"

local gamedb = import(lualib_path("public.gamedb"))
local netcmd = import(service_path("netcmd.init"))
local logiccmd = import(service_path("logiccmd.init"))
local worldobj = import(service_path("worldobj"))
local sceneobj = import(service_path("sceneobj"))
local warobj = import(service_path("warobj"))
local proxywarobj = import(service_path("kuafuproxy.proxywarobj"))
local gmobj = import(service_path("gmobj"))
local publicobj = import(service_path("publicobj"))
local npcobj = import(service_path("npcobj"))
local cbobj = import(service_path("cbobj"))
local notify = import(service_path("notify"))
local uiobj = import(service_path("uiobj"))
local interfacemgr = import(service_path("interfacemgr"))
local team = import(service_path("team"))
local chat = import(service_path("chat"))
local huodong = import(service_path("huodong"))
local mailmgr = import(service_path("mailmgr"))
local housemgr = import(service_path("housemgr"))
local store = import(service_path("store.storemgr"))
local partnercmt = import(service_path("partner.partnercmt"))
local friendobj = import(service_path("friendobj"))
local linkmgr = import(service_path("link.linkmgr"))
local rankmgr = import(service_path("rankmgr"))
local renamemgr = import(service_path("rename"))
local titlemgr = import(service_path("titlemgr"))
local warfilm = import(service_path("warfilm"))
local partnermgr = import(service_path("partnermgr"))
local derivedfilemgr = import(lualib_path("public.derivedfile"))
local logincheckmgr = import(service_path("logincheck"))
local taskmgr = import(service_path("taskmgr"))
local achievemgr = import(service_path("achieve.achievemgr"))
local imagemgr = import(service_path("imagemgr"))
local backendmgr = import(service_path("backendmgr"))
local offsetmgr = import(service_path("onlineoffset"))
local routercmd = import(service_path("routercmd.init"))
local hbmgr = import(service_path("hongbao.hbmgr"))
local handbookmgr = import(service_path("handbook.handbookmgr"))
local paymgr = import(service_path("paymgr"))
local demisdk = import(lualib_path("public.demisdk"))
local minigamemgr = import(service_path("minigamemgr"))
local assistmgr = import(service_path("assistmgr"))
local mailaddrmgr = import(service_path("mailaddrmgr"))
local orgmgr = import(service_path("orgmgr"))
local fulimgr = import(service_path("fulimgr"))
local insidefuli = import(service_path("insidefuli"))
--local kuafumgr = import(service_path("kuafumgr"))
local kfmain = import(service_path("kuafu.kfmain"))
local kuafuproxy = import(service_path("kuafuproxy.gs2kfmgr"))
local gamepush = import(service_path("gamepush"))
local showidmgr = import(service_path("showidmgr"))
local accountmgr = import(service_path("accountmgr"))
local kpmgr = import(service_path("kpmgr"))
local mergermgr = import(service_path("mergermgr"))

local iNo = ...

skynet.start(function()
    skynet.priority(true)
    skynet.change_gc_size(256)

    net.Dispatch(netcmd)
    interactive.Dispatch(logiccmd)
    texthandle.Dispatch()
    router.DispatchC(routercmd)
    if is_ks_server() then
        kfmain.KuaFuWorldStart(iNo)
        return
    end

    global.oGlobalTimer = servicetimer.NewTimer()
    global.oGMMgr = gmobj.NewGMMgr()
    global.oNotifyMgr = notify.NewNotifyMgr()
    global.oChatMgr = chat.NewChatMgr()
    global.oChatMgr:Init()
    global.oRankMgr = rankmgr.NewRankMgr()
    global.oDemiSdk = demisdk.NewDemiSdk(true)
    global.oPayMgr = paymgr.NewPayMgr()
    global.oShowIdMgr = showidmgr.NewShowIdMgr()
    global.oMergerMgr = mergermgr.NewMergerMgr()
    local mData = {
        server_id = get_server_tag()
    }

    local mLoadData = {
        module = "worlddb",
        cmd = "LoadWorld",
        data = mData
    }
    gamedb.LoadDb("world","common", "LoadDb", mLoadData, function (mRecord, mData)
            global.oWorldMgr = worldobj.NewWorldMgr()
            global.oWorldMgr:Load(mData.data)
            global.oWorldMgr:ConfigSaveFunc()
            global.oWorldMgr:Schedule()
            global.oWorldMgr:InitData()

            local lSceneRemote = {}
            for i = 1, SCENE_SERVICE_COUNT do
                local iAddr = skynet.newservice("scene")
                table.insert(lSceneRemote, iAddr)
            end
            global.oSceneMgr = sceneobj.NewSceneMgr(lSceneRemote)

            local lWarRemote = {}
            for i = 1, WAR_SERVICE_COUNT do
                local iAddr = skynet.newservice("war")
                table.insert(lWarRemote, iAddr)
            end
            global.oWarMgr = warobj.NewWarMgr(lWarRemote)
            global.oProxyWarMgr = proxywarobj.NewWarMgr(lWarRemote)

            -- local lPartnerRemote = {}
            -- for iNo = 1, PARTNER_SERVICE_COUNT do
            --     local iAddr = skynet.newservice("partner",iNo)
            --     table.insert(lPartnerRemote, iAddr)
            -- end
            -- global.oPartnerMgr = partnermgr.NewPartnerMgr(lPartnerRemote)

            local lAssistRemote = {}
            for iNo = 1, ASSIST_SERVICE_COUNT do
                local iAddr = skynet.newservice("assist",iNo)
                table.insert(lAssistRemote, iAddr)
            end
            global.oAssistMgr = assistmgr.NewAssistMgr(lAssistRemote)

            local lAddrRemote = {}
            for iNo = 1, PLAYER_SEND_COUNT do
                local iAddr = skynet.newservice("player_send_proxy",iNo)
                table.insert(lAddrRemote,iAddr)
            end
            global.oMailAddrMgr = mailaddrmgr.NewMailAddrMgr(lAddrRemote)

            skynet.newservice("autoteam")
            skynet.newservice("recommend")
            skynet.newservice("org")
            skynet.newservice("rank")
            skynet.newservice("report")
            skynet.newservice("assisthd")

            --lxldebug add some temp scene
            local mScene = res["daobiao"]["scene"]
            for k, v in pairs(mScene) do
                local iCnt = v.line_count
                local bHasAnlei = false
                if v.anlei == 1 then
                    bHasAnlei = true
                end
                for i = 1, iCnt do
                    global.oSceneMgr:CreateScene({
                        map_id = v.map_id,
                        is_durable = true,
                        has_anlei = bHasAnlei,
                        scene_type = k,
                        new_man = v.newman,
                    })
                end
            end

            local mLoading = {}
            local fWaitLoad = function (sName, o)
                mLoading[sName] = true
                local fLoaded = function ()
                    mLoading[sName] = nil
                    if not next(mLoading) then
                        global.oWorldMgr:OnServerStartEnd()
                    end
                end
                if sName == "huodong" then
                    o:Execute(fLoaded)
                else
                    o:WaitLoaded(fLoaded)
                end
            end

            global.oDerivedFileMgr = derivedfilemgr.NewDerivedFileMgr()
            global.oPubMgr = publicobj.NewPubMgr()
            global.oNpcMgr = npcobj.NewNpcMgr()
            local oNpcMgr = global.oNpcMgr
            oNpcMgr:LoadInit()
            global.oCbMgr = cbobj.NewCBMgr()
            global.oUIMgr = uiobj.NewUIMgr()
            global.oInterfaceMgr = interfacemgr.NewInterfaceMgr()
            global.oTeamMgr = team.NewTeamMgr()
            global.oHuodongMgr = huodong.NewHuodongMgr()
            global.oMailMgr = mailmgr.NewMailMgr()
            global.oStoreMgr = store.NewStoreMgr()
            global.oPartnerCmtMgr = partnercmt.NewPartnerCmtMgr()
            global.oFriendMgr = friendobj.NewFriendMgr()
            global.oTitleMgr = titlemgr.NewTitleMgr()
            local oHuodongMgr = global.oHuodongMgr
            oHuodongMgr:InitData()
            fWaitLoad("huodong",oHuodongMgr)
            local oPartnerCmtMgr =  global.oPartnerCmtMgr
            oPartnerCmtMgr:InitData()
            fWaitLoad("partnercmt",oPartnerCmtMgr)
            global.oHouseMgr = housemgr.NewHouseMgr()
            global.oLinkMgr = linkmgr.NewLinkMgr()
            global.oRenameMgr = renamemgr.NewRenameMgr()
            global.oWarFilmMgr = warfilm.NewWarFilmMgr()
            global.oWarFilmMgr:Schedule()
            global.oLoginCheckMgr = logincheckmgr:NewLoginCheckMgr()
            global.oTaskMgr = taskmgr.NewTaskMgr()
            global.oAchieveMgr = achievemgr.NewAchieveMgr()
            global.oImageMgr = imagemgr.NewImageMgr()
            global.oBackendMgr = backendmgr.NewBackendMgr()
            global.oOffsetMgr = offsetmgr.NewOnlineOffsetMgr()
            global.oHbMgr = hbmgr.NewHbMgr()
            global.oHbMgr:InitData()
            fWaitLoad("hongbao",global.oHbMgr)
            global.oHandBookMgr = handbookmgr.NewHandBookMgr()
            global.oHandBookMgr:InitData()
            global.oMiniGameMgr = minigamemgr.NewMiniGameMgr()
            global.oOrgMgr = orgmgr.NewOrgMgr()
            global.oFuliMgr = fulimgr.NewFuliMgr()
            global.oFuliMgr:InitData()
            fWaitLoad("fuli",global.oFuliMgr)
            global.oAccountMgr = accountmgr:NewAccountMgr()
            fWaitLoad("accountmgr",global.oAccountMgr)
            global.oKaopuMgr = kpmgr.NewKaopuMgr()
            --global.oKFMgr = kuafumgr.NewKuaFuMgr()
            global.oKFMgr = kuafuproxy.NewKuaFuMgr()
            global.oGamePushMgr = gamepush.NewGamePushMgr()
            global.iNetRecvProxyAddr = skynet.newservice("net_recv_proxy", MY_ADDR, "handlenrp")
            global.oInsideFuli = insidefuli.NewInsideFuliMgr()

            basehook.set_logic(function ()
                local oWorldMgr = global.oWorldMgr
                oWorldMgr:WorldDispatchFinishHook()
            end)

            interactive.Send(".dictator", "common", "AllServiceBooted", {type = "world"})
    end)
    skynet.register ".world"
    interactive.Send(".dictator", "common", "Register", {
        type = ".world",
        addr = MY_ADDR,
    })

    record.info("world service booted")
end)
