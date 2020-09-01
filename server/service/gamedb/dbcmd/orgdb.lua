--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sOrgTableName = "org"

function CreateOrg(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Insert(sOrgTableName, mData.data)
end

function RemoveOrg(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Delete(sOrgTableName, {orgid = mData.orgid})
end

function GetAllOrgID(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:Find(sOrgTableName, {}, {orgid = true})
    local mRet = {}
    while m:hasNext() do
        table.insert(mRet, m:next())
    end
    return {
        data = mRet
    }
end

function LoadWholeOrg(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOrgTableName, {orgid = mData.orgid}, 
        {orgid = true, name = true, base_info = true, member_info = true, 
        build_info = true, log_info = true, apply_info = true, boon_info = true, achieve_info = true,huodong=true})
    return {
        data = m,
        orgid = mData.orgid
    }
end

function SaveOrg(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOrgTableName, {orgid = mData.orgid}, {["$set"] = mData.data})
end

function LoadOrg(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOrgTableName, {orgid = mData.orgid}, {name = true})
    return {
        data = m,
        orgid = mData.orgid
    }
end

function SaveOrgBase(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOrgTableName, {orgid = mData.orgid}, {["$set"]={base_info = mData.data}})
end

function LoadOrgBase(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOrgTableName, {orgid = mData.orgid}, {base_info = true})
    return {
        data = m.base_info or {},
        orgid = mData.orgid
    }
end

function SaveOrgMember(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOrgTableName, {orgid = mData.orgid}, {["$set"]={member_info = mData.data}})
end

function LoadOrgMember(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOrgTableName, {orgid = mData.orgid}, {member_info = true})
    return {
        data = m.member_info or {},
        orgid = mData.orgid
    }
end

function SaveOrgLog(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOrgTableName, {orgid = mData.orgid}, {["$set"]={log_info = mData.data}})
end

function LoadOrgLog(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOrgTableName, {orgid = mData.orgid}, {log_info = true})
    return {
        data = m.log_info or {},
        orgid = mData.orgid
    }
end

function SaveOrgApply(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOrgTableName, {orgid = mData.orgid}, {["$set"]={apply_info = mData.data}})
end

function LoadOrgApply(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOrgTableName, {orgid = mData.orgid}, {apply_info = true})
    return {
        data = m.apply_info or {},
        orgid = mData.orgid
    }
end

function SaveOrgHuodong(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOrgTableName, {orgid = mData.orgid}, {["$set"]={huodong = mData.data}})
end

function LoadOrgHuodong(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOrgTableName, {orgid = mData.orgid}, {huodong = true})
    return {
        data = m.huodong or {},
        orgid = mData.orgid
    }
end

function GetConflictNameOrg(mCond,mData)
    local oGameDb = global.oGameDb
    local m1 = oGameDb:Find(sOrgTableName, {}, {orgid = true, name = true, from_server = true})
    local mOrgs = {}
    local mRet = {}
    while (m1:hasNext()) do
        local mInfo
        if m1:hasNext() then
            mInfo = m1:next()
        end
        local sName = mInfo.name
        local mNameInfo = mOrgs[sName]
        if not mNameInfo then
            mOrgs[sName] = mInfo
        else
            if mNameInfo.from_server and mNameInfo.from_server ~= get_server_tag() then
                mOrgs[sName] = mInfo
                mRet[mNameInfo.orgid] = sName
            elseif mInfo.from_server and mInfo.from_server ~= get_server_tag() then
                mRet[mInfo.orgid] = sName
            end
        end
    end
    return mRet
end