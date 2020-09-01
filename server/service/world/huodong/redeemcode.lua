--import module
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"
local router = require "base.router"
local loaditem = import(service_path("item/loaditem"))

local gamedefines = import(lualib_path("public.gamedefines"))

local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "兑换码兑换"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    return o
end


function CHuodong:UseRedeemCode(oPlayer, sCode)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if oWorldMgr:IsClose("redeemcode") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local iPid = oPlayer:GetPid()
    if not sCode then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1003))
        return
    end

    if oPlayer.m_oThisTemp:Query("redeem_code") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"请求过于频繁")
        return
    end
    oPlayer.m_oThisTemp:Set("redeem_code", sCode, 1)

    sCode = string.upper(sCode)
    local sPublisher = self:GetPublisherByChannel(oPlayer:GetChannel()) 
    local mArgs = {
        cmd= "UseRedeemCode", 
        data = {
            pid = iPid, 
            code = sCode, 
            channel = oPlayer:GetChannel(), 
            platform = oPlayer:GetPlatform(),
            publisher = sPublisher
        }
    } 

    router.Request("cs", ".redeemcode", "common", "Forward", mArgs, function (m1, m2)
        self:_UseRedeemCode(iPid, sCode, m2.errcode, m2.data) 
    end)
end

function CHuodong:_UseRedeemCode(iPid, sCode, iErr, mArgs)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:RedeemCodeReward(sCode, iErr, mArgs["gift_id"], mArgs["redeem_id"])
    else
        local oPubMgr = global.oPubMgr
        oPubMgr:OnlineExecute(iPid, "RedeemCodeReward", {sCode, iErr, mArgs["gift_id"], mArgs["redeem_id"]})
    end
end

function CHuodong:RedeemCodeReward(oPlayer, sCode, iErr, iGift, iRedeem)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()

    if table_in_list({1, 2}, iErr) then
        oNotifyMgr:Notify(oPlayer:GetPid(),self:GetTextData(1003))
        return
    end
    iGift = math.floor(iGift)
    local oItem = loaditem.GetItem(iGift)
    if not oItem then
        record.error("RedeemCodeReward error Pid:%d Redeem:%d sCode:%s iGift:%d", iPid, iRedeem, sCode, iGift)
        return
    end
    if iErr == 3 then
        oNotifyMgr:Notify(iPid,self:GetTextData(1001))
        return
    elseif iErr == 7 then
        local msg = self:GetTextData(1002)
        msg = string.gsub(msg,"$itemname",oItem:Name())
        oNotifyMgr:Notify(iPid,msg)
        return
    elseif iErr == 8 then
        local msg = self:GetTextData(1002)
        msg = string.gsub(msg,"$itemname",oItem:Name())
        oNotifyMgr:Notify(iPid,msg)
        return
    elseif iErr == 6 then
        oNotifyMgr:Notify(iPid,self:GetTextData(1004))
        return
    elseif table_in_list({4, 5}, iErr)  then
        oNotifyMgr:Notify(iPid,self:GetTextData(1005))
        return
    elseif iErr ~= 0 then
        record.warning("使用兑换码未知异常 Pid:%d, Code:%s, Error:%d", iPid, sCode, iErr)
        return
    end

    local mLog = {
    pid = iPid,
    code = sCode,
    gift = iGift,
    }
    record.user("player","redeemcode",mLog)
    local oItem = loaditem.ExtCreate(iGift)
    oItem:Reward(oPlayer,"兑换码")
    oNotifyMgr:Notify(iPid,"兑换成功")
end

function CHuodong:GetPublisherByChannel(iChannel)
    local res = require "base.res"
    local mData = res["daobiao"]['demichannel'][iChannel]
    if not mData then return end
    return mData["publisher"]
end


function CHuodong:TestOP(oPlayer,iFlag,...)
    local arg = {...}
    local iPid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    if iFlag == 100 then
        global.oNotifyMgr:Notify(iPid, [[
        101 - 兑换
        102 - 生成礼包
        103 - 生成兑换码
        104 - 获取信息
        ]])
    elseif iFlag == 101 then
        local scode = arg[1]
        self:UseRedeemCode(oPlayer,scode)
    elseif iFlag == 102 then
        local mData = {
        cmd = "SaveRedeemRuleInfo",
        data = {
            redeem_id = tonumber(arg[1]),
            redeem_name = "helloword",
            gift_id = 101,
            expire_time = get_time()+ 24*3600,
            player_redeem_cnt = 1000,
            code_redeem_cnt = 1002,
            operater = 12,
        },
        }
        router.Request("cs", ".redeemcode", "common", "Forward",mData,function (mRecord,m)
            print("SaveRedeemRuleInfo:",m)
            end)
    elseif iFlag == 103 then
        local mData = {
        cmd = "MakeRedeemCode",
        data = {
            redeem_id = tonumber(arg[1]),
            channels = "helloword",
            platforms = 1,
            amount = 10,
            operater = 2,
            publisher = "master",

        },
        }
        router.Request("cs", ".redeemcode", "common", "Forward",mData,function (mRecord,m)
            print("MakeRedeemCode:",m)
            end)
    elseif iFlag == 104 then
        local mData = {
        cmd = "GetAllRedeemRuleInfo",
        data = {
        },
        }
        router.Request("cs", ".redeemcode", "common", "Forward",mData,function (mRecord,m)
            print("GetAllRedeemRuleInfo:",m)
            end)
    elseif iFlag == 105 then
        local mData = {
        cmd = "GetBatchInfoByRedeemId",
        data = {
            redeem_id = tonumber(arg[1]),
        },
        }
        router.Request("cs", ".redeemcode", "common", "Forward",mData,function (mRecord,m)
            print("GetBatchInfoByRedeemId:",m)
            end)
    elseif iFlag == 106 then
        local mData = {
        cmd = "GetRedeemCodeByBatchId",
        data = {
            batch_id = tonumber(arg[1]),
        },
        }
        router.Request("cs", ".redeemcode", "common", "Forward",mData,function (mRecord,m)
            print("GetRedeemCodeByBatchId:",m)
            end)
    elseif iFlag == 107 then
            local mData = {type="item"}
            router.Request("bs", ".backend", "common", "MyTest", mData, function (m1, m2)
                print("GetResourceInfo",m1,m2)
            end)
    elseif iFlag == 108 then
        local oItem = loaditem.ExtCreate(27601)
        oItem:Reward(oPlayer,"兑换码")
    end

end


