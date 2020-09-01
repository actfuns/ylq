local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedb = import(lualib_path("public.gamedb"))
local loaditem = import(service_path("item.loaditem"))

local min = math.min
local max = math.max
local floor = math.floor

function NewMergerMgr(...)
    local o = CMergerMgr:New(...)
    return o
end

CMergerMgr = {}
CMergerMgr.__index = CMergerMgr
inherit(CMergerMgr, datactrl.CDataCtrl)

function CMergerMgr:New()
    local o = super(CMergerMgr).New(self)
    o.m_mMergedServers = {}
    return o
end

function CMergerMgr:Load(m)
    m = m or {}
    self.m_mMergerInfo = m.merger_info or {}
    self.m_iLastMerger = m.last_merger or 0
    self.m_iHasMerger = m.has_merger or 0
end

function CMergerMgr:Save()
    local m = {}
    m.merger_info = self.m_mMergerInfo
    m.last_merger = self.m_iLastMerger
    m.has_merger = self.m_iHasMerger
    return m
end

function CMergerMgr:GenMergedServers()
    self.m_mMergedServers = {}
    local mServers = self.m_mMergedServers
    for k, v in pairs(self.m_mMergerInfo) do
        mServers[v.from_server] = true
    end
end

function CMergerMgr:CheckMergedServer(sServerKey)
    local sServerTag = get_server_tag(sServerKey)
    return self.m_mMergedServers[sServerTag] and 0 or 1
end

function CMergerMgr:MergeFrom(mData)
    local mFromData = mData.from_data

    local iMergerTimes = mData.merger_times
    local sFromServer = mData.from_server
    local mMergerData = mData.merger

    if mMergerData and mMergerData.merger_info then
        for k, v in pairs(mMergerData.merger_info) do
            self.m_mMergerInfo[k] = v
        end
    end
    local iFromServerGrade = mFromData.server_grade
    local iFromServerOpenDays = mFromData.open_days
    self.m_mMergerInfo[iMergerTimes] = {
        from_server = sFromServer,
        from_grade = iFromServerGrade,
        from_open_day = iFromServerOpenDays,
        to_server = get_server_tag(),
        to_grade = global.oWorldMgr:GetServerGrade(),
        to_open_day = global.oWorldMgr:GetOpenDays(),
        time = get_time()
    }
    self.m_iLastMerger = iMergerTimes
    self.m_iHasMerger = 1
    return true
end

function CMergerMgr:OnServerStartEnd()
    if self.m_iHasMerger == 1 then
        print("merger HandleConfictNameOrg start----")
        self:HandleConfictNameOrg(function ()
            print("merger HandleConfictNamePlayer start----")
            self:HandleConfictNamePlayer(function ()
                save_all()
                global.oRankMgr:MergeFinish()
            end)
        end)
        self.m_iHasMerger = 0
        self:Dirty()
    end
    self:GenMergedServers()
end

function CMergerMgr:HandleConfictNameOrg(endfunc)
    local mData = {}
    interactive.Request(".org","merger","HandleConfictNameOrg",mData,endfunc)
end

function CMergerMgr:HandleConfictNamePlayer(endfunc)
    local mInfo = {
        module = "playerdb",
        cmd = "GetConflictNamePlayer",
    }
    gamedb.LoadDb("merge", "common", "LoadDb", mInfo,
    function (mRecord, mData)
        self:_HandleConfictNamePlayer1(endfunc, mRecord, mData)
    end)
end

function CMergerMgr:_HandleConfictNamePlayer1(endfunc, mRecord, mData)
    local oRenameMgr = global.oRenameMgr
    local oMailMgr = global.oMailMgr
    for iPid, sName in pairs(mData) do
        local sNewName = sName.."*"..iPid
        local mData = {
            name = sNewName,
        }
        local mInfo = {
            module = "playerdb",
            cmd = "SavePlayerMain",
            data = {data = mData,pid = iPid},
        }
        gamedb.SaveDb("merge", "common", "SaveDb", mInfo)
        local mInfo = {
            module = "namecounter",
            cmd = "InsertNewNameCounter",
            data = {name = sNewName},
        }
        gamedb.SaveDb("merge", "common", "SaveDb", mInfo)
        oRenameMgr:RefreshDbName(iPid, sName, sNewName)
        --给玩家发改名卡
        local oItem = loaditem.ExtCreate(10023)
        local mData, name = oMailMgr:GetMailInfo(74)
        oMailMgr:SendMail(0, name, iPid, mData, 0, {oItem})
    end
    print("----merger HandleConfictNamePlayer end: ", table_count(mData), mData)
    endfunc()
end

function CMergerMgr:OnLogin(oPlayer)
    local sNowServer = oPlayer:GetNowServer()
    local iPMergerCnt = oPlayer:Query("merger_cnt", 0)
    local iGrade = oPlayer:GetGrade()
    if iPMergerCnt < self.m_iLastMerger then
        oPlayer:Set("merger_cnt", self.m_iLastMerger)
        oPlayer:SetNowServer()
        if iGrade < 30 then
            return
        end
        print("----merger buchange start: ", oPlayer:GetPid(), iGrade, sNowServer, iPMergerCnt)
        local iNow = get_time()
        for i = iPMergerCnt + 1, self.m_iLastMerger do
            local mInfo = self.m_mMergerInfo[i]
            if mInfo and mInfo.time + 2592000 > iNow then
                if mInfo.from_server == sNowServer then
                    sNowServer = mInfo.to_server
                    self:FromBuchang(i, oPlayer, mInfo)
                elseif mInfo.to_server == sNowServer then
                    self:LocalBuchang(i, oPlayer, mInfo)
                end
            end
        end
        print("----merger buchange end")
    end
end

function CMergerMgr:FromBuchang(iTimes, oPlayer, mInfo)
    record.user("player", "merger_reward", {pid=oPlayer:GetPid(), times=iTimes, items={}})
end

function CMergerMgr:LocalBuchang(iTimes, oPlayer, mInfo)
    record.user("player", "merger_reward", {pid=oPlayer:GetPid(), times=iTimes, items={}})
end
