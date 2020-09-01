-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"

local caiquanobj = import(service_path("huodong/gameobj/caiquanobj"))

local mCreateGameFunc= {
    ["caiquan"] = caiquanobj.NewGame,
}

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "小游戏"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_iDispatchId = 0
    self.m_mGameList = {}
end

function CHuodong:DispatchId()
    self.m_iDispatchId = self.m_iDispatchId + 1
    return self.m_iDispatchId
end

function CHuodong:NewGame(sGameName,mArgs)
    if not mCreateGameFunc[sGameName] then
        return
    end
    local iID = self:DispatchId()
    mArgs = mArgs or {}
    mArgs.game_id = iID
    local oGame = mCreateGameFunc[sGameName](mArgs)
    self.m_mGameList[iID] = oGame
    return oGame
end

function CHuodong:GetGame(iGameID)
    return self.m_mGameList[iGameID]
end

function CHuodong:OnGameEnd(iGameID)
    local oGame = self.m_mGameList[iGameID]
    self.m_mGameList[iGameID] = nil
    baseobj_delay_release(oGame)
end