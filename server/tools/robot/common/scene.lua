local res = require "data"

local scene = {}

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
    o.m_lServerScope = res["map"][o.m_iMapId].server_scope

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
    self:fork(function ()
        self:DecideChangeScene()
    end)
end

function CSceneAgent:IsContinue()
    local oRobot = self.m_oClient
    return oRobot.m_iSceneVer == self.m_iSceneVer
end

function CSceneAgent:DecideChangeScene()
    while 1 do
        self:sleep(10)
        if not self:IsContinue() then
            break
        end
        --if math.random(5) == 1 then
        --    local iMap = self:ChooseMapId()
        --    self:run_cmd("C2GSClickWorldMap", {scene_id=self.m_iScene, map_id=iMap})
        --    break
        --end
    end
end

function CSceneAgent:ChooseMapId()
    local mFYList = {[501000] = true,[601000]=true,[204000]=true,[300000]=true,[300100]=true,[200100]=true,[208000] = true,[666666] = true}
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

        local iMinX, iMaxX = 1000, self.m_lServerScope[1]*1000
        local iMinY, iMaxY = 1000, self.m_lServerScope[2]*1000
        if self.m_iX < iMinX or self.m_iX > iMaxX or self.m_iY < iMinY or self.m_iY > iMaxY then
            local iRanX, iRanY = math.random(iMinX, iMaxX), math.random(iMinY, iMaxY)
            self.m_iX, self.m_iY = iRanX, iRanY
            self.m_lPlanWalk = {}
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

function CSceneAgent:GenNewWalk()
    local iMinX, iMaxX = 1000, self.m_lServerScope[1]*1000
    local iMinY, iMaxY = 1000, self.m_lServerScope[2]*1000

    local iRanX, iRanY = math.random(iMinX, iMaxX), math.random(iMinY, iMaxY)

    local iLen = math.sqrt((iRanX - self.m_iX)*(iRanX - self.m_iX)+(iRanY - self.m_iY)*(iRanY - self.m_iY))
    if iLen > 0 then
        local dx = (iRanX - self.m_iX)/iLen
        local dy = (iRanY - self.m_iY)/iLen
        local lRet = {}
        table.insert(lRet, {time = 1000, pos = {x = self.m_iX, y = self.m_iY}})

        local iDiff = 3000
        local iNow = iDiff
        local nx, ny = self.m_iX, self.m_iY
        while iNow < iLen do
            nx = nx + dx*iDiff
            ny = ny + dy*iDiff
            table.insert(lRet, {time = 1000, pos = {x = nx, y = ny}})
            iNow = iNow + iDiff
        end
        table.insert(lRet, {time = 1000, pos = {x = iRanX, y = iRanY}})
        return lRet
    end

    return {}
end

function CSceneAgent:PlanNewWalk()
    self.m_lPlanWalk = self:GenNewWalk()
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
                pos = {x = m1.pos.x, y = m1.pos.y}
            })
        else
            table.insert(lNetPos, {
                time = 0,
                pos = {x = m1.pos.x, y = m1.pos.y}
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
        self.m_iX = m.pos.x
        self.m_iY = m.pos.y

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


scene.GS2CShowScene = function(self, args)
    self.m_iMapId = args.map_id
    self.m_iSceneVer = (self.m_iSceneVer or 0) + 1
end

scene.GS2CEnterScene = function(self, args)
    local iScene = args.scene_id
    local iEid = args.eid
    local mPosInfo = args.pos_info
    local iX = mPosInfo.x
    local iY = mPosInfo.y
    local iZ = mPosInfo.z
    local iV = mPosInfo.v

    self.m_iScene = iScene

--    if not self.m_bInit then
--        self.m_bInit = true
--        self:run_cmd("C2GSGMCmd",{
--            cmd = "choosemap",
--        })
--        return
--    end

    local oAgent = CSceneAgent:New(self, self.m_iMapId, self.m_iScene, self.m_iSceneVer, iX, iY, iEid)
    oAgent:Start()
    self.m_oSceneAgent = oAgent
end

return scene


--临时恢复最初始版本测试
--local res = require "data"
--
--local scene = {}
--
--local function ChooseMapId(self)
--    local mFYList = {[501000] = true,[601000]=true,[204000]=true,[300000]=true,[300100]=true,[200100]=true,[208000] = true,[666666] = true}
--    local lMapList = {}
--    for _, mInfo in pairs(res["scene"]) do
--        if mInfo.map_id ~= self.m_iMapId and not mFYList[mInfo.map_id] then
--            table.insert(lMapList, mInfo.map_id)
--        end
--    end
--    return lMapList[math.random(#lMapList)]
--end
--
--scene.GS2CShowScene = function(self, args)
--    self.m_iMapId = args.map_id
--    self.m_iSceneVer = (self.m_iSceneVer or 0) + 1
--end
--
--scene.GS2CEnterScene = function(self, args)
--    local iScene = args.scene_id
--    local iEid = args.eid
--    local mPosInfo = args.pos_info
--    local iX = mPosInfo.x
--    local iY = mPosInfo.y
--    local iZ = mPosInfo.z
--    local iV = mPosInfo.v
--
--    self.m_iScene = iScene
--    self.m_iEid = iEid
--    self.m_iX = iX
--    self.m_iY = iY
--    self.m_lQueue = {}
--
--    local iNowVer = self.m_iSceneVer
--    self:fork(function ()
--        while 1 do
--            self:sleep(3)
--
--            if iNowVer ~= self.m_iSceneVer then
--                break
--            end
--
--            local lServerScope = res["map"][self.m_iMapId].server_scope
--
--            local iMinX, iMaxX = 1000, lServerScope[1]*1000
--            local iMinY, iMaxY = 1000, lServerScope[2]*1000
--
--            local iRanX, iRanY = math.random(iMinX, iMaxX), math.random(iMinY, iMaxY)
--
--            if (self.m_iX >= iMinX and self.m_iX <= iMaxX) and (self.m_iY >= iMinY and self.m_iY <= iMaxY) then
--                if not next(self.m_lQueue) then
--                    local iLen = math.sqrt((iRanX - self.m_iX)*(iRanX - self.m_iX)+(iRanY - self.m_iY)*(iRanY - self.m_iY))
--                    local dx = (iRanX - self.m_iX)/iLen
--                    local dy = (iRanY - self.m_iY)/iLen
--                    if iLen > 0 then
--                        local lRet = {}
--                        table.insert(lRet, {time = 1000, pos = {x = self.m_iX, y = self.m_iY}})
--
--                        local iDiff = 3000
--                        local iNow = iDiff
--                        local nx, ny = self.m_iX, self.m_iY
--                        while iNow < iLen do
--                            local nx = nx + dx*iDiff
--                            local ny = ny + dy*iDiff
--                            table.insert(lRet, {time = 1000, pos = {x = nx, y = ny}})
--                            iNow = iNow + iDiff
--                        end
--
--                        table.insert(lRet, {time = 1000, pos = {x = iRanX, y = iRanY}})
--
--                        self.m_lQueue = lRet
--                    end
--                end
--
--                if next(self.m_lQueue) then
--                    local lNetPos = {}
--
--                    local iLimit = 4
--                    table.insert(lNetPos, self.m_lQueue[math.min(#self.m_lQueue, iLimit)])
--
--                    local iCnt = 0
--                    while next(self.m_lQueue) and iCnt < iLimit do
--                        local o = table.remove(self.m_lQueue, 1)
--                        iCnt = iCnt + 1
--                    end
--
--                    local oLast = lNetPos[#lNetPos]
--                    self.m_iX = oLast.pos.x
--                    self.m_iY = oLast.pos.y
--
--                    self:run_cmd("C2GSSyncPosQueue", {
--                        scene_id = self.m_iScene,
--                        eid = self.m_iEid,
--                        poslist = lNetPos,
--                    })
--                end
--            else
--                self.m_iX, self.m_iY = iRanX, iRanY
--            end
--
--        end
--    end)
--
--    self:fork(function ()
--        while 1 do
--            self:sleep(10)
--
--            if iNowVer ~= self.m_iSceneVer then
--                break
--            end
--
--            --if math.random(5) == 1 then
--            --    local iMap = ChooseMapId(self)
--            --    self:run_cmd("C2GSClickWorldMap", {scene_id=self.m_iScene, map_id=iMap})
--            --    break
--            --end
--        end
--    end)
--end
--
--return scene