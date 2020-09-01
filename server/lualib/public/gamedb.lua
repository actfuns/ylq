-- import file
local interactive = require "base.interactive"

local bInitName = bInitName or false
local iTurnID = iTurnID or 0
local mServiceName = mServiceName or {}
local mBlock2Service = mBlock2Service or {}

function CheckInitServiceName()
    if bInitName then return end
    bInitName = true
    mBlock2Service = {}
    mServiceName = {}
    for iNo=1,GAMEDB_SERVICE_COUNT do
        table.insert(mServiceName,".gamedb"..iNo)
    end
end

function GetServiceName(sBlock)
    local iBlock = tonumber(sBlock)
    if iBlock then
        return mServiceName[iBlock % GAMEDB_SERVICE_COUNT + 1]
    end
    if mBlock2Service[sBlock] then
        return mBlock2Service[sBlock]
    end
    iTurnID = iTurnID + 1
    mBlock2Service[sBlock] = mServiceName[iTurnID % GAMEDB_SERVICE_COUNT + 1]
    return mBlock2Service[sBlock]
end

function SaveDb(sBlock,sModule,sCmd,mData)
    CheckInitServiceName()
    interactive.Send(GetServiceName(sBlock),sModule,sCmd,mData)
end

function LoadDb(sBlock,sModule,sCmd,mData,func)
    CheckInitServiceName()
    interactive.Request(GetServiceName(sBlock),sModule,sCmd, mData,func)
end