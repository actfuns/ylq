--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

local npcwarrior = import(service_path("npcwarrior"))

function NewActionMgr(...)
    local o = CActionMgr:New(...)
    return o
end

CActionMgr = {}
CActionMgr.__index = CActionMgr
inherit(CActionMgr, logic_base_cls())

function CActionMgr:New()
    local o = super(CActionMgr).New(self)
    return o
end

function CActionMgr:WarSkill(oAttack,lVictim, iSkill)
    oAttack:OnWarSkillStart(lVictim, iSkill)
    local oWar = oAttack:GetWar()
    local iCamp = oAttack:GetCampId()
    local iWid = oAttack:GetWid()
    local oVictim = lVictim[1]
    local oOriginal = oVictim
    local oPerform = oAttack:GetPerform(iSkill)
    if not oPerform then
        return
    end
    if not oPerform:CanPerform() then
        return
    end
    if not oVictim then
        local lVictim = oPerform:TargetList(oAttack)
        if #lVictim > 0 then
            oVictim = lVictim[1]
        end
    else
        --释放目标更正
        local lVictim = oPerform:TargetList(oAttack)
        if not table_in_list(lVictim,oVictim) then
            oVictim = lVictim[1]
        end
    end

    local iTrueSkill
    if not oPerform:ValidUse(oAttack,oVictim) then
        iTrueSkill = oAttack:GetNormalAttackSkillId()
    end
    if oPerform:InCD(oAttack) then
        iTrueSkill = oAttack:GetNormalAttackSkillId()
    end
    local mResume = oPerform:ValidResume(oAttack,oVictim)
    if not mResume then
        iTrueSkill = oAttack:GetNormalAttackSkillId()
    end
    local sName = oAttack:GetName()
    --普攻
  if iTrueSkill then
        iSkill = iTrueSkill
        local oPerform = oAttack:GetPerform(iSkill)
        --普攻，选择集火目标
        local mWarTarget = oWar:GetExtData("war_target",{})
        local iExtTargetWid = mWarTarget[iCamp]
        if iExtTargetWid then
            local iTarget = iExtTargetWid
            oVictim = oWar:GetWarrior(iTarget)
        elseif oOriginal then
            oVictim = oOriginal
        end
        if not oVictim then
            local lVictim = oPerform:TargetList(oAttack)
            oVictim = lVictim[1]
        end
    end

    --如果还没有目标
    if not oVictim then
        if oPerform.OnNoChooseTarget then
            oPerform:OnNoChooseTarget(oAttack)
            return
        else
            iSkill = oAttack:GetNormalAttackSkillId()
            local oPerform = oAttack:GetPerform(iSkill)
            local lVictim = oPerform:TargetList(oAttack)
            oVictim = lVictim[1]
        end
    end

    if not oVictim then
        local lVictim = oPerform:TargetList(oAttack)
        if #lVictim <= 0 then
            return
        end
        local oVictim = lVictim[1]
        record.error(string.format("WarSkill err:%d",iSkill))
    end

    self:Perform(oAttack,oVictim,iSkill)
    local oNewAttack = oWar:GetWarrior(iWid)
    if oNewAttack and oNewAttack:IsNpc() and oAttack:IsSpecialSkill(iSkill) then
        oAttack:ResetSpecialSkillGrid()
    end
end

function CActionMgr:WarEscape(oAction)
    local oWar = oAction:GetWar()
    oAction:SetWarTarget(2,nil)
    oAction:SendAll("GS2CWarEscape", {
        war_id = oAction:GetWarId(),
        action_wid = oAction:GetWid(),
        success = true,
    })
    oWar:AddAnimationTime(1000,{escape=1})

    if oAction:Type() == gamedefines.WAR_WARRIOR_TYPE.PLAYER_TYPE then
        oWar:LeavePlayer(oAction:GetPid(),true)
    elseif oAction:Type() == gamedefines.WAR_WARRIOR_TYPE.SUMMON_TYPE then
        oWar:SendAll("GS2CWarDelWarrior", {
            war_id = oAction:GetWarId(),
            wid = oAction:GetWid(),
        })
        oWar:Leave(oAction)
    end
end

function CActionMgr:ValidSummonPartner(oPlayer,mPartner)
    local oWar = oPlayer:GetWar()
    local iCamp = oPlayer:GetCampId()
    local mFightPartner = oPlayer:GetTodayFightPartner()
    for _,mData in pairs(mPartner) do
        local mPartnerData = mData["partnerdata"]
        local iPos = mData["pos"]
        local iParId = mData["parid"]
        local oWarrior = oWar:GetWarriorByPos(iCamp,iPos)
        if oWarrior and (not oWarrior:IsPartner() or oWarrior:GetData("owner") ~= oPlayer:GetWid()) then
            return false
        end
        local mFightData = mPartnerData["partnerdata"] or {}
        if mFightPartner[iParId] and not oWar:IsConfig() then
            oPlayer:Notify(string.format("%s已经参战过，无法再次参战",mFightData["name"]))
            return false
        end
        if table_count(mFightPartner) >= 4 and not oWar:IsConfig() then
            local sNotify = oWar.m_FullSummonPartnerNotify or "最多可以4个伙伴参战"
            oPlayer:Notify(sNotify)
            return false
        end
        if oWarrior and not oWarrior:IsDead() and oWarrior:GetData("friend") then
            oPlayer:Notify("好友伙伴不可替换")
            return false
        end
    end
    return true
end

function CActionMgr:WarPartner(oPlayer,mPartner)
    local oWar = oPlayer:GetWar()
    if not self:ValidSummonPartner(oPlayer,mPartner) then
        return
    end
    if oWar.CheckWarWarPartner and not oWar:CheckWarWarPartner(oPlayer,mPartner) then
        return
    end

    for _,mFightData in pairs(mPartner) do
        local iType = mFightData["partnerdata"]["partnerdata"]["type"]
        if table_in_list({1754,1755},iType) then
            return
        end
    end

    local iActionWid = oPlayer:GetWid()
    for _,mFightData in pairs(mPartner) do
        local mFightPartner = oPlayer:GetTodayFightPartner()
        if table_count(mFightPartner) >= 4 and not oWar:IsConfig() then
            oPlayer:Notify("最多可以4个伙伴参战")
            break
        end
        local iPos = mFightData["pos"]
        local mPartnerData = mFightData["partnerdata"]
        local iCamp = oPlayer:GetCampId()
        local oWarrior = oWar:GetWarriorByPos(iCamp,iPos)
        local iReplace
        if oWarrior then
            iReplace = oWarrior:GetData("parid")
            local iWid = oWarrior:GetWid()
            oWar:SendAll("GS2CWarDelWarrior", {
                war_id = oPlayer:GetWarId(),
                wid = oWarrior:GetWid(),
                del_type = 1,
            })
            oWarrior:OnReplacePartner()
            oWar:Leave(oWarrior)
            oWar:DelBoutCmd(iWid)
        end
        local mArgs = {
            add_type  = 1,
            replace = iReplace,
        }
        local oPartner = oWar:AddPartner(oPlayer,iPos,mPartnerData,mArgs)
        oWar:SendWarSpeed()
        if oPartner and oWar.m_SyncOperateCmd then
            local iSkill = oPartner:GetNormalAttackSkillId()
            oWar:SyncOperateCmd(oPartner,iSkill)
        end
        --战前配置同步到上阵设置
        if oWar:IsConfig() then
            local mData = mPartnerData["partnerdata"]
            if iPos > 4 then
                iPos = iPos - 4
            end
            oWar:RemoteWorldEvent("remote_config_partner", {
                pid = oPlayer:GetPid(),
                pos = iPos,
                parid = mData["parid"],
            })
        end
    end
end


function CActionMgr:Perform(oAttack,oVictim,iPerform)
    local oPerform = oAttack:GetPerform(iPerform)
    local oWar = oAttack:GetWar()
    local iWid = oAttack:GetWid()
    assert(oPerform,string.format("CActionMgr:Perform err:%d",iPerform))
    oWar:AddDebugMsg("", true)
    if not oAttack:ValidAction() then
        return
    end
    if oPerform:InCD(oAttack) then
        return
    end
    if not oPerform:SelfValidCast(oAttack,oVictim) then
        return
    end
    local oVictim = oPerform:ValidCast(oAttack,oVictim)
    if not oVictim then
        return
    end
    oPerform.m_Target = oVictim:GetWid()
    local mResume = oPerform:ValidResume(oAttack,oVictim)
    if not mResume then
        return
    end
    oPerform:DoResume(oAttack,mResume)
    local mTarget = oPerform:PerformTarget(oAttack,oVictim)
    local lVictim = {}
    for _,iWid in ipairs(mTarget) do
        table.insert(lVictim,oWar:GetWarrior(iWid))
    end

    oAttack:SendAll("GS2CWarAction",{
        war_id = oAttack:GetWarId(),
        wid = oAttack:GetWid()
    })
    oAttack:SetBoutArgs("perform_success",1)
    local lSelectWid = {}
    for _,oVictim in ipairs(lVictim) do
        table.insert(lSelectWid,oVictim:GetWid())
    end
    oAttack:SetBoutArgs("perform_target",lSelectWid)
    oPerform:SetData("Attack_Damage",0)
    oAttack:PerformStart(oPerform)
    oPerform:Perform(oAttack,lVictim)
end

--单人被多次攻击
function CActionMgr:DoMultiPerform(oAttack,oVictim,oPerform,iDamageRatio,iCnt,mArgs)
    mArgs = mArgs or {}
    local oWar = oAttack:GetWar()
    oPerform:SetData("PerformAttackCnt",nil)
    local iWarId = oWar:GetWarId()
    local iWid = oAttack:GetWid()
    local iVictimWid = oVictim:GetWid()
    oPerform:SetData("PerformAttackMaxCnt",iCnt)
    local f = mArgs["MagicID"] or function (i) return i end
    for i=1,iCnt do
        local oNewAttack = oWar:GetWarrior(iWid)
        local oNewVictim = oWar:GetWarrior(iVictimWid)
        if not oNewAttack or oNewAttack:IsDead() then
            break
        end
        if not oNewVictim or oNewVictim:IsDead() then
            break
        end
        oAttack:SendAll("GS2CWarSkill", {
            war_id = oAttack:GetWarId(),
            action_wlist = {oAttack:GetWid(),},
            select_wlist = {oVictim:GetWid()},
            skill_id = oPerform.m_ID,
            magic_id = f(i),
        })
        local iTime = oPerform:PerformMagicTime(i)
        if oWar then
            oWar:AddAnimationTime(iTime,{skill=oPerform:Type(),mgi=i,})
        end

        local iAttackCnt = oPerform:GetData("PerformAttackCnt",0)
        iAttackCnt = iAttackCnt + 1
        oPerform:SetData("PerformAttackCnt",iAttackCnt)
        self:DoAttack(oAttack,oVictim,oPerform,iDamageRatio)

        local oNewAttack = oWar:GetWarrior(iWid)
        local oNewVictim = oWar:GetWarrior(iVictimWid)

        if oNewVictim and not oNewVictim:IsDead() then
            oPerform:Effect_Condition_For_Victim(oVictim,oNewAttack)
        end
    end
    local oNewVictim = oWar:GetWarrior(iVictimWid)
    local oNewAttack = oWar:GetWarrior(iWid)
    if oNewVictim and not oNewVictim:IsDead() and oNewAttack then
        oVictim:OnPerformed(oAttack,oPerform)
    end
    oPerform:SetData("PerformAttackCnt",nil)

    local lVictim = {oVictim}
    if oNewAttack and oNewVictim and not oNewAttack:IsDead() then
        oAttack:OnPerform(lVictim,oPerform)
        oAttack.m_oBuffMgr:CheckAttackBuff(oAttack)
        oPerform:Effect_Condition_For_Attack(oAttack)
        if oPerform:IsCD(oAttack) then
            oPerform:SetCD(oAttack)
        end
    end
    oWar:SendAll("GS2CWarGoback", {
        war_id = iWarId,
        action_wid = iWid,
    })
    --反击
    if oNewAttack then
        self:AttackBack(oNewAttack,lVictim)
        oNewAttack:OnAfterGoback(lVictim,oPerform)
    end
end

function CActionMgr:AttackBack(oAttack,lVictim)
    for _,oVictim in pairs(lVictim) do
        if oVictim:ValidAttackBack(oAttack) then
            oVictim:AttackBack(oAttack)
        end
    end
end

--一次单个技能释放
function CActionMgr:DoPerform(oAttack,oVictim,oPerform,iDamageRatio,iMagicIdx)
    iMagicIdx = iMagicIdx or 1
    local oWar = oAttack:GetWar()
    local iWid = oAttack:GetWid()
    local iVictimWid = oVictim:GetWid()
    if not oAttack or oAttack:IsDead() then
        return
    end
    if not oVictim or oVictim:IsDead() then
        return
    end
    oAttack:SendAll("GS2CWarSkill", {
        war_id = oAttack:GetWarId(),
        action_wlist = {oAttack:GetWid(),},
        select_wlist = {oVictim:GetWid()},
        skill_id = oPerform.m_ID,
        magic_id = iMagicIdx,
    })
    local iTime = oPerform:PerformMagicTime(iMagicIdx)
    if oWar then
        oWar:AddAnimationTime(iTime,{skill=oPerform:Type(),mgi=iMagicIdx})
    end
    oPerform:SetData("PerformAttackMaxCnt",1)
    local iAttackCnt = oPerform:GetData("PerformAttackCnt",0)
    iAttackCnt = iAttackCnt + 1
    oPerform:SetData("PerformAttackCnt",iAttackCnt)
    self:DoAttack(oAttack,oVictim,oPerform,iDamageRatio)

    local oNewVictim = oWar:GetWarrior(iVictimWid)
    local oNewAttack = oWar:GetWarrior(iWid)

    if oNewVictim and not oNewVictim:IsDead() then
        oPerform:Effect_Condition_For_Victim(oVictim,oNewAttack)
    end
end

--单人多次计算伤害
function CActionMgr:DoMultiAttack(oAttack,oVictim,oPerform,iDamageRatio,iCnt)
    iDamageRatio = iDamageRatio or 100
    iCnt = iCnt or 1
    local oWar = oAttack:GetWar()
    local iWid = oAttack:GetWid()
    local iVictimWid = oVictim:GetWid()
    oPerform:SetData("PerformAttackCnt",nil)
    oPerform:SetData("PerformAttackMaxCnt",iCnt)
    oPerform:SetData("DoAttackCnt",nil)
    for i=1,iCnt do
        if not oAttack or oAttack:IsDead() then
            break
        end
        if not oVictim or oVictim:IsDead() then
            break
        end
        local iAttackCnt = oPerform:GetData("PerformAttackCnt",0)
        iAttackCnt = iAttackCnt + 1
        oPerform:SetData("PerformAttackCnt",iAttackCnt)
        oPerform:SetData("DoAttackCnt",iAttackCnt)
        self:DoAttack(oAttack,oVictim,oPerform,iDamageRatio)
        local oNewAttack = oWar:GetWarrior(iWid)
        local oNewVictim = oWar:GetWarrior(iVictimWid)
        if oNewVictim and not oNewVictim:IsDead() then
            oPerform:Effect_Condition_For_Victim(oVictim,oNewAttack)
        end
        if not oNewAttack or oNewAttack:IsDead() then
            break
        end
        if not oNewVictim or oNewVictim:IsDead() then
            break
        end
    end
    oPerform:SetData("PerformAttackCnt",nil)
end

--一次伤害扣除
function CActionMgr:DoAttack(oAttack,oVictim,oPerform,iDamageRatio)
    local iFlag = 0
    local iCritFlag
    local oWar = oAttack:GetWar()
    local iWarId = oWar:GetWarId()
    local iWid = oAttack:GetWid()
    local iVictimWid = oVictim:GetWid()
    if oVictim:IsDefense() then
        iFlag = gamedefines.WAR_RECV_DAMAGE_FLAG.DEFENSE
    end
    local iDamage = self:CalDamage(oAttack,oVictim,oPerform,iDamageRatio)
    if oAttack:QueryBoutArgs("IsCrit") then
        iCritFlag = 1
        oAttack:SetBoutArgs("IsCrit",nil)
    end
    oPerform:SetData("DoAttackCnt",1)
    local iHit
    iDamage,iHit = oVictim:ReceiveDamage(oAttack,oPerform,iDamage)
    oVictim:PerformDamage(oAttack,oPerform,iHit)
    if not oAttack:QueryBoutArgs("Shield_WarDamage") then
        oWar:SendAll("GS2CWarDamage", {
            war_id = iWarId,
            wid = iVictimWid,
            type = iFlag,
            damage = -iDamage,
            iscrit = iCritFlag,
        })
    else
        oAttack:SetBoutArgs("Shield_WarDamage",nil)
    end
    local iAttackDamage = oPerform:GetData("Attack_Damage",0)
    oPerform:SetData("Attack_Damage",iAttackDamage+iHit)
    local oNewAttack = oWar:GetWarrior(iWid)
    local oNewVictim = oWar:GetWarrior(iVictimWid)
    if oNewAttack and not oNewAttack:QueryBoutArgs("DoubleAttack") then
        oAttack:OnAttack(oVictim,oPerform,iHit)
    end
    if oNewVictim and not oNewVictim:IsDead() and oNewAttack and oNewAttack:IsCurrentAction() then
        oVictim:OnAttacked(oNewAttack,oPerform,iHit)
        oVictim:SetBoutArgs("IsCrited",nil)
    end
end

--固定伤害
function CActionMgr:DoStableDamage(oAttack,oVictim,oPerform,iDamage)
    local oWar = oAttack:GetWar()
    local iWarId = oWar:GetWarId()
    local iWid = oAttack:GetWid()
    local iVictimWid = oVictim:GetWid()

    oVictim:SubHp(iDamage,oAttack)
    oWar:SendAll("GS2CWarDamage", {
        war_id = iWarId,
        wid = iVictimWid,
        type = 0,
        damage = -iDamage,
    })
    local oNewAttack = oWar:GetWarrior(iWid)
    local oNewVictim = oWar:GetWarrior(iVictimWid)
    if oNewAttack and not oNewAttack:QueryBoutArgs("DoubleAttack") then
        oNewAttack:OnAttack(oVictim,oPerform,iDamage)
    end
    if oNewVictim and not oNewVictim:IsDead() and oNewAttack:IsCurrentAction() then
        oVictim:OnAttacked(oNewAttack,oPerform,iDamage)
    end
    if oNewVictim and not oNewVictim:IsDead() then
        oPerform:Effect_Condition_For_Victim(oNewVictim,oNewAttack)
    end
end

function CActionMgr:CalCureHp(iHP,oVictim,oAttack)
    local iCure_Power = oVictim:QueryAttr("cure_power")
    iHP = math.floor(iHP + iCure_Power)
    local iCriticalRatio = oAttack:QueryAttr("cure_critical_ratio")
    local iCritical = 0
    if in_random(iCriticalRatio,10000) then
        local iRatio = 15000 + oVictim:QueryAttr("cure_ratio")
        iHP = math.floor(iHP * iRatio / 10000)
        iCritical = 1
    end
    local mFunction = oVictim:GetFunction("OnCured")
    for _,fCallback in pairs(mFunction) do
        iHP = iHP + fCallback(oVictim,iHP)
    end

    iHP =  oAttack:OnCure(iHP,oVictim)

    return iHP,iCritical
end

function CActionMgr:DoSealAction(oAttack,oVictim,oPerform,iMinRatio,iMaxRatio)
    local iRatio = self:CalSealRatio(oAttack,oVictim,oPerform,iMinRatio,iMaxRatio)
    if in_random(iRatio,100) then
        if oVictim and not oVictim:IsDead() then
           oPerform:Effect_Condition_For_Victim(oVictim,oAttack)
        end
    end
end

--计算封印概率
function CActionMgr:CalSealRatio(oAttack,oVictim,oPerform,iMinRatio,iMaxRatio)
    local iSeal_Ratio = oAttack:QueryAttr("seal_ratio")
    local iRes_Seal_Ratio = oVictim:QueryAttr("res_seal_ratio")
    local iExpertSkillLevel = oAttack:QueryExpertSkill(1) - oVictim:QueryExpertSkill(4)
    local iRatio = oPerform:HitRatio(oAttack,oVictim) + iSeal_Ratio - iRes_Seal_Ratio
    iRatio = iRatio + iExpertSkillLevel * 2
    iRatio = math.min(iRatio,iMaxRatio)
    iRatio = math.max(iRatio,iMinRatio)
    return iRatio
end



--多次攻击一个玩家
function CActionMgr:WarNormalAttack(oAttack,oVictim,oPerform,iDamageRatio,iCnt,mArgs)
    mArgs = mArgs or {}
    iDamageRatio = iDamageRatio or 100
    iCnt = iCnt or 1
    local oWar = oAttack:GetWar()
    local iWarId = oWar:GetWarId()
    local iWid = oAttack:GetWid()
    local iVictimWid = oVictim:GetWid()
    self:NormalAttackOne(oAttack,oVictim,oPerform,iDamageRatio,iCnt,mArgs)

    local oNewAttack = oWar:GetWarrior(iWid)
    local oNewVictim = oWar:GetWarrior(iVictimWid)
    local lVictim = {oNewVictim}
    if oNewAttack and not oNewAttack:IsDead() then
        oNewAttack:OnPerform(lVictim,oPerform)
        oNewAttack.m_oBuffMgr:CheckAttackBuff(oNewAttack)
        oPerform:Effect_Condition_For_Attack(oNewAttack)
    end
    oWar:SendAll("GS2CWarGoback", {
        war_id = iWarId,
        action_wid = iWid,
    })
    --反击
    if oNewVictim and not oVictim:IsDead() and oNewAttack and not oNewAttack:IsDead() then
        if oNewVictim:ValidAttackBack(oNewAttack) then
            oNewVictim:AttackBack(oNewAttack)
        end
    end
end



function CActionMgr:NormalAttackOne(oAttack,oVictim,oPerform,iDamageRatio,iCnt,mArgs)
    mArgs = mArgs or {}
    local oWar = oAttack:GetWar()
    local iWarId = oWar:GetWarId()
    local iWid = oAttack:GetWid()
    local iVictimWid = oVictim:GetWid()
    local fSendWarSkill = mArgs["AttackOneWarSkill"] or function (iCnt,oWar,iWid,iVictimWid,oPerform)
        if iCnt == 1 then
            oWar:SendAll("GS2CWarSkill", {
                war_id = oWar:GetWarId(),
                action_wlist = {iWid,},
                select_wlist = {iVictimWid},
                skill_id = oPerform.m_ID,
                magic_id = iCnt,
            })
        end
    end
    for i=1,iCnt do
        if not oAttack or oAttack:IsDead() then
            break
        end
        if not oVictim or oVictim:IsDead() then
            break
        end
        fSendWarSkill(i,oWar,iWid,iVictimWid,oPerform)
        local iTime = oPerform:PerformMagicTime(i)
        if oWar then
            oWar:AddAnimationTime(iTime,{skill=oPerform:Type(),mgi=i})
        end
        self:DoAttack(oAttack,oVictim,oPerform,iDamageRatio)
        oPerform:SetData("PerformAttackMaxCnt",1)
        local iAttackCnt = oPerform:GetData("PerformAttackCnt",0)
        iAttackCnt = iAttackCnt + 1
        oPerform:SetData("PerformAttackCnt",iAttackCnt)
        local oNewVictim = oWar:GetWarrior(iVictimWid)
        local oNewAttack = oWar:GetWarrior(iWid)
        if oNewVictim and not oNewVictim:IsDead() then
            oPerform:Effect_Condition_For_Victim(oNewVictim,oNewAttack)
        end
    end
    oPerform:SetData("PerformAttackCnt",nil)
    local oNewVictim = oWar:GetWarrior(iVictimWid)
    local oNewAttack = oWar:GetWarrior(iWid)
    if oNewVictim and not oNewVictim:IsDead() then
        oVictim:OnPerformed(oNewAttack,oPerform)
    end
end


function CActionMgr:CallCritRatio(oAttack,oVictim)
    local iCritRatio = oAttack:QueryAttr("critical_ratio") - oVictim:QueryAttr("res_critical_ratio")
    local mFunction = oAttack:GetFunction("CallCritRatio")
    for _,fCallback in pairs(mFunction) do
        local iAdd = fCallback(oAttack,oVictim)
        iCritRatio = iCritRatio + iAdd
    end
    return iCritRatio
end

function CActionMgr:CalNormalDamage(oAttack,oVictim)
    local iAttack = oAttack:QueryAttr("attack")
    local iDefense = oVictim:QueryAttr("defense")
    local iAttack = iAttack * math.random(90,110) / 100
    local iDamage = math.floor(iAttack - iDefense)
    local iCritRatio = self:CallCritRatio(oAttack,oVictim)

    if in_random(iCritRatio,100) then
        local iRatioB = oAttack:QueryAttr("critical_damage") / 100
        iDamage = iDamage * iRatioB
        oAttack:SetBoutArgs("IsCrit",1)
    end
    iDamage = iDamage + oAttack:QueryAttr("FixDamage")
    iDamage = math.floor(iDamage)
    local iBaseDamage = math.floor(iAttack / 20)
    if iDamage < iBaseDamage then
        iDamage = iBaseDamage
    end
    return iDamage
end

function CActionMgr:CalDamage(oAttack,oVictim,oPerform,iDamageRatio)
    --固定伤害
    if oPerform.ConstantDamage then
        return oPerform:ConstantDamage(oAttack,oVictim)
    end
    local iCritRatio = self:CallCritRatio(oAttack,oVictim)
    local bIsCrit = false
    if in_random(iCritRatio,10000) or oAttack:HasKey("critical_sure") then
        bIsCrit = true
        oAttack:SetBoutArgs("IsCrit",1)
        oVictim:SetBoutArgs("IsCrited",1)
    end
    local iAttack = oAttack:QueryAttr("attack")
    local iDefense = oVictim:QueryAttr("defense")
    local mFunction = oAttack:GetFunction("OnCalDefense")
    for _,fCallback in pairs(mFunction) do
        iDefense = iDefense + fCallback(oAttack,oVictim,oPerform)
    end
    local iAttack = iAttack * math.random(90,110) / 100
    local iBaseDamage = iAttack - iDefense

    local iPfDamageRatio = oPerform:DamageRatio(oAttack,oVictim) / 10000
    local iExpertSkillLevel = oAttack:QueryExpertSkill(1) - oVictim:QueryExpertSkill(2)
    local iExpertRatio = (100 + iExpertSkillLevel * 2) /100
    local iRatioA = 10000
    iRatioA = iRatioA + oAttack:QueryAttr("damage_ratio") + oVictim:QueryAttr("damaged_ratio")

    iRatioA = oAttack:OnCalDamageRatio(oVictim,oPerform,iRatioA)

    iRatioA = iRatioA / 10000
    iDamageRatio = iDamageRatio / 100

    local iDamage = math.floor(iBaseDamage * iDamageRatio * iPfDamageRatio * iExpertRatio * iRatioA)
    iDamage = iDamage + iExpertSkillLevel * 5 +  oAttack:QueryAttr("damageadd")
    local iDamageA = iDamage
    local iRatioB = 10000
    if bIsCrit then
        iRatioB = oAttack:QueryAttr("critical_damage") or 15000
    end

    iRatioB = iRatioB + oAttack:QueryAttr("damage_addratio") + oVictim:QueryAttr("damaged_addratio")
    if oVictim:IsDefense() then
        iRatioB = iRatioB / 2
    end
    iRatioB = iRatioB / 10000
    iDamage = iDamage * iRatioB
    iDamage = iDamage + oAttack:QueryAttr("FixDamage")
    iDamage = math.max(iDamage,math.max(math.floor(iAttack/20),1))
    local iDamageB = iDamage

    iDamage = oAttack:OnCalDamage(oVictim,oPerform,iDamage)

    local mFunc = oVictim:GetFunction("OnCalDamaged")
    for _,fCallback in pairs(mFunc) do
        iDamage = iDamage + fCallback(oVictim,oAttack,oPerform,iDamage)
    end
    local oWar = oAttack:GetWar()
    oWar:AddDebugMsg(string.format("攻击%d,攻击波动%s,防御%d,效率%s%%,招式效率%s%%,修炼%d,敌方修炼%d,暴击几率%d%%,敌方抗暴击%d%%,是否暴击%s,伤害加成%d%%,伤害减少%d%%,伤害结果加成%d%%,伤害结果减少%d%%,A类系数:%s,B类系数:%s,暴击伤害:%s,基础伤害:%s,A类结果伤害:%s,B类结果伤害:%s,伤害:%s,异常命中:%s,速度:%s,本次暴击率:%d,",
        oAttack:QueryAttr("attack"),
        iAttack,
        iDefense,
        iDamageRatio * 100,
        iPfDamageRatio * 100,
        oAttack:QueryExpertSkill(1),
        oVictim:QueryExpertSkill(2),
        oAttack:QueryAttr("critical_ratio"),
        oVictim:QueryAttr("res_critical_ratio"),
        bIsCrit,
        oAttack:QueryAttr("damage_ratio") ,
        oVictim:QueryAttr("damaged_ratio") ,
        oAttack:QueryAttr("damage_addratio"),
        oVictim:QueryAttr("damaged_addratio"),
        iRatioA,
        iRatioB,
        oAttack:QueryAttr("critical_damage"),
        iBaseDamage,
        iDamageA,
        iDamageB,
        iDamage,
        oAttack:QueryAttr("abnormal_attr_ratio"),
        oAttack:GetSpeed(),
        iCritRatio
    ))



    return math.floor(iDamage)
end


function CActionMgr:PackWarriorInfo(iMonsterId)
    local res = require "base.res"
    local mData = res["daobiao"]["monster"]["perform_summon"][iMonsterId]
    assert(mData,string.format("perform summon err:%s",iMonsterId))
    local mModel = {
        shape = mData["model_id"],
        scale = mData["scale"],
        adorn = mData["ornament_id"],
        weapon = mData["wpmodel"],
        color = mData["mutate_color"],
        mutate_texture = mData["mutate_texture"],
    }

    local mPerform = {}
    local mAIPerform = {}
    local mActiveSkills = mData["activeSkills"] or {}
    for _,mSkill in pairs(mActiveSkills) do
        local iPerform = mSkill["pfid"]
        local iRatio = mSkill["ratio"]
        mPerform[iPerform] = 1
        mAIPerform[iPerform] = iRatio
    end
    local mPassiveSkill = mData["passiveSkills"] or {}
    for _,mSkill in pairs(mPassiveSkill) do
        local iSkill = mSkill["pfid"]
        mPerform[iSkill] = 1
    end

    local mRet = {}
    mRet.id = mData["id"]
    mRet.grade = mData["level"]
    mRet.name = mData["name"]
    mRet.hp = tonumber(mData["hp"])
    mRet.max_hp = tonumber(mData["hp"])
    mRet.model_info = mModel
    mRet.attack = mData["attack"]
    mRet.defense = mData["defense"]
    mRet.critical_ratio = mData["critical_ratio"]
    mRet.res_critical_ratio = mData["res_critical_ratio"]
    mRet.critical_damage = mData["critical_damage"]
    mRet.cure_critical__ratio = mData["cure_critical__ratio"]

    mRet.abnormal_attr_ratio = mData["abnormal_attr_ratio"]
    mRet.res_abnormal_ratio = mData["res_abnormal_ratio"]
    mRet.speed = mData["speed"]

    mRet.perform = mPerform
    mRet.perform_ai = mAIPerform
    mRet.double_attack_suspend = mData["double_attack_suspend"]
    local sShape = mData["shape_exchange"] ~= "" and mData["shape_exchange"] or "{}"
    mRet.shape_exchange = formula_string(sShape,{})
    mRet.data = {}
    return mRet
end

--技能召唤npc
function CActionMgr:PerformSummonWarrior(oAttack,iCamp,mData)
    local oCamp = oAttack:GetCamp()
    if not oCamp:ValidCallNpc() then
        return
    end
    local oWar = oAttack:GetWar()
    local iWid = oWar:DispatchWarriorId()
    local obj = npcwarrior.NewNpcWarrior(iWid)
    obj:Init({
        camp_id = iCamp,
        war_id = oAttack:GetWarId(),
        data = mData,
    })
    obj:SetData("call_obj",oAttack:GetWid())
    if oAttack:IsPartner() then
        obj:SetData("call_player",oAttack:GetData("owner"))
    end

    oWar:EnterCall(obj,iCamp)
    obj:SetAIType(gamedefines.AI_TYPE.COMMON)
    oAttack:SendAll("GS2CWarAddWarrior", {
        war_id = obj:GetWarId(),
        camp_id = obj:GetCampId(),
        type = obj:Type(),
        npcwarrior = obj:GetSimpleWarriorInfo(),
    })
    oAttack:SendAll("GS2CConfigFinish",{war_id = oAttack:GetWarId(),camp = iCamp,wid=iWid})
    oWar:BuildSpeedMQ()
    return obj
end


function CActionMgr:PerformAddWarrior(oAttack,iCamp,mData,pos)
    local oCamp = oAttack:GetCamp()
    local oWar = oAttack:GetWar()
    local iWid = oWar:DispatchWarriorId()
    local obj = npcwarrior.NewNpcWarrior(iWid)
    obj:Init({
        camp_id = iCamp,
        war_id = oAttack:GetWarId(),
        data = mData,
    })
    if pos then
        obj:SetPos(pos)
    end
    oWar:Enter(obj,iCamp)
    oAttack:SendAll("GS2CWarAddWarrior", {
        war_id = obj:GetWarId(),
        camp_id = obj:GetCampId(),
        type = obj:Type(),
        npcwarrior = obj:GetSimpleWarriorInfo(),
    })
    oWar:BuildSpeedMQ()
    return obj
end

