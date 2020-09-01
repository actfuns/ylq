--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function Register(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    local m = global.mServiceNote
    local sType = mData.type
    local sAddr = mData.addr

    if not m[sType] then
        m[sType] = {}
    end
    table.insert(m[sType], sAddr)
    oDictatorObj:SetEndlessCheck(sAddr, true)
end

function AllServiceBooted(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:AllServiceBooted(mData.type)
end

function UpdateRes(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:ReloadRes()
end

function ClientCode(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:ClientCode()
end

function ClientRes(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:ClientRes()
end

function MemCheckGlobal(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:MemCheckGlobal()
end

function MemCurrent(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:MemCurrent()
end

function MemShowTrack(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:MemShowTrack()
end

function MemSnapshot(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:MemSnapshot()
end

function MemDiff(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:MemDiff()
end

function CtrlMonitor(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:CtrlMonitor(mData.is_open)
end

function CtrlMeasure(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:CtrlMeasure(mData.is_open)
end

function DumpMeasure(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:DumpMeasure()
end

function StartMemMonitor(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:StartMemMonitor()
end

function StopMemMonitor(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:StopMemMonitor()
end

function DumpMemMonitor(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:DumpMemMonitor()
end

function ClearMemMonitor(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:ClearMemMonitor()
end

function UpdateCode(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    local bSucc, sErr = oDictatorObj:UpdateCode(mData.str_module_list, mData.is_update_proto)
    if bSucc then
        sErr = "update all ok"
    end
    interactive.Send(".world", "notify", "Notify", {pid = mData.pid, msg = sErr})
end

function UpdateFix(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    local bSucc, sErr = oDictatorObj:UpdateFix(mData.func)
    if bSucc then
        sErr = "update all ok"
    end
    interactive.Send(".world", "notify", "Notify", {pid = mData.pid, msg = sErr})
end

function CloseGS(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:CloseGS()
end

function SetEndlessCheck(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:SetEndlessCheck(mData.addr, mData.is_open)
end

function ResponseCheckEndless(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:UpdateCheckEndless(mData.addr)
end

function CheckGC(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:CheckGC()
end

--hcdebug
function AddDebugMessage(mRecord,mData)
    local oDictatorObj = global.oDictatorObj
    local sModule = mData.module
    local sCmd = mData.cmd
    local sKey = string.format("%s.%s",sModule,sCmd)
    oDictatorObj:AddDebugMessage(sKey)
end

function DeleteDebugMessage(mRecord,mData)
    local oDictatorObj = global.oDictatorObj
    local sModule = mData.module
    local sCmd = mData.cmd
    local sKey = string.format("%s.%s",sModule,sCmd)
    oDictatorObj:DeleteDebugMessage(sKey)
end

function TestMerge(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    oDictatorObj:TestMerge(mData.total, mData.index, mData.count, mData.data)
end

function TestShareObj(mRecord, mData)
    local oDictatorObj = global.oDictatorObj
    local obj = oDictatorObj:TestShareObj()
    interactive.Response(mRecord.source, mRecord.session, {shareobj = obj})
end
