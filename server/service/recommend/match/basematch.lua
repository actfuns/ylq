local skynet = require "skynet"

CMatch = {}
CMatch.__index = CMatch
inherit(CMatch, logic_base_cls())


function NewMatch()
    local o = CMatch:New()
    return o
end

function CMatch:New()
    local o = super(CMatch).New(self)
    o.m_MatchList = {}
    return o
end

function CMatch:Clear(mData)
    self.m_MatchList = {}
    self.m_MatchFunc = {}
end


function CMatch:Enter(uid,mData)
    self.m_MatchList[uid] = mData
end

function CMatch:Leave(uid,mData)
    if self.m_MatchList[uid] then
        self.m_MatchList[uid] = nil
    end
end





function CMatch:StartMatch(mData)
end

function CMatch:ToMatch(mData)
    if self.m_MatchTime then
        self:DelTimeCb("tomatchgame")
        self:AddTimeCb("tomatchgame",self.m_MatchTime,function ()
            self:ToMatch(mData)
            end)
    end
    self:OnMatch(mData)
end

function CMatch:OnMatch(mData)
end



function CMatch:StopMatch(mData)
    self:DelTimeCb("tomatchgame")
end

function CMatch:InMatch(pid,mData)
    local iIn = 0
    if self.m_MatchList[pid] then
        iIn = 1
    end
    return {inmatch = iIn}

end




