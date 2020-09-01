--import module
--与客户端回调管理
local global = require "global"
local extend = require "base.extend"
local cbobj = import(lualib_path("public.cbobj"))

function NewCBMgr()
    local oMgr = CCBMgr:New()
    return oMgr
end

CCBMgr = {}
CCBMgr.__index = CCBMgr
inherit(CCBMgr,cbobj.CCBMgr)

function CCBMgr:New()
    local o = super(CCBMgr).New(self)
    return o
end

function CCBMgr:GetSendObj(key)
    local iWarId,iPid = table.unpack(key)
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if not oWar then
        return
    end
    local oPlayer = oWar:GetPlayerWarrior(iPid)
    return oPlayer
end

function CCBMgr:GS2CConfirmUI(key,mNet)
    local oPlayer = self:GetSendObj(key)
    if oPlayer then
        oPlayer:Send("GS2CConfirmUI",mNet)
    end
end