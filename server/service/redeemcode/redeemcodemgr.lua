--import module
local global = require "global"
local skynet = require "skynet"
local record = require "public.record"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"


function NewRedeemCodeMgr(...)
    local o = CRedeemCodeMgr:New(...)
    return o
end

local sIdCounterTable = "idcounter"
local sRedeemRuleTable = "redeemrule"
local sRedeemBatchTable = "redeembatch"
local sRedeemCodeTable = "redeemcode"
local sRedeemLogTable = "redeemlog"


CRedeemCodeMgr = {}
CRedeemCodeMgr.__index = CRedeemCodeMgr
inherit(CRedeemCodeMgr, logic_base_cls())

function CRedeemCodeMgr:New()
    local o = super(CRedeemCodeMgr).New(self)
    o:Init()
    return o
end

function CRedeemCodeMgr:Init()
    self.m_oDB = nil
    self.m_iBatchID = nil
    self.m_iRedeemID = nil
    self.m_mRedeemCode = {}
    self.m_mUseRedeemCode = {}
end

function CRedeemCodeMgr:InitDB(mInit)
    local oClient = mongoop.NewMongoClient({
        host = mInit.host,
        port = mInit.port,
        username = mInit.username,
        password = mInit.password
    })
    self.m_oDB = mongoop.NewMongoObj()
    self.m_oDB:Init(oClient, mInit.name)

    skynet.fork(function ()
        local o = self.m_oDB
        o:CreateIndex(sRedeemCodeTable, {code = 1}, {name = "redeem_code_index"})
        o:CreateIndex(sRedeemLogTable, {"pid", "redeem_id", unique=true, name = "redeem_log_index"})
    end)
end

function CRedeemCodeMgr:GetDB()
    return self.m_oDB
end

function CRedeemCodeMgr:DispatchBatchId()
    if not self.m_iBatchID then
        local m = self:GetDB():FindOne("idcounter", {type = "batch"}, {id = true})
        m = m or {}
        self.m_iBatchID = m.id or 0
    end

    self.m_iBatchID = self.m_iBatchID + 1
    self:GetDB():Update("idcounter", {type = "batch"}, {["$set"]={id = self.m_iBatchID}}, true)
    return self.m_iBatchID
end

function CRedeemCodeMgr:DispatchRedeemId()
    if not self.m_iRedeemID then
        local m = self:GetDB():FindOne("idcounter", {type = "redeem"}, {id = true})
        m = m or {}
        self.m_iRedeemID = m.id or 0
    end

    self.m_iRedeemID = self.m_iRedeemID + 1
    self:GetDB():Update("idcounter", {type = "redeem"}, {["$set"]={id = self.m_iRedeemID}}, true)
    return self.m_iRedeemID
end

function CRedeemCodeMgr:SaveRedeemRuleInfo(mData)
    if not mData then return end

    local mRule = {}
    local iRedeem = mData["redeem_id"]
    if not iRedeem or iRedeem <= 0 then
        iRedeem = self:DispatchRedeemId()
    end
    mRule["redeem_id"] = iRedeem
    mRule["redeem_name"] = mData["redeem_name"]
    mRule["create_time"] = get_time()
    mRule["gift_id"] = mData["gift_id"]
    mRule["expire_time"] = mData["expire_time"]
    mRule["player_redeem_cnt"] = mData["player_redeem_cnt"]
    mRule["code_redeem_cnt"] = mData["code_redeem_cnt"]
    mRule["operater"] = mData["operater"]

    mongoop.ChangeBeforeSave(mRule)
    self:GetDB():Update(sRedeemRuleTable, {redeem_id = iRedeem}, mRule, true)
end

function CRedeemCodeMgr:GetAllRedeemRuleInfo()
    local lRet = {}
    local mResult = self:GetDB():Find(sRedeemRuleTable, {})
    while mResult:hasNext() do
        local m = mResult:next()
        m["_id"] = nil
        table.insert(lRet, m)
    end
    mongoop.ChangeAfterLoad(lRet)
    return lRet
end

function CRedeemCodeMgr:MakeRedeemCode(mData, func)
    local iRedeem = mData["redeem_id"]
    local lChannels, lPlatforms
    if mData["channels"] and type(mData["channels"]) == "table" then
        lChannels = mData["channels"]
    end
    if mData["platforms"] and type(mData["platforms"]) == "table" then
        lPlatforms = mData["platforms"]
    end
    local iAmount = mData["amount"]
    local iOperater = mData["operater"]
    local sPublisher = mData["publisher"]
    if not iAmount or not iRedeem then return end
    if iAmount > 10000 then
        func({errcode = 1, errmsg = "amount must less than 10000"})
        return
    end

    local iBatch = self:DispatchBatchId()
    local mBatch = {
        batch_id = iBatch,
        redeem_id = iRedeem,
        amount = iAmount,
        channels = lChannels,
        platforms = lPlatforms,
        operater = iOperater,
        publisher = sPublisher,
    }
    mongoop.ChangeBeforeSave(mBatch)
    self:GetDB():Update(sRedeemBatchTable, {batch_id=iBatch}, mBatch, true)
    self:TrueMakeRedeemCode(iRedeem, iBatch, iAmount, func)
end

function CRedeemCodeMgr:TrueMakeRedeemCode(iRedeem, iBatch, iAmount, func)
    self:DelTimeCb("TrueMakeRedeemCode")
    local mBatchCode = self.m_mRedeemCode[iBatch]
    if not mBatchCode then
        mBatchCode = {}
        self.m_mRedeemCode[iBatch] = mBatchCode
    end

    local iCnt, mSaveData = 0, {}
    while iCnt < iAmount do
        local sCode = self:_RandomRedeemCode(iRedeem, iBatch)
        if not mBatchCode[sCode] then
            mBatchCode[sCode] = true
            table.insert(mSaveData, {code = sCode, batch_id = iBatch})
            iCnt = iCnt + 1
        end
        -- 10000万兑换码(0.15s左右)
        if iCnt >= 10000 then break end
    end

    if #mSaveData <= 0 then
        record.error("make redeemcode error redeem:%d, batch:%d, amount:%d", iRedeem, iBatch, iAmount)
        return
    end

    self:GetDB():BatchInsert(sRedeemCodeTable, mSaveData)
    iAmount = iAmount - iCnt
    if iAmount > 0 then
        local f = function ()
            self:TrueMakeRedeemCode(iRedeem, iBatch, iAmount, func)
        end
        self:AddTimeCb("TrueMakeRedeemCode", 500, f)
    else
        self.m_mRedeemCode[iBatch] = nil
        func({})
    end
end

function CRedeemCodeMgr:_RandomRedeemCode(iRedeem, iBatch)
    local mKey = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        'A', 'B', 'C', "D", 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
        'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
    }
    local sCode = ""
    for i = 1, 12 do
        sCode = sCode .. mKey[math.random(#mKey)]
    end
    sCode = sCode .. string.format('%04d', iBatch)
    return sCode
end

function CRedeemCodeMgr:GetBatchInfoByRedeemId(iRedeem)
    local mResult = self:GetDB():Find(sRedeemBatchTable, {redeem_id = iRedeem})
    local lRet = {}
    while mResult:hasNext() do
        local m = mResult:next()
        table.insert(lRet, m)
    end
    mongoop.ChangeAfterLoad(lRet)
    return lRet
end

function CRedeemCodeMgr:GetRedeemCodeByBatchId(iBatch)
    local mResult = self:GetDB():Find(sRedeemCodeTable, {batch_id = iBatch}, {code=true, use_cnt=true})
    local lRet = {}
    while mResult:hasNext() do
        local mCode = mResult:next()
        table.insert(lRet, {code = mCode.code, use_cnt = mCode.use_cnt})
    end
    mongoop.ChangeAfterLoad(lRet)
    return lRet
end

function CRedeemCodeMgr:UseRedeemCode(mData, func)
    local iPid = mData["pid"]
    local sCode = mData["code"]
    if not sCode or not iPid then
        func({errcode = 1, errmsg = "params error"})
        return
    end
    if self.m_mUseRedeemCode[iPid] then
        func({errcode = 9, errmsg = "deal redeem code"})
        return
    end
    self.m_mUseRedeemCode[iPid] = get_time()
    local br, mRet = safe_call(self.TrueUseRedeemCode, self, mData)
    if br then
        func(mRet)
    else
        func({errcode = 1, errmsg = "unknown error"})
    end
    self.m_mUseRedeemCode[iPid] = nil
end

function CRedeemCodeMgr:TrueUseRedeemCode(mData)
    local sCode = mData["code"]
    local iPid = mData["pid"]
    local mCode = self:GetDB():FindOne(sRedeemCodeTable, {code = sCode})
    if not mCode or not mCode["batch_id"] then
        return {errcode = 2, errmsg = "not find redeem code"}
    end
    mongoop.ChangeAfterLoad(mCode)

    local iBatch = mCode["batch_id"]
    local mBatch = self:GetDB():FindOne(sRedeemBatchTable, {batch_id = iBatch})
    if not mBatch or not mBatch["redeem_id"] then
        return {errcode = 2, errmsg = "not find redeem batch"}
    end
    mongoop.ChangeAfterLoad(mBatch)

    local iRedeem = mBatch["redeem_id"]
    local mRedeem = self:GetDB():FindOne(sRedeemRuleTable, {redeem_id = iRedeem})
    if not mRedeem then
        return {errcode = 2, errmsg = "not find redeem info"}
    end
    mongoop.ChangeAfterLoad(mRedeem)
    return self:_TrueUseRedeemCode(mRedeem, mBatch, mCode, mData)
end

function CRedeemCodeMgr:_TrueUseRedeemCode(mRedeem, mBatch, mCode, mArgs)
    local sCode = mArgs["code"]
    local iPid = mArgs["pid"]
    local iChannel = mArgs["channel"]
    local sChannel = tostring(iChannel or 0)
    local iPlatform = mArgs["platform"]
    local sPlatform = tostring(iPlatform or 0)
    local sPublisher = mArgs["publisher"] or "czk"
    if get_time() > mRedeem["expire_time"] then
        return {errcode = 3, errmsg = "redeem code expire", data = mRedeem}
    end
    if mBatch["channels"] and not table_in_list(mBatch["channels"], sChannel) then
        return {errcode = 4, errmsg = "channel limit", data = mRedeem}
    end
    local sLimitPubliser = mBatch["publisher"] or "czk"
    if sLimitPubliser ~= sPublisher then
        return {errcode = 4, errmsg = "publisher limit", data = mRedeem}
    end
    if mBatch["platforms"] and not table_in_list(mBatch["platforms"], sPlatform) then
        return {errcode = 5, errmsg = "platform limit", data = mRedeem}
    end
    if (mCode["use_cnt"] or 0) >= mRedeem["code_redeem_cnt"] then
        return {errcode = 6, errmsg = "redeem code used", data = mRedeem}
    end
    local iRedeem = mRedeem["redeem_id"]
    local m = self:GetDB():FindOne(sRedeemLogTable, {pid = iPid, redeem_id = iRedeem}, {code_list=true})
    if m then
        mongoop.ChangeAfterLoad(m)
        local mUseCode = m["code_list"] or {}
        if table_count(mUseCode) >= mRedeem["player_redeem_cnt"] then
            return {errcode = 7, errmsg = "use code times limit", data = mRedeem}
        end
        if mUseCode[sCode] then
            return {errcode = 8, errmsg = "you has use redeem code", data = mRedeem}
        end
    end
    local mCode = self:GetDB():FindOne(sRedeemCodeTable,{code = sCode})
    mongoop.ChangeAfterLoad(mCode)
    local iUseCnt = mCode["use_cnt"] or 0
    if (iUseCnt) >= mRedeem["code_redeem_cnt"] then
        return {errcode = 6, errmsg = "redeem code used", data = mRedeem}
    end
    local mPlist = mCode["player"] or {}
    table.insert(mPlist,{iPid,get_time()})
    local mSaveCode = {use_cnt=iUseCnt+1,player= mPlist}
    mongoop.ChangeBeforeSave(mSaveCode)
    self:GetDB():Update(sRedeemCodeTable,{code=sCode},{["$set"] = mSaveCode})
    local mLog = {["code_list."..sCode] = get_time()}

    self:GetDB():Update(sRedeemLogTable, {pid = iPid, redeem_id = iRedeem}, {["$set"] = mLog}, true)
    return {errcode = 0, data = mRedeem}
end

function CRedeemCodeMgr:FindCodeExchangeLog(sCode)
    local mCode = self:GetDB():FindOne(sRedeemCodeTable,{code = sCode})
    mongoop.ChangeAfterLoad(mCode)
    local iBatch = mCode["batch_id"]
    local mRedeemRule = {}
    if iBatch then
        local mResult = self:GetDB():FindOne(sRedeemBatchTable,{batch_id=iBatch})
        mongoop.ChangeAfterLoad(mResult)
        mRedeemRule["redeem_id"] = mResult["redeem_id"]
        mRedeemRule["name"] = mResult["name"]
    end
    return {code=sCode,rule=mRedeemRule,player=mCode["player"] or {}}
end

-- 根据玩家ID查询兑换信息
function CRedeemCodeMgr:FindPlayerExchangeLog(iPid)
    local mResult = self:GetDB():Find(sRedeemLogTable, {pid = iPid,}, {code_list=true})
    local codelist = {}
    while mResult:hasNext() do
        local m = mResult:next()
        local mUseCode = m["code_list"] or {}
        for sCode,iTime in  pairs(mUseCode) do
            local mCode = self:GetDB():FindOne(sRedeemCodeTable, {code = sCode})
            mongoop.ChangeAfterLoad(mCode)
            local iBatch = mCode["batch_id"]
            local mBatch = self:GetDB():FindOne(sRedeemBatchTable, {batch_id = iBatch})
            mongoop.ChangeAfterLoad(mBatch)
            local iRedeem = mBatch["redeem_id"]
            local mRule = self:GetDB():FindOne(sRedeemRuleTable,{redeem_id=iRedeem})
            local mData = {
                code = sCode,
                pid = iPid,
                gif_id = mRule["gift_id"],
                etime = iTime,
                master = mBatch["publisher"],
                create_time = mRule["create_time"],
                expire_time = mRule["expire_time"],
                platforms = mBatch["platforms"],
                amount = mBatch["amount"],
                channels = mBatch["channels"],
                }
            table.insert(codelist,mData)
        end
    end

    print("codelist:",codelist)
end


