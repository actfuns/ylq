local global = require "global"
local interactive = require "base.interactive"

function test()
    local sCmd = [[
        local record = require "public.record"
        local global = require "global"
        local interactive = require "base.interactive"
        record.info(string.format("update_fix: %s %s", MY_SERVICE_NAME, MY_ADDR))
        local oWorldMgr = global.oWorldMgr
        local mPlayerList = oWorldMgr:GetOnlinePlayerList()
        local mPlayer = {}
        for pid,oPlayer in pairs(mPlayerList) do
            mPlayer[pid] = {mail = oPlayer:MailAddr()}
        end
        interactive.Send(".broadcast", "channel", "ClearOfflinePlayer", {online_player = mPlayer})
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function testitem()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local iGlobalItemId = oWorldMgr.m_iGlobalItemId
        print("----hcdebug-----world:iGlobalItemId--------",iGlobalItemId)
        local oCbMgr = global.oCbMgr
        local iCbIdx = oCbMgr.m_iSessionIdx
        print("----hcdebug-----world:cbidx-----",iCbIdx)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function testpartner()
    local sCmd = [[
        local global = require "global"
        local oPartnerMgr = global.oPartnerMgr
        local iGlobalItemId = oPartnerMgr.m_iGlobalItemID
        print("----hcdebug-----partner:iGlobalItemId--------",iGlobalItemId)
        local oCbMgr = global.oCbMgr
        local iCbIdx = oCbMgr.m_iSessionIdx
        print("----hcdebug-----partner:cbidx-----",iCbIdx)
    ]]
    for _, v in ipairs(global.mServiceNote[".partnerd"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function checkitem()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local mPlayer = oWorldMgr:GetOnlinePlayerList()
        for _,oPlayer in pairs(mPlayer) do
            local oItemCtrl = oPlayer.m_oItemCtrl
            local bFlag = false
            for iType, oContainer in pairs(oItemCtrl.m_mContainer) do
                local mItem = oContainer.m_mList or {}
                for iItemid,oItem in pairs(mItem) do
                    if iItemid >= 2^32-1 then
                        print(string.format("%s,",oPlayer:GetPid()))
                        bFlag = true
                        break
                    end
                end
                if bFlag then
                    break
                end
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function kickout()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local mPlayer = {
            1,
            106,
            198,
            4322,
            253,
            1854,
            340,
            903,
            2037,
        }
        for _,iPid in pairs(mPlayer) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                local oNowWar = oPlayer:GetNowWar()
                if not oNowWar then
                    oWorldMgr:Logout(iPid)
                    print("-------hcdeubg------111111",iPid)
                else
                    print("-------hcdebug------2222",iPid)
                end
            else
                print("------hcdebug-----333333",iPid)
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function send_reward_mail()
    local sCmd = [[
        local global = require "global"
        local loaditem = import(service_path("item.loaditem"))
        local gamedefines = import(lualib_path("public.gamedefines"))
        local oWorldMgr = global.oWorldMgr
        local oMailMgr = global.oMailMgr

        local mPlayer = {
                98,
        }
        -- local mPlayer = {
        --     1964,
        --     2909,
        --     1595,
        --     2904,
        --     293,
        --     108,
        --     1,
        -- }
        for _,iPid in pairs(mPlayer) do
            -- local iMailId = 21
            -- local oItem = loaditem.ExtCreate(13202)
            -- oItem:SetAmount(10)

            -- local iMailId = 22
            -- local oItem = loaditem.ExtCreate(10021)
            -- oItem:SetAmount(5)

            -- local iMailId = 22
            -- local mData, sName = oMailMgr:GetMailInfo(iMailId)
            -- local iCoinFlag = gamedefines.COIN_FLAG.COIN_COIN
            -- oMailMgr:SendMail(0, sName, iPid, mData, {{sid=iCoinFlag, value=1000000}}, {})

            -- local iMailId = 22
            -- local oItem = loaditem.ExtCreate('1017(value=4)')
            -- local mData, sName = oMailMgr:GetMailInfo(iMailId)
            -- oMailMgr:SendMail(0, sName, iPid, mData, {}, {oItem})

            -- local iMailId = 20
            -- local mData, sName = oMailMgr:GetMailInfo(iMailId)
            -- local iCoinFlag = gamedefines.COIN_FLAG.COIN_GOLD
            -- oMailMgr:SendMail(0, sName, iPid, mData, {{sid=iCoinFlag, value=5000}}, {})

            local iMailId = 25
            local mData, sName = oMailMgr:GetMailInfo(iMailId)
            local iCoinFlag = gamedefines.COIN_FLAG.COIN_COIN
            oMailMgr:SendMail(0, sName, iPid, mData, {{sid=iCoinFlag, value=5000000}}, {})

            print("send reward:", iPid)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function tongji()
    local sCmd = [[
        local global = require "global"
        local oOverViewObj = global.oOverViewObj
        oOverViewObj:TmpLiuCun()
     ]]
     for _, v in ipairs(global.mServiceNote[".backend"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function checkpartner()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local mOnline = oWorldMgr:GetOnlinePlayerList()
        for iPid, oPlayer in pairs(mOnline) do
            local lParID = {}
            local mFight = oPlayer.m_oPartnerCtrl.m_mFightPartners
            for iPos, oPartner in pairs(mFight or {}) do
                if oPartner.Release then
                    -- table.insert(lParID, oPartner:ID())
                end
                if is_release(oPartner) then
                    print(string.format("checkpartner, released pid:%s,pos:%s", iPid, iPos))
                end
            end
        end
     ]]
     for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end


function updatepartner()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local mPlayer = {
            1,
            193,
        }
        for _, iPid in pairs(mPlayer) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer.m_oPartnerCtrl.m_mFightPartners = {}
                print(string.format("gtxie fixbug:updatepartner, pid:%s", iPid))
            end
        end
     ]]
     for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
    --partner service
    local sCmd = [[
        local global = require "global"
        local oPartnerMgr = global.oPartnerMgr
        local mOnline = oPartnerMgr.m_mPlayers or {}
        local mPlayer = {
            1,
            193,
        }
        for _, iPid in pairs(mPlayer) do
            local oPlayer = oPartnerMgr:GetPlayer(iPid)
            if oPlayer then
                local lParID = {}
                local mFight = oPlayer.m_oPartnerCtrl:GetData("fight_partner", {})
                for iPos, iParId in pairs(mFight) do
                    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
                    if oPartner then
                        oPlayer.m_oPartnerCtrl:RemoteFightPartner(iPos, oPartner:ID(), oPartner:PackRemoteInfo())
                        table.insert(lParID, iParId)
                    end
                end
                print(string.format("gtxie fixbug:updatepartner, pid:%s, parid:%s", iPid, table.concat( lParID, ", ")))
            end
        end
     ]]
     for _, v in ipairs(global.mServiceNote[".partnerd"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function activity_mail()
    local sCmd = [[
        local global = require "global"
        local record = require "public.record"
        record.info(string.format("update_fix: %s %s", MY_SERVICE_NAME, MY_ADDR))
        local oWorldMgr = global.oWorldMgr
        local mPlayerList = oWorldMgr:GetOnlinePlayerList()
        for pid, oPlayer in pairs(mPlayerList) do
            oPlayer:SendActivityMail()
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function debug_war()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local iPid = 108
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local oNowWar = oPlayer:GetNowWar()
            if oNowWar then
                oNowWar:TestCmd("wardebug",iPid)
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function debug_token()
    local sCmd = [[
        local global = require "global"
        local oVerifyMgr = global.oVerifyMgr
        for sToken,mData in pairs(oVerifyMgr.m_mValidLoginToken) do
            print("token",sToken,mData)
        end
    ]]
    print(global.mServiceNote)
    for _, v in ipairs(global.mServiceNote[".loginverify"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function debug_channel( ... )
    local sCmd = [[
        local global = require "global"
        local oGateMgr = global.oGateMgr
        for _,oGate in pairs(oGateMgr.m_mGates) do
            for _,oConn in pairs(oGate.m_mConnections) do
                print("--connection--",oConn.m_sAccount,oConn.m_iChannel,oConn.m_sCpsChannel,"1111")
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".login"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        for _,oPlayer in pairs(oWorldMgr.m_mOnlinePlayers) do
            print("--player--",oPlayer.m_sAccount,oPlayer.m_iChannel,oPlayer:GetPid(),"222")
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function debug_partner(...)
    local sCmd = [[
        local global = require "global"
        local record = require "public.record"
        local oAssistMgr = global.oAssistMgr
        local oPlayer = oAssistMgr:GetPlayer(1406) --1406
        if oPlayer then
            local mPartner = oPlayer.m_oPartnerCtrl:GetList()
            local oPartner
            for iParId, o in pairs(mPartner) do
                if iParId == 37 then
                    oPartner = o
                    break
                end
            end
            if oPartner then
                record.debug(string.format("gtxiedebug, parid:%s,grade:%s,exp:%s", oPartner:ID(), oPartner:GetGrade(), oPartner:GetExp()))
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".assist"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_server_grade()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local iGrade = oWorldMgr:GetInitServerGrade()
        oWorldMgr:SetServerGrade(iGrade)
        oWorldMgr:SetOpenDays(0)
        print("-fix_server_grade--",iGrade)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_org_offer()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local iPid = 10066
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer.m_oActiveCtrl:SetData("org_offer",0)
            oPlayer:PropChange("org_offer")
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function repair_terrwars(iTerraId)
    local sCmd = [[
        local mArgs = ]]..iTerraId..[[
        local global = require "global"
        local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
        oHuoDong:ClearTerra(mArgs)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function checkteaminfo()
    local sCmd = [[
        local global = require "global"
        local oTeamMgr = global.oTeamMgr
        oTeamMgr:CheckPlayerTeamInfo(10051)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function orgmemname()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local mPlayerList = oWorldMgr:GetOnlinePlayerList()
        for pid,oPlayer in pairs(mPlayerList) do
            oPlayer:SyncTosOrg({name=true})
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function cleanyjfuben()
    local sCmd = [[
        local global = require "global"
        local oHuodongMgr = global.oHuodongMgr
        oHuodongMgr.m_mHuodongState["yjfuben"] = nil
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function show_war()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local iPid = 10192
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local oNowWar = oPlayer:GetNowWar()
            local iWarId = oNowWar:GetWarId()
            print("hcdebug",iWarId,oNowWar)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function tongjicode()
     interactive.Send(".backend", "common", "TongjiInvitecode",{})
end

function rewardnamebug(iPid,iCoin)
    local sCmd = [[
        local iPid = ]]..iPid..[[
        local iCoin = ]]..iCoin..[[
        local global = require "global"
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:RewardGoldCoin(iCoin, "起名bug补偿", mArgs)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function terra_guradinfo(iTerraId)
    local sCmd = [[
        local iTerraId = ]]..iTerraId..[[
        local global = require "global"
        local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
        local mGuard = oHuoDong.m_mGuard[iTerraId]
        print("terra_guradinfo:",mGuard)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_terrabug()
    local sCmd = [[
        local global = require "global"
        local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
        oHuoDong:FixBug()
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_offpartner()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        for pid,obj in pairs(oWorldMgr.m_mOfflinePartners) do
            if not oWorldMgr:GetOnlinePlayerByPid(pid) then
                if table_count(obj.m_ShowPartner) > 0 then
                    obj:RefreshPartner({})
                end
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fieldboss_debug()
    local sCmd = [[
        local global = require "global"
        local oHuoDong = global.oHuodongMgr:GetHuodong("fieldboss")
        oHuoDong:GMGetInfo()
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function debug_fd()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local mPlayer = oWorldMgr.m_mOnlinePlayers
        for iPid,oPlayer in pairs(mPlayer) do
            if oPlayer:GetNetHandle() == 6765 then
                print("--hcdebug_fd--",iPid,oPlayer:GetAccount())
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function debug_scene()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local mPlayer = oWorldMgr.m_mOnlinePlayers
        for iPid,oPlayer in pairs(mPlayer) do
           if not oPlayer.m_oActiveCtrl:GetNowScene() then
                local oTeam = oPlayer:HasTeam()
                if oTeam then
                    local iLeader = oTeam:Leader()
                    local oLeader = oWorldMgr:GetOnlinePlayerByPid(iLeader)
                    if oLeader then
                        print("hcdebug_scene_leader",iLeader,oLeader:TeamID(),oLeader.m_oActiveCtrl.m_mNowSceneInfo)
                    end
                end
                print("hcdebug_scene",iPid,oPlayer:TeamID(),oPlayer.m_oActiveCtrl.m_mNowSceneInfo,oPlayer.m_oActiveCtrl:GetDurableSceneInfo())
            end
        end
        local iMapid = 101000
        local oSceneMgr = global.oSceneMgr
        local oScene = oSceneMgr:SelectDurableScene(iMapid)
        print("hcdebug_map",oScene.m_iSceneId,oScene.m_mPlayers[10859],"aaa")
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function checkterrainfo()
    local sCmd = [[
        local global = require "global"
        local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
        oHuoDong:GetTerraState()
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_barrage()
    local sCmd = [[
        local global = require "global"
        local oHuoDong = global.oHuodongMgr:GetHuodong("dailytask")
        oHuoDong:Fixbug()
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function org_change_leader()
    local sCmd = [[
        local global = require "global"
        local orgid = 3
        local oOrgMgr = global.oOrgMgr
        local oOrg = oOrgMgr:GetNormalOrg(orgid)
        if oOrg then
            local iLeader = oOrg:GetLeaderID()
            local memlist = oOrg:GetOrgMemList()
            local iPid
            for iNo,pid in pairs(memlist) do
                if pid ~= iLeader and oOrgMgr:GetOnlinePlayerByPid(pid) then
                    iPid = pid
                    break
                end
            end
            if iPid then
                print ("******",iLeader,iPid)
                oOrg:GiveLeader2Other(iLeader, iPid)
                oOrg:SetAim("")
                oOrg:UpdateOrgInfo({aim = true})
            end
        end
    ]]
    interactive.Send(".org", "default", "ExecuteString", {cmd = sCmd})
end

function addexp()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local iPid = 10759
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:RewardExp(500000,"gm")
            oPlayer:RewardGoldCoin(100000,"gm")
            oPlayer:RewardCoin(10000000,"gm")
            print("hcdebug",oPlayer:GetName(),oPlayer:GetGrade())
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function cbt_reward()
    local sCmd = [[
        local global = require "global"
        local oMailMgr = global.oMailMgr
        local oWorldMgr = global.oWorldMgr
        local iMailId = 45
        local mData, sName = oMailMgr:GetMailInfo(iMailId)
        for iPid,oPlayer in pairs(oWorldMgr.m_mOnlinePlayers) do
            print("----cbt_reward--",iPid)
            oMailMgr:SendMail(0, sName, iPid, mData, {{sid=1, value=3000}}, {})
            oPlayer:Set("cbt_reward",1)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function debug_anlei( ... )
    local sCmd = [[
        local global = require "global"
        local oSceneMgr = global.oSceneMgr
        local oScene = oSceneMgr:GetScene(9)
        if oScene then
            local oAnleiCtrl = oScene.m_oAnLeiCtrl
            print(oAnleiCtrl.m_mPlayerInfo)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end


function test_make()
    local myfile = io.popen("./shell/des_encode.sh "..jdata,"r")
    local desstr = myfile:read("*all")
end

function testyybao()
    local sCmd = [[
        local httpuse = require "public.httpuse"
        local mHeader = {}
        mHeader["Content-type"] = "application/json"

        for iNo=1,1 do
            local sParam = httpuse.mkcontent_kv({
                -- openid = "zlj"..iNo,
                -- serverid = "dev_gs10001",
                -- taskid = 1001
            })
            httpuse.get("127.0.0.1:20003", "/notice/yybao/GetServerInfo", sParam, nil, mHeader)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".achieve"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function datacenter( ... )
    local sCmd = [[
        local sAccount = "f8910773e8fcabca70340f8df8fdd517"
        local iChannel = 1039
        local iPlatform = 1
        local lServer = {"gs20001"}
        local oDataCenter = global.oDataCenter
        local mRoleList = oDataCenter:GetRoleList(sAccount, iChannel,iPlatform,lServer)
        print(mRoleList)
    ]]
    for _, v in ipairs(global.mServiceNote[".datacenter"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function addcard()
    local sCmd = [[
        local global = require "global"
        local oPayMgr = global.oPayMgr
        local iPid = 10012
        local mOrders = {
            orderid = 0,
            product_key = "com.cilu.n1_yk",
            product_amount = 1
        }
        oPayMgr:DealSucceedOrder(iPid,mOrders)

        local mOrders = {
            orderid = 0,
            product_key = "com.cilu.n1_zsk",
            product_amount = 1
        }
        oPayMgr:DealSucceedOrder(iPid,mOrders)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fixchargelog()
    local sCmd = [[
        local global = require "global"
        local interactive = require "base.interactive"
        local mFixLog = {
            {pid=10012,num=6,before=0,gain=12,card="none",orderid=11,type="shopcharge",stime="2018-01-20 00:16:29"},
            {pid=10012,num=30,before=12,gain=30,card="month",orderid=12,type="buymonth",stime="2018-01-20 00:17:25"},
            {pid=10012,num=98,before=42,gain=98,card="forever",orderid=13,type="buyforever",stime="2018-01-20 00:17:41"},
            {pid=10012,num=98,before=140,gain=0,card="forever",orderid=14,type="buyfund",stime="2018-01-20 00:18:10"},
            {pid=10015,num=6,before=0,gain=12,card="none",orderid=16,type="shopcharge",stime="2018-01-20 00:20:29"},
            {pid=10009,num=6,before=0,gain=12,card="none",orderid=17,type="shopcharge",stime="2018-01-20 00:20:33"},
            {pid=10007,num=328,before=0,gain=656,card="none",orderid=18,type="shopcharge",stime="2018-01-20 00:24:18"},
            {pid=10007,num=30,before=320,gain=30,card="month",orderid=19,type="buymonth",stime="2018-01-20 00:31:26"},
            {pid=10007,num=98,before=350,gain=98,card="forever",orderid=20,type="buyforever",stime="2018-01-20 00:31:32"},
            {pid=10011,num=30,before=0,gain=30,card="month",orderid=21,type="buymonth",stime="2018-01-20 00:24:33"},
            {pid=10021,num=30,before=0,gain=30,card="month",orderid=22,type="buymonth",stime="2018-01-20 00:24:56"},
            {pid=10021,num=6,before=30,gain=12,card="month",orderid=23,type="shopcharge",stime="2018-01-20 00:28:26"},
            {pid=10003,num=98,before=0,gain=98,card="forever",orderid=24,type="buyforever",stime="2018-01-20 00:25:06"},
            {pid=10003,num=30,before=98,gain=30,card="forever",orderid=25,type="buymonth",stime="2018-01-20 00:26:12"},
            {pid=10003,num=6,before=128,gain=12,card="forever",orderid=26,type="shopcharge",stime="2018-01-20 00:27:35"},
            {pid=10003,num=30,before=140,gain=60,card="forever",orderid=27,type="shopcharge",stime="2018-01-20 1:13:01"},
            {pid=10029,num=6,before=0,gain=12,card="none",orderid=28,type="shopcharge",stime="2018-01-20 00:25:12"},
            {pid=10029,num=98,before=0,gain=98,card="forever",orderid=29,type="buyforever",stime="2018-01-20 00:32:48"},
            {pid=10029,num=30,before=110,gain=30,card="forever",orderid=30,type="buymonth",stime="2018-01-20 00:33:48"},
            {pid=10029,num=98,before=140,gain=0,card="forever",orderid=31,type="buyfund",stime="2018-01-20 2:03:14"},
            {pid=10010,num=98,before=0,gain=98,card="forever",orderid=32,type="buyforever",stime="2018-01-20 00:26:59"},
            {pid=10010,num=30,before=98,gain=30,card="forever",orderid=33,type="buymonth",stime="2018-01-20 00:27:37"},
            {pid=10010,num=98,before=128,gain=0,card="forever",orderid=34,type="buyfund",stime="2018-01-20 00:27:57"},
            {pid=10022,num=6,before=0,gain=12,card="none",orderid=35,type="shopcharge",stime="2018-01-20 00:35:48"},
            {pid=10046,num=6,before=0,gain=12,card="none",orderid=36,type="shopcharge",stime="2018-01-20 00:37:04"},
            {pid=10002,num=6,before=0,gain=12,card="none",orderid=37,type="shopcharge",stime="2018-01-20 00:40:28"},
            {pid=10023,num=6,before=0,gain=12,card="none",orderid=38,type="shopcharge",stime="2018-01-20 00:44:56"},
            {pid=10085,num=6,before=0,gain=12,card="none",orderid=39,type="shopcharge",stime="2018-01-20 01:03:34"},
            {pid=10076,num=6,before=0,gain=12,card="none",orderid=40,type="shopcharge",stime="2018-01-20 01:09:21"},
            {pid=10099,num=6,before=0,gain=12,card="none",orderid=41,type="shopcharge",stime="2018-01-20 01:17:10"},
            {pid=10108,num=30,before=0,gain=30,card="month",orderid=42,type="buymonth",stime="2018-01-20 01:31:49"},
        }
        for _,info in pairs(mFixLog) do
            local oWorldMgr = global.oWorldMgr
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(info.pid)
            if oPlayer then
                local mLog = oPlayer:GetPubAnalyData()
                mLog.recharge_num = info.num
                mLog.vip_level_before = 0
                mLog.vip_level_after = 0
                mLog.crystal_bd_before = 0
                mLog.gain_crystal_bd = 0
                mLog.crystal_before = info.before
                mLog.gain_crystal = info.gain
                mLog.card = info.card
                mLog.orderid = info.orderid
                mLog.type = info.type
                mLog.time= info.stime
                interactive.Send(".logfile", "common", "FixWriteData",  {sName = "Recharge", data = mLog})
            else
                oWorldMgr:LoadProfile(info.pid, function (oProfile)
                    if oProfile then
                        local mLog = oProfile:GetPubAnalyData()
                        mLog.recharge_num = info.num
                        mLog.vip_level_before = 0
                        mLog.vip_level_after = 0
                        mLog.crystal_bd_before = 0
                        mLog.gain_crystal_bd = 0
                        mLog.crystal_before = info.before
                        mLog.gain_crystal = info.gain
                        mLog.card = info.card
                        mLog.orderid = info.orderid
                        mLog.type = info.type
                        mLog.time= info.stime
                        interactive.Send(".logfile", "common", "FixWriteData",  {sName = "Recharge", data = mLog})
                    end
                end)
            end
            print ("----finish fix charge log--")
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end


function fixchargehis()
    local sCmd = [[
        local global = require "global"
        local mFixPlayer = {
            {pid=10022,num=6},{pid=10042,num=6},{pid=10050,num=6},
            {pid=10099,num=6},{pid=10172,num=6},
        }
        local oWorldMgr = global.oWorldMgr
        for _,info in pairs(mFixPlayer) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(info.pid)
            if oPlayer then
                local oProfile = oPlayer:GetProfile()
                if oProfile:HistoryCharge() < info.num then
                    oProfile:SetHistoryCharge(info.num)
                    global.oFuliMgr:CheckHistoryCharge(oPlayer)
                    global.oFuliMgr:TipFirstCharge(oPlayer)
                end
                print ("-----fixcharge---history---",info.pid)
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fixchargeach()
    local sCmd = [[
        local global = require "global"
        local mFixPlayer = {
            {pid=10022,num=6},{pid=10042,num=6},{pid=10050,num=6},
            {pid=10099,num=6},{pid=10172,num=6},
        }
        local oAchieveMgr = global.oAchieveMgr
        for _,info in pairs(mFixPlayer) do
            local oPlayer = oAchieveMgr:GetPlayer(info.pid)
            if oPlayer then
                for iAid=10601,10610 do
                    local oAchieve = oPlayer.m_oAchieveCtrl:GetAchieve(iAid)
                    if oAchieve and not oAchieve:IsDone() and oAchieve:GetDeGree() < info.num then
                        local iAdd = info.num - oAchieve:GetDeGree()
                        oAchieveMgr:AddDegree(info.pid,iAid,iAdd)

                    end
                end
                print ("-----fixchargeach--",info.pid)
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".achieve"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_taskachieve()
    local sCmd = [[
        local global = require "global"
        local oAssistMgr = global.oAssistMgr

        local fixs = {}
        local onlines = oAssistMgr.m_mPlayers or {}
        for iPid, oPlayer in pairs(onlines) do
            oAssistMgr:fixTaskAchieve(iPid)
            table.insert(fixs, iPid)
        end
        if next(fixs) then
            print("gtxiefixbug, fix_taskachieve pids:", fixs)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".assist"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_friendequip()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr

        local fixs = {}
        local friends = oWorldMgr.m_mOfflineFriends or {}
        for iPid, oFriend in pairs(friends) do
            table.insert(fixs, iPid)
            oFriend.m_ShowEquip = {}
            oFriend:Dirty()
        end
        print("gtxiefixbug, fix_friendequip world pids:", fixs)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end

    local sCmd = [[
        local global = require "global"
        local oAssistMgr = global.oAssistMgr

        local fixs = {}
        local onlines = oAssistMgr.m_mPlayers or {}
        for iPid, oPlayer in pairs(onlines) do
            oPlayer:UpdateFriendEquip()
            table.insert(fixs, iPid)
        end
        if next(fixs) then
            print("gtxiefixbug, fix_friendequip assist pids:", fixs)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".assist"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function debug_anlei()
    local sCmd = [[
        local iPid = 10007
        local global = require "global"
        local oAIMgr = global.oAIMgr
        local oAI = oAIMgr:GetOfflineTrapMineAI(iPid)
        if oAI then
            print("hcdebug--111")
        else
            print("hcdebug--2222")
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".client"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end

    local sCmd = [[
        local iPid = 10007
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            print("world,trapmine,hcdebug,111",oPlayer:GetInfo("auto_trapmine"),"aaa")
            print("world,trapmine,hcdebug,222",oPlayer:GetInfo("offline_trapmine"),"bbb")
            print("world,trapmine,hcdebug,3333",oPlayer:GetInfo("trapmine_map"),"ccc")
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function testkpreport()
    local sCmd = [[
        local urldefines = import(lualib_path("public.urldefines"))
        local httpuse = require "public.httpuse"
        local cjson = require "cjson"
        local mHeader = {["Content-type"]="application/x-www-form-urlencoded"}
        local mData = {{
            openid="A3FDF9C73E6DF8C4C4CE8540CD6D8E98",
            servername="东门水路",
            serverid="123",
            rolename="妖精神经",
            roleid="4561",
            channelkey="baidu",
            logintime="2017-05-06 10:12:10",
            logouttime="2017-05-06 13:13:10",
            onlinetime=56000,
            rolelevel=1,
            },}
            local sUrl = "/kpreport/game/userlogin/1305"
            local sData = cjson.encode(mData)
            local mParam = {
              data = sData,
              appid = 10481001,
              timestamp = get_time(),
            }
            local sParam = httpuse.mkcontent_kv(mParam)
            local sHost = urldefines.get_out_host()
            httpuse.post(sHost, sUrl, sParam, function(body, header)
              print ("--report--back-----",body)
            end, mHeader)
    ]]
    for _, v in ipairs(global.mServiceNote[".backend"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end




function debug_huodongscene()
    local sCmd = [[
        local global = require "global"
        local oHuodongMgr = global.oHuodongMgr
        local extend = require "base.extend"
        local obj = oHuodongMgr:GetHuodong("equipfuben")
        if obj then
            local iCnt = 0
            local rmlist = {}
            for _,sobj in pairs(obj.m_mSceneIdx2Obj[1001] or {}) do
                if sobj._release then
                    table.insert(rmlist,sobj)
                end
            end
            for _,sobj in ipairs(rmlist) do
                iCnt = iCnt + 1
                extend.Array.remove(obj.m_mSceneIdx2Obj[1001],sobj)
            end
            print("equipfuben:",table_count(obj.m_FubenList),table_count(obj.m_EmptyList),obj.m_GameID,table_count(obj.m_mSceneList),table_count(obj.m_mSceneIdx2Obj[1001]or {}),iCnt)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end

end


function fixrank()
    local sCmd =[[
        local global =  require "global"
        local oRankMgr = global.oRankMgr
        local fixs = {}
        local names = {"warpower", "grade", "parpower"}
        for _, sName in ipairs(names) do
            local oRank = oRankMgr:GetRankObjByName(sName)
            if oRank then
                if sName  == "parpower" then
                    for iType, o in pairs(oRank.m_mList or {}) do
                        local mRank = {}
                        local mOld = o.m_mRankData or {}
                        for idx, sKey in ipairs(o.m_lSortList or {}) do
                            if mOld[sKey] then
                                mRank[sKey] = mOld[sKey]
                            else
                                print("err:", sName, iType, sKey)
                            end
                        end
                        o.m_mRankData = mRank
                        table.insert(fixs, {name=sName, partype= iType, old = table_count(mOld), now = table_count(mRank)})
                        o:Dirty()
                    end
                else
                    oRank:Dirty()
                    local mRank = {}
                    local mOld = oRank.m_mRankData or {}
                    for idx, sKey in ipairs(oRank.m_lSortList or {}) do
                        if mOld[sKey] then
                            mRank[sKey] = mOld[sKey]
                        else
                            print("err:", sName, sKey)
                        end
                    end
                    oRank.m_mRankData = mRank
                    table.insert(fixs, {name=sName, partype= iType, old = table_count(mOld), now = table_count(mRank)})
                end
            end
        end
        print("gtxiefixbug, rank data:", fixs)
    ]]
    for _, v in ipairs(global.mServiceNote[".rank"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end


function findbadnpc()
    local sCmd = [[
        local global = require "global"
        local oSceneMgr = global.oSceneMgr
        local oNpcMgr = global.oNpcMgr
        local idList = {34,35,11,36,7,12,6}
        local mCnt = {}
        for _,id in pairs(idList) do
            for npcid,_ in pairs(oSceneMgr.m_mScenes[id].m_mNpc) do
                local oNpc = oNpcMgr:GetObject(npcid)
                if oNpc then
                    local iType = oNpc.m_iType
                    if iType then
                        mCnt[iType] = mCnt[iType] or 0
                        mCnt[iType] = mCnt[iType] + 1
                    end
                end
            end
        end
        for iType,iCnt in pairs(mCnt) do
            print ("---npc--cnt--type--",iType,iCnt)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fixsaverank()
    local sCmd =[[
        local global =  require "global"
        local oRankMgr = global.oRankMgr
        local fixs = {}
        local oRank = oRankMgr:GetRankObjByName("parpower")
        if oRank then
            oRank:FixSaveData()
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".rank"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function additem()
    local sCmd =[[
        local global =  require "global"
        local oWorldMgr = global.oWorldMgr
        local iPid = 10030
        local lItem = {
            {10019,10},
            {12042,1},
            {13009,6},
            {13221,100},
            {13222,50},
            {13223,50},
            {13232,100},
            {13276,10},
        }
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:GiveItem(lItem,"gm")
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function checkscene()
    local sCmd =[[
        local global =  require "global"
        local oSceneMgr = global.oSceneMgr
        local oHuodongMgr = global.oHuodongMgr
        local oHuoDong = oHuodongMgr:GetHuodong("equipfuben")
        print("GameID:",oHuoDong.m_GameID)
        for gid,oGame in pairs(oHuoDong.m_FubenList) do
            if not oGame:SceneObject() then
                print("ErrScene:",gid,oGame.m_SceneID)
            end
        end
        print("scene:info",table_count(oSceneMgr.m_mScenes),oSceneMgr.m_iDispatchId,oSceneMgr.m_iDispatchVirtualId)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function delrole()
    local sCmd =[[
        local global =  require "global"
        local oWorldMgr = global.oWorldMgr
        local gamedb = import(lualib_path("public.gamedb"))
        local iPid = 10842
        local mData = {
            pid = iPid,
        }
        gamedb.SaveDb("gm","common", "SaveDb", {
            module = "playerdb",
            cmd = "RemovePlayer",
            data = mData
        })
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_mem_monitor()
    local sCmd = [[
        local global = require "global"
        local mem_rt_monitor = require "base.mem_rt_monitor"
        local skynet = require "skynet"
        local measure = require "measure"
        local interactive = require "base.interactive"

        local mRecord = {}
        mem_rt_monitor.Record = function (key, iMem)
            local interactive = require "base.interactive"
            local c2 = collectgarbage("count")
            local i1 = iMem*1024
            local i2 =  c2*1024
            if i2-i1 > 1000  then
                local sKey = ConvertTblToStr(key)
                sKey = string.format("{%s}_%s",MY_SERVICE_NAME,sKey)
                if not mRecord[sKey] then
                    mRecord[sKey] = {}
                end
                local iSum = mRecord.sum or 0
                mRecord.sum = iSum + 1
                local mKeyRecord = mRecord[sKey]
                local iCnt = mKeyRecord.count or 0
                mKeyRecord.count = iCnt + 1
                local iTime = mKeyRecord.time or 0
                mKeyRecord.time = iTime + i2-i1
                mRecord[sKey] = mKeyRecord
                if mRecord.sum >= 200 then
                    mRecord.sum = nil
                    interactive.Send(".mem_rt_monitor", "common", "AddRtMonitor",mRecord)
                    mRecord = {}
                end
            end
        end
    ]]
    for k, v in pairs(global.mServiceNote) do
        for _, v2 in ipairs(v) do
            interactive.Send(v2, "default", "ExecuteString", {cmd = sCmd})
        end
    end
end

function testxgpush()
    local sCmd =[[
        local xgpush = import(lualib_path("public.xgpush"))
        xgpush.Push(10003,10002)
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function testxgpush2()
    local sCmd =[[
        local global = require "global"
        local oGamePushMgr =  global.oGamePushMgr
        oGamePushMgr.m_mData = {}
        oGamePushMgr:InitData()
        oGamePushMgr:Push(10010,"test","test")
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function testxgpush3()
    local sCmd =[[
        local global = require "global"
        local oGamePushMgr =  global.oGamePushMgr
        local f2
        f2 = function ()
            oGamePushMgr:CheckCleanSign()
            oGamePushMgr:DelTimeCb("cleansign")
            oGamePushMgr:AddTimeCb("cleansign",60*1000,f2)
        end
        f2()
    ]]
    for _, v in ipairs(global.mServiceNote[".gamepush"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function testxgpush4()
    local sCmd =[[
        local global = require "global"
        local oGamePushMgr =  global.oGamePushMgr
        local mSign = oGamePushMgr.m_mSign
        print("hcdebug",mSign)
    ]]
    for _, v in ipairs(global.mServiceNote[".gamepush"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function orgwar_active()
    local sCmd =[[
        local global = require "global"
        local oOrgMgr = global.oOrgMgr
        oOrgMgr:RewardActivePoint(10031,10000,"gm指令")
        oOrgMgr:RewardActivePoint(10035,10000,"gm指令")
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function checkqrcode()
    local sCmd =[[
        local global = require "global"
        local oQRCodeMgr = global.oQRCodeMgr
        for k,v in pairs(oQRCodeMgr.m_mCodeHandle) do
            print(k,v)
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".qrcode"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end



function testreport()
    local sCmd =[[
        local global = require "global"
        local httpuse = require "public.httpuse"
        local urldefines = import(lualib_path("public.urldefines"))
        local sHost = urldefines.get_out_host()
        local sKey = "userlogin"
        local mHeader = {["Content-type"]="application/x-www-form-urlencoded"}
        local m = os.date("*t",get_time())
        local mData = {{
            roleid=10008,
            rolelevel=56,
            consumecount=100,
            channelkey="baidu",
            servername="开发服",
            rolename="222338",
            consumewayname="角色改名",
            serverid=10001,
            eventtime=string.format("%04d-%02d-%02d %02d:%02d:%02d",m.year,m.month,m.day,m.hour,m.min,m.sec),
            surpluscount=36831,
            consumewayid=20001,
            openid="zlj1"
        }}
        local oReportMgr = global.oReportMgr
        local sUrl = urldefines.get_kaopu_url("android",sKey)
        local sParam = oReportMgr:MakeParam(mData,"android")

        print ("----report---",sUrl,sParam)
        print ("---data---",mData)

        if sUrl then
            httpuse.post(sHost, sUrl, sParam, function(body, header)
                    print ("---back--",body)
            end, mHeader)
        end
    ]]

    for _, v in ipairs(global.mServiceNote[".datareport"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
        break
    end
end

function cbt_month()
    local sCmd =[[
        local global = require "global"
        local mMonthCard = {}
        local oHuodongMgr = global.oHuodongMgr
        local oWorldMgr = global.oWorldMgr
        local oHuoDong = oHuodongMgr:GetHuodong("charge")
        local iMin = 1
        print("cbt_month")
        for _,iPid in pairs(mMonthCard) do
            local fCallback = function ()
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    oHuoDong:TestOP(oPlayer,201)
                    print("cbt_pay--month_card",iPid)
                end
            end
            local sType = string.format("buchang%d",iPid)
            oHuoDong:AddTimeCb(sType,iMin*60*1000,fCallback)
            iMin = iMin + 1
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function cbt_zsk()
    local sCmd =[[
        local global = require "global"
        local mZskCard = {}
        local oHuodongMgr = global.oHuodongMgr
        local oWorldMgr = global.oWorldMgr
        local oHuoDong = oHuodongMgr:GetHuodong("charge")
        print("cbt_zsk")
        local iMin = 1
        for _,iPid in pairs(mZskCard) do
            local fCallback = function ()
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    oHuoDong:TestOP(oPlayer,202)
                    print("cbt_pay--zsk_card",iPid)
                end
            end
            local sType = string.format("buchang%d",iPid)
            oHuoDong:AddTimeCb(sType,iMin*60*1000,fCallback)
            iMin = iMin + 1
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function cbt_czjj()
    local sCmd =[[
        local global = require "global"
        local mCzjj = {}
        local oHuodongMgr = global.oHuodongMgr
        local oWorldMgr = global.oWorldMgr
        local oHuoDong = oHuodongMgr:GetHuodong("charge")
        for _,iPid in pairs(mCzjj) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oHuoDong:TestOP(oPlayer,301)
                print("cbt_pay--czjj",iPid)
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function cbt_pay()
    local sCmd =[[
        local global = require "global"
        local mPlayer = {}
        local oHuodongMgr = global.oHuodongMgr
        local oWorldMgr = global.oWorldMgr
        local oHuoDong = oHuodongMgr:GetHuodong("charge")
        for _,iPid in pairs(mPlayer) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oHuoDong:TestOP(oPlayer,401,1001)
                print("cbt_pay--1001",iPid)
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_question()
    local sCmd =[[
        local global = require "global"
        local oHuodongMgr = global.oHuodongMgr
        local oWorldMgr = global.oWorldMgr
        local oHuoDong = oHuodongMgr:GetHuodong("question")
        local mOnline = oWorldMgr:GetOnlinePlayerList()
        for i, oScene in pairs(oHuoDong.m_mSceneList or {}) do
            for iPid, _ in pairs(oScene.m_mPlayers or {}) do
                oHuoDong:GobackRealScene(iPid)
            end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fixterrarank()
    local sCmd = [[
        local global = require "global"
        local oOrgMgr = global.oOrgMgr
        local mData = {}
        for iOrgId,oOrg in pairs(oOrgMgr.m_mNormalOrgs) do
            mData[iOrgId] = oOrg:GetOrgMemList()
        end
        local interactive = require "base.interactive"
        interactive.Send(".rank", "rank", "CheckTerraRank", {data = mData})
     ]]
     for _, v in ipairs(global.mServiceNote[".org"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function checkpaydata()
    local sCmd = [[
        local m = global.oGameDb:Find("pay")
        local mRet = {}
        while m:hasNext() do
            local mData = m:next()
            mongoop.ChangeAfterLoad(mData)
            local mExt = mData["ext"] or {}
            if mExt["grade_key"] then
                local sServerKey = mData["serverkey"]
                if not mRet[sServerKey] then
                    mRet[sServerKey] = {}
                end
                local iPid = mData["pid"]
                if not mRet[sServerKey][iPid] then
                    mRet[sServerKey][iPid]  = {}
                end
                mPayData = mRet[sServerKey][iPid]
                local sAccount = mData["account"]
                local sOrderid = mData["orderid"]
                local iRmb = mData["amount"] / 100
                local mInsertData = {
                    pid = iPid,
                    orderid = sOrderid,
                    rmb = iRmb,
                }
                table.insert(mPayData,mInsertData)
            end
        end
        print(lRet)
    ]]
    for _, v in ipairs(global.mServiceNote[".pay"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function addpaydata()
    local sCmd = [[
        local analy = import(lualib_path("public.dataanaly"))
        local oHuoDong = global.oHuodongMgr:GetHuodong("charge")
        local oWorldMgr = global.oWorldMgr
        local lPlayer = {}
        for _,iPid in ipairs(lPlayer) do
            local fCallback = function (oProfile)
                 DealPayLog(iPid,oProfile,lOrder)
            end
            oWorldMgr:LoadProfile(iPid,fCallback)
        end

        function DealPayLog(iPid,oProfile,lOrder)
             local mLog = oProfile:GetPubAnalyData()
             for _,mData in ipairs(lOrder) do
                 local iAdd = mData["rmb"]
                 local iOrderId = mData["orderid"]
                 mLog.recharge_num = iAdd
                 mLog.vip_level_before = 0
                 mLog.vip_level_after = 0
                 mLog.crystal_before = 0
                 mLog.gain_crystal = 0
                 mLog.crystal_bd_before = 0
                 mLog.gain_crystal_bd = 0
                 mLog.card = "none"
                 if oHuoDong:IsZskVip(iPid) then
                     mLog.card = "forever"
                 elseif oHuoDong:IsMonthCardVip(iPid) then
                     mLog.card = "month"
                 end
                 mLog.orderid = iOrderId
                 mLog.type = "等级礼包"
                 analy.log_data("Recharge", mLog)
             end
        end
    ]]
    for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fixcharge_achieve()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local oFuliMgr = global.oFuliMgr
        local iTarget = 11574
        local iVal = 1800
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iTarget)
        if oPlayer then
            oPlayer:AddHistoryCharge(iVal)
            oPlayer:AfterChargeGold(iVal,"gm指令")
            for i=1,6 do
                local mGetlist = oPlayer:FuliQuery("charge_get",{})
                if not  table_in_list(mGetlist, 10000+i) then
                    table.insert(mGetlist, 10000+i)
                end
                oPlayer:FuliSet("charge_get",mGetlist)
                oFuliMgr:CheckHistoryCharge(oPlayer)
            end
        end
     ]]
     for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function fix_fieldboss_hp()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
        oHuodong:SetFieldBossHp(1,60)
        oHuodong:SetFieldBossHp(2,100)
        oHuodong:SetFieldBossHp(3,100)
     ]]
     for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function checkresumerestore()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local oHuodong = global.oHuodongMgr:GetHuodong("resume_restore")
        print(oHuodong.m_iCurId,oHuodong.m_iStartTime,oHuodong.m_iEndTime)
     ]]
     for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function saverushrank()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local oHuodong = global.oHuodongMgr:GetHuodong("rankback")
        if oHuodong then
            oHuodong:QueryRankBack()
            print("gtxie, saverushrank")
        end
     ]]
     for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end

function sendrushrank()
    local sCmd = [[
        local global = require "global"
        local oWorldMgr = global.oWorldMgr
        local oHuodong = global.oHuodongMgr:GetHuodong("rushrank")
        if oHuodong then
            local lRank = {105,106,113,115}
            for _, idx in ipairs (lRank) do
                oHuodong:SetSendRwd(idx, 1)
            end
            oHuodong:DoRushRankReward(lRank, "gtxiefixbug")
            print("gtxiefixbug, rushrank reward")
            -- print("gtxie rushrank info:", oHuodong.m_mSendRwd)
        end
     ]]
     for _, v in ipairs(global.mServiceNote[".world"]) do
        interactive.Send(v, "default", "ExecuteString", {cmd = sCmd})
    end
end