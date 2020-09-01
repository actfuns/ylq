
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
    o.m_MatchLimit = 100 -- 一次最大匹配数
    o.m_ArenaStageList = {} -- 段位列表
    return o
end

function CMatch:Enter(uid,mData)
    mData.time = get_time()
    local iArenaGameStage = mData.stage
    if not self.m_ArenaStageList[iArenaGameStage] then
        self.m_ArenaStageList[iArenaGameStage] = {}
    end
    if not self.m_MatchList[uid] then
        table.insert(self.m_ArenaStageList[iArenaGameStage],uid)
    else
        local mUnit = self.m_MatchList[uid]
        mData.stage = mUnit.stage
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

    while idx < iCont do
        if #warlist >= self.m_MatchLimit then
            break
        end
        local pid = matchlist[idx]
        local mUnit=self.m_MatchList[pid]
        idx = idx + 1
        if mUnit then
            local iStage = mUnit.stage
            local iSucc = false
            local iMax =  (not mUnit.timeout and 0 ) or 8 -- 超时跨段分配
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
                                table.insert(warlist,{pid,iTarget})
                                self:Leave(pid)
                                self:Leave(iTarget)
                                iSucc = true
                                break
                            end
                        end
                    end

                end
            end

        end
    end

    local timeoutlist = {}
    local iNow = get_time()

    local res = require "base.res"
    local iTimeOut = res["daobiao"]["playconfig"]["arenagame"]["match_timeout"]

    local iTimeoutCnt = 0
    for uid,mUnit in pairs(self.m_MatchList) do
        if iNow - mUnit.time > iTimeOut then
            mUnit.timeout = 1
            iTimeoutCnt = iTimeoutCnt +1
        end
    end

    if #warlist~=0 then
        local mResult ={
        fight = warlist,
        info = {timeout = iTimeoutCnt,},
        }
        local addr = ".world"
        if get_server_tag() == "ks" then
            addr = ".world2"
        end
        interactive.Send(addr,"arenagame","ArenaGameResult",mResult)
    end
end


