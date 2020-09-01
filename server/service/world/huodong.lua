--import module
local global = require "global"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))

STATE_READY = 1
STATE_START = 2
START_END = 3

HUODONGLIST = {
    ["limitopen"] = "limitopen",
    ["trapmine"] = "trapmine",
    ["upcard"] = "upcard",
    ["worldboss"] = "worldboss", --ID 1001
    ["question"] = "question",
    ["arenagame"] = "arenagame", --ID 1002
    -- ["arenagame"] = "kuafu.kfarenagame",
    ["endless_pve"] = "endlesspve",
    ["pata"] = "pata",
    ["test"] = "test.testhuodong",
    ["lilian"] = "lilian",
    ["equipfuben"] = "equipfuben",
    ["treasure"] = "treasure",
    ["globaltemple"] = "globaltemple",
    ["game"] = "game",
    ["pefuben"] = "pefuben",
    ["minglei"] = "minglei",
    ["orgfuben"] = "orgfuben",
    ["loginreward"] = "loginreward",
    --["equalarena"] = "kuafu.kfequalarena",
    ["equalarena"] = "equalarena",
    ["npcfight"] = "npcfight",
    ["dailytask"] = "dailytask",
    ["terrawars"] = "terrawars",
    ["charge"] = "charge",
    ["travel"] = "travel",
    ["yjfuben"] = "yjfuben",
    ["fieldboss"] = "fieldboss",
    ["sociality"] = "sociality",
    ["dailysign"] = "dailysign",
    ["onlinegift"] = "onlinegift",
    ["rewardback"] = "rewardback",
    ["chapterfb"] = "chapterfb",
    ["convoy"] = "convoy",
    ["teampvp"] = "teampvp",
    ["msattack"] = "msattack",
    ["shimen"] = "shimen",
    ["rushrank"] = "rushrank",
    ["energy"] = "energy",
    ["redeemcode"] = "redeemcode",
    ["dailytrain"] = "dailytrain",
    ["clubarena"] = "clubarena",
    ["orgwar"] = "orgwar",
    ["hunt"] = "hunt",
    ["herobox"] = "herobox",
    ["marry"] = "marry",
    ["virtualchat"] = "virtualchat",
    ["warrecommend"] = "warrecommend",
    ["gradegift"] = "gradegift",
    ["chargescore"] = "chargescore",
    ["oneRMBgift"] = "oneRMBgift",
    ["welfare"] = "welfare",
    ["addcharge"] = "addcharge",
    ["daycharge"] = "daycharge",
    ["timelimitresume"] = "timelimitresume",
    ["rankback"] = "rankback",
    ["resume_restore"] = "resume_restore",
}

function NewHuodongMgr(...)
    return CHuodongMgr:New(...)
end

CHuodongMgr = {}
CHuodongMgr.__index = CHuodongMgr
inherit(CHuodongMgr,logic_base_cls())

function CHuodongMgr:New()
    local o = super(CHuodongMgr).New(self)
    o.m_mHuodongList = {}
    o.m_mHuodongState = {}
    o.m_mRedPointHandle = {}
    for sHuodongName, sDir in pairs(self:GetHuodongList()) do
        local sPath = self:Path(sDir)
        local oModule = import(service_path(sPath))
        assert(oModule,string.format("Create Huodong err:%s %s",sHuodongName,sPath))
        local oHuodong = oModule.NewHuodong(sHuodongName)
        o.m_mHuodongList[sHuodongName] = oHuodong
    end
    o.m_bAllHuodongLoaded = false
    o.m_lWaitLoadingFunc = {}
    return o
end

function CHuodongMgr:Path(sDir)
    return string.format("huodong.%s",sDir)
end

function CHuodongMgr:GetHuodongList()
    return HUODONGLIST
end

function CHuodongMgr:InitData()
    local mHuodong = {}
    for sName,oHuodong in pairs(self.m_mHuodongList) do
        oHuodong:Init()
        if oHuodong:NeedSave() then
            mHuodong[sName] = true
            oHuodong:LoadDb()
            oHuodong:WaitLoaded(function (o)
                mHuodong[sName] = nil
                if not next(mHuodong) then
                    self.m_bAllHuodongLoaded = true
                    self:WakeUpFunc()
                end
            end)
        end
    end
end

function CHuodongMgr:WakeUpFunc()
    local lFuncs = self.m_lWaitLoadingFunc
    self.m_lWaitLoadingFunc = {}
    for _, func in ipairs(lFuncs) do
        safe_call(func)
    end
end

function CHuodongMgr:Execute(func)
    if self.m_bAllHuodongLoaded then
        func()
    else
        table.insert(self.m_lWaitLoadingFunc,func)
    end
end

function CHuodongMgr:OnServerStartEnd()
end

function CHuodongMgr:OnLogin(oPlayer,bReEnter)
    for _, oHuodong in pairs(self.m_mHuodongList) do
        if oHuodong.OnLogin then
            safe_call(oHuodong.OnLogin, oHuodong,oPlayer,bReEnter)
        end
    end
end

function CHuodongMgr:OnLogout(oPlayer)
    for _, oHuodong in pairs(self.m_mHuodongList) do
        if oHuodong.OnLogout then
            safe_call(oHuodong.OnLogout, oHuodong,oPlayer)
        end
    end
end

function CHuodongMgr:OnDisconnected(oPlayer)
    for _, oHuodong in pairs(self.m_mHuodongList) do
        if oHuodong.OnDisconnected then
            safe_call(oHuodong.OnDisconnected, oHuodong,oPlayer)
        end
    end
end

function CHuodongMgr:GetHuodong(sHuodongName)
    return self.m_mHuodongList[sHuodongName]
end

function CHuodongMgr:NewHour(iWeekDay,iHour)
    interactive.Send(".assisthd", "common", "NewHour", {
        weekday = iWeekDay,
        hour = iHour,
    })

    self:CleanHuodongState(iHour)
    for _, oHuodong in pairs(self.m_mHuodongList) do
        safe_call(oHuodong.NewHour, oHuodong, iWeekDay, iHour)
    end
    if iHour == 0 then
        self:NewDay(iWeekDay)
    end
end

function CHuodongMgr:NewDay(iWeekDay)
    iWeekDay = iWeekDay or get_weekday()
    for _, oHuodong in pairs(self.m_mHuodongList) do
        safe_call(oHuodong.NewDay, oHuodong,iWeekDay)
    end
end

function CHuodongMgr:CleanHuodongState(iHour)
    if iHour == 0 then
        self.m_mHuodongState = {}
    end
end

function CHuodongMgr:SetHuodongState(sHuodongName, iScheduleID, iState)
    self.m_mHuodongState[sHuodongName] = {["scheduleid"]=iScheduleID, ["state"]=iState}
    local mOnlinePlayer = global.oWorldMgr:GetOnlinePlayerList()
    for iPid,oPlayer in pairs(mOnlinePlayer) do
        oPlayer.m_oScheduleCtrl:SetScheduleStatus(oPlayer,iScheduleID,iState)
    end
end

function CHuodongMgr:HuodongState()
    return self.m_mHuodongState
end

function CHuodongMgr:GetHuodongState(sName)
    return self.m_mHuodongState[sName]
end

function CHuodongMgr:RegistRedPointHandle(sHDName, func)
    self.m_mRedPointHandle[sHDName] = func
end

function CHuodongMgr:CheckRedPoint(oPlayer)
    for sHDName, info in pairs(self:HuodongState()) do
        if info["scheduleid"] ~= 0 and info["state"] == STATE_START and not oPlayer.m_oScheduleCtrl:IsDone(info["scheduleid"]) then
            return 1
        end
    end
    for sHDNames, func in pairs(self.m_mRedPointHandle) do
        if func(oPlayer) == 1 then
            return 1
        end
    end
    return 0
end

function CHuodongMgr:OnUpGrade(oPlayer, iGrade)
    for _, oHuodong in pairs(self.m_mHuodongList) do
        safe_call(oHuodong.OnUpGrade, oHuodong, oPlayer, iGrade)
    end
end

function CHuodongMgr:CloseGS()
    interactive.Send(".assisthd", "common", "CloseGS", {})
end
