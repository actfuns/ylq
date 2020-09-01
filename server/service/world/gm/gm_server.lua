local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base/extend"
local net = require "base.net"
local record = require "public.record"
local httpuse = require "public.httpuse"
local router = require "base.router"
local netproto = require "base.netproto"
local playersend = require "base.playersend"

local shareobj = import(lualib_path("base.shareobj"))

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

function Commands.testprotoonlineupdate(oMaster)
    print("lxldebug GS2CTestOnlineUpdate")
    oMaster:Send("GS2CTestOnlineUpdate", {
        a = 10,
        b = "bbb",
        c = 100,
        d = 999,
        e = "eee",
    })
end

function Commands.testprotoonlineadd(oMaster)
    print("lxldebug GS2CTestOnlineAdd")
    oMaster:Send("GS2CTestOnlineAdd", {
        a = 10,
    })
end

function Commands.testreceivebigpacket(oMaster, iCnt)
    local bigpacket = import(lualib_path("public.bigpacket"))
    local l = {}
    for i = 1, iCnt do
        table.insert(l, "a")
    end
    local sCmd = table.concat(l)
    local m = {
        s = sCmd,
    }
    bigpacket.SendBig(oMaster:MailAddr(), "GS2CTestBigPacket", m)
end

function Commands.testmongoop(oMaster)
    local mongoop = require "base.mongoop"
    local bson = require "bson"

    local _show_type
    _show_type = function (t)
        for k, v in pairs(t) do
            print(string.format("k:%s k-type:%s", k, type(k)))
            print(string.format("v:%s v-type:%s", v, type(v)))
            if type(v) == "table" then
                _show_type(v)
            end
        end
    end

    local mTest = {
        a = 1,
        b = "bbb",
        map1 = {m1 = 1, m2 = 2},
        map2 = {[10001] = 1, [10002] = 2},
        map3 = {k1 = 1, k2 = 2, [20001] = 10, [20002] = 20,},
        list = {'l1', 'l2', 'l3',},
    }

    print("TEST1")
    local s = bson.encode(mTest)
    local m = bson.decode(s)
    print("TEST1 result")
    print(m)
    print("TEST1 type")
    _show_type(m)

    print("TEST2")
    mongoop.ChangeBeforeSave(mTest)
    local s = bson.encode(mTest)
    local m = bson.decode(s)
    mongoop.ChangeAfterLoad(m)
    print("TEST2 result")
    print(m)
    print("TEST2 type")
    _show_type(m)
end

function Commands.testrouter(oMaster)
    local router = require "base.router"
    local sBig = string.rep("b", 10*1024)
    router.Send("cs", ".datacenter", "common", "TestRouterSend", {
        a = 1,
        b = sBig,
        c = {1, 2, 3,}
    })
    router.Request("cs", ".datacenter", "common", "TestRouterRequest", {
        a = 2,
        b = sBig,
        c = {e = 1, f = 2, g = 3,},
    }, function (mRecord, mData)
        print("lxldebug .world TestRouterRequest")
        print("show record")
        print(mRecord)
        print("show data")
        print(mData)
    end)
end

function Commands.testmd5(oMaster)
    local bigpacket = import(lualib_path("public.bigpacket"))
    local f = io.open("daobiao/gamedata/server/client-daobiao.package", "rb")
    local s = f:read("*a")
    f:close()
    local m = {
        is_change = true,
        s = s,
    }
    bigpacket.SendBig(oMaster:MailAddr(), "GS2CTestBigPacket", m)
end

function Commands.testsdk360(oMaster)
    local m = import(lualib_path("public.urldefines")).URL360.login_verify

    local sMethod = "POST"
    local sHost = m.host
    local sUrl = m.url

    local fCallback = function (mData,mHeader)
        table_print_pretty(mData)
    end

    httpuse.request(sMethod,sHost,sUrl,"",fCallback)

end

function Commands.testhttp(oMaster)
    local cjson = require "cjson"
    local sContent = cjson.encode({
        module = "common",
        cmd = "Test",
        args = {
            year = 2017,
            month = 5,
            server = 1,
        },
    })
    local sMethod = "POST"
    local sHost = "127.0.0.1:10003"
    local sUrl = "/backend"
    local fCallback = function (mData,mHeader)
        table_print_pretty(mData)
    end
    httpuse.request(sMethod,sHost,sUrl,sContent)
end

function Commands.ctrl_monitor(oMaster, bOpen)
    assert(type(bOpen) == "boolean", "gm ctrl_monitor fail")
    interactive.Send(".dictator", "common", "CtrlMonitor", {
        is_open = bOpen,
    })
end

function Commands.dump_monitor(oMaster)
    skynet.send(".rt_monitor", "lua", "Dump")
end

function Commands.clear_monitor(oMaster)
    skynet.send(".rt_monitor", "lua", "Clear")
end

function Commands.mem_purgeunused(oMaster)
    local memory = require "memory"
    memory.purgeunused()
end

function Commands.mem_printmalloc(oMaster)
    local memcmp = require "base.memcmp"
    memcmp.printjemalloc()
end

function Commands.mem_checkglobal(oMaster)
    interactive.Send(".dictator", "common", "MemCheckGlobal", {})
end

function Commands.mem_diff(oMaster)
    interactive.Send(".dictator", "common", "MemDiff", {})
end

function Commands.mem_current(oMaster)
    interactive.Send(".dictator", "common", "MemCurrent", {})
end

function Commands.mem_showtrack(oMaster)
    interactive.Send(".dictator", "common", "MemShowTrack", {})
end

function Commands.mem_snapshot(oMaster)
    interactive.Send(".dictator", "common", "MemSnapshot", {})
end

function Commands.testshareobj(oMaster)
    interactive.Request(".dictator", "common", "TestShareObj", {},
        function(mRecord, mData)
            local oRemote = mData.shareobj
            local oLocal = CTestShareObj:New()
            oLocal:Init(oRemote)

            local iCount = 0
            local iPid = oMaster:GetPid()
            local f1
            f1 = function ()
                iCount = iCount + 1
                local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    oPlayer:DelTimeCb("_TestShareObj")

                    if iCount > 10 then
                        oLocal = nil
                        return
                    end

                    oPlayer:AddTimeCb("_TestShareObj", 6*1000, f1)

                    oLocal:Update()
                    print("lxldebug testshareobj testint")
                    print(oLocal.m_iTestInt)
                    print("lxldebug testshareobj teststr")
                    print(oLocal.m_sTestStr)
                    print("lxldebug testshareobj testmap")
                    print(oLocal.m_mTestMap)
                end
            end
            f1()

        end)
end

function Commands.testidpool(oMaster)
    local idpool = import(lualib_path("base.idpool"))
    local oIDPool = idpool.CIDPool:New(2)
    local lTest = {}
    local iCount = 100
    local bFinish = false

    local f1
    f1 = function ()
        oMaster:DelTimeCb("_IDPoolProduce")
        if iCount <= 0 then
            bFinish = true
            return
        end
        oMaster:AddTimeCb("_IDPoolProduce", 10*1000, f1)
        oIDPool:Produce()
        iCount = iCount - 1
    end
    f1()

    local f2
    f2 = function ()
        oMaster:DelTimeCb("_IDPoolGain")
        if bFinish then
            return
        end
        oMaster:AddTimeCb("_IDPoolGain", math.random(1,3)*1000, f2)
        local id = oIDPool:Gain()
        table.insert(lTest, id)
        print("testidpool lxldebug701", oIDPool.m_iBaseId, id)
    end
    f2()

    local f3
    f3 = function ()
        oMaster:DelTimeCb("_IDPoolFree")
        if bFinish then
            return
        end
        oMaster:AddTimeCb("_IDPoolFree", math.random(1,3)*1000, f3)
        local iChooseIndex = math.random(1, #lTest)
        local id = lTest[iChooseIndex]
        table.remove(lTest, iChooseIndex)
        oIDPool:Free(id)
    end
    f3()
end

function Commands.testtimer(oMaster, bTestOverflow)
    local measure = require "measure"
    local servicetimer = require "base.servicetimer"

    print("testtimer", measure.timestamp())

    oMaster:AddTimeCb("testtimer1", 10, function ()
        print("testtimer1", measure.timestamp())
    end)

    oMaster:AddTimeCb("testtimer2", 100, function ()
        print("testtimer2", measure.timestamp())
    end)

    oMaster:AddTimeCb("testtimer3", 1000, function ()
        print("testtimer3", measure.timestamp())
    end)

    oMaster:AddTimeCb("testtimer4", 10000, function ()
        print("testtimer4", measure.timestamp())

        if bTestOverflow then
            servicetimer.TestOverflow(2^32-1)
            oMaster:AddTimeCb("testtimer_overflow", (2^32-1)*10, function ()
                print("testtimer_overflow")

                print("testtimer_after", measure.timestamp())

                oMaster:AddTimeCb("testtimer1_after", 10, function ()
                    print("testtimer1_after", measure.timestamp())
                end)

                oMaster:AddTimeCb("testtimer2_after", 100, function ()
                    print("testtimer2_after", measure.timestamp())
                end)

                oMaster:AddTimeCb("testtimer3_after", 1000, function ()
                    print("testtimer3_after", measure.timestamp())
                end)

                oMaster:AddTimeCb("testtimer4_after", 10000, function ()
                    print("testtimer4_after", measure.timestamp())
                end)
            end)
        end
    end)
end

function Commands.testcrypt(oMaster)
    local cbc = require("base.crypt.pattern.cbc")
--    local des = require("base.crypt.algo.des")
    local des = require("base.crypt.algo.des-c")
    local padding = require("base.crypt.padding.pkcs5")
    local array = require("base.crypt.common.array")
    local httpuse = require("public.httpuse")


    local o = cbc.Create(des, padding, "!~btusd.")
    local measure = require "measure"
    local str = string.lower(httpuse.urlencode('{"rdata":[{"ServerRange":3,"ServeID":"dev_gs10001","ServerAttach":"给应用宝用","ServerName":"开发服","OpenServerTime":"2017-10-01 15:52:30"}]}'))
    local ti = measure.timestamp()
    for iNo=1,1000 do
        local sEncode = o:Encode(str)
    end
    print ("-----cost---",measure.timestamp()-ti)

    -- local sDecode = o:Decode(sEncode)

    -- print("lxldebug700", array.toHex(array.fromString(sEncode)), httpuse.urldecode(sDecode))
end

function Commands.testproxy(oMaster, iCnt)
    local measure = require "measure"
    local playersend = require "base.playersend"
    local tinsert = table.insert

    local t1 = measure.timestamp()

    for i = 1, iCnt do
        playersend.PackData("GS2CCheckProxy", {
            record = i
        })
    end

    local t2 = measure.timestamp()
    print("lxldebug501:", t2 - t1)

    local l = {}
    for i = 1, iCnt do
        tinsert(l, {record = i})
    end
    playersend.PackData("GS2CCheckProxyMerge", {
        record_list = l
    })

    local t3 = measure.timestamp()
    print("lxldebug502", t3 - t2)
end

function Commands.testendless(oMaster)
    local iNow = os.time()
    local iCnt = 10000000000
    for i = 1, iCnt do
        local a = 1 + 2
    end
    record.info(string.format("lxldebug testendless :%s",os.time()-iNow))
end

function Commands.testprotoencode(oMaster, iCnt)
    local netproto = require "base.netproto"
    local fTime = get_time(true)
    local sData
    for i = 1, iCnt do
        sData = netproto.ProtobufFunc("encode", "GS2CTestEncode", {
            a = 100,
            b = "bbb",
        })
    end
    print("protobuf encode time:", iCnt, get_time(true) - fTime)
    fTime = get_time(true)
    for i = 1, iCnt do
        netproto.ProtobufFunc("decode", "GS2CTestEncode", sData)
    end
    print("protobuf decode time:", iCnt, get_time(true) - fTime)
end

function Commands.testluaencode(oMaster, iCnt)
    local skynet = require "skynet"
    local fTime = get_time(true)
    local sData
    for i = 1, iCnt do
        sData = skynet.packstring({
            a = 100,
            b = "bbb",
        })
    end
    print("lua encode time:", iCnt, get_time(true) - fTime)
    fTime = get_time(true)
    for i = 1, iCnt do
        skynet.unpack(sData)
    end
    print("lua decode time:", iCnt, get_time(true) - fTime)
end

function Commands.testmerge(oMaster, iTotal, iSingle)
    local iCnt = 0
    local iIndex = 1
    local l = {}
    for i = 1, iTotal do
        local m = {
            a = math.random(10000),
            b = math.random(10000),
            c = math.random(10000),
            d = math.random(10000),
            e = math.random(10000),
            f = math.random(10000),
        }
        iCnt = iCnt + 1
        table.insert(l, m)
        if iCnt >= iSingle then
            interactive.Send(".dictator", "common", "TestMerge", {total = iTotal, index = iIndex, count = iCnt, data = l})
            iIndex = iIndex + 1
            iCnt = 0
            l = {}
        end
    end
    if next(l) then
        interactive.Send(".dictator", "common", "TestMerge", {total = iTotal, index = iIndex, count = iCnt, data = l})
    end
end

function Commands.shownetmessage(oMaster)
    local mTestMap = net.netcmd
    local lStat = {"\n"}
    table.insert(lStat,string.format("-----------------current_time:%s",get_time()))
    for sKey,iCnt in pairs(mTestMap) do
        table.insert(lStat,string.format(
            "客户端请求类型:%s,未处理数目:%s",
            sKey,
            iCnt
        ))
    end
    oMaster:Send("GS2CGMMessage", {
        msg = table.concat(lStat, "\n"),
    })
end

function Commands.showmessage(oMaster)
    local mTestMap = net.testmap
    local lStat = {"\n"}
    table.insert(lStat,string.format("-----------------current_time:%s",get_time()))
    for sKey,iCnt in pairs(mTestMap) do
        table.insert(lStat,string.format(
            "客户端请求类型:%s,数目:%s",
            sKey,
            iCnt
        ))
    end
    oMaster:Send("GS2CGMMessage", {
        msg = table.concat(lStat, "\n"),
    })
end

function Commands.showtimemessage(oMaster)
    local servicetimer = require "base.servicetimer"
    local lStat = {"\n"}
    local mCbAmount = servicetimer.CbAmount()
    for sKey,iCnt in pairs(mCbAmount) do
        table.insert(lStat,string.format("定时器类型:%s,未处理数目:%s",
        sKey,
        iCnt
        ))
    end
    oMaster:Send("GS2CGMMessage", {
        msg = table.concat(lStat, "\n"),
    })
end

Helpers.servertime = {
    "设置测试时间,时间只对有测试需求的系统/玩法有效",
    "servertime year month day hour min ",
    "设置示例: servertime 2017 4 20 16 30 ",
    "删除时间: servertime 0"
}

function Commands.servertime(oPlayer,...)
    local mArg = {...}
    local iYear = mArg[1] or 0
    local oChatMgr = global.oChatMgr
    local msg
    if iYear == 0 then
        global.g_TestTime = nil
        msg = string.format("%s(%d) 删除了测试时间",oPlayer:GetName(),oPlayer:GetPid())
    else
        local iMonth,iDay = mArg[2],mArg[3]
        local iHour,iMin = mArg[4] or 0 ,mArg[5] or 0
        global.g_TestTime =os.time({year=iYear,month=iMonth,day=iDay,
            hour=iHour,min=iMin,sec=0})

        msg = string.format("%s(%d) 设置时间为 %s ",
            oPlayer:GetName(),oPlayer:GetPid(),os.date("%c",global.g_TestTime))

    end
    oChatMgr:HandleSysChat(msg,1,1)
end

Helpers.addopenday = {
    "添加开服天数",
    "addopenday 数目",
    "addopenday 2",
}
function Commands.addopenday(oMaster, iVal)
    local oWorldMgr = global.oWorldMgr
    local iServerOpenDays = oWorldMgr:GetOpenDays()
    local iDay = math.max(iServerOpenDays + iVal,0)
    oWorldMgr:SetOpenDays(iDay)
    oWorldMgr:SetServerGrade(0)
    oWorldMgr:CheckUpGrade()

    global.oAchieveMgr:UpdateOpenDay()
end

function Commands.testclient2cs(oMaster,iCnt)
    iCnt = iCnt or 1
    local sUrl = "loginverify/test_verify_account"
    local sAccount = oMaster:GetAccount()
    --local sVerifyUrl = string.format("%s?channelkey=%s&openid=%s",sUrl,"pc",sAccount)
    local mContent = {
    ["cps"] = "kaopu",
    ["demi_channel"] =1039,
    ["account"] = "F8910773E8FCABCA70340F8DF8FDD517",
    ["platform"] = 1,
    ["notice"] = 0,
    ["token"] = "http://sdk.kpzs.com/Api/CheckUserValidate?channelkey=kaopu&appid=10481001&devicetype=android&imei=130367851239410&openid=f8910773e8fcabca70340f8df8fdd517&r=0&tag=10481&tagid=aab72880-4ac6-431f-955b-6f174030e40e&timespans=1505790632&token=17b585760ddb6acb6078356ed175ed3e&msig=446d62ebfe658efa936ed6306e0fc616&sign=C53B98EF4473CC4FFE9C2D3DBCD08388",
    ["device_id"]="0|f719e12e-6ac1-450e-bb67-cee47e39fcf0",
    ["packet_info"] = {game_type="yhsh"}
    }
    local iFloatTime = get_time(true)
    local iReceiveCnt = 0
    for i = 1,iCnt do
        local fCallback = function (mRecord,mData)
            local iNowTime = get_time(true)
            print(mData)
            record.info(string.format("testclient2cs 当前请求编号%d 消耗时间:%s",i,iNowTime-iFloatTime))
            iReceiveCnt = iReceiveCnt + 1
            if iReceiveCnt== iCnt then
                record.info(string.format("花费的总时间:%s",get_time(true)-iFloatTime))
            end
        end
        router.Request("cs",".loginverify1","common","TestClientVerifyAccount",mContent,fCallback)
    end
end

function Commands.checklfs(oMaster)
    local lfs = require "lfs"
    local sRoot = "./"
    for n in lfs.dir(sRoot) do
        local sPath = sRoot..n
        record.info(string.format("lxldebug %s %s",n,lfs.attributes(sPath,"mode")))
    end
end

Helpers.updatelocal = {
    "更新本地有差异文件",
    "updatelocal",
}

function Commands.updatelocal(oMaster)
        local t = io.popen("cd service && svn st")
        local states = t:read("*all")
        for _, v in ipairs(split_string(states, "\n")) do
            local sOp = string.sub(v,1,1)
            local sPath = "service."..string.sub(v,9,-5)
            sPath = string.gsub(sPath,"/",".")
            if (sOp == "M" or  sOp == "?" or sOp == "A") and string.sub(v,-4) == ".lua" then
                interactive.Send(".dictator", "common", "UpdateCode", {
                pid = oMaster:GetPid(),
                str_module_list = sPath,
                })
            end
        end
end

function Commands.updateachieve(oMaster)
    interactive.Send(".achieve", "common", "UpdateAchievekey", {})
end

function Commands.setopen(oMaster,iOpen)
    local oWorldMgr = global.oWorldMgr
    if iOpen > 0 then
        oWorldMgr:SetOpen(true)
        interactive.Send(".login", "login", "StartServerOpenGate", {})
    else
        oWorldMgr:SetOpen(false)
        interactive.Send(".login", "login", "ReadyCloseGS", {})
    end
end

function Commands.ctrl_measure(oMaster, bOpen)
    assert(type(bOpen) == "boolean", "gm ctrl_measure fail")
    interactive.Send(".dictator", "common", "CtrlMeasure", {
        is_open = bOpen,
    })
end

function Commands.dump_measure(oMaster)
    interactive.Send(".dictator", "common", "DumpMeasure", {})
end

function Commands.start_mem_monitor(oMaster)
    interactive.Send(".dictator", "common", "StartMemMonitor", {})
end

function Commands.stop_mem_monitor(oMaster)
    interactive.Send(".dictator", "common", "StopMemMonitor", {})
end

function Commands.dump_mem_monitor(oMaster)
    interactive.Send(".dictator", "common", "DumpMemMonitor", {})
end

function Commands.clear_mem_monitor(oMaster)
    interactive.Send(".dictator", "common", "ClearMemMonitor", {})
end

function Commands.update_code(oMaster, s, flag)
    -- os.execute("./shell/update.sh")
    local bUpdateProto = false
    if flag and tonumber(flag) > 0 then
        bUpdateProto = true
    end
    interactive.Send(".dictator", "common", "UpdateCode", {
        pid = oMaster:GetPid(),
        str_module_list = s,
        is_update_proto = bUpdateProto,
    })
end

function Commands.update_fix(oMaster, s)
    interactive.Send(".dictator", "common", "UpdateFix", {
        pid = oMaster:GetPid(),
        func = s,
    })
end

function Commands.gc(oMaster)
    interactive.Send(".dictator", "common", "CheckGC", {})
end

function Commands.client_res(oMaster)
    interactive.Send(".dictator", "common", "ClientRes", {
        pid = oMaster:GetPid(),
    })
end

function Commands.client_code(oMaster)
    local t = io.popen("svn update")
    interactive.Send(".dictator", "common", "ClientCode", {
        pid = oMaster:GetPid(),
    })
end

Helpers.daobiao = {
    "导表",
    "daobiao",
    "示例: daobiao",
}
function Commands.daobiao(oMaster)
    os.execute("svn update daobiao")
    interactive.Send(".dictator", "common", "UpdateRes", {})
end

function Commands.testrecord(oMaster)

    record.user("test", "test_test", {pid=1, name="hehe", other=11})
    record.user("test", "test_test", {pid=1})
    record.user("test", "test_test", {pid=1, name="hehe"})

    record.error("test error %d %s", 1, "haha")
    record.info("test info %d %s", 1, "haha")
    record.warning("test warning %d %s", 1, "haha")
    record.debug("test debug %d %s", 1, "haha")
end

function Commands.testcharge(oMaster)
    local sProductKey = "com.kaopu.ylq.appstore.6"
    local iAmount = 1
    local mOrders = {
        orderid = 0,
        product_key = sProductKey,
        product_amount = 1,
    }
    global.oPayMgr:DealSucceedOrder(oMaster:GetPid(), mOrders)
end

function Commands.mergepacket(oMaster)
    local lMessage = {}
    for i=1,10 do
        table.insert(lMessage,{
            message = "GS2CShortWay",
            data = {
                type = 1,
            },
        })
    end
    playersend.SendMergePacket(oMaster:GetPid(),lMessage)
end

function Commands.testxgpush()
    local xgpush = import(lualib_path("public.xgpush"))
    xgpush.Push(10010,"test","test")
end

function Commands.testxgpush2()
    local oGamePushMgr =  global.oGamePushMgr
    oGamePushMgr.Push(10010,"test","test")
end

--------------------------------------开放指令---------------------------
Helpers.looktime = {
    "查看时间",
    "示例:looktime",
}
Opens["looktime"] = true
function Commands.looktime(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local timefunc = function (iTime,sFormat)
        local ino = get_weekno(iTime)
        local msg = string.format(sFormat,os.date("%c",iTime),ino)
        oNotifyMgr:Notify(oPlayer:GetPid(),msg)
    end
    timefunc(get_time(),"当前系统时间为:%s,周数:%d")
    if global.g_TestTime then
        timefunc(global.g_TestTime,"测试时间:%s,周数:%d")
    end
end

Helpers.getserverinfo = {
    "获取服务器信息",
    "getserverinfo ",
    "getserverinfo ",
}
Opens["getserverinfo"] = true
function Commands.getserverinfo(oMaster)
    local oWorldMgr = global.oWorldMgr
    local iOpenDays, iServerGrade = oWorldMgr:GetOpenDays(), oWorldMgr:GetServerGrade()
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oMaster:GetPid(), string.format("开服天数: %s, 服务器等级: %s.", iOpenDays, iServerGrade))
end

Helpers.showscenestat = {
    "场景详细信息",
    "showscenestat",
    "showscenestat",
}
Opens["showscenestat"] = true
function Commands.showscenestat(oMaster)
    local oSceneMgr = global.oSceneMgr
    local iTotal = 0
    local lStat = {"\n",}
    for id, oScene in pairs(oSceneMgr.m_mScenes) do
        if oScene:MapId() ~= 501000 then
            local iCount = table_count(oScene.m_mPlayers)
            table.insert(lStat,
                string.format("场景ID:%s, 场景名:%s, 场景服务:%s, 地图ID:%s, 场景人数:%s",
                    id,
                    oScene:GetName(),
                    oScene:GetRemoteAddr(),
                    oScene:MapId(),
                    iCount
                )
            )
            iTotal = iTotal + iCount
        end
    end
    table.insert(lStat, string.format("服内总人数:%s", iTotal))

    oMaster:Send("GS2CGMMessage", {
        msg = table.concat(lStat, "\n"),
    })
end

Helpers.showwarstat = {
    "场景详细信息",
    "showwarstat",
    "showwarstat",
}
Opens["showwarstat"] = true
function Commands.showwarstat(oMaster)
    local oWarMgr = global.oWarMgr
    local iTotal = 0
    local lStat = {"\n",}
    local mServiceWar = {}
    for id,oWar in pairs(oWarMgr.m_mWars) do
        local iService = oWar.m_iRemoteAddr
        if not mServiceWar[iService] then
            mServiceWar[iService] = 0
        end
        mServiceWar[iService] = mServiceWar[iService] + 1
    end

    for iService,iWarCnt in pairs(mServiceWar) do
        table.insert(lStat,string.format(
            "战斗服务id:%s,战斗数目:%s",
            iService,
            iWarCnt
        ))
    end

    for _,iService in pairs(oWarMgr.m_lWarRemote) do
        if not mServiceWar[iService] then
            table.insert(lStat,string.format(
            "战斗服务id:%s,战斗数目:%s",
            iService,
            0
        ))
        end
    end

    oMaster:Send("GS2CGMMessage", {
        msg = table.concat(lStat, "\n"),
    })
end


CTestShareObj = {}
CTestShareObj.__index = CTestShareObj
inherit(CTestShareObj, shareobj.CShareReader)

function CTestShareObj:New()
    local o = super(CTestShareObj).New(self)
    return o
end

function CTestShareObj:Unpack(m)
    self.m_iTestInt = m.testint
    self.m_sTestStr = m.teststr
    self.m_mTestMap = m.testmap
end
