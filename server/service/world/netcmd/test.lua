--import module

local global = require "global"
local skynet = require "skynet"

function C2GSTestBigPacket(oPlayer, mData)
    local s = mData.s
    local iCnt = #s
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oPlayer.m_iPid, string.format("该包s字段长度为%d", iCnt))
end

function C2GSTestOnlineAdd(oPlayer, mData)
    oPlayer:Send("GS2CTestOnlineAdd",{
        a = 1,
    })
end

function C2GSCheckProxy(oPlayer, mData)
    local iRecord = mData.record
    if mData.type == 1 then
        for i = 1, iRecord do
            oPlayer:Send("GS2CCheckProxy", {
                record = i
            })
        end
    else
        local l = {}
        for i = 1, iRecord do
            table.insert(l, {record = i})
        end
        oPlayer:Send("GS2CCheckProxyMerge", {
            record_list = l
        })
    end
end
