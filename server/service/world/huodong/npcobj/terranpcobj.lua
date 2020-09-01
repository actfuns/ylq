--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"
local templ = import(service_path("templ"))
local npcobj = import(service_path("npc/npcobj"))

CTerra = {}
CTerra.__index = CTerra
CTerra.m_sName = "terrawars"
inherit(CTerra, npcobj.CNpc)

function NewTerra(mArgs)
    local o = CTerra:New(mArgs)
    return o
end

function CTerra:New(mArgs)
    local o = super(CTerra).New(self)
    o:Init(mArgs)
    return o
end

function CTerra:Init(mArgs)
    local mArgs = mArgs or {}

    self.m_iSize = mArgs.size or 1         -----据点规模1：小型，2：中型，3：大型
    self.m_iTerraId = mArgs.terra_id
    self.m_tSaveEndTime = mArgs.saveendtime or 0
    self.m_iOwner = mArgs.owner or 0
    self.m_sSysName = mArgs.sys_name
    self.m_iType = mArgs["type"]
    self.m_iMapid = mArgs["map_id"] or 0
    self.m_mModel = mArgs["model_info"] or {}
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iEvent = mArgs["event"] or 0
    self.m_iReUse = mArgs["reuse"] or 0
    self.m_iDefeated = 0
    self.m_tTakeTime = mArgs.take_time or 0
    self.m_iIsUp = mArgs.is_up or 0
    self.m_iPerPoints = mArgs.per_points or 0    --个人获得的积分
    self.m_iPerContribution = mArgs.per_contribution or 0 --个人获得的贡献度
    self.m_sOwnerName = mArgs.playername
    self.m_iOrgId  = mArgs.orgid
    self.m_sOrgName = mArgs.orgname
    self.m_sOrgFlag = mArgs.orgflag
end

function CTerra:Clear()
    self.m_tTakeTime = 0
    self.m_iIsUp = 0
    self.m_iPerPoints = 0    --个人获得的积分
    self.m_iPerContribution = 0 --个人获得的贡献度
    self.m_sOwnerName = ""
    self.m_iOwner = 0
    self.m_iOrgId  = 0
    self.m_sOrgName = ""
    self.m_sOrgFlag = ""
    self.m_tSaveEndTime = 0
    self:DelTimeCb("_Update"..self.m_iTerraId)
end

function CTerra:Save()
    local mInfo = {}
    mInfo.size = self.m_iSize
    mInfo.terra_id = self.m_iTerraId
    mInfo.saveendtime = self.m_tSaveEndTime
    mInfo.owner = self.m_iOwner
    mInfo.sys_name = self.m_sSysName
    mInfo.type = self.m_iType
    mInfo.map_id = self.m_iMapid
    mInfo.model_info = self.m_mModel
    mInfo.pos_info = self.m_mPosInfo
    mInfo.event = self.m_iEvent
    mInfo.reuse = self.m_iReUse
    mInfo.take_time = self.m_tTakeTime
    mInfo.is_up = self.m_iIsUp
    mInfo.per_points = self.m_iPerPoints
    mInfo.per_contribution = self.m_iPerContribution
    mInfo.playername = self.m_sOwnerName
    mInfo.orgid = self.m_iOrgId
    mInfo.orgflag = self.m_sOrgFlag
    mInfo.orgname = self.m_sOrgName
    return mInfo
end

function CTerra:GetSize()
    return self.m_iSize
end

function CTerra:GetData(iNpcType)
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["npc"][iNpcType]
end

function CTerra:GetID()
    return self.m_iTerraId
end

function CTerra:GetTerraBaseData()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sSysName]["terraconfig"]
    assert(mData[self.m_iTerraId],string.format("miss terra config:%s,%d",self.m_sSysName,self.m_iTerraId))
    return mData[self.m_iTerraId]
end

function CTerra:GetData(iNpcType)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sSysName]["npc"]
    assert(mData[iNpcType],string.format("miss npc config:%s,%d",self.m_sSysName,iNpcType))
    return mData[iNpcType]
end

function CTerra:GetMapId()
    local mData = self:GetTerraBaseData(self.m_iTerraId)
    return mData["map_id"]
end

--单位时间贡献度产出
function CTerra:GetContributionData()
    local mData = self:GetTerraBaseData(self.m_iTerraId)
    return mData["contribution"]
end

function CTerra:GetOrgPoint()
    local mData = self:GetTerraBaseData(self.m_iTerraId)
    local iPerPoints = mData["org_point"]
    local iCoefficient = self:GetCoefficient()
    if self:IsUp() then
        
        local iRate = self:GetUpRate()
        local fPoint = math.floor(((iRate+100)/100) * iPerPoints * iCoefficient)
        return fPoint > 0 and fPoint or 1
    end
    return math.floor(iPerPoints*iCoefficient) > 0 and math.floor(iPerPoints*iCoefficient) or 1
end

function CTerra:GetOccupyPoint()
    local mData = self:GetTerraBaseData(self.m_iTerraId)
    return mData["occupy_point"]
end

function CTerra:GetAttackPoint()
    local mData = self:GetTerraBaseData(self.m_iTerraId)
    return mData["attack_point"]
end

function CTerra:GetHelpPoint()
    local mData = self:GetTerraBaseData(self.m_iTerraId)
    return mData["help_point"]
end

function CTerra:GetNeighbour()
    local mData = self:GetTerraBaseData(self.m_iTerraId)
    return mData["neighbour"]
end

function CTerra:IsNeighbour(iTerrid)
    if iTerrid == self.m_iTerraId then
        return false
    end
    local mNeighbour = self:GetNeighbour()
    for _,id in pairs(mNeighbour) do
        if id == iTerrid then
            return true
        end
    end
    return false
end

function CTerra:GetUpRate()
    local mData = self:GetTerraBaseData(self.m_iTerraId)
    return mData["up_rate"]
end

function CTerra:SetUp(iStatus)
    self.m_iIsUp = iStatus
end

function CTerra:IsUp()
    return self.m_iIsUp == 1
end

function CTerra:do_look(oPlayer)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:ClickTerra(oPlayer,self.m_iTerraId)
end

function CTerra:PackNetInfo()
    
    local oWorldMgr = global.oWorldMgr
    local mNetInfo = {
        id = self.m_iTerraId,
        playername = self.m_sOwnerName,
        orgid = self.m_iOrgId,
        orgname = self.m_sOrgName,
        orgflag = self.m_sOrgFlag,
        orgscore = self:GetOrgCreateScore(),
        times = self:GetSaveTime(),
    }
    return mNetInfo
end

function CTerra:PackPersonalInfo()
    -- body
    local mNet = {
        personal_score = self.m_iPerPoints,
        personal_contribution = self.m_iPerContribution,
    }
    return mNet
end
function CTerra:CanAttack(oPlayer)
    if self:IsOnSave() then
        return false,1
    end
end

function CTerra:IsOnSave()
    if (self.m_tSaveEndTime - get_time()) > 0 then
        return true
    else
        return false
    end
end

function CTerra:GetTerraOwner()
    return self.m_iOwner
end

function CTerra:GetOwnerName()
    return self.m_sOwnerName or ""
end

function CTerra:SetOwnerName(sName)
    self.m_sOwnerName = sName
    self:UpdateSceneInfo()
end

function CTerra:SetTerraOwner(iPid,mArgs)
    local oWorldMgr = global.oWorldMgr
    if self.m_iOwner ~= iPid then
        self:ChangeOwner(self.m_iOwner,iPid)
    end
    self.m_iOwner = iPid
    self.m_sOwnerName = ""
    self.m_iOrgId = 0
    self.m_sOrgName = ""
    self.m_sOrgFlag = ""
    if self.m_iOwner ~= 0 then
        if mArgs then
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
            self.m_sOwnerName = mArgs.name
            self.m_iOrgId = mArgs.orgid
            self.m_sOrgName = mArgs.orgname
            self.m_sOrgFlag = mArgs.sflag
        end
    else
        self:SetTakeTime(0)
    end
    self:UpdateSceneInfo()
end

function CTerra:UpdateSceneInfo()
    local mInfo = {owner = "领主:"..(self:GetOwnerName() or "暂无"),orgid = self.m_iOrgId,orgflag = self.m_sOrgFlag,ownerid = self.m_iOwner}
    self:SyncSceneInfo(mInfo)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:UpdateMirrorNpc(self.m_iTerraId,mInfo)
end

function CTerra:SetSaveTime(iTime)
    self.m_tSaveEndTime = get_time()+(iTime or 900)
end

function CTerra:GetSaveTime()
    return self.m_tSaveEndTime
end

function CTerra:SetTakeTime(tTime)
    self.m_tTakeTime = tTime
end

function CTerra:GetTakeTime()
    return self.m_tTakeTime
end

function CTerra:GetCoefficient()
    local iInterval = get_time() - self.m_tTakeTime
    if iInterval < 3600 then
        return 1
    elseif iInterval < 7200 then
        return 0.5
    elseif iInterval < 10800 then
        return 0.2
    else
        return 0.1
    end
end

function CTerra:SetOrg(iID)
    self.m_iOrgId = iID
end

function CTerra:GetOrgID()
    return self.m_iOrgId
end

function CTerra:GetPersonalPoint()
    local mData = self:GetTerraBaseData(self.m_iTerraId)
    local iPerPoints = mData["personal_point"]
    local iCoefficient = self:GetCoefficient()
    if self:IsUp() then
        local iRate = self:GetUpRate() or 0
        local fPoint = ((iRate+100)/100) * iPerPoints * iCoefficient
        fPoint = math.floor(fPoint) > 0 and math.floor(fPoint) or 1
        return fPoint
    end
    return math.floor(iPerPoints*iCoefficient) > 0 and math.floor(iPerPoints*iCoefficient) or 1
end

function CTerra:GetOrgCreateScore()
    if self.m_iOwner == 0 then
        return 0
    end
    local tTakeTime = self:GetTakeTime()
    local tNowTime = get_time()
    if (tNowTime - tTakeTime) <= 0 then
        return 0
    end
    if tTakeTime == 0 then
        return 0
    end
    local iAveScore = self:GetOrgPoint()
    local iCreateTime = math.modf((tNowTime - tTakeTime)/60)
    return iCreateTime*iAveScore
end

function CTerra:ChangeOwner(iOldOwner,iNewOwner)
    self.m_iPerPoints = self:GetOccupyPoint()
    self.m_iPerContribution = self:GetOccupyPoint()
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:ChangeOwner(iOldOwner,iNewOwner)
    local iTerrid = self.m_iTerraId
    local func
    func = function()
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("terrawars")
        local oTerra = oHuodong:GetTerra(iTerrid)
        if oTerra then
            oTerra:DelTimeCb("_Update"..iTerrid)
            oTerra:AddTimeCb("_Update"..iTerrid,1*60*1000,func)
            oTerra:Update()
        end
    end
    func()
end

function CTerra:Update()
    if self:GetTerraOwner() == 0 then
        return
    end

    local iPerPoints = self:GetPersonalPoint()
    local iOrgPoints = self:GetOrgPoint()
    self.m_iPerPoints = self.m_iPerPoints+iPerPoints
    self.m_iPerContribution = self.m_iPerContribution+iPerPoints
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:AddPerPoints(self.m_iOwner,self.m_iTerraId,iPerPoints)
    oHuodong:AddPerContribution(self.m_iOwner,self.m_iTerraId,iPerPoints,{cancel_tip = true,cancel_channel = true,cancel_keepshow = true})
    oHuodong:AddOrgPoints(self.m_iOwner,self.m_iOrgId,self.m_iTerraId,iOrgPoints)
    oHuodong:RecoverHp(self.m_iTerraId)
end

function CTerra:Close()
    self:Update()
    self:DelTimeCb("_Update"..self.m_iTerraId)
end

function CTerra:PackSceneInfo()
    local mNet = super(CTerra).PackSceneInfo(self)
    mNet["owner"] = self:GetOwnerName() and ("领主: "..self:GetOwnerName()) or "暂无"
    mNet["orgid"] = self:GetOrgID()
    mNet["orgflag"] = self.m_sOrgFlag or ""
    mNet["ownerid"] = self.m_iOwner or 0
    return mNet
end

function CTerra:SetDefeated(iDefeated)
    self.m_iDefeated = iDefeated
end

function CTerra:IsGuardAlive()
    return self.m_iDefeated ~= 1
end

function CTerra:SetOrgFlag(sFlag)
    self.m_sOrgFlag = sFlag or ""
    self:UpdateSceneInfo()
end