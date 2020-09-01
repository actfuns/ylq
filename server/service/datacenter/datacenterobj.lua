--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local cjson = require "cjson"
local mongoop = require "base.mongoop"

local datactrl = import(lualib_path("public.datactrl"))
local serverdesc = import(lualib_path("public.serverdesc"))
local serverinfo = import(lualib_path("public.serverinfo"))

function NewDataCenter(...)
    local o = CDataCenter:New(...)
    return o
end

CDataCenter = {}
CDataCenter.__index = CDataCenter
inherit(CDataCenter, datactrl.CDataCtrl)

function CDataCenter:New()
    local o = super(CDataCenter).New(self)
    o.m_oDataCenterDb = nil
    return o
end

function CDataCenter:Init()
end

function CDataCenter:InitDataCenterDb(mInit)
    local oClient = mongoop.NewMongoClient({
        host = mInit.host,
        port = mInit.port,
        username = mInit.username,
        password = mInit.password,
    })
    self.m_oDataCenterDb = mongoop.NewMongoObj()
    self.m_oDataCenterDb:Init(oClient, mInit.name)

    skynet.fork(function ()
        local o = self.m_oDataCenterDb

        local sTestTableName = "roleinfo"
        o:CreateIndex(sTestTableName, {pid = 1}, {name = "role_pid_index"})
        o:CreateIndex(sTestTableName, {"account", "channel", name = "role_account_channel_index"})
    end)
end

function CDataCenter:TryCreateRole(sServerTag, sAccount, iChannel,mInfo, endfunc)
    interactive.Request(".idsupply", "common", "GenPlayerId", {},
        function(mRecord, mData)
            endfunc(self:_TryCreateRole2(mRecord, mData, sServerTag, sAccount, iChannel,mInfo))
        end
    )
end

function CDataCenter:_TryCreateRole2(mRecord, mData, sServerTag, sAccount, iChannel,mInfo)
    if is_release(self) then
        return
    end
    local iPid = mData.id
    local mInsert = {
        server = sServerTag,
        now_server = sServerTag,
        account = sAccount,
        channel = iChannel,
        platform = mInfo.platform,
        publisher = mInfo.publisher,
        pid = iPid,
        icon = mInfo.icon,
        grade = 1,
        school = mInfo.school,
        name = mInfo.name,
    }
    mongoop.ChangeBeforeSave(mInsert)
    self.m_oDataCenterDb:Insert("roleinfo", mInsert)
    return iPid
end

function CDataCenter:UpdateRoleInfo(iPid, mInfo)
    if not mInfo.no_login then
        mInfo.login_time = mInfo.login_time or get_time()
    end
    mongoop.ChangeBeforeSave(mInfo)
    self.m_oDataCenterDb:Update("roleinfo", {pid = iPid}, {["$set"]=mInfo}, true)
end

function CDataCenter:GetRoleList(sAccount, lChannel,iPlatform,lServer,sPublisher)
    local m = self.m_oDataCenterDb:Find("roleinfo", {
            account = sAccount,
            channel = {["$in"] = lChannel},
            --platform = iPlatform,
            now_server = {["$in"] = lServer},
        }, {
            server = true,
            now_server = true,
            pid = true,
            icon = true,
            name = true,
            school = true,
            grade = true,
            platform = true,
    })
    local mRet = {}
    while m:hasNext() do
        local mInfo = m:next()
        mongoop.ChangeAfterLoad(mInfo)
        local mRoleData = {
            server = make_server_key(mInfo.server),
            now_server = make_server_key(mInfo.now_server),
            pid = mInfo.pid,
            icon = mInfo.icon,
            name = mInfo.name,
            school = mInfo.school,
            grade = mInfo.grade,
        }
        local sServerKey = make_server_key(mInfo.now_server)
        if  serverinfo.is_role_interflow(sPublisher,sServerKey) then
            table.insert(mRet,mRoleData)
        else
            if mInfo.platform == iPlatform then
                table.insert(mRet,mRoleData)
            end
        end
    end
    return mRet
end

function CDataCenter:GetRoleNowServer(iPid)
    local m = self.m_oDataCenterDb:FindOne("roleinfo", {pid = iPid}, {now_server = true, server = true})
    if m then
        return m.now_server or m.server
    end
    return nil
end