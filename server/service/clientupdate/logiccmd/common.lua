--import module
local global = require "global"
local skynet = require "skynet"
local record = require "public.record"
local interactive = require "base.interactive"

function Register(mRecord, mData)
    local oUpdateMgr = global.oUpdateMgr
    local iPid = mData.pid
    local mInfo = mData.info
    oUpdateMgr:Add(iPid, mInfo)
    oUpdateMgr:OnRegister(iPid)
end

function UnRegister(mRecord, mData)
    local oUpdateMgr = global.oUpdateMgr
    local iPid = mData.pid
    oUpdateMgr:Del(iPid)
    oUpdateMgr:OnUnRegister(iPid)
end

function CodeUpdate(mRecord, mData)
    local oUpdateMgr = global.oUpdateMgr
    oUpdateMgr:OnCodeUpdate()
end

function ResUpdate(mRecord, mData)
    local oUpdateMgr = global.oUpdateMgr
    oUpdateMgr:OnResUpdate()
end

function QueryResUpdate(mRecord, mData)
    local oUpdateMgr = global.oUpdateMgr
    local iPid = mData.pid
    local mClientData = mData.data
    local mVersion = mClientData.res_file_version or {}
    oUpdateMgr:OnQueryResUpdate(iPid, mVersion)
end

function QueryLogin(mRecord,mData)
    local oUpdateMgr = global.oUpdateMgr
    local mFileVersion = mData.res_file_version or {}
    local mResData = oUpdateMgr:QueryLogin(mFileVersion)
    interactive.Response(mRecord.source, mRecord.session, {
        res_file = mResData
    })
end

function CheckRes(mRecord,mData)
    local res = require "base.res"
    local mMap = res.map
    local mNpcArea = mMap.npc_area
    local mLeiTai = mMap.leitai
    local mMonster = mMap.monster
    local bWarning = false
    for i = 1,#mLeiTai do
        for j = 1,#mNpcArea do
            if mNpcArea[j][1] == mLeiTai[i][1] and mNpcArea[j][2] == mLeiTai[i][2] then
                break
            end
            if j == #mNpcArea then
                bWarning = true
                record.warning("擂台区域不在可行走区域中")
                return
            end
        end
    end
    for i = 1,#mMonster do
        for j = 1,#mNpcArea do
            if mNpcArea[j][1] == mLeiTai[i][1] and mNpcArea[j][2] == mLeiTai[i][2] then
                break
            end
            if j == #mNpcArea then
                bWarning = true
                record.warning("刷怪区域不在可行走区域中")
                return
            end
        end
    end
end
