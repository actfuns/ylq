--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local playersend = require "base.playersend"

local gamedefines = import(lualib_path("public.gamedefines"))

local auramgr = import(service_path("auramgr"))

function NewCamp(...)
    local o = CCamp:New(...)
    return o
end

CCamp = {}
CCamp.__index = CCamp
inherit(CCamp, logic_base_cls())

function CCamp:New(id,iWarID)
    local o = super(CCamp).New(self)
    o.m_iCampId = id
    o.m_iWarID = iWarID
    o.m_mWarriors = {}
    o.m_mPos2Wid = {}
    o.m_iMaxPos = 0
    o.m_iMaxSummonPos = 8
    o.m_iSP = 0
    o.m_mAttrs = {}
    o.m_mFunction = {}
    o.m_mBoutArgs = {}
    o.m_Auramgr = auramgr.NewAuraMgr()
    
    return o
end

function CCamp:Release()
    for _, v in pairs(self.m_mWarriors) do
        baseobj_safe_release(v)
    end
    self.m_mWarriors = {}
    self.m_mFunction = {}
    super(CCamp).Release(self)
end

function CCamp:Init(mInit)
end

function CCamp:GetCampId()
    return self.m_iCampId
end

function CCamp:GetWarrior(id)
    return self.m_mWarriors[id]
end

function CCamp:GetWar()
    local oWarMgr = global.oWarMgr
    return oWarMgr:GetWar(self.m_iWarID)
end

function CCamp:GetAliveCount()
    local i = 0
    for k, v in pairs(self.m_mWarriors) do
        if v:IsAlive() then
            i = i + 1
        end
    end
    return i
end

function CCamp:GetPlayerAliveCout()
    local i = 0
    for k,v in pairs(self.m_mWarriors) do
        if v:IsAlive() and v:IsPlayer() then
            i = i + 1
        end
    end
    return i
end

function CCamp:GetWarriorList()
    local l = {}
    for k,v in pairs(self.m_mWarriors) do
        table.insert(l,v)
    end
    return l
end

--
function CCamp:SwitchPos(oSrcWarrior,iDestPos)
    local oWar = oSrcWarrior:GetWar()

    local mNet = {}
    local oDestWarrior = self:GetWarriorByPos(iDestPos)
    local iSrcWid = oSrcWarrior:GetWid()
    local iSrcPos = oSrcWarrior:GetPos()

    self.m_mPos2Wid[iDestPos] = iSrcWid
    oSrcWarrior:SetPos(iDestPos)
    table.insert(mNet,{wid = iSrcWid, pos = iDestPos})

    if oDestWarrior then
        local iDestWid = oDestWarrior:GetWid()
        oDestWarrior:SetPos(iSrcPos)
        self.m_mPos2Wid[iSrcPos] = iDestWid
        table.insert(mNet,{wid = iDestWid, pos = iSrcPos})
    end

    oWar:SendAll("GS2CSwitchPos",{
        war_id = oWar:GetWarId(),
        pos_list = mNet,
    })
end

function CCamp:ResetPos(oAction,iDestPos)
    self.m_mPos2Wid[iDestPos] = oAction:GetWid()
    oAction:SetPos(iDestPos)
end

function CCamp:GetWarriorByPos(iPos)
    local id = self.m_mPos2Wid[iPos]
    if id then
        return self:GetWarrior(id)
    end
end

function CCamp:DispatchPos(iWid, iPos)
    local iTarget
    if not iPos then
        local iMax = self.m_iMaxPos + 1
        for i = 1, iMax do
            if not self.m_mPos2Wid[i] then
                iTarget = i
                break
            end
        end
    else
        assert(not self.m_mPos2Wid[iPos], string.format("CCamp DispatchPos fail %d %d", iWid, iPos))
        iTarget = iPos
    end
    if iTarget > self.m_iMaxPos then
        self.m_iMaxPos = iTarget
    end
    self.m_mPos2Wid[iTarget] = iWid
    return iTarget
end

function CCamp:Enter(obj)
    local iTargetPos = self:DispatchPos(obj:GetWid(),obj:GetPos())
    obj:SetPos(iTargetPos)
    self.m_mWarriors[obj:GetWid()] = obj
end

function CCamp:EnterPartner(obj,iTargetPos)
    local iTargetPos = self:DispatchPos(obj:GetWid(),iTargetPos)
    obj:SetPos(iTargetPos)
    self.m_mWarriors[obj:GetWid()] = obj
end

function CCamp:EnterNpc(obj)
    self.m_iMaxSummonPos = self.m_iMaxSummonPos + 1
    local iTargetPos = self.m_iMaxSummonPos
    obj:SetPos(iTargetPos)
    self.m_mWarriors[obj:GetWid()] = obj
    self.m_mPos2Wid[iTargetPos] = obj:GetWid()
end

function CCamp:ValidCallNpc()
    local iCnt = self:CallNpcAmount()
    if iCnt >= 2 then
        return false
    end
    return true
end

function CCamp:CallNpcAmount()
    local iCnt = 0
    for iPos = 9,10 do
        local oWarrior = self:GetWarriorByPos(iPos)
        if oWarrior then
            iCnt = iCnt + 1
        end
    end
    return iCnt
end

--召唤物
function CCamp:EnterCall(obj)
    local iTargetPos = self:GetEnterCallPos()
    assert(iTargetPos,string.format("entercall err %s",obj:GetName()))
    obj:SetPos(iTargetPos)
    obj:Set("is_call",true)
    self.m_mWarriors[obj:GetWid()] = obj
    self.m_mPos2Wid[iTargetPos] = obj:GetWid()
end

function CCamp:GetEnterCallPos()
    for iPos = 9,10 do
        local oWarrior = self:GetWarriorByPos(iPos)
        if not oWarrior then
            return iPos
        end
    end
end

function CCamp:Leave(obj)
    self.m_mPos2Wid[obj:GetPos()] = nil
    self.m_mWarriors[obj:GetWid()] = nil
end

function CCamp:WarriorCount()
    return table_count(self.m_mWarriors)
end

function CCamp:OnWarStart()
    for k,v in pairs(self.m_mWarriors) do
        v:OnWarStart()
    end
end

function CCamp:OnBoutStart()
    self.m_mBoutArgs = {}
    for k, v in pairs(self.m_mWarriors) do
        v:OnBoutStart()
    end
end

function CCamp:NewBout()
    for k,v in pairs(self.m_mWarriors) do
        v:NewBout()
    end
end

function CCamp:OnBoutEnd()
    for k, v in pairs(self.m_mWarriors) do
        v:OnBoutEnd()
    end
end

function CCamp:SendAll(sMessage, mData, mExclude)
    mExclude = mExclude or {}
    local oWar = self:GetWar()
    if not oWar.m_LockCachePacket then
        local sData = playersend.PackData(sMessage,mData)
        for k,oAction in pairs(self.m_mWarriors) do
            if not mExclude[k] then
                oAction:SendRaw(sData)
            end
        end
        oWar:SendObserverRaw(sData,mExclude)
    else
        for k,oAction in pairs(self.m_mWarriors) do
            if not mExclude[k] then
                oAction:Send(sMessage, mData)
            end
        end
        oWar:SendObserver(sMessage, mData,mExclude)
    end
    if oWar:IsWarRecord() then
        oWar.m_oRecord:AddClientPacket(sMessage,mData)
    end
end

function CCamp:ValidResumeSP(iSP)
    if self.m_iSP < iSP then
        return false
    end
    return true
end

function CCamp:AddSP(iValue)
    self.m_iSP = self.m_iSP + iValue
    self.m_iSP = math.min(self.m_iSP,100)
    self.m_iSP = math.max(self.m_iSP,0)
    local mFunction = self:GetFunction("OnAddSP")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,iValue)
    end
end

function CCamp:GetSP()
    return self.m_iSP
end

function CCamp:IsFullSP()
    if self.m_iSP >= 100 then
        return true
    end
    return false
end

function CCamp:GetPartnerByID(iOwnWid,iParid)
    for k,oAction in pairs(self.m_mWarriors) do
        if oAction:IsPartner() and oAction:GetData("parid") == iParid and oAction:GetData("owner") == iOwnWid then
            return oAction
        end
    end
end

function CCamp:Add(key,value)
    local iValue = self.m_mAttrs[key] or 0
    self.m_mAttrs[key] = iValue + value
end

function CCamp:Set(key,value)
    self.m_mAttrs[key] = value
end

function CCamp:Query(key,rDefault)
    return self.m_mAttrs[key] or rDefault
end

function CCamp:GetFunction(sFunction)
    local mFunction = self.m_mFunction[sFunction] or {}
    return mFunction
end

function CCamp:AddFunction(sFunction,iNo,fCallback)
    local mFunction = self.m_mFunction[sFunction] or {}
    mFunction[iNo] = fCallback
    self.m_mFunction[sFunction] = mFunction
end

function CCamp:RemoveFunction(sFunction,iNo)
    local mFunction = self.m_mFunction[sFunction] or {}
    mFunction[iNo] = nil
    self.m_mFunction[sFunction] = mFunction
end

function CCamp:AddBoutArgs(key,value)
    local iValue = self.m_mBoutArgs[key] or 0
    self.m_mBoutArgs[key] = iValue + value
end

function CCamp:SetBoutArgs(key,value)
    self.m_mBoutArgs[key] = value
end

function CCamp:QueryBoutArgs(key,rDefault)
    return self.m_mBoutArgs[key] or rDefault
end

function CCamp:IsSinglePlayer()
    local iCnt = 0
    for _,oWarrior in pairs(self.m_mWarriors) do
        if oWarrior:IsPlayer() then
            iCnt = iCnt + 1
        end
        if iCnt > 1 then
            return false
        end
    end
    if iCnt > 1 then
        return false
    end
    return true
end

function CCamp:GetAttrBaseRatio(sAttr)
    return self.m_Auramgr:GetAttrBaseRatio(sAttr,0)
end

function CCamp:GetAttrAddValue(sAttr)
    return 0
end

function CCamp:OndDead(oAction)
    for id,obj in pairs(self.m_Auramgr:AuraList()) do
        if obj:GetWid() == oAction:GetWid() then
            if obj:Args()["dead_remove"] then
                self.m_Auramgr:RemoveAura(obj.m_ID)
            end
        end
    end
end
