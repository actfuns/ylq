
local interactive = require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"

local basematch = import(service_path("match.basematch"))

CMatch = {}
CMatch.__index = CMatch
inherit(CMatch, basematch.CMatch)


function NewMatch()
    return CMatch:New()
end


function CMatch:New()
    local o = super(CMatch).New(self)
    o.m_MatchLimit = 50 -- 一次最大匹配数
    o.m_ArenaStageList = {} -- 段位列表
    o.m_SingleDog = {} -- 单身玩家
    return o
end

function CMatch:Enter(uid,mData)
    mData.time = get_time()
    local iArenaGameStage = math.floor(mData.score/100)
    mData.stage = iArenaGameStage
    mData.range = 0
    if not self.m_ArenaStageList[iArenaGameStage] then
        self.m_ArenaStageList[iArenaGameStage] = {}
    end
    if not self.m_MatchList[uid] then
        table.insert(self.m_ArenaStageList[iArenaGameStage],uid)
    else 
        local mUnit = self.m_MatchList[uid]
        mData.stage = mUnit.stage
    end
    if mData.size == 1 then
        self.m_SingleDog[uid] = iArenaGameStage
    end
    super(CMatch).Enter(self,uid,mData)
    return {ok =true}
end

function CMatch:Leave(uid,mData)
    local leave = false
    if self.m_MatchList[uid] then
        leave = true
        local iStage = self.m_MatchList[uid].stage
        if self.m_ArenaStageList[iStage] then
            local idx = extend.Array.member(self.m_ArenaStageList[iStage],uid)
            if idx then
                table.remove(self.m_ArenaStageList[iStage],idx)
            end
        end
    end
    if self.m_SingleDog[uid] then
        self.m_SingleDog[uid] = nil
    end
    super(CMatch).Leave(self,uid,mData)
    return {leave = leave}
end


function CMatch:StartMatch(mData)
    self:OnMatch()
    local iTime = mData.time or 1000
    self.m_MatchLimit = mData.limit or 100
    if self.m_MatchTime then
        self.m_MatchTime = iTime
    else
        self.m_MatchTime = iTime
    end
    self:ToMatch(mData.data or {})
end

--先简单匹配
function CMatch:OnMatch(mData)
    local matchlist = table_key_list(self.m_MatchList)
    local iCont = table_count(matchlist)
    local warlist = {}
    local idx = 1
    local fPartner = function (exlist,iStage,iRange)
        local iMax = iStage +iRange
        local iMin = iStage - iRange
        for uid,t in pairs(self.m_SingleDog) do
            if t<= iMax and t>=iMin  and not table_in_list(exlist,uid)  then
                return uid
            end
        end
    end

    local iSingle = 0
    local iTeam = 0
    while idx < iCont do
        if #warlist > self.m_MatchLimit then
            break
        end
        local pid = matchlist[idx]
        local mUnit=self.m_MatchList[pid]
        idx = idx + 1
        if mUnit then
            local iStage = mUnit.stage
            local iSucc = false
            local iRange = mUnit.range
            local iMax = iStage +iRange -- 超时跨段分配

            for i = 0,iMax do 
                if iSucc then break end
                for j =1,2 do 
                    if iSucc then break end
                    local iP = iStage - i
                    if j%2 ==0 then
                        iP = iStage + i
                    end

                    local plist = table_deep_copy(self.m_ArenaStageList[iP] or {})
                    for k,iTarget in ipairs(plist) do
                        if iTarget ~= pid then
                            if not self.m_MatchList[iTarget] then
                                record.info(string.format("err match %d",iTarget))
                                if self.m_ArenaStageList[iP] then
                                    extend.Array.remove(self.m_ArenaStageList[iP],iTarget)
                                end
                            else
                                local plist1 = table_copy(mUnit["mem"])
                                local exlist = table_copy(plist1)
                                table.insert(exlist,iTarget)
                                if mUnit.size == 1 then
                                    local iPartner = fPartner(exlist,mUnit.stage,mUnit.range)
                                    if iPartner then
                                        iSingle = iSingle +1
                                        table.insert(exlist,iPartner)
                                        table.insert(plist1,iPartner)
                                    end
                                else
                                    iTeam = iTeam + 1
                                end

                                local mUnit2 = self.m_MatchList[iTarget]
                                local plist2 = table_copy(mUnit2["mem"])
                                exlist = extend.Array.append(exlist,plist2)
                                if mUnit2.size == 1 then
                                    local iPartner = fPartner(exlist,mUnit2.stage,mUnit2.range)
                                    if iPartner then
                                        iSingle = iSingle +1
                                        table.insert(exlist,iPartner)
                                        table.insert(plist2,iPartner)
                                    end
                                else
                                    iTeam = iTeam + 1
                                end

                                if #plist1 == 2 and #plist2 == 2 then
                                    table.insert(warlist,{plist1,plist2})
                                    for _,pid in ipairs(exlist) do
                                        self:Leave(pid)
                                    end
                                    iSucc = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local timeoutlist = {}
    local iNow = get_time()
    
    local iTimeOut = 30

    local iTimeoutCnt = 0
    for uid,mUnit in pairs(self.m_MatchList) do
        if mUnit.range < 3 and iNow - mUnit.time > iTimeOut then 
            mUnit.range = mUnit.range + 1
            iTimeoutCnt = iTimeoutCnt +1
        end
    end
    if #warlist~=0 then
        local mResult ={
        fight = warlist,
        info = {timeout = iTimeoutCnt,single=iSingle,team=iTeam},
        }
        interactive.Send(".world","arenagame","TeamPVPMatchResult",mResult)
    end
end


