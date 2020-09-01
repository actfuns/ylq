local res = require "data"

local scene = {}

local iYJMap = 204000

function ShowPartner(self)
    local mData = res["partner"]["partner_info"]
    local lPartner = {}
    for iPartner,_ in pairs(mData) do
        table.insert(lPartner,iPartner)
    end
    local iPartner = lPartner[math.random(#lPartner)]
    local sCmd = string.format("addpartner %d 1",iPartner)
    self:run_cmd("C2GSGMCmd",{cmd=sCmd})
end

local CSceneAgent = {}
CSceneAgent.__index = CSceneAgent

function CSceneAgent:New(oClient, iMap, iScene, iSceneVer, iX, iY, iEid)
    local o = setmetatable({}, self)
    o.m_oClient = oClient
    o.m_iMapId = iMap
    o.m_iScene = iScene
    o.m_iSceneVer = iSceneVer
    o.m_iX = iX
    o.m_iY = iY
    o.m_iEid = iEid

    o.m_lPlanWalk = {}
    o.m_iPlanVer = 0
    o.m_iStartWalk = 0
    o.m_iFinishWalk = 0
    return o
end

function CSceneAgent:fork(...)
    return self.m_oClient:fork(...)
end

function CSceneAgent:sleep(...)
    return self.m_oClient:sleep(...)
end

function CSceneAgent:run_cmd(...)
    return self.m_oClient:run_cmd(...)
end

function CSceneAgent:Start()
    self:fork(function ()
        self:DecideCmd()
    end)
end

function CSceneAgent:IsContinue()
    local oRobot = self.m_oClient
    return oRobot.m_iSceneVer == self.m_iSceneVer
end

function CSceneAgent:ChooseMapId()
    local mFYList = {[501000] = true,[601000]=true,[204000]=true,[300000]=true,[300100]=true,[200100]=true}
    local lMapList = {}
    for _, mInfo in pairs(res["scene"]) do
        if mInfo.map_id ~= self.m_iMapId and not mFYList[mInfo.map_id] then
            table.insert(lMapList, mInfo.map_id)
        end
    end
    return lMapList[math.random(#lMapList)]
end

function CSceneAgent:DecideCmd()
    while 1 do
        self:sleep(4)
        if not self:IsContinue() then
            break
        end
        local bNew = false
        if #self.m_lPlanWalk > 0 then
            local iRan = math.random(100)
            if iRan <= 30 then
                bNew = true
            else
                bNew = false
            end
        else
            bNew = true
        end

        if bNew then
            self:PlanNewWalk()
        end
    end
end

function CSceneAgent:NewPos(x, y, r, a)
    return math.floor(x+r*math.cos(a)),math.floor(y+r*math.sin(a))
end

function CSceneAgent:GenNewWalk(n)
    local lRet = {}
    local iNX, iNY = self.m_iX, self.m_iY
    for i = 1, n do
        local iAngle = math.random(360)
        local iCount = 0
        while iCount < 10 do
            local iGX, iGY = self:NewPos(iNX, iNY, 1000, iAngle)
            if (iGX>=1000 and iGX <=100000) and (iGY>=1000 and iGY<=100000) then
                table.insert(lRet, {time = 1000, x = iGX, y = iGY})
                iNX, iNY = iGX, iGY
                break
            end
            iCount = iCount + 1
        end
    end
    return lRet
end

function CSceneAgent:PlanNewWalk()
    self.m_lPlanWalk = self:GenNewWalk(math.random(2, 20))
    self.m_iPlanVer = self.m_iPlanVer + 1
    local iLen = #self.m_lPlanWalk
    if iLen > 0 then
        self.m_iStartWalk = 0
        self.m_iFinishWalk = math.min(self.m_iStartWalk + 3, iLen)
        self:PreNotifyServer()
        self:fork(function ()
            self:Walk(self.m_iPlanVer)
        end)
    end
end

function CSceneAgent:PreNotifyServer()
    local iStart = self.m_iStartWalk + 1
    if iStart > self.m_iFinishWalk then
        return
    end

    local iX, iY = self.m_iX, self.m_iY
    local lNetPos = {}
    table.insert(lNetPos, {
        time = self.m_lPlanWalk[iStart].time,
        pos = {x = iX, y = iY}
    })
    for i = iStart, self.m_iFinishWalk do
        local m1 = self.m_lPlanWalk[i]
        local m2
        if i < self.m_iFinishWalk then
            m2 = self.m_lPlanWalk[i+1]
        end
        if m2 then
            table.insert(lNetPos, {
                time = m2.time,
                pos = {x = m1.x, y = m1.y}
            })
        else
            table.insert(lNetPos, {
                time = 0,
                pos = {x = m1.x, y = m1.y}
            })
        end
    end

    self:run_cmd("C2GSSyncPosQueue", {
        scene_id = self.m_iScene,
        eid = self.m_iEid,
        poslist = lNetPos,
    })
end

function CSceneAgent:Walk(iVer)
    while 1 do
        self:sleep(1)
        if not self:IsContinue() then
            break
        end
        if iVer ~= self.m_iPlanVer then
            break
        end

        local iX, iY = self.m_iX, self.m_iY
        local iLen = #self.m_lPlanWalk
        self.m_iStartWalk = self.m_iStartWalk + 1

        if self.m_iStartWalk > iLen then
            self.m_lPlanWalk = {}
            break
        end

        local m = self.m_lPlanWalk[self.m_iStartWalk]
        self.m_iX = m.x
        self.m_iY = m.y

        if self.m_iStartWalk >= self.m_iFinishWalk then
            self.m_iFinishWalk = math.min(self.m_iFinishWalk + 3, iLen)
            self:PreNotifyServer()

            if self.m_iStartWalk >= iLen then
                self.m_lPlanWalk = {}
                break
            end
        end
    end
end

scene.GS2CAddPartnerList = function (self,args)
    local lPartner = args["partner_list"]
    for _,mData in pairs(lPartner) do
        local iParId = mData["parid"]
        self:run_cmd("C2GSSetFollowPartner",{
            partnerid = iParId,
        })
        break
    end
end

scene.GS2CShowScene = function(self, args)
    self.m_iScene = args.scene_id
    self.m_iMapId = args.map_id
    self.m_iSceneVer = (self.m_iSceneVer or 0) + 1
end

scene.GS2CEnterScene = function(self, args)
    if self.m_iMapId ~= iYJMap then
        self:sleep(3+math.random(10))
        self:run_cmd("C2GSInitRoleName",{name=self.account})
        ShowPartner(self)
        self:run_cmd("C2GSClickWorldMap", {scene_id=self.m_iScene, map_id=iYJMap})
        return
    end
    local iScene = args.scene_id
    local iEid = args.eid
    local mPosInfo = args.pos_info
    local iX = mPosInfo.x
    local iY = mPosInfo.y
    local iZ = mPosInfo.z
    local iV = mPosInfo.v

    local oAgent = CSceneAgent:New(self, self.m_iMapId, self.m_iScene, self.m_iSceneVer, iX, iY, iEid)
    oAgent:Start()
    self.m_oSceneAgent = oAgent
end

return scene