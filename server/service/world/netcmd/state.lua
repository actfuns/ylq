--import module

local global = require "global"
local skynet = require "skynet"


function C2GSClickState(oPlayer, mData)
    local iState = mData["state_id"]
    local oState = oPlayer.m_oStateCtrl:GetState(iState)
    if not oState then
        return
    end
    oState:Click(oPlayer,mData)
end