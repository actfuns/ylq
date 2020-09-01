--import module
local global = require "global"
local geometry = require "base.geometry"
local extend = require "base.extend"
local res = require "base.res"
local colorstring = require "public.colorstring"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))

local loaditem = import(service_path("item/loaditem"))
local monster = import(service_path("monster"))
local loadpartner = import(service_path("partner/loadpartner"))

local table = table
local string = string

CTempl = {}
CTempl.__index = CTempl
CTempl.m_sName = "test"
CTempl.m_sTempName = "神秘玩法"
inherit(CTempl, datactrl.CDataCtrl)

function CTempl:New(sName)
    local o = super(CTempl).New(self)
    o.m_sName = sName
    o.m_mKeepList = {}
    return o
end

function CTempl:Init()
    -- body
end

function CTempl:GetFightData()
    return {}
end

function CTempl:GetWarMonster(oWar,iFight)
    local mData = self:GetTollGateData(iFight)
    return mData["monster"] or {}
end

function CTempl:GetTollGateData(iFight)
    local res = require "base.res"
    local mData = res["daobiao"]["tollgate"]["test"][iFight]
    return mData
end

function CTempl:GetMonsterData(iMonsterIdx)
    local res = require "base.res"
    local mData = res["daobiao"]["monster"]["test"][iMonsterIdx]
    assert(mData,string.format("CTempl GetMonsterData err: %s %d", self.m_sName, iMonsterIdx))
    return mData
end

function CTempl:GetGlobalData(idx)
    local res = require "base.res"
    return res["daobiao"]["global"][idx]
end

function CTempl:GetRewardData(iReward)
    local res = require "base.res"
    local mData = res["daobiao"]["reward"][self.m_sName]["reward"][iReward]
    assert(mData,string.format("CTempl:GetRewardData err:%s %d", self.m_sName, iReward))
    return mData
end

function CTempl:GetItemRewardData(iItemReward)
    local res = require "base.res"
    local mData = res["daobiao"]["reward"][self.m_sName]["itemreward"][iItemReward]
    assert(mData,string.format("CTempl:GetItemRewardData err:%s %d", self.m_sName, iItemReward))
    return mData
end

function CTempl:AddKeep(iPid,sKey,value)
    self.m_mKeepList = self.m_mKeepList or {}
    if not self.m_mKeepList[iPid] then
        self.m_mKeepList[iPid] = {}
    end
    self.m_mKeepList[iPid][sKey] = value
end

function CTempl:GetKeep(iPid,sKey,rDefault)
    local mKeep = self.m_mKeepList[iPid] or {}
    return mKeep[sKey] or rDefault
end

function CTempl:ClearKeep(iPid)
    self.m_mKeepList[iPid] = nil
end

function CTempl:GetEventData()
    return {}
end

function CTempl:GetNpcObj(npcid)
end

function CTempl:RewardDie(iFight)
    return false
end

function CTempl:ValidFight(pid,npcobj,iFight)
    if pid then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        if oPlayer and oPlayer.m_oActiveCtrl:GetNowWar() then
            return false
        end
    end
    return true
end

function CTempl:Fight(pid,npcobj,iFight)
    local bValid,iErrCode = self:ValidFight(pid,npcobj,iFight)
    if not bValid then
        if iErrCode then
            if iErrCode == gamedefines.FIGHTFAIL_CODE.HASTEAM then
                local oNotifyMgr = global.oNotifyMgr
                oNotifyMgr:Notify(pid,"单人战斗，请先离开队伍")
            end
        end
        return
    end
    local oWar = self:CreateWar(pid,npcobj,iFight)
    if self:RewardDie(iFight) then
        oWar.m_RewardDie = true
    end
    return oWar
end

function CTempl:SingleFight(pid,npcobj,iFight)
    if npcobj and npcobj:InWar() then
        return false
    end
    if not self:ValidFight(pid,npcobj,iFight) then
        return
    end
    local oWar = self:CreateWar(pid,npcobj,iFight)
    if self:RewardDie(iFight) then
        oWar.m_RewardDie = true
    end
    if npcobj then
        local oSceneMgr = global.oSceneMgr
        npcobj:SetNowWar(oWar.m_iWarId)
        oSceneMgr:NpcEnterWar(npcobj)
    end
    return oWar
end

function CTempl:GetCreateWarArg(mArg)
    return mArg
end

--发送给战斗服务的数据
function CTempl:GetRemoteWarArg()
    return {}
end

--战斗信息配置
function CTempl:ConfigWar(oWar,pid,npcobj,iFight, mInfo)
    -- body
end

function CTempl:GetEnemyMonster(oWar, pid, npcobj, mArgs, mEnemy)
    mEnemy = mEnemy or {}

    return mEnemy
end

function CTempl:CreateWar(pid,npcobj,iFight,mInfo)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    assert(oPlayer,string.format("CTempl:CreateWar player offline:%d %d",pid,iFight))
    if oPlayer:IsSocialDisplay() then
        oPlayer:CancelSocailDisplay()
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("war") then
        oPlayer:NotifyMessage("当前场景禁止战斗")
        return
    end
    local oNowWar = oPlayer:GetNowWar()
    assert(not oNowWar,string.format("CreateWar err %d %d %s",pid,iFight,self.m_sName))

    mInfo = mInfo or {}
    local oWarMgr = global.oWarMgr
    local oWorldMgr = global.oWorldMgr
    local mData = self:GetTollGateData(iFight)
    local mRemote = self:GetRemoteWarArg() or {}
    mRemote["sp_start"] = mData["sp_start"] or 0
    local mArgs = self:GetCreateWarArg({
        war_type = mInfo.war_type or gamedefines.WAR_TYPE.NPC_TYPE,
        remote_war_type = mInfo.remote_war_type or "common",
        remote_args = mRemote,
    })
    mArgs["lineup"] = mData["lineup"] or 0

    local oWar = self:NewWar(mArgs)
    oWar:SetData("CreatePid",pid)
    oWar.m_FightIdx = iFight

    if npcobj then
        --
    end

    assert(mData,string.format("CPublicMgr:CreateWar %d err",iFight))
    local iAuto = self:GetWarConfig("close_auto_skill",mData)
    local iAuotOpen = self:GetWarConfig("open_auto_skill",mData)
    if iAuto and iAuto == 1 then
        --设置不继承上次自动战斗状态
        oWar:SetData("close_auto_skill",true)
    end
    if iAuotOpen ~= 0 then
        oWar:SetData("open_auto_skill",true)
    end
    self:ConfigWar(oWar,pid,npcobj,iFight, mInfo)

    local ret
    local mEnterWarArg = mInfo.enter_arg or {}
    mEnterWarArg.camp_id = mEnterWarArg.camp_id or 1

    local bFriend = mInfo.war_friend or false
    local bForce = mInfo.war_force or true
    if bFriend and ( not oPlayer:HasTeam() or oPlayer:IsTeamShortLeave() ) then
        ret = oWarMgr:FFEnterWar(oPlayer,oWar:GetWarId(), mEnterWarArg, bForce)
    elseif oPlayer:HasTeam() and oPlayer:IsTeamLeader() then
        ret = oWarMgr:TeamEnterWar(oPlayer,oWar:GetWarId(),mEnterWarArg,bForce)
    elseif oPlayer:HasTeam() and oPlayer:IsTeamShortLeave() then
        ret = oWarMgr:EnterWar(oPlayer, oWar:GetWarId(), mEnterWarArg, bForce)
    elseif not oPlayer:HasTeam() then
        ret = oWarMgr:EnterWar(oPlayer, oWar:GetWarId(), mEnterWarArg, bForce)
    else
        record.error(string.format("create templ war error %s pid:%d", self.m_sName, oPlayer:GetPid()))
        return
    end
    oWar:InitAttr()
    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end

    local mMonsterData = self:GetWarMonster(oWar, iFight)
    -- local mEnemy = {}
    local mWaveEnemy = {}
    local mWaveData = {}

    if self:ArrayDepth(mMonsterData) == 2 then
        mWaveData[1] = mMonsterData
    else
        mWaveData = mMonsterData
    end
    local iMonsterCnt = 0
    for iWave,mMaveMonsterData in pairs(mWaveData) do
        mWaveEnemy[iWave] = {}
        for _,mMonsterData in pairs(mMaveMonsterData) do
            local iMonsterIdx = mMonsterData["monsterid"]
            local iCnt = mMonsterData["count"]
            iMonsterCnt = iMonsterCnt + iCnt
            iCnt = math.min(iCnt,10)
            mArgs.monster_wave = iWave
            for i=1,iCnt do
                local oMonster = self:CreateMonster(oWar,iMonsterIdx,npcobj, mArgs)
                table.insert(mWaveEnemy[iWave], oMonster:PackAttr())
            end
        end
    end
    if iMonsterCnt > 20 then
        record.error(string.format("huodong:%s,pid:%s,fight:%s monster count big:%s",self.m_sName,pid,iFight,iMonsterCnt))
        return
    end
    local mEnemy = self:GetEnemyMonster(oWar,pid,npcobj,mArgs,mWaveEnemy[1])

    local mMonsterData = mData["friend"] or {}
    local mFriend = {}
    for _,mData in pairs(mMonsterData) do
        local iMonsterIdx = mData["monsterid"]
        local iCnt = mData["count"]
        for i=1,iCnt do
            local oMonster = self:CreateMonster(oWar,iMonsterIdx,npcobj, mArgs)
            table.insert(mFriend, oMonster:PackAttr())
            if #mFriend >= 2 then
                break
            end
        end
        if #mFriend >= 2 then
            break
        end
    end

    local mMonster = {
        [1] = mFriend,
        [2] = mEnemy,
    }

    local mMonsterData = {
        monster_data = mMonster,
        wave_enemy = mWaveEnemy,
        monster_servant = self:GetServant(oWar,mArgs),
    }

    oWarMgr:PrepareWar(oWar:GetWarId(),mMonsterData)
    if npcobj then
        oWar.m_iEvent = self:GetEvent(npcobj.m_ID)
    else
        oWar.m_iEvent = self:GetTriggerEvent()
    end
    local npcid
    if npcobj then
        npcid = npcobj.m_ID
    end
    local fSelfCallback = self:GetSelfCallback()
    local sDebug =  self.m_sName or "unknown"
    local fWarEndCallback = function (mArgs)
        local npcobj
        if fSelfCallback then
            local oSelf = fSelfCallback()
            if not oSelf then
                record.error(string.format("nil oSelf %s",sDebug))
            end
            if npcid then
                npcobj = oSelf:GetNpcObj(npcid)
            end
            oSelf:WarFightEnd(oWar,pid,npcobj,mArgs)
        end
    end
    oWarMgr:SetWarEndCallback(oWar:GetWarId(),fWarEndCallback)
    local fEscapeCallBack = function (mArgs)
        if fSelfCallback then
            local oSelf = fSelfCallback()
            oSelf:EscapeCallBack(oWar, pid, npcobj, mArgs)
        end
    end
    oWarMgr:SetEscapeCallBack(oWar:GetWarId(), fEscapeCallBack)
    if self:GetWarConfig("war_config",mData, oPlayer) ~= 0 then
        oWarMgr:StartWarConfig(oWar:GetWarId())
    else
        oWarMgr:StartWar(oWar:GetWarId())
    end
    return oWar
end

function CTempl:CreateRomWar(iPid,npcobj,mRomPlayer,mRomPartner,mInfo)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    assert(oPlayer,string.format("CTempl:CreateRomWar player offline:%d",iPid,self.m_sName))
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    assert(not oNowWar,string.format("CTempl:CreateRomWar err %d %s",iPid,self.m_sName))

    mInfo = mInfo or {}
    local oWarMgr = global.oWarMgr
    local oWorldMgr = global.oWorldMgr
    local mArgs = self:GetCreateWarArg({
        war_type = mInfo.war_type or gamedefines.WAR_TYPE.NPC_TYPE,
        remote_war_type = mInfo.remote_war_type or "common",
        remote_args = self:GetRemoteWarArg(),
    })

    local oWar = self:NewWar(mArgs)
    oWar:SetData("CreatePid",iPid)

    if npcobj then
        --
    end
    local iAuto = mInfo["close_auto_skill"] or 0
    local iAuotOpen = mInfo["open_auto_skill"] or 0
    if iAuto and iAuto == 1 then
        --设置不继承上次自动战斗状态
        oWar:SetData("close_auto_skill",true)
    end
    if iAuotOpen ~= 0 then
        oWar:SetData("open_auto_skill",true)
    end

    self:ConfigWar(oWar,iPid,npcobj,iFight, mInfo)

    local ret
    local mEnterWarArg = mInfo.enter_arg or {}
    mEnterWarArg.camp_id = mEnterWarArg.camp_id or 1

    local bFriend = mInfo.war_friend or false
    local bForce = mInfo.war_force or true

    if oPlayer:HasTeam() and oPlayer:IsTeamLeader() then
        ret = oWarMgr:TeamEnterWar(oPlayer,oWar:GetWarId(),mEnterWarArg,bForce)
    elseif oPlayer:HasTeam() and oPlayer:IsTeamShortLeave() then
        ret = oWarMgr:EnterWar(oPlayer, oWar:GetWarId(), mEnterWarArg, bForce)
    elseif not oPlayer:HasTeam() then
        ret = oWarMgr:EnterWar(oPlayer, oWar:GetWarId(), mEnterWarArg, bForce)
    else
        record.error(string.format("create templ romwar error %s pid:%d", self.m_sName, oPlayer:GetPid()))
        return
    end

    if ret.errcode ~= gamedefines.ERRCODE.ok then
        return
    end
    local mEnemy = {}
    local mWaveEnemy = {}
    local mWaveData = {}

    if #mRomPartner >= 1 then
        mRomPlayer.partner = mRomPartner[1]
        mRomPartner[1] = nil
    end

    local mRomData = {
        rom_player = mRomPlayer,
        rom_partner = mRomPartner,
    }
    mWaveEnemy[1] = mRomData

    local mMonsterData = {
        monster_data = mRomData,
        wave_enemy = mWaveEnemy,
        monster_servant = self:GetServant(oWar,mArgs),
        camp_id = mEnterWarArg.rom_camp_id,
    }

    oWarMgr:PrepareRomWar(oWar:GetWarId(),mMonsterData)
    if npcobj then
        oWar.m_iEvent = self:GetEvent(npcobj.m_ID)
    else
        oWar.m_iEvent = self:GetTriggerEvent()
    end
    local npcid
    if npcobj then
        npcid = npcobj.m_ID
    end
    local fSelfCallback = self:GetSelfCallback()
    local fWarEndCallback = function (mArgs)
        local npcobj
        if fSelfCallback then
            local oSelf = fSelfCallback()
            if npcid then
                npcobj = oSelf:GetNpcObj(npcid)
            end
            oSelf:WarFightEnd(oWar,iPid,npcobj,mArgs)
        end
    end
    oWarMgr:SetWarEndCallback(oWar:GetWarId(),fWarEndCallback)
    local fEscapeCallBack = function (mArgs)
        if fSelfCallback then
            local oSelf = fSelfCallback()
            oSelf:EscapeCallBack(oWar, iPid, npcobj, mArgs)
        end
    end
    oWarMgr:SetEscapeCallBack(oWar:GetWarId(), fEscapeCallBack)
    if self:GetWarConfig("war_config",mInfo) ~= 0 then
        oWarMgr:StartWarConfig(oWar:GetWarId())
    else
        oWarMgr:StartWar(oWar:GetWarId())
    end
    return oWar
end

function CTempl:GetServant(oWar,mArgs)
    ---
end

function CTempl:ArrayDepth(mArray)
    local is_table = function (t)
        if type(t) == "table" then
            return true
        end
    end
    local iDepth = 0
    local iLimit = 15
    local iCnt = 1
    while(is_table(mArray) and iCnt < iLimit) do
        iCnt = iCnt + 1
        iDepth = iDepth + 1
        mArray = mArray[1]
    end
    return iDepth
end

function CTempl:GetWarConfig(sKey,mData, ...)
    local mData = mData or {}
    return mData[sKey] or 0
end


function CTempl:NewWar(mArgs)
    local oWarMgr = global.oWarMgr
    return oWarMgr:CreateWar(mArgs)
end

--连续战斗
function CTempl:CreateSerialWar(iPid,oNpc,iFight)
    local oWar = self:CreateWar(iPid,oNpc,iFight)
    local fSerialWarCallback = function (mArgs)
        self:SerialWarCallback(oWar,iPid,oNpc,mArgs)
    end
    oWar:SetSerialWarCallback(fSerialWarCallback)
    return oWar
end

function CTempl:SerialWarCallback(oWar,iPid,oNpc,mArgs)
end

function CTempl:EscapeCallBack(oWar,iPid,oNpc,mArgs)
    -- body
end

function CTempl:CreateMonster(oWar,iMonsterIdx,npcobj, mArgs)
    local mData = self:GetMonsterData(iMonsterIdx)
    assert(mData,string.format("CTempl:CreateMonster err:%d",iMonsterIdx))
    mArgs = mArgs or {}
    local sName = mData["name"]
    local mModel = {
        shape = mData["model_id"],
        scale = mData["scale"],
        adorn = mData["ornament_id"],
        weapon = mData["wpmodel"],
        color = mData["mutate_color"],
        mutate_texture = mData["mutate_texture"],
    }
    if sName == "$npc" and npcobj then
        sName = npcobj:Name()
        mModel = npcobj:ModelInfo()
    end
    local mAttrData = {}
    mAttrData["type"] = iMonsterIdx
    mAttrData["show_skill"] = mData["show_skill"] or {}
    local sLevelFormula = mData["level"]
    local iLevel
    if tonumber(sLevelFormula) then
        iLevel = tonumber(sLevelFormula)
    else
        local mEnv = {
            LV = oWar:GetTeamLeaderGrade(),
            CLV = oWar:GetTeamLeaderGrade(),
            WLV = oWar:GetTeamWLV(),
            ALV = oWar:GetTeamAveGrade(),
            MLV = oWar:GetTeamMaxGrade(),
            SLV = oWar:GetTeamMinGrade(),
            MSLV = mArgs.monster_lv or 1,
            wave = mArgs.monster_wave,
            LLV = oWar:GetTeamPlayerAVG(),
        }
        local m = {
                value = sLevelFormula,
                env = mEnv,
        }
        iLevel = self:TransMonsterAble(oWar, "level", m)
    end

    local iShowLV = 0
    local sShowLV = mData["show_lv"]
    if sShowLV and sShowLV ~= "" then
        if tonumber(sShowLV) then
            iShowLV = tonumber(sShowLV)
        else
            local mEnv = {
                LV = oWar:GetTeamLeaderGrade(),
                CLV = oWar:GetTeamLeaderGrade(),
                WLV = oWar:GetTeamWLV(),
                ALV = oWar:GetTeamAveGrade(),
                MLV = oWar:GetTeamMaxGrade(),
                SLV = self:GetServerGrade(oWar),
                MSLV = mArgs.monster_lv or 1,
                level = iLevel,
                wave = mArgs.monster_wave,
                LLV = oWar:GetTeamPlayerAVG(),
            }
            local m = {
                value = sShowLV,
                env = mEnv,
            }
            iShowLV = self:TransMonsterAble(oWar, sShowLV, m)
        end
    end
    mAttrData["show_lv"] = iShowLV
    mAttrData["grade"] = iLevel
    mAttrData["name"] = sName
    mAttrData["model_info"] = mModel
    mAttrData["boss"] = mData["boss"] or 0
    mAttrData["ai"] = mData["ai_arg"] or 0
    local mPerform = {}
    local mAIPerform = {}

    local mActiveSkills = mData["activeSkills"] or {}
    for _,mSkill in pairs(mActiveSkills) do
        local iPerform = mSkill["pfid"]
        local iRatio = mSkill["ratio"]
        mPerform[iPerform] = mSkill["level"] or 1
        mAIPerform[iPerform] = iRatio
    end
    local mPassiveSkill = mData["passiveSkills"] or {}
    for _,mSkill in pairs(mPassiveSkill) do
        local iPerform = mSkill["pfid"]
        mPerform[iPerform] = mSkill["level"] or 1
    end
    --暂时加普攻处理
    if table_count(mPerform) <= 0 then
        mPerform[3901] = 1
        mAIPerform[3901] = 1
    end

    local mSpecialSkill = mData["special_skill"] or {}
    mSpecialSkill = mSpecialSkill[1] or {}
    local iSpecialSkill = mSpecialSkill["pfid"]
    if iSpecialSkill then
        mAttrData["special_skill"] = {
            skill_id = iSpecialSkill,
            sum_grid = mSpecialSkill["sum_grid"],
            cur_grid = mSpecialSkill["cur_grid"],
        }
        mPerform[iSpecialSkill] = mSpecialSkill["level"] or 1
    end

    mAttrData["perform"] = mPerform
    mAttrData["perform_ai"] = mAIPerform

    local iSuspend = mData["double_attack_suspend"] or 0
    if iSuspend == 1 then
        mAttrData["double_attack_suspend"] = false
    else
        mAttrData["double_attack_suspend"] = true
    end
    local iServerGrade = self:GetServerGrade(oWar)
    local mEnv = {
        level  = iLevel,
        wave = mArgs.monster_wave,
        SLV = iServerGrade,
        LLV = oWar:GetTeamPlayerAVG(),
        WLV = oWar:GetTeamWLV(),
    }
    local mAttrName = res["daobiao"]["attrname"]
    local mAttrs = table_key_list(mAttrName)
    for _,sAttr in ipairs(mAttrs) do
        local sValue = mData[sAttr]
        if tonumber(sValue) then
            mAttrData[sAttr] = tonumber(sValue)
        else
            local m = {
                value = sValue,
                env = mEnv,
            }
            mAttrData[sAttr] = self:TransMonsterAble(oWar, sAttr, m)
        end
        if extend.Table.find({"hp",},sAttr) then
            local sMaxAttr = string.format("max%s",sAttr)
            mAttrData[sMaxAttr] = mAttrData[sAttr]
        end
    end

    local oMonster = monster.NewMonster(mAttrData)
    return oMonster
end

function CTempl:GetServerGrade(oWar)
    return global.oWorldMgr:GetServerGrade()
end


function CTempl:GetEvent(npcid)
end

function CTempl:GetTriggerEvent()
end

function CTempl:WarFightEnd(oWar,iPid,oNpc,mArgs)
    local oWorldMgr = global.oWorldMgr
    local win_side = mArgs.win_side
    if oWar.m_RewardDie then
        mArgs.m_RewardDie = true
    end

    if oNpc then
        local oSceneMgr = global.oSceneMgr
        oNpc:ClearNowWar()
        oSceneMgr:NpcLeaveWar(oNpc)
    end

    local mWin = mArgs.win_list or {}
    local mFail = mArgs.fail_list or {}
    local mPlayer=  {}
    list_combine(mPlayer,mWin)
    list_combine(mPlayer,mFail)
    for _,iPid in pairs(mPlayer) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:AddKeep(iPid,"old_grade",oPlayer:GetGrade())
        end
    end

    if win_side == 1 then
        self:OnWarWin(oWar, iPid, oNpc, mArgs)
    else
        self:OnWarFail(oWar, iPid, oNpc, mArgs)
    end
    self:OnWarEnd(oWar, iPid, oNpc, mArgs,win_side == 1)
    local oTeamMgr = global.oTeamMgr
    local mEscapeList = mArgs.escape_list
    oTeamMgr:WarFightEnd(iPid,self.m_sTempName,win_side,mEscapeList[1])
    local oRecommend = global.oHuodongMgr:GetHuodong("warrecommend")
    if oRecommend then
        oRecommend:WarFightEnd(oWar,iPid,oNpc,mArgs)
    end
    local iWarid = oWar:GetWarId()
    if not self.m_PopRewardUIFirst then
        self:PopWarRewardUI(iWarid,mArgs)
    end

    for _,iPid in pairs(mPlayer) do
        self:ClearKeep(iPid)
    end
end

function CTempl:GetWarWinRewardUIData(oPlayer, mArgs)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local iGainExp = self:GetKeep(iPid,"exp")
    local bOverGrade = false
    if iGainExp == 0 then
        bOverGrade = true
    end
    iGainExp = iGainExp or 0
    local iLimitGrade = oWorldMgr:GetMaxPlayerGrade()
    local iOldGrade = self:GetKeep(iPid,"old_grade") or oPlayer:GetGrade()
    local iCurExp = math.max(oPlayer:GetExp() - iGainExp,0)
    local mPlayerExp = {limit_grade = iLimitGrade,grade = iOldGrade,exp = iCurExp,gain_exp = iGainExp, is_over_grade=bOverGrade}
    local mPartnerExp = {}
    local mAddExp = self:GetKeep(iPid,"partner_exp",{})
    local mPartner = self:GetFightPartner(oPlayer, mArgs)
    for iParId,mInfo in pairs(mPartner) do
        local iPartnerExp = mAddExp[iParId]
        local iGrade = mInfo.grade
        local iExp = mInfo.exp
        local iLimitGrade = iOldGrade + 5
        table.insert(mPartnerExp,{parid = iParId,gain_exp = iPartnerExp,exp = iExp,grade = iGrade,limit_grade = iLimitGrade})
    end
    local lItemInfo = global.oUIMgr:PackKeepItem(iPid)
    oPlayer:CheckUpGrade()
    return {
        player_exp = mPlayerExp,
        partner_exp = mPartnerExp,
        player_item = lItemInfo,
    }
end



function CTempl:PopWarRewardUI(iWarid,mArgs)
    local oWorldMgr = global.oWorldMgr
    local iSide = mArgs.win_side
    local mWin = mArgs.win_list or {}
    local mFail = mArgs.fail_list or {}
    local mPlayer   = {}
    list_combine(mPlayer,mWin)
    list_combine(mPlayer,mFail)
    local iWin = 0
    if iSide == 1 then--0为失败，1为胜利，2为平局
        iWin = 1
    elseif iSide == 0 then
        iWin = 2
    end
    for _,iPid in pairs(mPlayer) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local mData = self:GetWarWinRewardUIData(oPlayer, mArgs)
            mData.war_id = iWarid
            mData.win = iWin
            mData.win_tips = mArgs.win_tips
            mData.fail_tips = mArgs.fail_tips
            oPlayer.m_oItemCtrl:ShowWarEndUI(mData)
            -- oPlayer:Send("GS2CWarEndUI", mData)
        end
    end
end

function CTempl:OnWarWin(oWar, pid, npcobj, mArgs)
    local iEvent = oWar.m_iEvent
    if not iEvent then
        return
    end
    local mEvent = self:GetEventData(iEvent)
    if not mEvent then
        return
    end
    self:DoScript(pid,npcobj,mEvent["win"],mArgs)
end

function CTempl:OnWarFail(oWar, pid, npcobj, mArgs)
    local iEvent = oWar.m_iEvent
    if not iEvent then
        return
    end
    local mEvent = self:GetEventData(iEvent)
    if not mEvent then
        return
    end
    self:DoScript(pid,npcobj,mEvent["fail"],mArgs)

    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer and not mArgs.cancel_failtips then
        oNotifyMgr:Notify(pid,"战斗失败")
    end
end

function CTempl:OnWarEnd(oWar, iPid, oNpc, mArgs,bWin)
    --pass
end


function CTempl:DoScript(pid,npcobj,s,mArgs)
    if type(s) ~= "table" then
        return
    end
    for _,ss in pairs(s) do
        self:DoScript2(pid,npcobj,ss,mArgs)
    end
    self:DoScriptEnd(pid,s)
end

function CTempl:DoScript2(pid,npcobj,s,mArgs)
    if string.sub(s,1,1) == "F" then
        local iFight = string.sub(s,2,-1)
        iFight = tonumber(iFight)
        self:Fight(pid,npcobj,iFight)
    elseif string.sub(s,1,2) == "SF" then
        local iFight = string.sub(s,3,-1)
        iFight = tonumber(iFight)
        self:SingleFight(pid,npcobj,iFight)
    elseif string.sub(s,1,1) == "R" then
        local sArgs = string.sub(s,2,-1)
        self:Reward(pid,sArgs,mArgs)
    elseif string.sub(s,1,2) == "TR" then
        local sArgs = string.sub(s,3,-1)
        self:TeamReward(pid,sArgs,mArgs)
    end
end

function CTempl:DoScriptEnd(iPid,s)
    local mRewad = self:GetKeep(iPid,"reward2mail",{})
    if #mRewad > 0 then
        self:SendRewardToMail(iPid,mRewad)
        self:AddKeep(iPid,"reward2mail",{})
    end
end

function CTempl:GetFightList(oPlayer, mArgs)
    local lPlayers = {}
    if mArgs then
        extend.Array.append(lPlayers, mArgs.win_list)
        extend.Array.append(lPlayers, mArgs.fail_list)
    else
        local oTeam = oPlayer:HasTeam()
        if oTeam then
            extend.Array.append(lPlayers, oTeam:GetTeamMember())
        else
            table.insert(lPlayers, oPlayer:GetPid())
        end
    end
    return lPlayers
end

function CTempl:GetFightPartner(oPlayer,mArgs)
    local mPartnerInfo = {}
    if mArgs and mArgs and mArgs.fight_partner then
        mPartnerInfo = mArgs.fight_partner[oPlayer:GetPid()] or {}
    end
    return mPartnerInfo
end

function CTempl:TeamReward(iPid, sIdx, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local lPlayers = self:GetFightList(oPlayer,mArgs)
    local mExpExclude = mArgs.exp_exclude or {}
    for _,pid in ipairs(lPlayers) do
        mArgs.cancel_exp = nil
        if mExpExclude[iPid] then
            mArgs.cancel_exp = 1
        end
        self:Reward(pid, sIdx, mArgs)
    end
end


function CTempl:RewardByMail(iPid,iReward,mArgs)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iPid, function(oProfile)
        self:OnSendRewardMail(oProfile, {iReward}, mArgs)
    end)
end


function CTempl:RewardListByMail(iPid,rewardlist,mArgs)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iPid, function(oProfile)
        self:OnSendRewardMail(oProfile, rewardlist, mArgs)
    end)
end

function CTempl:OnSendRewardMail(oProfile, rewardlist, mArgs)
    mArgs = mArgs or {}
    local oMailMgr = global.oMailMgr
    local iPid = oProfile:GetPid()
    local mRewardContent
    for _,iReward in ipairs(rewardlist) do
        local mReward = self:SolidifyReward(oProfile, iReward, mArgs)
        if mReward then
            if not mRewardContent then
                mRewardContent = mReward
            else
                mRewardContent.exp = mRewardContent.exp + mReward.exp
                mRewardContent.coin = mRewardContent.coin + mReward.coin
                mRewardContent.partnerexp = mRewardContent.partnerexp + mReward.partnerexp
                list_combine(mRewardContent.iteminfo.item,mReward.iteminfo.item)
            end
        end
    end

    if mRewardContent then
        local mRewardItem = mRewardContent.iteminfo
        local lItemObj = mRewardItem.item or {}
        local lPartnerObj = mRewardItem.partner or {}
        local iCoin = mRewardContent.coin
        local mData = mArgs.mailinfo
        local sName = mArgs.name or "系统"
        oMailMgr:SendMail(0, sName, iPid, mData, {{sid = gamedefines.COIN_FLAG.COIN_COIN,value=iCoin}}, lItemObj, lPartnerObj)
        if mArgs.func then
            mArgs.func(mRewardContent)
        end
    end
end


function CTempl:SolidifyReward(oProfile, iReward, mArgs)
    mArgs = mArgs or {}
    local iPid = oProfile:GetPid()
    local mRewardInfo = self:GetRewardData(iReward)
    if math.random(10000) <= mRewardInfo.rate then
        return self:GenRewardContent(oProfile, mRewardInfo, mArgs)
    end
end

function CTempl:BuildRewardItemList(mItemInfo,sShape,mArg)
    local iAmount = mItemInfo["amount"]

    local iBind = mItemInfo["bind"] or 0
    local mItem = {}
    sShape= sShape or mItemInfo['sid'][1]
    local pid = mArg["pid"]
    while(iAmount>0) do
        local oItem = loaditem.ExtCreate(sShape)
        local iAddAmount = math.min(oItem:GetMaxAmount(),iAmount)
        iAmount = iAmount - iAddAmount
        oItem:SetAmount(iAddAmount)
        if iBind ~= 0 then
            oItem:Bind(pid)
        end
        table.insert(mItem,oItem)
    end
    return mItem
end

function CTempl:CheckRewardMonitor(oPlayer, iReward, iCnt, mArgs)
    return true
end

function CTempl:CheckRewardDayLimit(oPlayer,iReward,mArg)
    local res = require "base.res"
    if not res["daobiao"]["reward"][self.m_sName]["daylimit"] then
        return true
    end
    local key = string.format("dl_%s",self.m_sName)
    local mReward = oPlayer.m_oToday:Query(key,{})
    local iLimit = res["daobiao"]["reward"][self.m_sName]["daylimit"][iReward]
    if not iLimit or iLimit < 1 then
        return true
    end
    local iCnt = mReward[iReward] or 0
    if iCnt >= iLimit then
        return false
    end
    iCnt = iCnt + 1
    mReward[iReward] = iCnt
    oPlayer.m_oToday:Set(key,mReward)
    return true
end

function CTempl:Reward(iPid, sIdx, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end

    local iReward = tonumber(sIdx)
    if not iReward then
        return
    end
    if not self:CheckRewardDayLimit(oPlayer,iReward,mArgs) then
        return
    end
    if not self:CheckRewardMonitor(oPlayer, iReward, 1, mArgs) then
        return
    end

    local mRewardInfo = self:GetRewardData(iReward)
    local iRate = mRewardInfo.rate
    if iRate < math.random(10000) then
        return
    end

    local mRewardContent = self:GenRewardContent(oPlayer:GetProfile(), mRewardInfo, mArgs)
    mRewardContent = self:DoRewardContent(oPlayer, mRewardContent, mArgs)
    return mRewardContent
end

function CTempl:DoRewardContent(oPlayer, mRewardContent, mArgs)
    local iExp = mRewardContent.exp
    local iCoin = mRewardContent.coin
    local sPartnerExp = mRewardContent.partnerexp
    local mItemInfo = mRewardContent.iteminfo
    local sOrgOffer = mRewardContent.orgoffer

    mArgs = mArgs or {}
    if sPartnerExp and sPartnerExp ~= "" and sPartnerExp ~= "0" then
        self:RewardPartnerExp(oPlayer, sPartnerExp, mArgs)
    end

    if iExp > 0 and not mArgs.cancel_exp then
        self:RewardExp(oPlayer, iExp, mArgs)
    end

    if iCoin > 0 then
        self:RewardCoin(oPlayer, iCoin, mArgs)
    end

    if sOrgOffer and sOrgOffer ~= "" then
        self:RewardOrgOffer(oPlayer, sOrgOffer, mArgs)
    end

    local lItemObj = mItemInfo.item
    local mBox = self:GetKeep(oPlayer:GetPid(),"reward2mail",{})
    local mBriefItem = {}
    mArgs.bSendMailLater = self.m_SendRewardMailOnce
    if lItemObj then
        local mKeepItem = self:GetKeep(oPlayer:GetPid(), "item", {})
        for _, oItem in ipairs(lItemObj) do
            local mBriefInfo = {
                id = oItem.m_ID,
                sid = oItem.m_SID,
                amount = oItem:GetAmount(),
            }
            mArgs.bSendMailLater = self.m_SendRewardMailOnce
            local sName = loaditem.ItemColorName(oItem.m_SID)
            local mShowInfo = oItem:GetShowInfo()
            local iAmount = oItem:GetAmount()
            local iSid = oItem.m_SID
            local mResult = oPlayer:RewardItem(oItem, self.m_sName,mArgs)
            if mArgs and mArgs.chuanwen and mItemInfo.sys == 1 then
                local sMsg = mArgs.chuanwen
                sMsg = string.gsub(sMsg,"#role",oPlayer:GetName())
                sMsg = string.gsub(sMsg,"#role",{["#role"]=oPlayer:GetName()})
                sMsg = string.gsub(sMsg,"#item",sName)
                sMsg = string.gsub(sMsg,"#linkinfo",string.format("{link28,%d,%d}",iSid,iAmount))
                sMsg = string.gsub(sMsg,"#amount",iAmount)
                local oNotify = global.oNotifyMgr
                if mArgs.priority then
                    oNotify:SendPrioritySysChat(mArgs.priority,sMsg,1)
                elseif mArgs.delay then
                    oNotify:DelaySendSysChat(sMsg,1,1,{},{pid=oPlayer.m_iPid,delay=mArgs.delay,sys_name=mArgs.sys_name})
                else
                    oNotify:SendSysChat(sMsg,1,1)
                end
            end
            if mResult and mResult.retobj then
                table.insert(mBox,mResult.retobj)
            end
            if mResult.virtual and mResult.virtual_reward then
                local mInfo = mResult.virtual_reward.iteminfo
                mBriefInfo["virtual"]  = mBriefInfo["sid"]
                mBriefInfo["sid"] = mInfo["sid"]
                mBriefInfo["id"] = mInfo["id"]
                mBriefInfo["amount"] = mInfo["amount"]
            end
            table.insert(mBriefItem,mBriefInfo)
            local mK = mKeepItem[mShowInfo.sid] or {}
            mK[mShowInfo.virtual] = (mK[mShowInfo.virtual] or 0) + mShowInfo.amount
            mKeepItem[mShowInfo.sid] = mK
        end
        self:AddKeep(oPlayer:GetPid(), "item", mKeepItem)
    end
    mRewardContent.briefitem = mBriefItem

    if #mBox > 0 then
        self:AddKeep(oPlayer:GetPid(),"reward2mail",mBox)
    end
    return mRewardContent
end

function CTempl:GenRewardContent(oProfile, mRewardInfo, mArgs)
    local mItemInfo = {}
    local mRewardItem = mRewardInfo["item"]
    local iItemIdx = self:GenItemIdx(mRewardItem)
    local mItemInfo = self:GenRewardItemInfo(oProfile, mRewardInfo, iItemIdx)

    local sExp = mRewardInfo["exp"]
    local iExp = 0
    if sExp and sExp ~= "" and sExp ~= "0" then
        iExp = self:TransReward(oProfile, sExp,mArgs)
    end

    local sCoin = mRewardInfo["coin"]
    local iCoin = 0
    if sCoin and sCoin ~= "" and sCoin ~= "0" then
        iCoin = self:TransReward(oProfile, sCoin,mArgs)
    end

    local sPartnerExp = mRewardInfo["partnerexp"]

    return {
        exp = iExp,
        coin = iCoin,
        iteminfo = mItemInfo,
        partnerexp = sPartnerExp,
        orgoffer = mRewardInfo.orgoffer,
    }
end

function CTempl:GenItemIdx(mRewardItem)
    mRewardItem = mRewardItem or {}
    local iTotalRate = 0
    for _, mItem in pairs(mRewardItem) do
        iTotalRate = iTotalRate + mItem.rate
    end
    if iTotalRate > 0 then
        local iRanRate = math.random(iTotalRate)
        local iCountRate = 0
        for _, mItem in pairs(mRewardItem) do
            iCountRate = iCountRate + mItem.rate
            if iCountRate >= iRanRate then
                return mItem.idx
            end
        end
    end
end

function CTempl:GenRewardItemInfo(oProfile, mRewardInfo, iItemIdx)
    if not iItemIdx or iItemIdx == 0 then
        return {}
    end

    local iPid = oProfile:GetPid()
    local iPlayerGrade = oProfile:GetGrade()
    local iRewardGrade = 1
    local mRewardData = self:GetItemRewardData(iItemIdx)
    local mRewardGrade = table_key_list(mRewardData)
    table.sort(mRewardGrade)

    for _,iGrade in ipairs(mRewardGrade) do
        if iPlayerGrade >= iGrade then
            iRewardGrade = iGrade
        end
    end
    local mRewardInfo = mRewardData[iRewardGrade]

    local mItemInfo = self:ChooseRewardKey(mRewardInfo, iItemIdx, mArgs)
    assert(mItemInfo,string.format("CTempl:RewardItem err:%s %s %s",iPid,iPlayerGrade,iItemIdx))

    local sShape = mItemInfo["sid"]
    sShape = self:TransItemShape(oProfile, iItemIdx, sShape,mArgs)
    local iAmount = mItemInfo["amount"]
    local mRetItemInfo = {}
    mRetItemInfo.item = self:BuildRewardItemList(mItemInfo,sShape,{pid=iPid})
    mRetItemInfo.sys = mItemInfo.sys
    return mRetItemInfo
end

function CTempl:RewardExp(oPlayer, sExp, mArgs)
    local iExp = self:TransReward(oPlayer,sExp,mArgs)
    iExp = math.floor(iExp)
    assert(iExp, string.format("schedule reward exp err: %s", sExp))
    local sReason = self.m_sName
    if mArgs and mArgs.reason then
        sReason = mArgs.reason
    end
    iExp = oPlayer:RewardExp(iExp, sReason, mArgs)
    self:AddKeep(oPlayer:GetPid(),"exp",iExp)
end

function CTempl:RewardCoin(oPlayer, sCoin, mArgs)
    local iCoin = self:TransReward(oPlayer,sCoin,mArgs)
    iCoin = math.floor(iCoin)
    assert(iCoin, string.format("%s reward coin err: %s",self.m_sName,sCoin))
    local sReason = self.m_sName
    if mArgs and mArgs.reason then
        sReason = mArgs.reason
    end
    oPlayer:RewardCoin(iCoin, sReason, mArgs)
    local mKeepItem = self:GetKeep(oPlayer:GetPid(), "item", {})
    mKeepItem[1002] = mKeepItem[1002] or {}
    mKeepItem[1002][1002] = (mKeepItem[1002][1002] or 0) + iCoin
    self:AddKeep(oPlayer:GetPid(), "item", mKeepItem)
    local iTotal = mKeepItem[1002][1002]
    self:AddKeep(oPlayer:GetPid(), "coin", iTotal)
end

function CTempl:RewardOrgOffer(oPlayer, sOrgOffer, mArgs)
    local iOrgOffer = self:TransReward(oPlayer,sOrgOffer,mArgs)
    iOrgOffer = math.floor(iOrgOffer)
    if iOrgOffer < 0 then return end
    local sReason = self.m_sName
    if mArgs and mArgs.reason then
        sReason = mArgs.reason
    end
    oPlayer:RewardOrgOffer(iOrgOffer,sReason)
    self:AddKeep(oPlayer:GetPid(),"orgoffer",iOrgOffer)
end

function CTempl:LogAnalyGame(sGameName,oPlayer,mArgs)
    mArgs = mArgs or {}
    local partner_exp = self:GetKeep(oPlayer:GetPid(), "partner_exp")
    local exp = self:GetKeep(oPlayer:GetPid(), "exp")
    local mCurrency
    local iCoin = self:GetKeep(oPlayer:GetPid(), "coin", 0)
    if iCoin > 0 then
        mCurrency = {[gamedefines.COIN_FLAG.COIN_COIN]=iCoin}
    end
    local mKeepItem = self:GetKeep(oPlayer:GetPid(), "item", {})
    local mItem = {}
    for iShape,info in pairs(mKeepItem) do
        for _,amount in pairs(info) do
            mItem[iShape] = mItem[iShape] or 0
            mItem[iShape] = mItem[iShape] + amount
        end
    end
    local mLog = mArgs.log or {}
    oPlayer:LogAnalyGame(mLog,sGameName,mItem,mCurrency,partner_exp,exp)
end

function CTempl:RewardPartnerExp(oPlayer,sPartnerExp,mArgs)
    mArgs = mArgs or {}
    local mPartner = self:GetFightPartner(oPlayer,mArgs)
    local mExp = {}
    if mPartner then
        for iParId,mInfo in pairs(mPartner) do
            mArgs.level = mInfo.grade
            local iPartnerExp = self:TransReward(oPlayer,sPartnerExp,mArgs)
            iPartnerExp = math.floor(iPartnerExp)
            assert(iPartnerExp, string.format("schedule reward exp err: %s", sPartnerExp))
            if oPlayer.m_oPartnerCtrl:ValidUpgradePartner(mInfo.effect_type) then
                mExp[mInfo.parid] = iPartnerExp
            end
        end
    end
    local sReason = self.m_sName
    if mArgs and mArgs.reason then
        sReason = mArgs.reason
    end
    oPlayer.m_oPartnerCtrl:AddPartnerListExp(table_deep_copy(mExp), sReason, mArgs)
    self:AddKeep(oPlayer:GetPid(),"partner_exp",mExp)
end

function CTempl:GetRandomMax(iItemIdx,mArgs)
    local iTotal = 0
    for _, mItemUnit in pairs(mArgs) do
        iTotal = iTotal + mItemUnit["ratio"]
    end
    return iTotal
end

function CTempl:ChooseRewardKey(mRewardInfo, iItemIdx, mArgs)
    local iLimit = self:GetRandomMax(iItemIdx, mRewardInfo)
    local iRandom = math.random(iLimit)
    local iTotal = 0
    for _, mItemUnit in pairs(mRewardInfo) do
        iTotal = iTotal + mItemUnit["ratio"]
        if iRandom <= iTotal then
            return mItemUnit
        end
    end
end

function CTempl:TransItemShape(oPlayer,iItemIdx,sShape,mArgs)
    return sShape
end

function CTempl:RewardItem(oPlayer,iItemIdx, mArgs)
    if not iItemIdx or iItemIdx == 0 then
        return
    end
    local iPlayerGrade = oPlayer:GetGrade()
    local iRewardGrade = 1
    local mRewardData = self:GetItemRewardData(iItemIdx)
    local mRewardGrade = table_key_list(mRewardData)
    table.sort(mRewardGrade)

    for _,iGrade in ipairs(mRewardGrade) do
        if oPlayer:GetGrade() >= iGrade then
            iRewardGrade = iGrade
        end
    end
    local mRewardInfo = mRewardData[iRewardGrade]

    local mItemInfo = self:ChooseRewardKey(mRewardInfo, iItemIdx, mArgs)
    assert(mItemInfo,string.format("CTempl:RewardItem err:%s %s %s",oPlayer:GetPid(),iPlayerGrade,iItemIdx))

    local mShapeList = mItemInfo["sid"]
    local sShape = mShapeList[math.random(#mShapeList)]
    sShape = self:TransItemShape(oPlayer, iItemIdx, sShape,mArgs)

    local iRecord = mItemInfo["amount"]
    for _,oItem in pairs(self:BuildRewardItemList(mItemInfo,sShape,{pid=oPlayer:GetPid()})) do
        local sName = oItem:Name()
        local sReason = self.m_sName
        if mArgs and mArgs.reason then
            sReason = mArgs.reason
        end
        oPlayer:RewardItem(oItem,sReason)
        if mArgs and mArgs.chuanwen and mItemInfo.sys == 1 then
            local sMsg = mArgs.chuanwen
            sMsg = string.gsub(sMsg,"#role",{["#role"]=oPlayer:GetName()})
            sMsg = string.gsub(sMsg,"#item",sName)
            local oNotify = global.oNotifyMgr
            oNotify:SendSysChat(sMsg,1,1)
        end
    end

    local oItem = loaditem.GetItem(sShape)
    local iShape = oItem:SID()
    local mShowInfo = oItem:GetShowInfo()
    local mKeepItem = self:GetKeep(oPlayer:GetPid(), "item", {})
    local mK = mKeepItem[mShowInfo.sid] or {}
    mK[mShowInfo.virtual] = (mK[mShowInfo.virtual] or 0) + mShowInfo.amount
    mKeepItem[mShowInfo.sid] = mK
    self:AddKeep(oPlayer:GetPid(),"item", mKeepItem)
    if oItem then
        local oChatMgr = global.oChatMgr
        local oNotifyMgr = global.oNotifyMgr
        local sMsg = "获得#amount个#item"
        local mNotifyArgs = {
            amount = iRecord, item = oItem:Name()
        }
        local iPid = oPlayer:GetPid()
        local lMessage = {"GS2CNotify","GS2CConsumeMsg"}
        oNotifyMgr:BroadCastNotify(iPid,lMessage,sMsg,mNotifyArgs)
    end
end

function CTempl:SendRewardToMail(iPid,mBox)
    if mBox then
        local oMailMgr = global.oMailMgr
        local oNotifyMgr = global.oNotifyMgr
        local mData, name = oMailMgr:GetMailInfo(1)
        oMailMgr:SendMail(0, name, iPid, mData, {}, mBox)
        oNotifyMgr:Notify(iPid, "你的背包已满，剩余奖励将以邮件的形式发送至邮箱，请及时领取")
    end
end

function CTempl:TransMonsterAble(oWar,sAttr,mArgs)
    mArgs = mArgs or {}
    local sValue = mArgs.value
    local mEnv = mArgs.env
    local iValue = formula_string(sValue,mEnv)
    return iValue
end

function CTempl:TransReward(oRewardObj,sReward, mArgs)
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local iServerGrade = oWorldMgr:GetServerGrade()
    local iLevel = oRewardObj and oRewardObj:GetGrade()
    if not iLevel then
        iLevel = mArgs.level
    end
    local mEnv = {
        lv = iLevel,
        SLV = iServerGrade,
    }
    local iValue = formula_string(sReward,mEnv)
    return iValue
end

function CTempl:GetSelfCallback()
end