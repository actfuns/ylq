--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local res = require "base.res"
local record = require "public.record"
local extend = require "base.extend"
local loadai = import(service_path("ai/loadai"))

local status = import(lualib_path("base.status"))
local gamedefines = import(lualib_path("public.gamedefines"))
local pfload = import(service_path("perform/pfload"))
local buffmgr = import(service_path("buffmgr"))
local pfmgr = import(service_path("pfmgr"))

CWarrior = {}
CWarrior.__index = CWarrior
inherit(CWarrior, logic_base_cls())

function CWarrior:New(iWid)
    local o = super(CWarrior).New(self)
    o.m_iType = gamedefines.WAR_WARRIOR_TYPE.WARRIOR_TYPE
    o.m_iWid = iWid
    o.m_iWarId = nil
    o.m_iCamp = nil
    o.m_iPos = nil
    o.m_iBout = 0
    o.m_bIsDefense = false
    o.m_iProtectVictim = nil
    o.m_iProtectGuard = nil

    o.m_oStatus = status.NewStatus()
    o.m_oStatus:Set(gamedefines.WAR_WARRIOR_STATUS.ALIVE)

    o.m_mFunction = {}
    o.m_mBoutArgs = {}                                                                                  --每回合数据
    o.m_mAttrs = {}                                                                                         --属性数据
    o.m_mExtData = {}
    o.m_iAIType = gamedefines.AI_TYPE.COMMON
    return o
end

function CWarrior:Type()
    return self.m_iType
end

function CWarrior:GetAIType()
    return self.m_iAIType
end

function CWarrior:SetAIType(iAIType)
    self.m_iAIType = iAIType
end

function CWarrior:Init(mInit)
    self.m_iWarId = mInit.war_id
    self.m_iCamp = mInit.camp_id
    self.m_mData = mInit.data
    self.m_oBuffMgr = buffmgr.NewBuffMgr(self.m_iWarId,self.m_iWid)
    self.m_oPerformMgr = pfmgr.NewPerformMgr(self.m_iWarId,self.m_iWid)

    local mPerform = self:GetData("perform",{})
    for iPerform,iLevel in pairs(mPerform) do
        self:SetPerform(iPerform,iLevel)
    end
    self.m_mTestData = self.m_mData["testdata"] or {}
    self:SetPos(self.m_mData["pos"])
end

function CWarrior:IsDead()
    return self.m_oStatus:Get() == gamedefines.WAR_WARRIOR_STATUS.DEAD
end

function CWarrior:IsAlive()
    return self.m_oStatus:Get() == gamedefines.WAR_WARRIOR_STATUS.ALIVE
end

function CWarrior:IsVisible(oVictim)
    return true
end

function CWarrior:Status()
    return self.m_oStatus:Get()
end

function CWarrior:IsObserver()
    return false
end

function CWarrior:IsPlayer()
    return self.m_iType == gamedefines.WAR_WARRIOR_TYPE.PLAYER_TYPE
end

function CWarrior:IsRomPlayer()
    return self.m_iType == gamedefines.WAR_WARRIOR_TYPE.ROM_PLAYER_TYPE
end

function CWarrior:IsNpc()
    return self.m_iType == gamedefines.WAR_WARRIOR_TYPE.NPC_TYPE
end

function CWarrior:IsPartner()
    return self.m_iType == gamedefines.WAR_WARRIOR_TYPE.PARTNER_TYPE
end

function CWarrior:IsRomPartner()
    return self.m_iType == gamedefines.WAR_WARRIOR_TYPE.ROM_PARTNER_TYPE
end

function CWarrior:IsRomWarrior()
    return self:IsRomPartner() or self:IsRomPlayer()
end

function CWarrior:IsAIAction()
    return not (self:IsPlayer() or self:IsPartner())
end


--是否是召唤物
function CWarrior:IsCallNpc()
    if self:IsNpc() and self:Query("is_call") then
        return true
    end
    return false
end

--是否献祭或者自爆
function CWarrior:IsSacrifice()
    return self:Query("is_sacrifice")
end

function CWarrior:GetWid()
    return self.m_iWid
end

function CWarrior:GetWarId()
    return self.m_iWarId
end

function CWarrior:GetCampId()
    return self.m_iCamp
end

function CWarrior:GetEnemyCampId()
    return 3 - self.m_iCamp
end

function CWarrior:GetCamp()
    local oWar = self:GetWar()
    local iCamp = self:GetCampId()
    local oCamp = oWar:GetCamp(iCamp)
    return oCamp
end

function CWarrior:GetEnemyCamp()
    local oWar = self:GetWar()
    local iCamp = self:GetEnemyCampId()
    local oCamp = oWar:GetCamp(iCamp)
    return oCamp
end

function CWarrior:SetPos(id)
    self.m_iPos = id
end

function CWarrior:GetPos()
    return self.m_iPos
end

function CWarrior:GetData(k, rDefault)
    if table_in_list({"hp",},k) then
        if self.m_mTestData[k] then
            return self.m_mTestData[k]
        end
    end
    return self.m_mData[k] or rDefault
end

function CWarrior:SetData(k, v)
    self.m_mData[k] = v
end

function CWarrior:GetExtData(k,rDefault)
    return self.m_mExtData[k] or rDefault
end

function CWarrior:SetExtData(k,v)
    self.m_mExtData[k] = v
end

function CWarrior:StatusChange(...)
end

function CWarrior:GetMaxHp()
    return self:GetData("max_hp",0)
end

function CWarrior:GetModelInfo()
    return self:GetData("model_info")
end

function CWarrior:GetMaxMp()
    return self:GetData("max_mp")
end

function CWarrior:GetHp()
    return self:GetData("hp")
end

function CWarrior:GetHpRatio()
    local iHp = math.floor(self:GetHp())
    local iMaxHp = math.floor(self:GetMaxHp())
    return math.floor(iHp/iMaxHp*100)
end

function CWarrior:GetMp()
    return self:GetData("mp")
end

function CWarrior:GetName()
    return self:GetData("name")
end

function CWarrior:IsBoss()
    return self:GetData("boss",0) == 1
end

function CWarrior:BanPassiveSkill()
    local oBuff = self.m_oBuffMgr:HasBuff(1032)
    if oBuff then
        if oBuff.m_awake then
            return 2
        else
            return 1
        end
    end
end

function CWarrior:SubHp(iDamage,mArgs)
    mArgs = mArgs or {}
    local oWar = self:GetWar()
    local iAttack = mArgs["attack"]
    local iSkill = 0
    if iAttack then
        local oAttack = oWar:GetWarrior(iAttack)
        if oAttack then
            iSkill = oAttack:GetBoutCmdSkill() or 0
            oAttack:AddBoutArgs("Bout_Damage",iDamage)
        end
    end
    local oWar = self:GetWar()

    if not ( self:GetHp()>0 and iDamage >= 0 ) then
        local iKill = self:GetData("LastKiller",0)
        local sName = ""
        local sSkilllist = ""
        local sArg = ""
        local oAttack = oWar:GetWarrior(iKill)
        if oAttack then
            sName = oAttack:GetName()
            local m = self.m_oPerformMgr.m_mPerform
            local skilllist = {}
            for iPerform,_ in pairs(m) do
                table.insert(skilllist,iPerform)
            end
            sSkilllist = table.concat(skilllist,",")
        end
        sArg = ConvertTblToStr(self:GetData("LastKillArg",{}))
        local msg = string.format("debug hp<0 %s %s attcker : %s %s skill:%s args:%s",self:GetWid(),self:GetName(),iKill,sName,sSkilllist,sArg)
        record.error(msg)
        msg = string.format("subhp err:%d %d %s %s,attack skill:%s,danmage:%s dead:%s ,live:%s type:%s",oWar:GetWarId(),self:GetWid(),self:GetName(),self:GetHp(),iSkill,iDamage,self:IsDead(),self:IsAlive(),oWar:GetWarType())
        record.error(msg)
        return
    end
    self:SetData("hp", math.floor(self:GetHp() - iDamage))
    self:SetData("hp", math.max(0, math.min(self:GetMaxHp(), self:GetData("hp",0))))
    self:KeepAlive()

    self:AddSPForDamage(iDamage,iAttack)

    local mFunction = self:GetFunction("OnSubHp")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,iDamage)
    end
    self:AddBoutArgs("SumDamage",iDamage)
    if self:GetData("hp") <= 0 then
        --触发保命，不死
        local iReviveRatio = self:QueryAttr("revive_ratio")
        if not mArgs["dead"] then
            local mFunction = self:GetFunction("ReviveHandle")
            for _,fCallback in pairs(mFunction) do
                if fCallback(self) then
                    self:SetData("hp",1)
                    self:AddBoutArgs("revived_cnt",1)
                    self:Add("revived_cnt",1)
                end
            end
        end
    end
    if self:GetData("hp") <= 0 then
        local mFunction = self:GetFunction("BeforeDie")
        for _,fCallback in pairs(mFunction) do
            fCallback(self)
        end
        local oCamp = self:GetCamp()
        local mFunction = self:GetCampFunction(oCamp,"BeforeDie")
        for _,fCallback in pairs(mFunction) do
            fCallback(self)
        end
    end
    self:StatusChange("hp")
    if self:GetData("hp") <= 0 and iAttack then
        local oAttack = oWar:GetWarrior(iAttack)
        if oAttack then
            local mFunction = oAttack:GetFunction("OnKill")
            for _,fCallback in pairs(mFunction) do
                fCallback(oAttack,self,iDamage)
            end
            mFunction = self:GetFunction("OnKilled")
            for _,fCallback in pairs(mFunction) do
                fCallback(self,oAttack,iDamage)
            end
        end
        self:SetData("LastKiller",iAttack)
    end
    if self:IsAlive() and self:GetData("hp") <= 0 then
        self:SetDeadStatus(mArgs)
        self:SetData("LastKillArg",mArgs)
    end
end

function CWarrior:KeepAlive()
end

function CWarrior:SetDeadStatus(mArgs)
    local oWar = self:GetWar()
    self.m_oStatus:Set(gamedefines.WAR_WARRIOR_STATUS.DEAD)
    self:StatusChange("status")
    self:AddSPForDead()
    self:OnDead(mArgs)
    if self:IsCallNpc() or self:IsSacrifice() then
        local mArgs = {
        del_type = 2,
        speed = 1,
        }
        oWar:KickOutWarrior(self,mArgs)
        oWar:BuildSpeedMQ()
        end
end


function CWarrior:AddSPForDead()
    if self:IsCallNpc() or self:IsNpc() then
        return
    end
    local oWar = self:GetWar()
    oWar:AddSP(self:GetCampId(),20)
end

function CWarrior:AddSPForDamage(iDamage,iAttack)
    if self:IsCallNpc() or self:IsNpc()  then
        return
    end
    local oWar = self:GetWar()
    local iMaxHp = self:GetMaxHp()
    local iSP = math.floor(iDamage*2000/iMaxHp)
    iSP = math.max(1,math.min(20,math.floor(iSP//100)))
    if iSP >= 0 then
        local oWar = self:GetWar()
        local iCamp = self:GetCampId()
        if oWar and not self:HasKey("no_add_sp") then
            oWar:AddSP(iCamp,iSP,{wid=self:GetWid()})
        end
    end
end


function CWarrior:OnActionBeforeStart()
    local mFunction= self:GetFunction("OnActionBeforeStart")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnActionBeforeStart")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
end

function CWarrior:OnActionStart(oAction)
    local mFunction= self:GetFunction("OnActionStart")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnActionStart")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
end


function  CWarrior:OnWarSkillStart(lVictim,iSkill)
    local mFunction= self:GetFunction("OnWarSkillStart")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,lVictim,iSkill)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnWarSkillStart")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,lVictim,iSkill)
    end
end


function CWarrior:AddHp(i)
    assert(i>=0,string.format("subhp err: %d %s %s,danmage:%s dead:%s ,live:%s",self:GetWid(),self:GetName(),self:GetHp(),i,self:IsDead(),self:IsAlive()))
    self:SetData("hp", math.floor(self:GetData("hp") + i))
    self:SetData("hp", math.max(0, math.min(self:GetMaxHp(), self:GetData("hp"))))
    self:StatusChange("hp")

    if self:IsDead() and self:GetData("hp") > 0 then
        self.m_oStatus:Set(gamedefines.WAR_WARRIOR_STATUS.ALIVE)
        self:StatusChange("status")

        local mFunction = self:GetFunction("OnRevive")
        for _,fCallback in pairs(mFunction) do
            fCallback(self)
        end
    end
    local mFunction = self:GetFunction("OnAddHp")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,i)
    end
    self:SetData("call_partner",nil)
    self:AddBoutArgs("AddHP",i)
end


function CWarrior:ValidRevive(mArgs)
    mArgs = mArgs or {}
    local mFunction = self:GetFunction("OnValidRevive")
    for _,fCallback in pairs(mFunction) do
        if not fCallback(self,mArgs) then
            return false
        end
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnValidRevive")
    for _,fCallback in pairs(mFunction) do
        if not fCallback(self,mArgs) then
            return false
        end
    end
    return true
end



--更改气血，同时显示
function CWarrior:ModifyHp(iHp,mArgs)
    mArgs = mArgs or {}
    local oWar = self:GetWar()
    local iAttack = mArgs.attack_wid or 0
    if not mArgs["attack"] then
        mArgs["attack"] = mArgs.attack_wid
    end
    local oAttack = oWar:GetWarrior(iAttack)
    local iCritical = 0
    if iHp > 0 then
        if oAttack then
            local oActionMgr = global.oActionMgr
            if not mArgs["steal"] then
                iHp,iCritical = oActionMgr:CalCureHp(iHp,self,oAttack)
            end
        end
        if self:IsDead() and not self:ValidRevive(mArgs) then
            return
        end
    end

    iHp = math.floor(iHp)
    if iHp > 0 then
        if self:HasKey("disable_cure") and not self:Query("50303buff") then
            return
        end
    end
    self:SendAll("GS2CWarDamage", {
        war_id = self:GetWarId(),
        wid = self:GetWid(),
        damage = iHp,
        iscrit = iCritical,
        damage_type = mArgs["damage_type"] or 0,
    })



    if iHp > 0 then
        if self:HasKey("curse_hp") then
            self:SubHp(iHp)
            self:OnModifyHp(iHp,mArgs)
            return
        end
        self:AddHp(iHp)
    else
        if self:IsDead() or self:GetHp() <= 0 then
            return
        end
        local iSubHp = math.abs(iHp)
        self:SubHp(iSubHp,mArgs)
    end
    self:OnModifyHp(iHp,mArgs)
end

function CWarrior:GetSimpleWarriorInfo()
end

function CWarrior:GetSimpleStatus()
end

function CWarrior:GetWar()
    local oWarMgr = global.oWarMgr
    return oWarMgr:GetWar(self:GetWarId())
end

function CWarrior:GetWarrior(iWid)
    local oWar = self:GetWar()
    return oWar:GetWarrior(iWid)
end


function CWarrior:GetSpeed()
    local iSpeed = self:QueryAttr("speed")
    local oWar = self:GetWar()
    local mCmds = oWar:GetBoutCmd(self.m_iWid)
    local bSkill = false
    local iRatio = self:QueryAttr("speed_ratio")
    local iExtSpeed = 0
    if mCmds then
        local cmd = mCmds.cmd
        local mSkillData = mCmds.data
        if cmd == "skill" then
            local iSkill = mSkillData.skill_id
            local oPerform = self:GetPerform(iSkill)
            if oPerform then
              iRatio = iRatio + oPerform:SpeedRatio()
              iExtSpeed = oPerform:PerformTempAddSpeed(self)
              bSkill = true
            end
        end
    end
    if not bSkill then
        iRatio = iRatio + 100
    end
    iSpeed = iSpeed * iRatio / 100
    iSpeed = math.floor(iSpeed + iExtSpeed)
    local mFunction = self:GetFunction("OnCallSpeed")
    for iNo,fCallback in pairs(mFunction) do
        iSpeed =fCallback(self,iSpeed)
    end
    return iSpeed
end

function CWarrior:SetDefense(bFlag)
    self.m_bIsDefense = bFlag
end

function CWarrior:IsDefense()
    return self.m_bIsDefense
end

function CWarrior:SetProtect(iVictim)
    if not iVictim then
        if self.m_iProtectVictim then
            local oVictim = self:GetWarrior(self.m_iProtectVictim)
            if oVictim then
                oVictim:SetGuard()
            end
            self.m_iProtectVictim = nil
        end
    else
        local oVictim = self:GetWarrior(iVictim)
        if oVictim then
            self.m_iProtectVictim = iVictim
            oVictim:SetGuard(self:GetWid())
        end
    end
end

function CWarrior:SetGuard(iGuard)
    self.m_iProtectGuard = iGuard
end

function CWarrior:GetProtect()
    local id = self.m_iProtectVictim
    if not id then
        return
    end
    return self:GetWarrior(id)
end

function CWarrior:GetGuard()
    local id = self.m_iProtectGuard
    if not id then
        return
    end
    return self:GetWarrior(id)
end

function CWarrior:OnWarStart()
    local mFunction = self:GetFunction("OnWarStart")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
end

function CWarrior:OnBoutStart()
    self.m_oBuffMgr:OnBoutStart(self)
    self.m_mBoutArgs = {}
    self.m_bAction = false
    local mFunction = self:GetFunction("OnBoutStart")
    for iNo,fCallback in pairs(mFunction) do
        fCallback(self)
    end
end

function CWarrior:NewBout()
    self.m_iBout = self.m_iBout + 1
    local mFunction = self:GetFunction("OnNewBout")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
end

function CWarrior:OnBoutEnd()
    local mFunction = self:GetFunction("OnBoutEnd")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
    self.m_oBuffMgr:OnBoutEnd(self)
end

function CWarrior:Send(sMessage, mData)
end

function CWarrior:SendRaw(sData)
end

function CWarrior:SendAll(sMessage, mData, mExclude)
    local oWar = self:GetWar()
    oWar:SendAll(sMessage, mData, mExclude)
end

function CWarrior:QueryAttr(sAttr)
    local iBase = self:GetBaseAttr(sAttr) * ( 10000 + self:GetAttrBaseRatio(sAttr)) /10000 + self:GetAttrAddValue(sAttr)
    iBase = iBase * (10000 + self:GetAttrTempRatio(sAttr) ) /10000 + self:GetAttrTempAddValue(sAttr)
    iBase  = iBase + self:QueryBoutArgs(sAttr,0) + self:Query(sAttr,0) + self.m_oBuffMgr:GetAttr(sAttr,0)
    iBase = math.floor(iBase)
    return iBase
end

function CWarrior:GetBaseAttr(sAttr)
    return self:GetData(sAttr,0)
end

function CWarrior:GetAttrBaseRatio(sAttr)
    local iAdd = self:GetCamp():GetAttrBaseRatio(sAttr)
    local iRatio = self.m_oBuffMgr:GetAttrBaseRatio(sAttr) + self.m_oPerformMgr:GetAttrBaseRatio(sAttr) + self:GetCamp():GetAttrBaseRatio(sAttr)
    return iRatio
end

function CWarrior:GetAttrAddValue(sAttr)
    local iValue = self.m_oBuffMgr:GetAttrAddValue(sAttr) + self.m_oPerformMgr:GetAttrAddValue(sAttr) + self:GetCamp():GetAttrAddValue(sAttr)
    return iValue
end

function CWarrior:GetAttrTempRatio(sAttr)
    local iRatio = self.m_oBuffMgr:GetAttrTempRatio(sRatio)
    return iRatio
end

function CWarrior:GetAttrTempAddValue(sAttr)
    local iValue = self.m_oBuffMgr:GetAttrTempAddValue(sAttr)
    return iValue
end

function CWarrior:SetPerform(iPerform,iLevel)
    self.m_oPerformMgr:SetPerform(self,iPerform,iLevel)
end

function CWarrior:GetPerform(pfid)
    return self.m_oPerformMgr:GetPerform(pfid)
end

function CWarrior:GetPerformList()
    local mPerform = self.m_oPerformMgr:GetPerformList()
    mPerform = mPerform or {}
    return mPerform
end

function CWarrior:GetPerformLevelList()
    local mPerform = self.m_oPerformMgr:GetPerformLevelList()
    mPerform = mPerform or {}
    return mPerform
end

function CWarrior:AddBoutArgs(key,value)
    local iValue = self.m_mBoutArgs[key] or 0
    self.m_mBoutArgs[key] = iValue + value
end

function CWarrior:SetBoutArgs(key,value)
    self.m_mBoutArgs[key] = value
end

function CWarrior:QueryBoutArgs(key,rDefault)
    return self.m_mBoutArgs[key] or rDefault
end


function CWarrior:Add(key,value)
    local iValue = self.m_mAttrs[key] or 0
    self.m_mAttrs[key] = iValue + value
end

function CWarrior:Set(key,value)
    self.m_mAttrs[key] = value
end

function CWarrior:Query(key,rDefault)
    return self.m_mAttrs[key] or rDefault
end

function CWarrior:HasKey(sKey)
    local oBuffMgr = self.m_oBuffMgr
    if oBuffMgr:HasKey(sKey) then
        return true
    end
    if self:QueryBoutArgs(sKey) then
        return true
    end
    if self:Query(sKey) then
        return true
    end
    return false
end

function CWarrior:GetFriendList(bAll,bRandom)
    local oWar = self:GetWar()
    local iCamp = self.m_iCamp
    local mFriendList = oWar:GetWarriorList(iCamp)
    local iCount = table_count(mFriendList)
    if bRandom and  #mFriendList > 1 then
        mFriendList = extend.Random.sample_list(mFriendList,#mFriendList)
    end
    if bAll then
        return mFriendList
    else
        local l = {}
        for _,oVictim in pairs(mFriendList) do
            if oVictim:IsAlive() and oVictim:GetHp() > 0 then
                table.insert(l,oVictim)
            end
        end
        return l
    end
end

function CWarrior:GetEnemyList(bAll,bRandom)
    local oWar = self:GetWar()
    local iCamp = 3 - self.m_iCamp
    local mEnemy = oWar:GetWarriorList(iCamp)
    if bRandom and  #mEnemy > 1 then
        mEnemy = extend.Random.sample_list(mEnemy,#mEnemy)
    end
    if bAll then
        return mEnemy
    else
        local l = {}
        for _,oVictim in pairs(mEnemy) do
            if oVictim:IsAlive() and oVictim:GetHp() > 0 and oVictim:IsVisible(self) then
                table.insert(l,oVictim)
            end
        end
        return l
    end
end

function CWarrior:IsFriend(oVictim)
    if not oVictim then
        return
    end
    if self.m_iCamp == oVictim.m_iCamp then
        return true
    end
    return false
end

function CWarrior:IsEnemy(oVictim)
    if not oVictim then
        return
    end
    if self.m_iCamp ~= oVictim.m_iCamp then
        return true
    end
    return false
end

function CWarrior:GetFunction(sFunction)
    local mFunction = self.m_mFunction[sFunction] or {}
    local mBuffFunction = self.m_oBuffMgr:GetFunction(sFunction)
    local mPfFunction = self.m_oPerformMgr:GetFunction(sFunction)
    local mCallback = {}
    for iNo,fCallback in pairs(mFunction) do
        mCallback[iNo] = fCallback
    end
    for iNo,fCallback in pairs(mBuffFunction) do
        mCallback[iNo] = fCallback
    end
    for iNo,fCallback in pairs(mPfFunction) do
        mCallback[iNo] = fCallback
    end
    return mCallback
end

function CWarrior:AddFunction(sFunction,iNo,fCallback)
    local mFunction = self.m_mFunction[sFunction] or {}
    mFunction[iNo] = fCallback
    self.m_mFunction[sFunction] = mFunction
end

function CWarrior:RemoveFunction(sFunction,iNo)
    local mFunction = self.m_mFunction[sFunction] or {}
    mFunction[iNo] = nil
    self.m_mFunction[sFunction] = mFunction
end

function CWarrior:QueryExpertSkill(iNo)
    local mData = self:GetData("expertskill",{})
    local iValue = mData[iNo] or 0
    return iValue
end

function CWarrior:ReceiveDamage(oAttack,oPerform,iDamage)
    assert(self:GetWid() ~= oAttack:GetWid(),string.format("ReceiveDamage err:%d %d",oAttack:GetWid(),oPerform.m_ID))
    if self:IsDead() or self:GetHp() <= 0 then
        record.warning(string.format("-------hcdebug------ReceiveDamage:%s %s",self:GetName(),oPerform.m_ID))
    end
    iDamage = math.abs(iDamage)
    local iBaseDamage = iDamage
    local mFunction = oAttack:GetFunction("OnReceiveDamage")
    for iNo,fCallback in pairs(mFunction) do
        local iAdd = fCallback(oAttack,self,oPerform,iDamage)
        assert(iAdd,string.format("err OnReceiveDamage %d %d",iNo,oPerform:Type()))
        iDamage = iDamage + iAdd
    end

    iDamage = self:OnReceivedDamage(oAttack,oPerform,iDamage)
    if not iDamage or iDamage == 0 or self:IsDead() then
        return 0,0
    end

    local iShowDamage = iDamage

    local mFunction = self:GetFunction("AfterReceiveDamage")
    for _,fCallback in pairs(mFunction) do
        iDamage = iDamage + fCallback(self,oAttack,oPerform,iDamage)
    end

    local oWar = self:GetWar()
    if oWar then
        oWar.m_oRecord:AddAttack(oAttack,self,iBaseDamage)
        oWar.m_oRecord:AddReceiveDamage(self,oAttack,iBaseDamage)
    end
    if oAttack then
        self:RecordFloatAttack(oAttack)
    end
    return iShowDamage,iDamage
end

function CWarrior:PerformDamage(oAttack,oPerform,iDamage)
    local mArgs = oPerform:PackModifyArg(self,oAttack,-iDamage,{attack = oAttack:GetWid()})
    self:SubHp(iDamage,mArgs)
    self:OnModifyHp(-iDamage,mArgs)
end


--新加的用来代替ModifyHp,可以参数配置来处理策划比较恶心的伤害处理
function CWarrior:FixedDamage(oAttack,iDamage,mArg)
    mArg = mArg or {}
    local iShowDamage = iDamage
    if not mArg["no_absorb"] then
        local mFunction = self:GetFunction("AfterReceiveDamage")
        for _,fCallback in pairs(mFunction) do
            iDamage = iDamage + fCallback(self,oAttack,oPerform,iDamage)
        end
    end
    self:SendAll("GS2CWarDamage", {
            war_id = self:GetWarId(),
            wid = self:GetWid(),
            type = 0,
            damage = -iShowDamage,
            iscrit = 0,
        })
    local args = mArg["arg"] or {}
    if mArg["perform"] then
        args = mArg["perform"]:PackModifyArg(self,oAttack,-iDamage,{attack = oAttack:GetWid()})
    else
        args["attack"] = oAttack:GetWid()
    end

    self:SubHp(iDamage,args)
    self:OnModifyHp(-iDamage,args)
end

function CWarrior:IsTestMan()
    if self:GetData("testman") ==  99 then
        return true
    end
    return false
end

function CWarrior:AbnormalRatio(oVictim,iBaseRatio,iMaxRatio,iMinRatio)
    local iRatio = iBaseRatio * (10000 + self:QueryAttr("abnormal_attr_ratio") - oVictim:QueryAttr("res_abnormal_ratio"))
    iRatio = math.floor(iRatio/10000)
    iRatio = math.max(iRatio,iMinRatio)
    iRatio = math.min(iRatio,iMaxRatio)
    if self:IsTestMan() then
        iRatio = 10000
    end
    return iRatio
end

function CWarrior:SpecialRatio(iPerform)
    return 0
end

function CWarrior:Random(iRatio,iMax)
    iMax = iMax or 10000
    if self:IsTestMan() then
        iRatio = 10000
    end
    return in_random(iRatio,iMax)
end

function CWarrior:GetNormalAttackSkillId()
    local mPerform = self:GetPerformList()
    for _,iPerform in pairs(mPerform) do
        if iPerform % 10 == 1 then
            return iPerform
        end
    end
    return mPerform[math.random(#mPerform)]
end

function CWarrior:GetPerformCDList()
    local mPerform = self:GetPerformList()
    local mCD = {}
    for _,iPerform in pairs(mPerform) do
        local oPerform = self:GetPerform(iPerform)
        if oPerform and oPerform:InCD(self) then
            local iBout = oPerform:CDBout(self)
            table.insert(mCD,{skill_id=iPerform,bout=iBout})
        end
    end
    return mCD
end

function CWarrior:RefreshPerformCD()
    local mCD = self:GetPerformCDList()
    self:Send("GS2CWarSkillCD",{
         war_id = self:GetWarId(),
         wid = self:GetWid(),
         skill_cd = mCD,
     })
end

function CWarrior:GetTestData(k)
    return self.m_mTestData[k]
end

function CWarrior:SetTestData(k, v)
    self.m_mTestData[k] = v
    if k == "max_hp" then
        self:SetData("hp", self:GetMaxHp())
        self:StatusChange("hp")
        self:StatusChange("max_hp")
    end
end


function CWarrior:OnAddBuff(oBuff)
    local mFunction = self:GetFunction("OnAddBuff")
    for _,fCallback in pairs(mFunction) do
        if not fCallback(self,oBuff) then
            return false
        end
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnAddBuff")
    for _,fCallback in pairs(mFunction) do
        if not fCallback(self,oBuff) then
            return false
        end
    end
    return true
end

function CWarrior:OnPerform(lVictim,oPerform)
    local mFunction = self:GetFunction("OnPerform")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,lVictim,oPerform)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnPerform")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,lVictim,oPerform)
    end
end

function CWarrior:OnAfterGoback(lVictim,oPerform)
    local mFunction = self:GetFunction("OnAfterGoback")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,lVictim,oPerform)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnAfterGoback")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,lVictim,oPerform)
    end
end


function CWarrior:OnCalDamage(oVictim,oPerform,iDamage)
    local mFunction = self:GetFunction("OnCalDamage")
    for _,fCallback in pairs(mFunction) do
        iDamage = iDamage + fCallback(self,oVictim,oPerform,iDamage)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnCalDamage")
    for _,fCallback in pairs(mFunction) do
        iDamage = iDamage + fCallback(self,oVictim,oPerform,iDamage)
    end
    return iDamage
end

function CWarrior:OnCalDamageRatio(oVictim,oPerform,iRatioA)
    local mFunction = self:GetFunction("OnCalDamageRatio")
    for _,fCallback in pairs(mFunction) do
        iRatioA = iRatioA + fCallback(self,oVictim,oPerform)
    end

    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnCalDamageRatio")
    for _,fCallback in pairs(mFunction) do
        iRatioA = iRatioA + fCallback(self,oVictim,oPerform)
    end
    return iRatioA
end

function CWarrior:OnPerformed(oAttack,oPerform)
    local mFunction = self:GetFunction("OnPerformed")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oAttack,oPerform)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnPerformed")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oAttack,oPerform)
    end
end

function CWarrior:OnAttack(oVictim,oPerform,iDamage)
    local mFunction = self:GetFunction("OnAttack")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oVictim,oPerform,iDamage)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnAttack")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oVictim,oPerform,iDamage)
    end
end

function CWarrior:PerformStart(oPerform)
    local mFunction = self:GetFunction("PerformStart")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oPerform)
    end

    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"PerformStart")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oPerform)
    end
end



function  CWarrior:OnActionEnd()
    self:SetBoutArgs("acntion_end",1)
    local mFunction = self:GetFunction("OnActionEnd")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnActionEnd")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
end

function CWarrior:OnAddBuffHandle(oBuff)
    local mFunction = self:GetFunction("OnAddBuffHandle")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oBuff)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnAddBuffHandle")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oBuff)
    end
end

function CWarrior:OnAttacked(oAttack,oPerform,iDamage)
    local mFunction = self:GetFunction("OnAttacked")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oAttack,oPerform,iDamage)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnAttacked")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oAttack,oPerform,iDamage)
    end
    self:AddBoutArgs("attacked_cnt",1)
end

function CWarrior:BeforeCommand()
    local mFunction = self:GetFunction("BeforeCommand")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"BeforeCommand")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
end

function CWarrior:OnDead(mArgs)
    mArgs = mArgs or {}
    local mFunction = self:GetFunction("OnDead")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,mArgs)
    end

    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnDead")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,mArgs)
    end
    if self:IsDead() then
        self.m_oBuffMgr:OnDead()
        oCamp:OndDead(self)
    end
end

function CWarrior:OnCure(iHP,oVictim)
    local mFunction = self:GetFunction("OnCure")
    for _,fCallback in pairs(mFunction) do
        iHP = iHP + fCallback(self,iHP,oVictim)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnCure")
    for _,fCallback in pairs(mFunction) do
        iHP = iHP + fCallback(self,iHP,oVictim)
    end
    return iHP
end


function CWarrior:OnModifyHp(iHP,mArgs)
    local mFunction = self:GetFunction("OnModifyHp")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,iHP,mArgs)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnModifyHp")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,iHP,mArgs)
    end
end

function CWarrior:OnReceivedDamage(oAttack,oPerform,iDamage)
    local mFunction = self:GetFunction("OnReceivedDamage")
    for _,fCallback in pairs(mFunction) do
        iDamage = iDamage + fCallback(self,oAttack,oPerform,iDamage)
    end

    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnReceivedDamage")
    for _,fCallback in pairs(mFunction) do
        iDamage = iDamage + fCallback(self,oAttack,oPerform,iDamage)
    end

    return iDamage
end

function CWarrior:OnPerformTarget(oVictim,mTarget,oPerform)
    local mFunction = self:GetFunction("OnPerformTarget")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oVictim,mTarget,oPerform)
    end

    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnPerformTarget")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oVictim,mTarget,oPerform)
    end
end


function CWarrior:OnChooseAITarget(oPerform,wid)
    local iWid = wid

    local mFunction = self:GetFunction("OnChooseAITarget")
    for _,fCallback in pairs(mFunction) do
        iWid = fCallback(self,oPerform,wid)
    end

    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnChooseAITarget")
    for _,fCallback in pairs(mFunction) do
        iWid = fCallback(self,oPerform,wid)
    end
    return iWid
end

function CWarrior:OnReplacePartner()
    self.m_oBuffMgr:OnReplacePartner(self)
    local mFunction = self:GetFunction("OnReplacePartner")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
    local oCamp = self:GetCamp()
    local mFunction = self:GetCampFunction(oCamp,"OnReplacePartner")
    for _,fCallback in pairs(mFunction) do
        fCallback(self)
    end
end


function CWarrior:GetAutoSkill()
    return 0
end

function CWarrior:SetAutoSkill(iActionSkill,bRefresh)
    self:SetData("auto_skill",iActionSkill)
    local oWar = self:GetWar()
    if bRefresh then
        if self:IsPlayer() then
            self:AutoSkillStatusChange()
        else
            local iOwner = self:GetData("owner")
            local oPlayer = oWar:GetWarrior(iOwner)
            if not oPlayer or not oPlayer:IsPlayer() then
                return
            end
            oPlayer:AutoSkillStatusChange(self)
        end
    end
end

--选取自动技能规则
function CWarrior:ChooseSkillAuto()
    local oWar = self:GetWar()
    local iWid = self:GetWid()
    local iAutoSkill = 0
    local mCmds = oWar:GetBoutCmd(iWid)
    if mCmds then
        if not mCmds.data then
        end
        local mData = mCmds.data or {}
        iAutoSkill = mData.skill_id or 0
    end
    if oWar.m_oBoutStatus:Get() == gamedefines.WAR_BOUT_STATUS.OPERATE then
        if iAutoSkill ~= 0 then
            return iAutoSkill
        end
    end
    iAutoSkill = self:Query("action_skill",0)
    if iAutoSkill ~= 0 then
        return iAutoSkill
    end
    iAutoSkill = self:GetData("auto_skill",0)
    if iAutoSkill ~= 0 then
        return iAutoSkill
    end
    iAutoSkill = self:GetNormalAttackSkillId()
    return iAutoSkill
end

function CWarrior:IsAwake()
    if self:GetData("awake") then
        return true
    end
    return false
end

function CWarrior:IsCurrentAction()
    local oWar = self:GetWar()
    return oWar.m_NowAction == self:GetWid()
end

function CWarrior:IsAction()
    if self.m_bAction then
        return true
    end
    return false
end

function CWarrior:AttackBack(oAttack,oPerform)
    local mFunction = self:GetFunction("AttackBack")
    for _,fCallback in pairs(mFunction) do
        fCallback(self,oAttack,oPerform)
    end
end

function CWarrior:OnAttackBack(oAttack)
    local mAttackWid = self:QueryBoutArgs("enemy_float_attack",{})
    for iPos,iAttackWid in ipairs(mAttackWid) do
        if iAttackWid == oAttack:GetWid() then
            table.remove(mAttackWid,iPos)
            self:SetBoutArgs("enemy_float_attack")
            break
        end
    end
end

function CWarrior:OnAIChoosePerform(oPerfrom)
    local mFunction = self:GetFunction("OnAIChoosePerform")
    for _,fCallback in pairs(mFunction) do
        oPerfrom = fCallback(self,oPerfrom)
    end
    return oPerfrom
end


function CWarrior:IsDoubleAttack(oLastAttack,oAttack)
    local iLastSort = oLastAttack:QueryBoutArgs("action_sort",0)
    local iSort = oAttack:QueryBoutArgs("action_sort",0)
    local iOwnSort = self:QueryBoutArgs("action_sort",0)
    --相邻
    if iSort - iLastSort ~= 1 then
        return false
    end
    --不能是下一个
    if iOwnSort - iSort == 1 then
        return false
    end
    --没有浮空资源
    if not self:GetData("double_attack_suspend") then
        return false
    end
    return true
end

--攻击者和浮空者，不能士顺序出手
function CWarrior:ValidAttackFloat()
    local oWar = self:GetWar()
    local mAttackWid = self:QueryBoutArgs("enemy_float_attack",{})
    local iOwnSort = self:QueryBoutArgs("action_sort",0)
    local iLastSort = 0
    local iSort = 0
    for iPos = 1,#mAttackWid-1 do
        local iLastAttackWid = mAttackWid[iPos] or 0
        local iAttackWid = mAttackWid[iPos+1] or 0
        local oLastAttack = oWar:GetWarrior(iLastAttackWid)
        local oAttack = oWar:GetWarrior(iAttackWid)
        if not oAttack or not oLastAttack then
            return false
        end
        iLastSort = oLastAttack:QueryBoutArgs("action_sort",0)
        iSort = oAttack:QueryBoutArgs("action_sort",0)
        if iSort - iLastSort ~= 1 then
            return true
        end
    end
    if iOwnSort - iSort ~= 1 then
        return true
    end
    return false
end

function CWarrior:CheckAttackFloat()
    local mAttackWid = self:QueryBoutArgs("enemy_float_attack",{})
    if #mAttackWid < 2 then
        return
    end
    if not self:ValidAttackFloat() then
        return
    end
    local iWid = self:GetWid()
    local oWar = self:GetWar()
    local mFloat = oWar:QueryBoutArgs("attack_float",{})
    local mFloatAttack = {}
    local mAttackedInfo = {}
    local mAttackedCnt = self:QueryBoutArgs("enemy_attack_cnt",{})
    local iOwnSort = self:QueryBoutArgs("action_sort",0)
    local iTotalSec = 0
    for iPos = 1,#mAttackWid-1 do
        local iLastAttackWid = mAttackWid[iPos] or 0
        local iAttackWid = mAttackWid[iPos+1] or 0
        local oLastAttack = oWar:GetWarrior(iLastAttackWid)
        local oAttack = oWar:GetWarrior(iAttackWid)
        if not oAttack or not oLastAttack then
            return
        end
        if self:IsDoubleAttack(oLastAttack,oAttack) then
            for _,iEnemyWid in ipairs({iLastAttackWid,iAttackWid}) do
                local iCnt = mAttackedCnt[iEnemyWid] or 1
                if not mFloatAttack[iEnemyWid] then
                    table.insert(mAttackedInfo,{
                        attack_id = iEnemyWid,
                        attack_cnt = iCnt,
                    })
                end
                mFloatAttack[iEnemyWid] = true
            end
            mFloat[iWid] = mAttackedInfo
            oWar:SetBoutArgs("attack_float",mFloat)
            --浮空时间
            local mTime = res["warfloattime"] or {}
            local iLastPerform = oLastAttack:GetBoutCmdSkill()
            local iPerform = oAttack:GetBoutCmdSkill()
            local mData = mTime[iLastPerform] or {}
            local iSecs = mData[iPerform] or 0
            iSecs = math.floor(iSecs * 1000)
            iTotalSec = iTotalSec + iSecs
        end
    end
    if iTotalSec > 0 then
        oWar:AddAnimationTime(iSecs,{attack_float=1,})
    end
end

function CWarrior:IsAttackBack()
    if self:QueryBoutArgs("attack_back") then
        return true
    end
    return false
end

function CWarrior:ValidAction()
    if self:IsDead() then
        return false
    end
    if self:HasKey("disable") then
        return false
    end
    return true
end




--连击,浮空信息
function CWarrior:RecordFloatAttack(oAttack)
    local oWar = self:GetWar()
    if oAttack:GetCampId() == self:GetCampId() then
        return
    end
    local iAttackWid = oAttack:GetWid()
    local mAttackWid = self:QueryBoutArgs("enemy_float_attack",{})
    --攻击时被攻击者过滤
    if self:IsAttackBack() then
        return
    end
    --反击时,攻击者过滤
    if oAttack:IsAttackBack() then
        return
    end
    if not oAttack:IsCurrentAction() then
        return
    end
    if not table_in_list(mAttackWid,iAttackWid) then
        table.insert(mAttackWid,iAttackWid)
        self:SetBoutArgs("enemy_float_attack",mAttackWid)
    end

    --被攻击次数
    local mAttackCnt = self:QueryBoutArgs("enemy_attack_cnt",{})
    if not mAttackCnt[iAttackWid] then
        mAttackCnt[iAttackWid] = 0
    end
    mAttackCnt[iAttackWid] = mAttackCnt[iAttackWid] + 1
    self:SetBoutArgs("enemy_attack_cnt",mAttackCnt)
end

function CWarrior:ValidAttackBack(oAttack)
    if oAttack:IsDead() then
        return false
    end
    if not self:ValidAction() then
        return false
    end
    if oAttack:IsFriend(self) then
        return false
    end
    if oAttack:GetWid() == self:GetWid() then
        return false
    end
    return true
end

function CWarrior:GetBoutCmdSkill()
    local oWar = self:GetWar()
    local iWid = self:GetWid()
    local mCmds = oWar:GetBoutCmd(iWid) or {}
    local mData = mCmds.data or {}
    local iSkill = mData.skill_id
    return iSkill
end

--怒气技能
function CWarrior:GetSPSkill()
    local mPerform = self:GetPerformList()
    for _,iPerform in pairs(mPerform) do
        local oPerform = self:GetPerform(iPerform)
        if oPerform and oPerform:IsSp() then
            return oPerform
        end
    end
end

function CWarrior:SetActionCmd(mCmd)
    self:SetBoutArgs("action_cmd",mCmd)
end

function CWarrior:GetActionCmd()
    return self:QueryBoutArgs("action_cmd")
end


function CWarrior:AutoCommand()
    if not self:GetActionCmd() then
        local iAIType = self:GetAIType()
        local oAIObj = loadai.GetAI(iAIType)
        if oAIObj then
            oAIObj:Command(self)
        end
    end
end


function CWarrior:GetAutoFightTime()
    return 0
end

function CWarrior:BanCampPassiveSkill(iNo)
    return false
end

function CWarrior:GetCampFunction(oCamp,sName)
    local mFunction =  oCamp:GetFunction(sName)
    local mCallback = {}
    local oWar = self:GetWar()
    for iNo,fCallback in pairs(mFunction) do
        local iWid = iNo%100
        local iSkill = math.floor(iNo/100)
        local oWner = oWar:GetWarrior(iWid)
        if oWner and not oWner:BanCampPassiveSkill(iSkill) then
            mCallback[iNo] = fCallback
        end
    end
    return mCallback
end