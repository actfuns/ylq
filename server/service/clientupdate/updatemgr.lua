--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"

local bigpacket = import(lualib_path("public.bigpacket"))
local version = import(lualib_path("public.version"))

function NewUpdateMgr(...)
    local o = CUpdateMgr:New(...)
    return o
end

function NewMemberObj(...)
    local o = CMemberObj:New(...)
    return o
end


CUpdateMgr = {}
CUpdateMgr.__index = CUpdateMgr
inherit(CUpdateMgr, logic_base_cls())

function CUpdateMgr:New()
    local o = super(CUpdateMgr).New(self)
    o.m_mMembers = {}
    o.m_mClientResFile = {}
    return o
end

function CUpdateMgr:Init()
end

function CUpdateMgr:Add(iPid, mInfo)
    local o = self.m_mMembers[iPid]
    if o then
        o:Update(mInfo)
    else
        self.m_mMembers[iPid] = NewMemberObj(mInfo)
    end
end

function CUpdateMgr:Del(iPid)
    local oMember = self.m_mMembers[iPid]
    if oMember then
        baseobj_delay_release(oMember)
    end
    self.m_mMembers[iPid] = nil
end

function CUpdateMgr:Get(iPid)
    return self.m_mMembers[iPid]
end

function CUpdateMgr:GetAll()
    return self.m_mMembers
end

function CUpdateMgr:GetAmount()
    return table_count(self.m_mMembers)
end

function CUpdateMgr:SendRaw(sData, mExclude)
    mExclude = mExclude or {}

    for k, o in pairs(self.m_mMembers) do
        if not mExclude[k] then
            o:SendRaw(sData)
        end
    end
end

function CUpdateMgr:SendBigRaw(lRet, mExclude)
    mExclude = mExclude or {}

    for k, o in pairs(self.m_mMembers) do
        if not mExclude[k] then
            o:SendBigRaw(lRet)
        end
    end
end

function CUpdateMgr:Send(sMessage, mData, mExclude)
    local sData = playersend.PackData(sMessage,mData)
    mExclude = mExclude or {}

    for k, o in pairs(self.m_mMembers) do
        if not mExclude[k] then
            o:SendRaw(sData)
        end
    end
end

function CUpdateMgr:SendBig(sMessage, mData, mExclude)
    local sData = playersend.PackData(sMessage,mData)
    mExclude = mExclude or {}

    for k, o in pairs(self.m_mMembers) do
        if not mExclude[k] then
            o:SendRaw(sData)
        end
    end
end

function CUpdateMgr:ReadVersion(sVersion)
    local iNum = 0
    local iFactor = 1
    for i =4,1,-1 do
        local iValue = string.byte(sVersion,i)*iFactor
        iNum = iNum + iValue
        iFactor = iFactor * 256
    end
    return iNum
end

function CUpdateMgr:FlushClientRes()
    local br, rr1 = safe_call(function ()
        local sDir = skynet.getenv("client_res_file")
        local mFile = get_all_files(sDir)
        local mResData = {}
        for _,sFile in pairs(mFile) do
            local sFilePath = string.format("%s/%s",sDir,sFile)
            local h = io.open(sFilePath, "rb")
            local sData = h:read("*a")
            assert(#sData>=4, "FlushClientRes failed read file")
            local sVersion,sContent = string.sub(sData,1,4),sData
            local iVersion = self:ReadVersion(sVersion)
            mResData[sFile] = {
                version = tonumber(iVersion),
                content = sContent,
            }
            h:close()
        end
        return mResData
    end)
    if br then
        self.m_mClientResFile = rr1
    else
        self.m_mClientResFile = {}
    end
end

function CUpdateMgr:GetClientResFileVersion()
    local mVersionData = {}
    for sFile,mData in pairs(self.m_mClientResFile) do
        mVersionData[sFile] = mData["version"]
    end
    return mVersionData
end

function CUpdateMgr:GetUpdateCode()
    return version.CLIENT_UPDATE_CODE
end

function CUpdateMgr:IsUpdateRes()
    return version.CLIENT_UPDATE_RES
end

function CUpdateMgr:OnRegister(iPid)
end

function CUpdateMgr:OnUnRegister(iPid)
end

function CUpdateMgr:OnCodeUpdate()
    local sCode = self:GetUpdateCode()
    if sCode and sCode ~= "" then
        self:SendBig("GS2CClientUpdateCode", {
            code = sCode,
        })
    end
end

function CUpdateMgr:OnResUpdate()
    if not self:IsUpdateRes() then
        self.m_mClientResFile = {}
        return
    end

    local mOldVersion = self:GetClientResFileVersion()
    self:FlushClientRes()
    local mNewVersion = self:GetClientResFileVersion()
    local mFile = {}
    for sFile,iOldVersion in pairs(mOldVersion) do
        local iNewVersion = mNewVersion[sFile] or 0
        if iOldVersion ~= iNewVersion then
            table.insert(mFile,sFile)
        end
    end
    for sFile,iNewVresion in pairs(mNewVersion) do
        local iOldVersion = mOldVersion[sFile]
        if not iOldVersion then
            table.insert(mFile,sFile)
        end
    end
    if #mFile > 0 then
        local iTime = 0
        local iCnt = 0
        for k, o in pairs(self.m_mMembers) do
            o:Send("GS2CClientUpdateResVersion", {
                res_file = mFile,
                delay = iTime + math.random(3),
            })
            iCnt = iCnt + 1
            if iCnt >= 100 then
                iCnt = 0
                iTime = iTime + 10
            end
        end
    end
end

function CUpdateMgr:OnQueryResUpdate(iPid, mVersion)
    if not self:IsUpdateRes() then
        return
    end

    local obj = self:Get(iPid)
    local mUpdateFileRes = {}
    for _,mFileVersion in pairs(mVersion) do
        local sFile = mFileVersion["file_name"]
        local iVersion = mFileVersion["version"]
        local mData = self.m_mClientResFile[sFile]
        if not mData then
            table.insert(mUpdateFileRes,sFile)
        else
            local iNowVersion = tonumber(mData["version"] or 0)
            if iNowVersion ~= iVersion then
                table.insert(mUpdateFileRes,sFile)
            end
        end
    end
    if obj and #mUpdateFileRes > 0 then
        local mResData = {}
        local mDelete = {}
        for _,sFile in pairs(mUpdateFileRes) do
            local mData = self.m_mClientResFile[sFile]
            if not mData then
                table.insert(mDelete,sFile)
            else
                table.insert(mResData,{
                    file_name = sFile,
                    content = mData["content"],
                })
            end
        end
        obj:SendBig("GS2CClientUpdateRes",{
            res_file = mResData,
            delete_file = mDelete,
        })
    end
end

function CUpdateMgr:GetClientResFile()
    return self.m_mClientResFile
end

function CUpdateMgr:QueryLogin(mQueryResFile)
    local mClientResFile = self:GetClientResFile()
    local mDelete = {}
    local mResFile = {}
    local mRequestFile = {}
    for _,mQueryFile in pairs(mQueryResFile) do
        local sFile = mQueryFile["file_name"] or ""
        local iClientVersion = mQueryFile["version"] or 0
        mRequestFile[sFile] = true
        local mData = mClientResFile[sFile]
        if not mData then
            table.insert(mDelete,sFile)
        else
            local iServerVersion = tonumber(mData["version"] or 0)
            if iClientVersion < iServerVersion then
                table.insert(mResFile,{
                    file_name = sFile,
                    content = mData["content"]
                })
            end
        end
    end
    --新增加
    for sFile,mData in pairs(mClientResFile) do
        if not mRequestFile[sFile] then
            table.insert(mResFile,{
                file_name = sFile,
                content = mData["content"]
            })
        end
    end
    local mRes = {
        res_file = mResFile,
        delete_file = mDelete
    }
    local sCode = self:GetUpdateCode()
    if sCode and sCode ~= "" then
        mRes.code = sCode
    end
    return mRes
end


CMemberObj = {}
CMemberObj.__index = CMemberObj
inherit(CMemberObj, logic_base_cls())

function CMemberObj:New(mInfo)
    local o = super(CMemberObj).New(self)
    o.m_iPid = mInfo.pid
    return o
end

function CMemberObj:Update(mInfo)
end

function CMemberObj:Send(sMessage, mData)
    playersend.Send(self.m_iPid,sMessage,mData)
end

function CMemberObj:SendBig(sMessage, mData)
    playersend.SendMergePacket(self.m_iPid,{{message=sMessage,data=mData}})
end

function CMemberObj:SendRaw(sData)
    playersend.SendRaw(self.m_iPid,sData)
end

function CMemberObj:SendBigRaw(lRet)
    playersend.SendRawList(self.m_iPid,lRet)
end
