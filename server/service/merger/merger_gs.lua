--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"

local serverinfo = import(lualib_path("public.serverinfo"))
local defines = import(service_path("defines"))


function NewMerger(...)
    local o = CMerger:New(...)
    return o
end


CMerger = {}
CMerger.__index = CMerger
inherit(CMerger, logic_base_cls())

function CMerger:New()
    local o = super(CMerger).New(self)
    o.m_iMergerTimes = 0
    o.m_sFromServer = nil
    o.m_oFromDb = nil
    o.m_oLocalDb = nil
    o.m_mPending = {}
    o.m_lWaitFunc = {}
    o.m_iLocalMaxOrgShowId = 0
    return o
end

function CMerger:GetFromDb()
    local sFromServer = self.m_sFromServer
    local sFromServerKey = make_server_key(sFromServer)
    local mFromSlave = serverinfo.get_slave_dbs({sFromServerKey})[sFromServerKey]
    if not mFromSlave then
        record.error("merger error from server tag: %s", sFromServer)
        return
    end
    local oFromClient = mongoop.NewMongoClient({
        host = mFromSlave.game.host,
        port = mFromSlave.game.port,
        username = mFromSlave.game.username,
        password = mFromSlave.game.password
    })
    local oFromGameDb = mongoop.NewMongoObj()
    oFromGameDb:Init(oFromClient, "game")
    self.m_oFromDb = oFromGameDb
    return oFromGameDb
end

function CMerger:GetLocalDb()
    local mLocal = serverinfo.get_local_dbs()

    local oLocalClient = mongoop.NewMongoClient({
        host = mLocal.game.host,
        port = mLocal.game.port,
        username = mLocal.game.username,
        password = mLocal.game.password
    })
    local oLocalGameDb = mongoop.NewMongoObj()
    oLocalGameDb:Init(oLocalClient, "game")
    self.m_oLocalDb = oLocalGameDb
    return oLocalGameDb
end

function CMerger:GetLocalOrgShowId()
    local mData = self.m_oLocalDb:FindOne("world")
    if mData and mData.data and mData.data.orgid then
        self.m_iLocalMaxOrgShowId = mData.data.orgid
    end
    print(string.format("----merger get local org showid : %s ----", self.m_iLocalMaxOrgShowId))
end

function CMerger:StartMerger(iMergerTimes)
    local lInfo = defines.MERGER_INFO[iMergerTimes]
    if not lInfo then
        record.error("error merger times %s", iMergerTimes)
        return
    end
    if lInfo[2] ~= get_server_tag() then
        record.error("error host server %s", lInfo[2])
        return
    end
    self.m_iMergerTimes = iMergerTimes
    self.m_sFromServer = lInfo[1]
    local oFromGameDb = self:GetFromDb()
    local oLocalGameDb = self:GetLocalDb()
    if not oFromGameDb or not oLocalGameDb then
        return
    end
    print(string.format("----merger start: %s times----", iMergerTimes))

    print("start merge player----")
    self:MergePlayer(oFromGameDb, oLocalGameDb)

    print("start merge offline----")
    self:MergeOffline(oFromGameDb, oLocalGameDb)

    print("start merge achieve----")
    self:MergeAchieve(oFromGameDb, oLocalGameDb)

    print("start merge picture----")
    self:MergePicture(oFromGameDb,oLocalGameDb)

    print("start merge task----")
    self:MergeTask(oFromGameDb,oLocalGameDb)

    print("start merge gamepush----")
    self:MergeGamePush(oFromGameDb,oLocalGameDb)

    print("start merge house----")
    self:MergeHouse(oFromGameDb,oLocalGameDb)

    print("start merge image----")
    self:MergeImage(oFromGameDb,oLocalGameDb)

    print("start merge partner----")
    self:MergePartner(oFromGameDb,oLocalGameDb)

    print("start merge org----")
    self:MergeOrg(oFromGameDb, oLocalGameDb)
    print("----merge org finish")

    print("start merge invitecode----")
    self:MergeInviteCode(oFromGameDb, oLocalGameDb)
    print("----merge invitecode finish")

    print("start merge warfilm----")
    self:MergeWarFilm(oFromGameDb, oLocalGameDb)
    
    print("start merge global----")
    self:MergeGlobal(oFromGameDb, oLocalGameDb)
    
    print("start merge rank----")
    self:MergeRank(oFromGameDb, oLocalGameDb)
    
    print("start merge assisthd----")
    self:MergeAssistHD(oFromGameDb, oLocalGameDb)
    
    print("start merge world----")
    self:MergeWorld(oFromGameDb, oLocalGameDb)
    
    self:Wait2Exec(function ()
        save_all()
        print("----data is merged! reboot now----")
    end)
end



function CMerger:MergePlayer(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "player", 500) do
        for idx, mInfo in ipairs(lInfos) do
            oLocalGameDb:Update("namecounter", {name = mInfo.name}, {["$set"] = {name = mInfo.name}}, true)
        end
        oLocalGameDb:BatchInsert("player", lInfos)
    end
end

function CMerger:MergeOffline(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "offline", 500) do
        oLocalGameDb:BatchInsert("offline", lInfos)
    end
end

function CMerger:MergeAchieve(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "achieve", 500) do
        oLocalGameDb:BatchInsert("achieve", lInfos)
    end
end

function CMerger:MergePicture(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "picture", 500) do
        oLocalGameDb:BatchInsert("picture", lInfos)
    end
end

function CMerger:MergeTask(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "task", 500) do
        oLocalGameDb:BatchInsert("task", lInfos)
    end
end

function CMerger:MergeGamePush(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "gamepush", 500) do
        oLocalGameDb:BatchInsert("gamepush", lInfos)
    end
end

function CMerger:MergeHouse(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "house", 500) do
        oLocalGameDb:BatchInsert("house", lInfos)
    end
end

function CMerger:MergeImage(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "image", 500) do
        oLocalGameDb:BatchInsert("image", lInfos)
    end
end

function CMerger:MergeOrg(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "org", 100,"HandleOrgData") do
        oLocalGameDb:BatchInsert("org", lInfos)
    end
end

function CMerger:HandleOrgData(mData)
    mData.from_server = self.m_sFromServer
    return mData
end

function CMerger:MergeInviteCode(oFromGameDb, oLocalGameDb)
    --丢弃被合服数据
end

function CMerger:MergePartner(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "partner", 500) do
        oLocalGameDb:BatchInsert("partner", lInfos)
    end
end

function CMerger:MergeWarFilm(oFromGameDb, oLocalGameDb)
    for lInfos in self:BatchDealTable(oFromGameDb, "warfilm", 100) do
        oLocalGameDb:BatchInsert("warfilm", lInfos)
    end
end

GLOBAL_HANDLE = {
    ["achieve"] = "HandleGlobalAchieve",
    ["player_account"] = "HandleGlobalAccount",
    ["welfarecenter"] = "HandleGlobalWelfarecenter",
    ["partner"] = "HandleGlobalPartnerCmt",
    ["hongbao"] = "HandleGlobalHongbao",
}

function CMerger:MergeGlobal(oFromGameDb, oLocalGameDb)
    local m = oFromGameDb:Find("global")
    while m:hasNext() do
        local mInfo = m:next()
        mInfo._id = nil
        local sName = mInfo.name
        print(string.format("merge global %s start----", sName))
        local f = self[GLOBAL_HANDLE[sName]]
        if f then
            local mData = mInfo.data
            mongoop.ChangeAfterLoad(mData)
            f(self, sName, mData)
        else
            --活动
            self:AddPending("huodong."..sName)
            interactive.Request(".world", "merger", "MergeHuodong", mInfo,
            function (mRecord, mData)
                if mData.err then
                    record.error(mData.err)
                else
                    print(string.format("----merge global %s finish", sName))
                end
                self:OnModuleFinish("huodong."..sName)
            end)
        end
    end
end



function CMerger:HandleGlobalAchieve(sName, mInfo)
    self:AddPending("global."..sName)
    interactive.Request(".achieve", "merger", "MergeAchieve", mInfo,
    function (mRecord, mData)
        if mData.err then
            record.error(mData.err)
        else
            print(string.format("----merge global %s finish", sName))
        end
        self:OnModuleFinish("global."..sName)
    end)
end

function CMerger:HandleGlobalAccount(sName, mInfo)
    self:AddPending("global."..sName)
    interactive.Request(".world", "merger", "MergeGlobalAccount", mInfo,
    function (mRecord, mData)
        if mData.err then
            record.error(mData.err)
        else
            print(string.format("----merge global %s finish", sName))
        end
        self:OnModuleFinish("global."..sName)
    end)
end

function CMerger:HandleGlobalWelfarecenter(sName, mInfo)
    self:AddPending("global."..sName)
    interactive.Request(".world", "merger", "MergeWelfarecenter", mInfo,
    function (mRecord, mData)
        if mData.err then
            record.error(mData.err)
        else
            print(string.format("----merge global %s finish", sName))
        end
        self:OnModuleFinish("global."..sName)
    end)
end

function CMerger:HandleGlobalPartnerCmt(sName, mInfo)
    self:AddPending("global."..sName)
    interactive.Request(".world", "merger", "MergePartnerCmt", mInfo,
    function (mRecord, mData)
        if mData.err then
            record.error(mData.err)
        else
            print(string.format("----merge global %s finish", sName))
        end
        self:OnModuleFinish("global."..sName)
    end)
end

function CMerger:HandleGlobalHongbao(sName,mInfo)
    self:AddPending("global."..sName)
    interactive.Request(".world", "merger", "MergeHongbao", mInfo,
    function (mRecord, mData)
        if mData.err then
            record.error(mData.err)
        else
            print(string.format("----merge global %s finish", sName))
        end
        self:OnModuleFinish("global."..sName)
    end)
end

function CMerger:MergeRank(oFromGameDb, oLocalGameDb)
    local m = oFromGameDb:Find("rank")
    while m:hasNext() do
        local mInfo = m:next()
        mInfo._id = nil
        mongoop.ChangeAfterLoad(mInfo)
        local sName = mInfo.name
        print(string.format("merge rank %s start----", sName))
        self:AddPending("rank."..sName)
        interactive.Request(".rank", "merger", "MergeRank", mInfo, function (mRecord, mData)
            if mData.err then
                record.error(mData.err)
            else
                print(string.format("----merge rank %s finish", sName))
            end
            self:OnModuleFinish("rank."..sName)
        end)
    end
end

function CMerger:MergeAssistHD(oFromGameDb, oLocalGameDb)
    local m = oFromGameDb:Find("assithd")
    while m:hasNext() do
        local mInfo = m:next()
        mInfo._id = nil
        mongoop.ChangeAfterLoad(mInfo)
        local sName = mInfo.name
        print(string.format("merge assithd %s start----", sName))
        self:AddPending("assithd."..sName)
        interactive.Request(".assithd", "merger", "MergeAssistHD", mInfo, function (mRecord, mData)
            if mData.err then
                record.error(mData.err)
            else
                print(string.format("----merge assithd %s finish", sName))
            end
            self:OnModuleFinish("assithd."..sName)
        end)
    end
end

function CMerger:MergeWorld(oFromGameDb)
    local mInfo = oFromGameDb:FindOne("world")
    local mData = mInfo.data
    mongoop.ChangeAfterLoad(mData)
    self:AddPending("world")
    interactive.Request(".world", "merger", "MergeWorld", {
        from_data = mData,
        org_showid = self.m_iLocalMaxOrgShowId,
        merger_times = self.m_iMergerTimes,
        from_server = self.m_sFromServer,
    },
    function (mRecord, mData)
        if mData.err then
            record.error(mData.err)
        else
            print("----merge world finish")
        end
        self:OnModuleFinish("world")
    end)
end

function CMerger:AddPending(sKey)
    self.m_mPending[sKey] = true
end

function CMerger:OnModuleFinish(sKey)
    self.m_mPending[sKey] = nil
    if not next(self.m_mPending) then
        for idx, func in ipairs(self.m_lWaitFunc) do
            func()
        end
    end
end

function CMerger:Wait2Exec(func)
    if not next(self.m_mPending) then
        func()
    else
        table.insert(self.m_lWaitFunc, func)
    end
end

function CMerger:BatchDealTable(oGameDb, sTable, iLimit, sHook)
    local m = oGameDb:Find(sTable)
    return function ()
        if not m:hasNext() then
            return
        end
        local lInfos = {}
        for i = 1, iLimit do
            if not m:hasNext() then
                break
            end
            local mInfo = m:next()
            mInfo._id = nil
            if sHook then
                local mRet = self[sHook](self, mInfo)
                if mRet then
                    table.insert(lInfos, mRet)
                end
            else
                table.insert(lInfos, mInfo)
            end
        end
        return lInfos
    end
end
