--import module

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"
local extend = require "base.extend"

local gamedefines = import(lualib_path("public.gamedefines"))
local buffmgr = import(service_path("buffmgr"))
local pfload = import(service_path("perform.pfload"))

function NewCPerform(...)
    local o = CPerform:New(...)
    return o
end

CPerform = {}
CPerform.__index = CPerform
inherit(CPerform, logic_base_cls())

function CPerform:New(id)
    local o = super(CPerform).New(self)
    o.m_ID = id
    o.m_iLevel = 1
    o.m_mExtData  = {}
    return o
end

function CPerform:CampFuncNo(wid)
    return self.m_ID * 100 + wid
end

function CPerform:GetPerformData()
    local res = require "base.res"
    local mData = res["daobiao"]["perform"][self.m_ID]
    assert(mData,string.format("GetPerformData err %d",self.m_ID))
    return mData
end

--等级效果数据
function CPerform:GetSkillData()
    local res = require "base.res"
    local mData = res["daobiao"]["skill"][self.m_ID]
    assert(mData,string.format("GetSkillData err:%d",self.m_ID))
    mData = mData[self.m_iLevel] or {}
    assert(mData,string.format("GetSkillData err:%d %d",self.m_ID,self.m_iLevel))
    return mData
end

function CPerform:GetPerformRatio(iMaxCnt)
    iMaxCnt = math.max(iMaxCnt,1)
    iMaxCnt = math.min(iMaxCnt,12)
    local res = require "base.res"
    local mData = res["daobiao"]["performratio"][iMaxCnt]
    return mData["damageRatio"]
end

--等级效果环境变量参数
function CPerform:GetSkillArgsEnv()
    local mData = self:GetSkillData()
    local mArgs = {}
    local sArgs = mData["args"]
    if not sArgs or  sArgs == "" then
        return mArgs
    end
    local mEnv = {}
    mArgs = formula_string(sArgs,mEnv)
    return mArgs
end

function CPerform:CanPerform()
    local mData = self:GetPerformData()
    if mData["activeSkill"] == 1 then
        return true
    end
    return false
end

--被动技能调用
function CPerform:CalWarrior(oWarrior,oPerformMgr)
    -- body
end

function CPerform:SetLevel(iLevel)
    self.m_iLevel = iLevel
end

function CPerform:Level()
    return self.m_iLevel or 1
end

--法术id
function CPerform:Type()
    return self.m_ID
end

function CPerform:Name()
    local mData = self:GetPerformData()
    return mData["name"]
end

function CPerform:ShowPerfrom(oAction,mArg)
    mArg = mArg or {}
    local oWar = oAction:GetWar()
    local iSkill = mArg["skill"] or self.m_ID
    local oAttackPerorm = mArg["perform"]
    if oAttackPerorm then
        if oAttackPerorm:GetData("PerformAttackCnt") ~= 1 then
            return
        end
        if oAttackPerorm:GetData("DoAttackCnt") and oAttackPerorm:GetData("DoAttackCnt") ~= 1 then
            return
        end
    end
    if mArg["bout"] then
        local sKey = string.format("Show_Perform_%d",iSkill)
        if oAction:QueryBoutArgs(sKey) then
            return
        end
        oAction:SetBoutArgs(sKey,1)
    end
    local mNet = {skill = iSkill,}
    mNet["wid"] = mArg["wid"] or oAction:GetWid()
    mNet["type"] = mArg["type"] or pfload.GetShowPerfromType(iSkill)
    oWar:SendAll("GS2CShowWarSkill",mNet)
end

--作用目标类型,1:己方,2:敌方
function CPerform:TargetType()
    local mData = self:GetPerformData()
    local iType = mData["targetType"]
    return iType
end

--作用目标状态,死亡和存活
function CPerform:TargetStatus()
    local mData = self:GetPerformData()
    local iStatus = mData["useTargetStatus"]
    if iStatus == 1 then
        return gamedefines.WAR_WARRIOR_STATUS.ALIVE
    elseif iStatus == 2 then
        return gamedefines.WAR_WARRIOR_STATUS.DEAD
    end
end

--行动方式,1:攻击,2:封印,3:辅助,4:治疗
function CPerform:ActionType()
    local mData = self:GetPerformData()
    local iType = mData["skillActionType"] or 1
    return iType % 10
end

function CPerform:GroupAttackType()
    local mData = self:GetPerformData()
    local iType = mData["skillGroupType"] or 0
    return iType % 10
end

function CPerform:IsGroupAttack()
    local iType = self:GroupAttackType()
    if iType == 1 then
        return false
    end
    return true
end

--是否是近身攻击
function CPerform:IsNearAction()
    local mData = self:GetPerformData()
    local iNearAction = mData["effectAction"]
    if iNearAction == 1 then
        return true
    end
    return false
end

--特效编号
function CPerform:PerformMagicID()
    local mData = self:GetPerformData()
    local iEfffectID = mData["effectType"]
    if iEfffectID == 0 then
        return self.m_ID
    end
    return iEfffectID
end


--招式时间
function CPerform:PerformMagicTime(idx)
    idx = idx or 1
    local mData = self:GetPerformData()
    local mMagicTime = mData["effectTime"] or {}
    local iCnt = #mMagicTime
    if idx >= iCnt then
        return mMagicTime[iCnt]
    else
        return mMagicTime[idx]
    end
end

--法术修正时间
function CPerform:PerformCorrectMagicTime(idx)
    idx = idx or 1
    local mData = self:GetPerformData()
    local mMagicTime = mData["corrent_effectTime"] or {}
    local iCnt = #mMagicTime
    if idx >= iCnt then
        return mMagicTime[iCnt]
    else
        return mMagicTime[idx]
    end
end

--特效编号段
function CPerform:SpecialPerformMagicID(idx)
    idx = idx or 1
    local mData = self:GetPerformData()
    local mMagicTime = mData["effectTime"] or {}
    local iCnt = #mMagicTime
    if idx >= iCnt then
        return iCnt
    else
        return idx
    end
end

--归位时间
function CPerform:GoBackTime()
    local mData = self:GetPerformData()
    return mData["go_back_time"] or 0
end

--命中率
function CPerform:HitRatio()
    local mData = self:GetPerformData()
    return mData["hitRate"]
end

function CPerform:SpeedRatio()
    local mData = self:GetPerformData()
    local iRatio = mData["speedRatio"] or 120
    return iRatio
end

--技能加速度
function CPerform:PerformTempAddSpeed(oAction)
    return 0
end

function CPerform:RangeEnv()
    return {}
end

--作用人数
function CPerform:Range()
    local mData = self:GetPerformData()
    local sRange = mData["range"]
    local mRange = mData["range"] or {}
    local sRange
    for _,mData in pairs(mRange) do
        local iLevel = mData["level"]
        if self:Level() >= iLevel then
            sRange = mData["range"]
        end
    end
    if not sRange then
        return 1
    end
    local iRange = tonumber(sRange)
    if iRange then
        return iRange
    else
        local mEnv = self:RangeEnv()
        local iRange = formula_string(sRange,mEnv)
        return iRange
    end
    return 1
end

function CPerform:DamageRatioEnv(oAttack,oVictim)
    return {}
end

--效率
function CPerform:DamageRatio(oAttack,oVictim)
    local mSkillData = self:GetSkillData()
    local sDamageRatio = mSkillData["damage_ratio"] or ""
    local mEnv = self:DamageRatioEnv(oAttack,oVictim)
    local mDamageRatio = formula_string(sDamageRatio,mEnv)
    local iAttackCnt = self:GetData("PerformAttackCnt",1)
    local iDamageRatio
    if iAttackCnt < #mDamageRatio then
        iDamageRatio = mDamageRatio[iAttackCnt]
    else
        iDamageRatio = mDamageRatio[#mDamageRatio]
    end
    if not iDamageRatio then
        return 100
    end
    return iDamageRatio
end

function CPerform:ExtArg()
    local mData = self:GetPerformData()
    local sExtArgs = mData["extArgs"]
    return sExtArgs
end

function CPerform:ValidCast(oAttack,oVictim)
    local mTarget = self:TargetList(oAttack)
    if not oVictim then
        record.error(string.format("ValidCast err:%d",self.m_ID))
        return mTarget[math.random(#mTarget)]
    end
    for _,w in pairs(mTarget) do
        if w:GetWid() == oVictim:GetWid() then
            return w
        end
    end
    if #mTarget <= 0 then
        return
    end
    return mTarget[math.random(#mTarget)]
end

--检查释放条件,主要判断气血等条件
function CPerform:SelfValidCast(oAttack,oVictim)
    return true
end

function CPerform:IsSp()
    local mData = self:GetPerformData()
    local iSP = mData["sp"]
    if iSP and iSP > 0 then
        return true
    end
    return false
end

function CPerform:GetResumeSP()
    local mData = self:GetPerformData()
    return mData["sp"] or 0
end

--消耗判断
function CPerform:ValidResume(oAttack,oVictim)
    local iHP = 0
    local mData = self:GetPerformData()
    local iSP = mData["sp"]
    local oWar = oAttack:GetWar()
    if not oWar then
        return
    end
    local iCamp = oAttack:GetCampId()
    local oCamp = oWar:GetCamp(iCamp)
    if oAttack:IsNpc() or oAttack:GetData("IgnoreSpSkill") then
        iSP = 0
    end
    if not oWar:ValidSP(iCamp,iSP) then
        return
    end
    return {0,iSP}
end

function CPerform:ValidUse(oAttack,oVictim)
    return true
end

function CPerform:DoResume(oAttack,mResume)
    local  iHP,iSP = table.unpack(mResume)
    local oWar = oAttack:GetWar()
    if iHP > 0 then
        oAttack:SubHp(iHP)
    end
    local oCamp = oAttack:GetCamp()
    local iRatio = oCamp:Query("no_sp_ratio",0)
    local wid = oCamp:Query("no_sp_attack",0)
    local oWarrior = oWar:GetWarrior(wid)
    if oWarrior and oWarrior:BanPassiveSkill() ~= 2 then
        if iSP >0 and in_random(iRatio,10000) then
            iSP = 0
            if oWarrior and oWarrior:IsAlive() then
                self:ShowPerfrom(oAttack,{skill = 40503,wid = oCamp:Query("no_sp_attack",0)})
            end
        end
    end
    if iSP and iSP > 0 then
        local iCamp = oAttack:GetCampId()
        if oWar then
            oWar:AddSP(iCamp,-iSP)
        end
    end
end

function CPerform:TargetList(oAttack)
    local mTarget = {}
    if self:TargetType() == 1 then
        mTarget = oAttack:GetFriendList(true)
    elseif self:TargetType() == 2 then
        mTarget = oAttack:GetEnemyList(true)
    elseif self:TargetType() == 3 then
        table.insert(mTarget,oAttack)
    elseif self:TargetType() == 4 then
        local lVictim = oAttack:GetFriendList(true)
        for _,w in pairs(lVictim) do
            if w:GetWid() ~= oAttack:GetWid() then
                table.insert(mTarget,w)
            end
        end
    else
        local oWar = oAttack:GetWar()
        local mWarrior = oWar:GetWarriorMap()
        for k,_ in pairs(mWarrior) do
            local w = oWar:GetWarrior(k)
            if w and oAttack:GetWid() ~= k then
                table.insert(mTarget,w)
            end
        end
    end
    local mRet = {}
    local iStatus = self:TargetStatus()
    for _,oTarget in pairs(mTarget) do
        if iStatus == gamedefines.WAR_WARRIOR_STATUS.ALIVE then
            if oTarget:IsAlive() and oTarget:GetHp() > 0 then
                table.insert(mRet,oTarget)
            end
        elseif iStatus == gamedefines.WAR_WARRIOR_STATUS.DEAD then
            if oTarget:IsDead() and oTarget:GetHp() <= 0 then
                table.insert(mRet,oTarget)
            end
        else
            table.insert(mRet,oTarget)
        end
    end
    return mRet
end

function CPerform:PerformTarget(oAttack,oVictim)
    local iCnt = self:Range()
    if self.MaxRange then
        iCnt = self:MaxRange(oAttack,oVictim)
    end
    local iRatio = oAttack:Query("perform_range_ratio",0)
    if in_random(iRatio,10000) then
        iCnt = iCnt + 1
        self:ShowPerfrom(oAttack,{skill = 3206})
    end
    local mTarget = {oVictim.m_iWid,}
    if iCnt <= 1 then
        oAttack:OnPerformTarget(oVictim,mTarget,self)
        self:SetData("PerformTarget",mTarget)
        return mTarget
    end
    local m = self:TargetList(oAttack)
    for _,w in pairs(m) do
        if w:GetWid() ~= oVictim:GetWid() and #mTarget < iCnt then
            table.insert(mTarget,w:GetWid())
        end
        if #mTarget >= iCnt then
            break
        end
    end
    oAttack:OnPerformTarget(oVictim,mTarget,self)
    self:SetData("PerformTarget",mTarget)

    return mTarget
end

--AI选择目标
function CPerform:ChooseAITarget(oAttack,mArgs)
    mArgs = mArgs or {}
    local mRet = self:TargetList(oAttack)
    if #mRet <= 0 then
        return
    end
    mRet = extend.Random.sample_list(mRet,#mRet)
    local iX = oAttack:GetData("ai",0)
    if iX == 0 or  not oAttack:Random(iX,100) then
        return mRet[1]:GetWid()
    end
    if mArgs["selectfun"] then
        return mArgs["selectfun"](mRet):GetWid()
    end
    local iType,iArg = self:AISelectTargetType()
    local mTarget = {}
    if not iType or iType == gamedefines.AI_CHOOSE_TARGET.NULL then
        mTarget = mRet
    elseif iType == gamedefines.AI_CHOOSE_TARGET.LIKE_BUFF then
        for _,o in ipairs(mRet) do
            if o.m_oBuffMgr:HasBuff(iArg) then
                table.insert(mTarget,o)
            end
        end
    elseif iType == gamedefines.AI_CHOOSE_TARGET.NO_BUFF then
        for _,o in ipairs(mRet) do
            if not o.m_oBuffMgr:HasBuff(iArg) then
                table.insert(mTarget,o)
            end
        end
    elseif iType == gamedefines.AI_CHOOSE_TARGET.LOW_HP then
        table.sort(mRet,function (o1,o2)
                return o1:GetHpRatio() < o2:GetHpRatio()
            end)
        table.insert(mTarget,mRet[1])
    elseif iType == gamedefines.AI_CHOOSE_TARGET.HIGH_HP then
        table.sort(mRet,function (o1,o2)
                return o1:GetHpRatio() > o2:GetHpRatio()
            end)

        mTarget = {mRet[1],}
    elseif iType == gamedefines.AI_CHOOSE_TARGET.LOW_HP2 then
        local mNewVictim = {}
        for _,o in ipairs(mRet) do
            if oAttack:GetHpRatio() <= o:GetHpRatio() then
                table.insert(mNewVictim,o)
            end
        end
        if #mNewVictim > 0 then
            table.sort(mNewVictim,function (o1,o2)
                    return o1:GetHpRatio() < o2:GetHpRatio()
                end)
            mTarget = {mNewVictim[1],}
        end
    elseif iType == gamedefines.AI_CHOOSE_TARGET.CALL_SUMMON then
        for _,o in ipairs(mRet) do
            if o:IsCallNpc() then
                table.insert(mTarget,o)
            end
        end
    end
    if #mTarget == 0 then
        mTarget = mRet
    end
    local iWid = mTarget[math.random(#mTarget)]:GetWid()
    return iWid
end

function CPerform:AISelectTargetType()
    local mData = self:GetSkillData()
    if not mData["ai_target"] then
        return 0,0
    end
    for k,v in pairs(mData["ai_target"]) do
        return k,v
    end
    return 0,0
end


function CPerform:AiCanPerform(oAction)
    local mData = self:GetPerformData()
    local mArgs = mData["ai_canperform"]
    if not mArgs then
        return true
    end
    if mArgs["callsum"] then
        for _,o in ipairs(oAction:GetFriendList()) do
            if o:IsCallNpc() then
                return false
            end
        end
    end
    if mArgs["allbuff"] then
        local iBuff = mArgs["allbuff"]
        local bFlag = false
        for _,o in ipairs(oAction:GetFriendList()) do
            if not o.m_oBuffMgr:HasBuff(iBuff) then
                bFlag = true
                break
            end
        end
        if not bFlag then
            return false
        end
    end
    return true
end

function CPerform:Perform(oAttack,lVictim,mArgs)
    mArgs = mArgs or {}
    local oWar = oAttack:GetWar()
    local iWarId = oWar:GetWarId()
    local iSkill = self.m_ID
    local iWid = oAttack:GetWid()
    local magic_id = mArgs["magic_id"] or 1
    local old = self:GetData("pf_arg")
    self:SetData("pf_arg",mArgs)
    local lSelectWid = {}
    for _,oVictim in ipairs(lVictim) do
        table.insert(lSelectWid,oVictim:GetWid())
    end
    oAttack:SendAll("GS2CWarSkill", {
        war_id = oAttack:GetWarId(),
        action_wlist = {oAttack:GetWid(),},
        select_wlist = lSelectWid,
        skill_id = iSkill,
        magic_id = magic_id,
    })
    local iTime = self:PerformMagicTime(magic_id)
    oWar:AddAnimationTime(iTime,{skill=self:Type(),mgi=magic_id,})

    local iRatio = self:GetPerformRatio(#lVictim)
    local mFunction = oAttack:GetFunction("AfterShowWarSkill")
    for _,fCallback in pairs(mFunction) do
        fCallback(oAttack,lVictim,self)
    end
    local mNewVictim = {}
    for _,iVictimWid in ipairs(lSelectWid) do
        local oVictim = oWar:GetWarrior(iVictimWid)
        if oVictim then
            local iAttackCnt = self:GetData("PerformAttackCnt",0)
            self:SetData("PerformAttackCnt",iAttackCnt+1)
            self:TruePerform(oAttack,oVictim,iRatio)
            local oNewVictim = oWar:GetWarrior(iVictimWid)
            local oNewAttack = oWar:GetWarrior(iWid)
            if oNewVictim and not oNewVictim:IsDead() and oNewAttack and not oNewAttack:IsDead() then
                oVictim:OnPerformed(oAttack,self)
                table.insert(mNewVictim,oVictim)
            end
        end
    end
    
    self:SetData("PerformAttackCnt",nil)
    local oNewAttack = oWar:GetWarrior(iWid)
    if oNewAttack and not oNewAttack:IsDead() then
        oAttack:OnPerform(mNewVictim,self)
        oAttack.m_oBuffMgr:CheckAttackBuff(oAttack)
        self:Effect_Condition_For_Attack(oAttack)
        if self:IsCD(oAttack) then
            self:SetCD(oAttack)
        end
        self:SetAICD(oAttack)
    end
    oAttack:SetBoutArgs("perform_target",nil)
    oWar:SendAll("GS2CWarGoback", {
        war_id = iWarId,
        action_wid = iWid,
    })
    if oNewAttack then
        self:AttackBack(oNewAttack,mNewVictim)
        oAttack:OnAfterGoback(mNewVictim,self)
    end
    self:SetData("pf_arg",old)
end


function CPerform:RandomPerform(oAttack,lVictim,iAttackCnt,mArgs)
    mArgs = mArgs or {}
    local mNewVictim = {}
    local oActionMgr = global.oActionMgr
    local oWar = oAttack:GetWar()
    local iWarId = oWar:GetWarId()
    local iWid = oAttack:GetWid()
    local iMagicIdx = 1
    local old = self:GetData("pf_arg")
    self:SetData("pf_arg",mArgs)
    local fPerfrom= mArgs["random_perform_action"] or function (oAttack,oVictim,oPerform,iRatio,iMagicIdx)
        oActionMgr:DoPerform(oAttack,oVictim,oPerform,100,iMagicIdx)
    end
    self:SetData("PerformAttackMaxCnt",iAttackCnt)
    local iTotalCnt = 0
    for i=1,iAttackCnt do
        if oAttack:IsDead() then
            break
        end
        local oVictim = lVictim[i]
        if not oVictim then
            local mEnemy = oAttack:GetEnemyList(false,true)
            if #mEnemy <= 0 then
                break
            end
            oVictim = mEnemy[1]
        end
        if not oVictim or oVictim:IsDead() then
            break
        end
        iMagicIdx = i
        iTotalCnt = i
        fPerfrom(oAttack,oVictim,self,100,iMagicIdx)

        if oVictim and not oVictim:IsDead() and oAttack and not oAttack:IsDead() then
            table.insert(mNewVictim,oVictim)
        end
    end

    self:SetData("add_perform_cnt",nil)
    self:SetData("PerformAttackCnt",nil)
    
    if oAttack and not oAttack:IsDead() then
        oAttack:OnPerform(mNewVictim,self)
        self:Effect_Condition_For_Attack(oAttack)
        oAttack.m_oBuffMgr:CheckAttackBuff(oAttack)
        local iBuffID = 1010
        local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oAttack.m_oBuffMgr:RemoveBuff(oBuff)
        end
        if self:IsCD(oAttack) then
            self:SetCD(oAttack)
        end
        self:SetAICD(oAttack)
    end

    oWar:SendAll("GS2CWarGoback", {
        war_id = iWarId,
        action_wid = iWid,
    })

    local fAdjustMagicTime = mArgs["random_perform_adjusttime"] or function (oWar,iAttackCnt)
        local iCorrectTime = self:PerformCorrectMagicTime(iAttackCnt) or 0
        local iMagicTime = self:PerformMagicTime(iAttackCnt) or 0
        local iAddTime = math.max(iCorrectTime-iMagicTime,0)
        if iAddTime > 0 then
            oWar:AddAnimationTime(iAddTime,{skill=self:Type(),mgi=1,ext="xiuzheng"})
        end
    end

    fAdjustMagicTime(oWar,iTotalCnt)
    if oAttack then
        self:AttackBack(oAttack,mNewVictim)
        oAttack:OnAfterGoback(mNewVictim,self)
    end
    self:SetData("pf_arg",old)
    
end




function CPerform:MultiPerform(oAttack,lVictim)
    local oWar = oAttack:GetWar()
    local iSkill = self.m_ID
    local iRatio = self:GetPerformRatio(#lVictim)
    local iCnt = 1
    local iWid = oAttack:GetWid()
    local iWarId = oWar:GetWarId()


    local mNewVictim = {}
    for _, oVictim in ipairs(lVictim) do
        local iVictimWid = oVictim:GetWid()
        oAttack:SendAll("GS2CWarSkill", {
            war_id = oAttack:GetWarId(),
            action_wlist = {oAttack:GetWid(),},
            select_wlist = {oVictim:GetWid()},
            skill_id = iSkill,
            magic_id = self:SpecialPerformMagicID(iCnt),
        })
        local iTime = self:PerformMagicTime()
        oWar:AddAnimationTime(iTime,{skill=self:Type(),mgi=1})
        self:SetData("PerformAttackCnt",1)
        local iAttackCnt = self:GetData("PerformAttackCnt",0)
        self:SetData("PerformAttackCnt",iAttackCnt+1)
        self:TruePerform(oAttack,oVictim,iRatio)
        local oNewVictim = oWar:GetWarrior(iVictimWid)
        local oNewAttack = oWar:GetWarrior(iWid)
        if oNewVictim and not oNewVictim:IsDead() and oNewAttack then
            oVictim:OnPerformed(oAttack,self)
            table.insert(mNewVictim,oVictim)
        end
        if not oNewAttack then
            break
        end
        iCnt = iCnt + 1
    end
    self:SetData("PerformAttackCnt",nil)
    local oNewAttack = oWar:GetWarrior(iWid)
    if oNewAttack and not oNewAttack:IsDead() then
        oAttack:OnPerform(mNewVictim,self)
        oAttack.m_oBuffMgr:CheckAttackBuff(oAttack)
        self:Effect_Condition_For_Attack(oAttack)
        if self:IsCD(oAttack) then
            self:SetCD(oAttack)
        end
        self:SetAICD(oAttack)
    end
    oWar:SendAll("GS2CWarGoback", {
        war_id = iWarId,
        action_wid = iAttackWid,
    })
    if self:IsNearAction() then
        local iGoBackTime = self:GoBackTime()
        oWar:AddAnimationTime(iGoBackTime,{skill=self:Type(),goback=1,})
    end
    --反击
    if oNewAttack then
        self:AttackBack(oAttack,mNewVictim)
        oAttack:OnAfterGoback(mNewVictim,self)
    end
end

function CPerform:CalculateHP(oAttack,oVictim)
    return 0
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    local oWar = oAttack:GetWar()
    local iWid = oAttack:GetWid()
    local iVictimWid = oVictim:GetWid()
    if self:ActionType() == gamedefines.WAR_ACTION_TYPE.SEAL then
       oActionMgr:DoSealAction(oAttack,oVictim,self,20,80)
       return
    end
    if self:ActionType() == gamedefines.WAR_ACTION_TYPE.CURE then
        local iHP = self:CalculateHP(oAttack,oVictim)
        local mArgs = {
            attack_wid = oAttack:GetWid(),
            damage_type = 1,
        }
        self:ModifyHp(oVictim,oAttack,iHP,mArgs)
        return
    end
    if not oVictim or oVictim:IsDead() then
        return
    end
    oActionMgr:DoAttack(oAttack,oVictim,self,iDamageRatio)
    
    local oNewVictim = oWar:GetWarrior(iVictimWid)
    local oNewAttack = oWar:GetWarrior(iWid)
    if oNewVictim and not oNewVictim:IsDead() then
        self:Effect_Condition_For_Victim(oNewVictim,oNewAttack)
    end
end

function CPerform:ModifyHp(oVictim,oAttack,iHp,mArgs)
    mArgs = self:PackModifyArg(oVictim,oAttack,iHp,mArgs)
    oVictim:ModifyHp(iHp,mArgs)
end

function CPerform:PackModifyArg(oVictim,oAttack,iHp,mArgs)
    mArgs = mArgs or {}
    local iAttack
    if type(oAttack) == "number" then
        iAttack = oAttack
    else
        iAttack = oAttack:GetWid()
    end
    if not mArgs["attack_wid"] then
        mArgs["attack_wid"] = iAttack
    end
    mArgs["type"] = "perform"
    mArgs["PID"] = self:Type()
    return mArgs
end


function CPerform:Effect_Condition_For_Attack(oAttack,mExArg)
    mExArg = mExArg or {}
    local mData = self:GetSkillData()
    local oWar = oAttack:GetWar()
    local mBuff = mData["attackBuff"] or {}
    local mArgs = {
        level = mExArg["level"] or self:Level(),
        attack = mExArg["attack"] or oAttack:GetWid(),
        buff_bout = mExArg["war_bout"] or oWar.m_iBout,
        parg = mExArg["parg"],
    }
    local oBuffMgr = oAttack.m_oBuffMgr
    for _,mData in pairs(mBuff) do
        local iBuffID = mData["buffid"]
        local iBout = mData["bout"]
        if iBuffID == mExArg["buffid"] then
            iBout = mExArg["bout"] or iBout
        end
        local oBuff = oBuffMgr:AddBuff(iBuffID,iBout,mArgs)
        if oBuff then
            if mExArg["NoSubNow"] then
                oBuff.m_NoSubNowWar = mExArg["NoSubNow"]
            end
            if mExArg["casterstart_falg"] then
                oAttack.m_CheckCasterBoutStartBuff = mExArg["casterstart_falg"]
            end
            if mExArg["casterend_falg"] then
                oAttack.m_CheckCasterBoutEndBuff = mExArg["casterend_falg"]
            end
        end
    end
    local mData = self:GetPerformData()
    mBuff = mData["attackDelBuff"] or {}
    for _,iBuffID in pairs(mBuff) do
        local oBuff = oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuffMgr:RemoveBuff(oBuff)
        end
    end
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack,mExArg)
    if not oVictim or oVictim:IsDead() then
        return
    end
    mExArg = mExArg or {}
    local iAttackWid = 0
    if oAttack then
        iAttackWid = oAttack:GetWid()
    end
    local oWar = oVictim:GetWar()
    local mData = self:GetSkillData()
    local mBuff = mData["victimBuff"] or {}
    local mArgs = {
        level = mExArg["level"] or self:Level(),
        attack = mExArg["attack"] or iAttackWid,
        buff_bout = mExArg["war_bout"] or oWar.m_iBout,
    }

    for _,mData in pairs(mBuff) do
        local iBuffID = mData["buffid"]
        local iBout = mData["bout"]
        if iBuffID == mExArg["buffid"] then
            iBout = mExArg["bout"] or iBout
        end
        local oBuffMgr = oVictim.m_oBuffMgr
        local oBuff = oBuffMgr:AddBuff(iBuffID,iBout,mArgs)
        if oBuff then
            if mExArg["NoSubNow"] then
                oBuff.m_NoSubNowWar = mExArg["NoSubNow"]
            end
            if mExArg["casterstart_falg"] then
                oAttack.m_CheckCasterBoutStartBuff = mExArg["casterstart_falg"]
            end
            if mExArg["casterend_falg"] then
                oAttack.m_CheckCasterBoutEndBuff = mExArg["casterend_falg"]
            end
        end
    end
    local mData = self:GetPerformData()
    mBuff = mData["victimDelBuff"] or {}
    for _,iBuffID in pairs(mBuff) do
        local oBuff = oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuffMgr:RemoveBuff(oBuff)
        end
    end
end

function CPerform:GetData(key,rDefault)
    return self.m_mExtData[key] or rDefault
end

function CPerform:SetData(key, value)
    self.m_mExtData[key] = value
end

function CPerform:IsCD(oAttack)
    local mData = self:GetPerformData()
    local iCDBout = mData["cd"]
    if iCDBout <= 0 then
        return false
    end
    return true
end

function CPerform:SetCD(oAttack)
    local oWar = oAttack:GetWar()
    local iCurBout = oWar.m_iBout
    local mData = self:GetPerformData()
    local iBout = mData["cd"]
    local iRatio = oAttack:Query("no_cd_ratio",0)
    if in_random(iRatio,10000) then
        self:ShowPerfrom(oAttack,{skill = 3207})
        return
    end

    iBout = iBout + 1                                      --BoutEnd减少次数,+1
    self:SetData("CD",iBout)
    self:SetData("CDBout",iBout+iCurBout)
    local mCD = {
        skill_id = self.m_ID,
        bout = iBout,
    }

    local mCD = {}
    table.insert(mCD,{skill_id=self.m_ID,bout=iBout})
     oAttack:Send("GS2CWarSkillCD",{
         war_id = oWar:GetWarId(),
         wid = oAttack:GetWid(),
         skill_cd = mCD,
     })
end

function CPerform:InCD(oAction)
    local iCD = self:GetData("CD",0)
    if  iCD <= 0 then
        return false
    end
    return true
end

function CPerform:CDBout(oAction)
    local iCDBout = self:GetData("CDBout")
    local oWar = oAction:GetWar()
    local iCurBout = oWar.m_iBout
    local iBout = math.max(iCDBout - iCurBout,0)
    return iBout
end


function CPerform:IsAICD(oAttack)
    local mData = self:GetSkillData()
    local iCDBout = mData["ai_cd"] or 0
    if iCDBout <= 0 then
        return false
    end
    return true
end

function CPerform:SetAICD(oAttack)
    if not self:IsAICD(oAttack) then
        return
    end
    if not oAttack:IsRomWarrior() then
        return
    end
    local oWar = oAttack:GetWar()
    local iCurBout = oWar.m_iBout
    local mData = self:GetSkillData()
    local iBout = mData["ai_cd"]
    iBout = iBout + 1
    self:SetData("AICD",iBout)
    self:SetData("AICDBout",iBout+iCurBout)
    local mCD = {
        skill_id = self.m_ID,
        bout = iBout,
    }
end

function CPerform:InAICD(oAction)
    if not oAction:IsRomWarrior() then
        return false
    end
    local iCDBout = self:GetData("AICD",0)
    if iCDBout <= 0 then
        return false
    end
    return true
end

function CPerform:AICDBout(oAction)
    local iCDBout = self:GetData("AICDBout")
    local oWar = oAction:GetWar()
    local iCurBout = oWar.m_iBout
    local iBout = math.max(iCDBout - iCurBout,0)
    return iBout
end


function CPerform:SubCD()
    local iCD = self:GetData("CD",0)
    if iCD > 0 then
        self:SetData("CD",iCD - 1)
    end
    iCD = self:GetData("AICD",0)
    if iCD > 0 then
        self:SetData("AICD",iCD - 1)
    end
end




function CPerform:AttackBack(oAttack,lVictim)
    for _,oVictim in pairs(lVictim) do
        if oVictim:ValidAttackBack(oAttack) then
            oVictim:AttackBack(oAttack)
        end
    end
end

function CPerform:CheckEffectRatio(oAttack,oVictim)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["abnormal_ratio"] or 1000
    local iMaxRatio = mArgs["max_ratio"] or 5000
    local iMinRatio = mArgs["min_ratio"] or 1000
    local iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
    return in_random(iRatio,10000)
end

function CPerform:IsPassiveSkill()
    return false
end

function CPerform:DeadActionShowAttack(oAttack,oVictim,mArgs)
end


CPassivePerform = {}
CPassivePerform.__index = CPassivePerform
inherit(CPassivePerform, CPerform)

function CPassivePerform:New(pfid)
    local o = super(CPassivePerform).New(self,pfid)
    return o
end

function CPassivePerform:CanPerform()
    return false
end

function CPassivePerform:GetPerformData()
    return {}
end

function CPassivePerform:IsPassiveSkill()
    return true
end

