local global = require "global"
local extend = require "base.extend"
local gamedefines = import(lualib_path("public.gamedefines"))
local loadgame = import(service_path("minigame/loadminigame"))

function NewMiniGameMgr()
    return CMiniGameMgr:New()
end

CMiniGameMgr = {}
CMiniGameMgr.__index = CMiniGameMgr
inherit(CMiniGameMgr, logic_base_cls())

function CMiniGameMgr:New()
    local o = super(CMiniGameMgr).New(self)
    o.m_GameList = {}
    o.m_MiniGameName = {}
    return o
end

function CMiniGameMgr:Release()
    local mGame = self.m_GameList
    for _,oGame in pairs(mGame) do
        baseobj_safe_release(oGame)
    end
    self.m_GameList = {}
    self.m_MiniGameName = {}
    super(CMiniGameMgr).Release(self)
end

function CMiniGameMgr:ForMatKey(oPlayer,sMiniGame)
    local iPid
    if type(oPlayer) == "number" then
        iPid = oPlayer
    else
        iPid = oPlayer:GetPid()
    end
    return string.format("%d_%s",iPid,sMiniGame)
end

function CMiniGameMgr:HasMiniGame(sKey)
    return self.m_GameList[sKey]
end

function CMiniGameMgr:GameStart(oPlayer,sMiniGame,mArgs)
    local sKey = self:ForMatKey(oPlayer,sMiniGame)
    if self:HasMiniGame(sKey) then return end
    local oGame = loadgame.Create(sMiniGame,mArgs)
    oGame:GameStart(oPlayer,mArgs)
    self.m_GameList[sKey] = oGame
    self.m_MiniGameName[sMiniGame] = true
    local iPid = oPlayer:GetPid()
    local sTimeFlag = string.format("%s_End_%d",sMiniGame,iPid)
    local iTime = mArgs.overtime or 30
    self:DelTimeCb(sTimeFlag)
    self:AddTimeCb(sTimeFlag, iTime*1000, function ()
        self:GameEnd(iPid,sMiniGame)
    end)
end

function CMiniGameMgr:GameEnd(iPid,sMiniGame)
    local sTimeFlag = string.format("%s_End_%d",sMiniGame,iPid)
    self:DelTimeCb(sTimeFlag)
    local sKey = self:ForMatKey(iPid,sMiniGame)
    local oGame = self:HasMiniGame(sKey)
    if not oGame then return end
    oGame:GameEnd(iPid)
    baseobj_safe_release(oGame)
    self.m_GameList[sKey] = nil
end

function CMiniGameMgr:CreateCmdTable(mCmd)
    local mCopyCmd = {}
    for _,info in pairs(mCmd) do
        mCopyCmd[info.key] = info.value
    end
    return mCopyCmd
end

function CMiniGameMgr:GameOp(oPlayer,sMiniGame,mCmd)
    local sKey = self:ForMatKey(oPlayer,sMiniGame)
    local oGame = self:HasMiniGame(sKey)
    if not oGame then return end
    mCmd = self:CreateCmdTable(mCmd)
    if mCmd.endgame then
        self:GameEnd(oPlayer:GetPid(),sMiniGame)
        return
    end
    oGame:GameOp(oPlayer,mCmd)
    if oGame:IsEnd() then
        self:GameEnd(oPlayer:GetPid(),sMiniGame)
    end

end

function CMiniGameMgr:GetMiniGame(oPlayer,sMiniGame)
    local mList = sMiniGame and {[sMiniGame]=true} or self.m_MiniGameName
    for sName,_ in pairs(mList) do
        local sKey = self:ForMatKey(oPlayer,sName)
        local oGame = self:HasMiniGame(sKey)
        if oGame then
            return oGame
        end
    end
end