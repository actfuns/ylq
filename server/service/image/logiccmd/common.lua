local global = require "global"

function OnLogin(mRecord, mData)
    local oImageMgr = global.oImageMgr
    local iPid = mData.pid
    oImageMgr:OnLogin(iPid, mData)
end

function OnLogout(mRecord, mData)
    local oImageMgr = global.oImageMgr
    local iPid = mData.pid
    oImageMgr:OnLogout(iPid)
end

function Disconnected(mRecord, mData)
    local oImageMgr = global.oImageMgr
    local iPid = mData.pid
    oImageMgr:Disconnected(iPid)
end

function CloseGS(mRecord, mData)
    global.oImageMgr:CloseGS()
end

ForwardNetcmds = {}

function Forward(mRecord, mData)
    local iPid = mData.pid
    local sCmd = mData.cmd
    local oImageMgr = global.oImageMgr
    local oPlayer = oImageMgr:GetPlayer(iPid)
    if oPlayer then
        local func = ForwardNetcmds[sCmd]
        assert(func, string.format("Forward function:%s not exist!", sCmd))
        func(oPlayer, mData.data)
    end
end

function ForwardNetcmds.C2GSGetImages(oPlayer,mData)
    oPlayer:OpenImages()
 end

function ForwardNetcmds.C2GSAddImage(oPlayer,mData)
    oPlayer:AddImage(mData.key)
end

function TestCmd(mRecord, mData)
    local oImageMgr = global.oImageMgr
    local iPid = mData.pid
    local sCmd = mData.cmd
    oImageMgr:TestCmd(sCmd, iPid, mData.data)
end