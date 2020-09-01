
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"
local pfload = import(service_path("perform/pfload"))

local gamedefines = import(lualib_path("public.gamedefines"))
local CWarrior = import(service_path("warrior")).CWarrior
local loadai = import(service_path("ai/loadai"))

function NewPlayerWarrior(...)
    return CPlayerWarrior:New(...)
end

function NewRomPlayerWarrior( ... )
    return CRomPlayerWarrior:New(...)
end

StatusHelperFunc = {}

function StatusHelperFunc.hp(o)
    return o:GetHp()
end

function StatusHelperFunc.max_hp(o)
    return o:GetMaxHp()
end

function StatusHelperFunc.model_info(o)
    return o:GetModelInfo()
end

function StatusHelperFunc.name(o)
    return o:GetName()
end

function StatusHelperFunc.status(o)
    return o.m_oStatus:Get()
end

function StatusHelperFunc.auto_skill(o)
    return o:GetAutoSkill()
end


CPlayerWarrior = {}
CPlayerWarrior.__index = CPlayerWarrior
inherit(CPlayerWarrior, CWarrior)

function CPlayerWarrior:New(iWid, iPid)
    local o = super(CPlayerWarrior).New(self, iWid)
    o.m_iType = gamedefines.WAR_WARRIOR_TYPE.PLAYER_TYPE
    o.m_iPid = iPid
    o.m_iAIType = gamedefines.AI_TYPE.AI_SMART
    self.m_bDisconnected = true
    return o
end

function CPlayerWarrior:Init(mInit)
    self.m_bDisconnected = false
    super(CPlayerWarrior).Init(self, mInit)
    if self:GetTestData("wardebug") then
        local oWar = self:GetWar()
        oWar:AddDebugPlayer(self)
    end
end

function CPlayerWarrior:GetPid()
    return self.m_iPid
end

function CPlayerWarrior:Send(sMessage, mData)
    local oWar = self:GetWar()
    if oWar then
        oWar:Send(self:GetPid(),self:GetWid(),sMessage,mData)
    end
end

function CPlayerWarrior:Disconnected()
    self.m_bDisconnected = true
end

function CPlayerWarrior:SendRaw(sData)
    local oWar = self:GetWar()
    if oWar then
        oWar:SendRaw(self:GetPid(),self:GetWid(),sData)
    end
end

function CPlayerWarrior:IsDisconnected()
    return self.m_bDisconnected
end

function CPlayerWarrior:Notify(sMsg)
    if self.m_iPid then
        self:Send("GS2CNotify",{cmd = sMsg})
    end
end


function CPlayerWarrior:WarNotify(sMsg)
    if self.m_iPid then
        self:Send("GS2CWarNotify",{cmd = sMsg})
    end
end


function CPlayerWarrior:GetTodayFightPartner()
    local mFight = {}
    table_combine(mFight,self:Query("fight_partner",{}))
    table_combine(mFight,self:Query("today_fight",{}))
    return mFight
end

function CPlayerWarrior:SyncFightPartner()
    local list = self:Query("fight_partner",{})
    local oWar = self:GetWar()
    if oWar then
        oWar:RemoteWorldEvent("remote_outfight_partner",{
            war_id = self:GetWarId(),
            pid = self.m_iPid,
            partner_list = list
        })
    end
end

function CPlayerWarrior:ReEnter()
    self:Send("GS2CEnterWar", {})
    self.m_bDisconnected = false
    local oWar = self:GetWar()
    oWar:GS2CWarWave(self)

    self:Send("GS2CWarAddWarrior", {
        war_id = self:GetWarId(),
        camp_id = self:GetCampId(),
        type = self:Type(),
        warrior = self:GetSimpleWarriorInfo(),
    })

    local mWarriorMap = oWar:GetWarriorMap()
    for k, _ in pairs(mWarriorMap) do
        local o = self:GetWarrior(k)
        if o and o:GetWid() ~= self:GetWid() then
            if o:IsPlayer() or o:IsRomPlayer() then
                self:Send("GS2CWarAddWarrior", {
                    war_id = o:GetWarId(),
                    camp_id = o:GetCampId(),
                    type = o:Type(),
                    warrior = o:GetSimpleWarriorInfo(),
                })
            elseif o:IsNpc() then
                self:Send("GS2CWarAddWarrior", {
                    war_id = o:GetWarId(),
                    camp_id = o:GetCampId(),
                    type = o:Type(),
                    npcwarrior = o:GetSimpleWarriorInfo(),
                })
            elseif o:IsPartner() or o:IsRomPartner() then
                self:Send("GS2CWarAddWarrior",{
                        war_id = o:GetWarId(),
                        camp_id = o:GetCampId(),
                        type = o:Type(),
                        partnerwarrior = o:GetSimpleWarriorInfo()
                })
            end
        end
    end

    local mWarriorMap = oWar:GetWarriorMap()
    for k, _ in pairs(mWarriorMap) do
        local oWarrior = self:GetWarrior(k)
        local mBuff = oWarrior.m_oBuffMgr:GetBuffList()
        for _,oBuff in pairs(mBuff) do
            self:Send("GS2CWarBuffBout", {
                war_id = oWarrior:GetWarId(),
                wid = k,
                buff_id = oBuff.m_ID,
                bout  = oBuff:Bout(),
                level = oBuff:BuffLevel(),
                produce_wid = oBuff:GetAttack(),
            })
        end
    end
    local iStatus, iStatusTime = oWar.m_oActionStatus:Get()

    self:Send("GS2CWarBoutStart", {
            war_id = oWar:GetWarId(),
            bout_id = oWar.m_iBout,
            left_time = 0,
        })
    if iStatus == gamedefines.WAR_ACTION_STATUS.OPERATE then
        local oAction = oWar:GetWarrior(oWar:GetNowAction())
        local iTimeOut = 3
        if oAction then
            iTimeOut = math.max(0, math.floor((iStatusTime + self:GetAutoFightTime() - get_msecond())/1000))
        end
        self:Send("GS2CActionStart",{
            war_id=oWar:GetWarId(),
            action_id = self.m_ActionId,
            left_time = iTimeOut,
            })
    else
        self:Send("GS2CActionEnd",{
            war_id=oWar:GetWarId(),
            action_id = self.m_ActionId,
            wid = oWar:GetNowAction()
            })
    end


    local mCommand = {}
    for iWid,_ in pairs(oWar.m_mBoutCmds) do
        table.insert(mCommand,iWid)
    end
    local iCamp = self:GetCampId()
    local oCamp = oWar:GetCamp(iCamp)
    local iSP = 0
    if oCamp then
        iSP = oCamp:GetSP()
    end
    self:Send("GS2CPlayerWarriorEnter",{
        war_id = self.m_iWarId,
        wid = self:GetWid(),
        partner_list = table_key_list(self:GetTodayFightPartner()),
        command_list = mCommand,
        sp = iSP,
    })
    oWar:SendWarSpeed(self)
    if oWar:IsConfig() then
        local iSecs = oWar.m_iWarConfigTime - get_time()
        local bConfig = oWar:GetWarConfigCmd(self:GetWid())
        if bConfig then
            iSecs = 0
        end
        self:Send("GS2CWarConfig",{
            war_id = self.m_iWarId,
            secs = iSecs
        })
    else
        self:RefreshPerformCD()
        local mFriend = self:GetFriendList()
        for _,oFriend in pairs(mFriend) do
            if oFriend:IsPartner() and oFriend:GetData("owner") == self:GetWid() then
                local mCD = oFriend:GetPerformCDList()
                self:Send("GS2CWarSkillCD",{
                     war_id = oFriend:GetWarId(),
                     wid = oFriend:GetWid(),
                     skill_cd = mCD,
                 })
            end
        end
        local mWarTarget = oWar:GetExtData("war_target",{})
        local iTarget = mWarTarget[iCamp]
        local mTarget = {}
        if iTarget then
            table.insert(mTarget,{select_wid = iTarget ,type = 1})
        end
        self:Send("GS2CWarTarget",{
            war_id = oWar:GetWarId(),
            war_target = mTarget
        })
    end
    oWar:RefreshBatleCmd(self:GetCampId(),self)
end

function CPlayerWarrior:GetSimpleWarriorInfo()
    return {
        wid = self:GetWid(),
        pid = self:GetPid(),
        pos = self:GetPos(),
        status = self:GetSimpleStatus(),
        pflist = self:GetPerformLevelList(),
        bcmd = self:GetData("CanBCmd")
    }
end

function CPlayerWarrior:GetSimpleStatus(m)
    local mRet = {}
    if not m then
        m = StatusHelperFunc
    end
    for k, _ in pairs(m) do
        local f = assert(StatusHelperFunc[k], string.format("GetSimpleStatus fail f get %s", k))
        mRet[k] = f(self)
    end
    return net.Mask("base.WarriorStatus", mRet)
end

function CPlayerWarrior:StatusChange(...)
    local l = table.pack(...)
    local m = {}
    for _, v in ipairs(l) do
        m[v] = true
    end
    local mStatus = self:GetSimpleStatus(m)
    self:SendAll("GS2CWarWarriorStatus", {
        war_id = self:GetWarId(),
        wid = self:GetWid(),
        type = self:Type(),
        status = mStatus,
    })
end

function CPlayerWarrior:SetTestData(k, v)
    super(CPlayerWarrior).SetTestData(self, k, v)
    local oWar = self:GetWar()
    if not oWar then
        return
    end
    if k == "wardebug" then
        if v then
            oWar:AddDebugPlayer(self)
        else
            oWar:DelDebugPlayer(self)
        end
    end
end

function CPlayerWarrior:GetAutoSkill()
    if self:IsOpenAutoFight() then
        local iAutoSkill = self:GetData("auto_skill")
        if not iAutoSkill  or iAutoSkill == 0 then
            iAutoSkill = self:ChooseSkillAuto()
        end
        return iAutoSkill
    end
    return 0
end

function CPlayerWarrior:StartAutoFight()
    local bRefresh = false
    if not self:IsOpenAutoFight() then
        self:OpenAutoFightSwitch()
        bRefresh = true
    end
    local mAction = {}
    local iAutoSkill = self:ChooseSkillAuto()
    if iAutoSkill ~= self:GetData("auto_skill",0) then
        self:SetAutoSkill(iAutoSkill,true)
    else
        if bRefresh then
            self:AutoSkillStatusChange()
        end
    end
    mAction[self:GetWid()] = 1
    local iWid = self:GetWid()
    local mFriend = self:GetFriendList(true)
    for _,oFriend in pairs(mFriend) do
        if (oFriend:IsPartner() or oFriend:IsNpc()) and oFriend:GetData("owner") == iWid then
            local iAutoSkill = oFriend:ChooseSkillAuto()
            if iAutoSkill ~= oFriend:GetData("auto_skill",0) then
                oFriend:SetAutoSkill(iAutoSkill,true)
            end
            if bRefresh then
                self:AutoSkillStatusChange(oFriend)
            end
            mAction[oFriend:GetWid()] = 1
        end
    end
    local oWar = self:GetWar()
    for iWid,_ in pairs(mAction) do
        local oAction = oWar:GetWarrior(iWid)
        if not oWar:GetBoutCmd(iWid) then
            local iAIType = oAction:GetAIType()
            local oAIObj = loadai.GetAI(iAIType)
            if oAIObj then
                oAIObj:Command(oAction)
            end
        end
    end
end

function CPlayerWarrior:AutoFight()
    self:SyncAutoFight()
    local oWar = self:GetWar()
    local iNowAcion = oWar:GetNowAction()
    local oAction = oWar:GetWarrior(iNowAcion)
    if oWar.m_oActionStatus:Get() == gamedefines.WAR_ACTION_STATUS.OPERATE then
        if iNowAcion == self:GetWid() or ( oAction and (oAction:IsPartner() or oAction:IsNpc()) and oAction:GetData("owner") == self:GetWid()) then
            oWar:ActionAutoStart()
        end
    end
end


function CPlayerWarrior:CancleAutoFight()
    self:CloseAutoFightSwitch()
    self:AutoSkillStatusChange()
    local iWid = self:GetWid()
    local mFriend = self:GetFriendList()
    for _,oFriend in pairs(mFriend) do
        if (oFriend:IsPartner() or oFriend:IsNpc()) and oFriend:GetData("owner") == iWid then
            self:AutoSkillStatusChange(oFriend)
        end
    end
    local oWar = self:GetWar()
    local iCamp = self:GetCampId()
    local oCamp = oWar:GetCamp(iCamp)
    if  self:ValidWarTarget() then
        local mWarTarget = oWar:GetExtData("war_target",{})
        local iTarget = mWarTarget[iCamp]
        local mTarget = {}
        if iTarget then
            table.insert(mTarget,{select_wid = iTarget ,type = 0})
        end
        mWarTarget[iCamp] = nil
        oWar:SetExtData("war_target",mWarTarget)
        oCamp:SendAll("GS2CWarTarget",{
            war_id = oWar:GetWarId(),
            war_target = mTarget
        })
    end
end

function CPlayerWarrior:IsOpenAutoFight()
    if self:GetData("auto_skill_switch",0) == 1 then
        return true
    else
        return false
    end
end

function CPlayerWarrior:OpenAutoFightSwitch()
    self:SetData("auto_skill_switch",1)
end

function CPlayerWarrior:CloseAutoFightSwitch()
    self:SetData("auto_skill_switch",0)
end


function CPlayerWarrior:ValidWarTarget()
    local oWar = self:GetWar()
    if oWar:IsSinglePlayer() then
        return true
    end
    if self:GetData("is_team_leader") then
        return true
    end
    if self:GetData("team_size") <= 1 then
        return true
    end
    return false
end


function CPlayerWarrior:NowFight()
    local mAction = {}
    mAction[self:GetWid()] = 1
    local iWid = self:GetWid()
    local mFriend = self:GetFriendList(true)
    for _,oFriend in pairs(mFriend) do
        if (oFriend:IsPartner() or oFriend:IsNpc()) and oFriend:GetData("owner") == iWid then
            mAction[oFriend:GetWid()] = 1
        end
    end
    local oWar = self:GetWar()
    for iWid,_ in pairs(mAction) do
        local oAction = oWar:GetWarrior(iWid)
        if oAction and not oWar:GetBoutCmd(iWid) then
            local iAIType = oAction:GetAIType()
            local oAIObj = loadai.GetAI(iAIType)
            if oAIObj then
                oAIObj:NowCommand(oAction)
            end
        end
    end
end

function CPlayerWarrior:AutoSkillStatusChange(oWarrior)
    oWarrior = oWarrior or self
    local m = {
        ["auto_skill"] = true
    }
    local mStatus = oWarrior:GetSimpleStatus(m)
    self:Send("GS2CWarWarriorStatus", {
        war_id = self:GetWarId(),
        wid = oWarrior:GetWid(),
        type = oWarrior:Type(),
        status = mStatus,
    })
end

function CPlayerWarrior:GetNormalAttackSkillId()
    local iSchool = self:GetData("school")
    local iSchoolBranch = self:GetData("school_branch")
    local iPerform = 3000 + ((iSchool - 1) * 2 + iSchoolBranch - 1) * 100 + 1
    return iPerform
end

function CPlayerWarrior:GetPlaySpeed()
    return self:GetData("play_speed",1)
end

function CPlayerWarrior:SetPlaySpeed(iSpeed)
    self:SetData("play_speed",iSpeed)
    self:SendAll("GS2CWarSetPlaySpeed",{
        war_id = self:GetWarId(),
        play_speed = iSpeed
    })
end

function CPlayerWarrior:SetWarTarget(iType,iWid)
    local oWar = self:GetWar()
    if not self:ValidWarTarget() then
        return
    end
    local iCamp = self:GetCampId()
    local oCamp = self:GetCamp()
    if iType == 1 then
        local mWarTarget = oWar:GetExtData("war_target",{})
        local iOldTarget = mWarTarget[iCamp]
        local mTarget = {}
        if iOldTarget then
            table.insert(mTarget,{select_wid = iOldTarget ,type = 0})
        end
        table.insert(mTarget,{select_wid = iWid,type = 1})
        mWarTarget[iCamp] = iWid
        oWar:SetExtData("war_target",mWarTarget)
        oCamp:SendAll("GS2CWarTarget",{
            war_id = oWar:GetWarId(),
            war_target = mTarget
        })
    else
        local mWarTarget = oWar:GetExtData("war_target",{})
        local iOldTarget = mWarTarget[iCamp]
        local mTarget = {}
        if iOldTarget then
            table.insert(mTarget,{select_wid = iOldTarget,type = 0})
        end
        mWarTarget[iCamp] = nil
        oWar:SetExtData("war_target",mWarTarget)
        oCamp:SendAll("GS2CWarTarget",{
            war_id = oWar:GetWarId(),
            war_target = mTarget
        })
    end
end

function CPlayerWarrior:ValilBattleCommand()
    local oWar = self:GetWar()
    if oWar:IsSinglePlayer() then
        return true
    end
    if self:GetData("is_team_leader") then
        return true
    end
    if self:GetData("team_size") <= 1 then
        return true
    end
    if self:GetData("CanBCmd",0) ~=0 then
        return true
    end
    return false
end

function CPlayerWarrior:BattleCommand(wid,sCmd)
    local oWar = self:GetWar()
    if not self:ValilBattleCommand() then
        return
    end
    oWar:SetBattleCmd(self:GetCampId(),wid,sCmd)
end


function CPlayerWarrior:CleanBattleCommand(wid)
    local oWar = self:GetWar()
    if not self:ValilBattleCommand() then
        return
    end
    oWar:SetBattleCmd(self:GetCampId(),wid,nil)
end





function CPlayerWarrior:AutoCommand()
    if self:GetActionCmd() then
        return
    end
    if not self:IsOpenAutoFight() then
        self:SyncAutoFight()
    end
    super(CPlayerWarrior).AutoCommand(self)
end


function CPlayerWarrior:SyncAutoFight()
    self:OpenAutoFightSwitch()
    local iAutoSkill = self:ChooseSkillAuto()
    if iAutoSkill ~= self:GetData("auto_skill",0) then
        self:SetAutoSkill(iAutoSkill,true)
    else
        self:AutoSkillStatusChange()
    end
    self:Set("action_skill",nil)
    local iWid = self:GetWid()
    local mFriend = self:GetFriendList(true)
    for _,oFriend in pairs(mFriend) do
        if (oFriend:IsPartner() or oFriend:IsNpc()) and oFriend:GetData("owner") == iWid then
            local iFriendAutoSkill = oFriend:ChooseSkillAuto()
            if iFriendAutoSkill ~= oFriend:GetData("auto_skill",0) then
                oFriend:SetAutoSkill(iFriendAutoSkill,true)
            else
                self:AutoSkillStatusChange(oFriend)
            end
            oFriend:Set("action_skill",nil)
        end
    end
end

function CPlayerWarrior:GetAutoFightTime()
    local oWar = self:GetWar()

    if self:IsOpenAutoFight() and oWar.m_ActionId >1  then
        return 0
    end
    local oWar = self:GetWar()
    if oWar:IsSinglePlayer() then
        return 15
    else
        return 10
    end
end

function CPlayerWarrior:GetBoutAutoFightTime()
    if not self:IsOpenAutoFight() then
        return 0
    end
    local oWar = self:GetWar()
    if oWar.m_ActionId == 1 then
        return 4000
    end
    return 0
end
function CPlayerWarrior:GetFunction(sFunction)
    local mFunction = super(CPlayerWarrior).GetFunction(self,sFunction)
    local mCallback = {}
    for iNo,fCallback in pairs(mFunction) do
        local oPf = self.m_oPerformMgr:GetPerform(iNo)
        if oPf then
            if oPf:IsPassiveSkill() then
                local iRet = self:BanPassiveSkill()
                if not iRet then
                    mCallback[iNo] = fCallback
                elseif iRet == 1 then
                    if not pfload.IsEquipSkill(iNo) then
                        mCallback[iNo] = fCallback
                    end
                end
            else
                mCallback[iNo] = fCallback
            end
        else
            mCallback[iNo] = fCallback
        end
    end
    return mCallback
end

function CPlayerWarrior:BanCampPassiveSkill(iNo)
    local oPf = self.m_oPerformMgr:GetPerform(iNo)
    if oPf then
        if oPf:IsPassiveSkill() then
            local iRet = self:BanPassiveSkill()
            if iRet and ((iRet == 2) or (iRet == 1 and pfload.IsEquipSkill(iNo))) then
                return true
            else
                return false
            end
        else
            return false
        end
    else
        return true
    end
end

function CPlayerWarrior:SpecialRatio(iPerform)
    local mSkillRatio = self:GetData("skill_ratio",{})
    return mSkillRatio[iPerform] or 0
end

CRomPlayerWarrior = {}
CRomPlayerWarrior = {}
CRomPlayerWarrior.__index = CRomPlayerWarrior
inherit(CRomPlayerWarrior, CPlayerWarrior)

function CRomPlayerWarrior:New(iWid, iPid)
    local o = super(CRomPlayerWarrior).New(self, iWid)
    o.m_iType = gamedefines.WAR_WARRIOR_TYPE.ROM_PLAYER_TYPE
    o.m_iPid = iPid
    o.m_iAIType = gamedefines.AI_TYPE.ROM_AI_SMART
    return o
end


function CRomPlayerWarrior:Init(mInit)
    super(CPlayerWarrior).Init(self, mInit)
    self.m_bDisconnected = true
end

function CRomPlayerWarrior:ReEnter()
    --
end

function CRomPlayerWarrior:SyncFightPartner()
    --
end

function CRomPlayerWarrior:GetAutoFightTime()
    return 0
end