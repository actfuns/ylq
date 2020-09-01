local  global = require "global"

function C2GSGetImages(oPlayer,mData)
    local oImageMgr = global.oImageMgr
    oImageMgr:Forward("C2GSGetImages",oPlayer:GetPid(),mData)
end

function C2GSAddImage(oPlayer,mData)
    local oImageMgr = global.oImageMgr
    oImageMgr:Forward("C2GSAddImage",oPlayer:GetPid(),mData)
end