--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"
local extend = require "base/extend"
local record = require "public.record"
local res = require "base.res"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))
local playerctrl = import(service_path("playerctrl.init"))
local equipmgr = import(service_path("equipmgr"))
local skillmgr = import(service_path("skillmgr"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item.loaditem"))
local loadskill = import(service_path("skill.loadskill"))
local stonemgr = import(service_path("stonemgr"))

function NewPlayer(...)
    local o = CPlayer:New(...)
    return o
end

local function SaveDbFunc(self)
    local iPid = self:GetPid()
    if self.m_oItemCtrl:IsDirty() then
        local mData = {
            pid = iPid,
            data = self.m_oItemCtrl:Save()
        }
        gamedb.SaveDb(iPid,"common", "SaveDb", {module = "playerdb",cmd="SavePlayerItem",data = mData})
        self.m_oItemCtrl:UnDirty()
    end
    if self.m_oPartnerCtrl:IsDirty() then
        local mData = {
            pid = iPid,
            data = self.m_oPartnerCtrl:Save()
        }
        gamedb.SaveDb(iPid,"common", "SaveDb", {module ="partnerdb" ,cmd="SavePartner",data = mData})
        self.m_oItemCtrl:UnDirty()
    end
    if self.m_oSkillCtrl:IsDirty() then
        local mData = {
            pid = iPid,
            data = self.m_oSkillCtrl:Save(),
        }
        gamedb.SaveDb(iPid,"common", "SaveDb",{module ="playerdb",cmd = "SaveSkillInfo",data = mData})
        self.m_oSkillCtrl:UnDirty()
    end
    if self.m_oParSoulCtrl:IsDirty() then
        local mData = {
            pid = iPid,
            data = self.m_oParSoulCtrl:Save(),
        }
        gamedb.SaveDb(iPid, "common", "SaveDb", {module = "playerdb", cmd = "SaveParSoulPlan", data = mData})
    end
end

CPlayer = {}
CPlayer.__index = CPlayer
inherit(CPlayer, datactrl.CDataCtrl)

function CPlayer:New(iPid,mRole)
    local o = super(CPlayer).New(self)
    o.m_iPid = iPid
    o.m_mStableData = mRole.stable_data

    o.m_oItemCtrl = playerctrl.NewItemCtrl(o.m_iPid)
    o.m_oPartnerCtrl = playerctrl.NewPartnerCtrl(o.m_iPid)
    o.m_oEquipMgr = equipmgr.NewEquipMgr(o.m_iPid)
    o.m_oSkillCtrl = playerctrl.NewSkillCtrl(o.m_iPid)
    o.m_oSkillMgr = skillmgr.NewSkillMgr(o.m_iPid)
    o.m_oStoneMgr = stonemgr.NewStoneMgr(o.m_iPid)
    o.m_oParSoulCtrl = playerctrl.NewParsoulCtrl(o.m_iPid)

    o:Init(mRole)
    return o
end

function CPlayer:Init(mData)
    self:SetData("name", mData.name)
    self:SetData("grade", mData.grade)
    self:SetData("model_info", mData.model_info)
    self:SetData("school_branch",mData.school_branch)
    self:SetData("equip_strength",mData.equip_strength)
end

function CPlayer:Release()
    baseobj_safe_release(self.m_oItemCtrl)
    baseobj_safe_release(self.m_oSkillMgr)
    baseobj_safe_release(self.m_oEquipMgr)
    baseobj_safe_release(self.m_oPartnerCtrl)
    baseobj_safe_release(self.m_oSkillCtrl)
    baseobj_safe_release(self.m_oStoneMgr)
    baseobj_safe_release(self.m_oParSoulCtrl)
    super(CPlayer).Release(self)
end

function CPlayer:ConfigSaveFunc()
    local iPid = self:GetPid()
    self:ApplySave(function ()
        local oAssistMgr = global.oAssistMgr
        local oPlayer = oAssistMgr:GetPlayer(iPid)
        if not oPlayer then
            record.warning(string.format("伙伴服务,玩家不存在:%d",iPid))
            return
        end
        SaveDbFunc(oPlayer)
    end)
end

function CPlayer:OnLogin(bReEnter,mInfo)
    if mInfo.is_new then
        self:InitNewRole(mInfo)
    end
    self.m_oItemCtrl:OnLogin(self, bReEnter)
    self.m_oPartnerCtrl:OnLogin(self, bReEnter)
    self.m_oSkillCtrl:OnLogin(self,bReEnter)
    self.m_oParSoulCtrl:OnLogin(self, bReEnter)
    self:UpdateFriendEquip()
end

function CPlayer:OnLogout()
    self.m_oPartnerCtrl:OnLogout(self)
    self:DoSave()
end

function CPlayer:Disconnected()
end

function CPlayer:GetName()
    return self:GetData("name")
end

function CPlayer:GetGrade()
    return self:GetData("grade")
end

function CPlayer:GetModelInfo()
    return self:GetData("model_info")
end

function CPlayer:GetShape()
    return self:GetModelInfo().shape
end

function CPlayer:GetSchool()
    return self.m_mStableData["school"]
end

function CPlayer:GetAccount()
    return self.m_mStableData["account"]
end

function CPlayer:GetPower()
    return self:GetData("power")
end

function CPlayer:GetPid()
    return self.m_iPid
end

function CPlayer:GetIP()
    return self.m_mStableData["ip"] or ""
end

function CPlayer:GetPlatform()
    return self.m_mStableData["platform"] or 0
end

function CPlayer:GetPlatformName()
    local sName = gamedefines.GetPlatformName(self:GetPlatform())
    return sName or string.format("未知平台%s",self:GetPlatform())
end

function CPlayer:GetClientOs()
    return self.m_mStableData["client_os"]
end

function CPlayer:GetUdid()
    return self.m_mStableData["udid"]
end

function CPlayer:GetClientVersion()
    return self.m_mStableData["client_version"]
end

function CPlayer:GetChannel()
    return self.m_mStableData["channel"]
end

function CPlayer:GetCpsChannel()
    return self.m_mStableData["cps"] or ""
end

function CPlayer:GetIMEI()
    return self.m_mStableData["imei"] or ""
end

function CPlayer:GetDevice()
    return self.m_mStableData["device"] or ""
end

function CPlayer:GetMac()
    return self.m_mStableData["mac"] or ""
end

function CPlayer:GetSex()
    return self.m_mStableData["sex"] or ""
end

function CPlayer:LogData()
    return {pid=self:GetPid(), name=self:GetName(), grade=self:GetGrade()}
end

function CPlayer:SyncPlayerData(mInfo)
    if mInfo.name then
        self:SetData("name", mInfo.name)
    end
    if mInfo.grade then
        self:SetData("grade", mInfo.grade)
    end
    if mInfo.model_info  then
        self:SetData("model_info", mInfo.model_info)
    end
    if mInfo.school_branch then
        self:SetData("school_branch",mInfo.school_branch)
    end
    if mInfo.power then
        self:SetData("power",mInfo.power)
    end
end

function CPlayer:GetPid()
    return self.m_iPid
end

function CPlayer:HasItem(iItemId)
    return self.m_oItemCtrl:HasItem(iItemId)
end

function CPlayer:Update(mInfo)
end

function CPlayer:Send(sMessage, mData)
    playersend.Send(self:GetPid(),sMessage,mData)
end

function CPlayer:SendRaw(sData)
    playersend.SendRaw(self:GetPid(),sData)
end

function CPlayer:GetItemContainer(iType)
    return self.m_oItemCtrl:GetContainer(iType)
end

function CPlayer:DoResultMoney(bFlag, mData)
    local sCmd = "UnFrozenMoney"
    if bFlag then
        sCmd = "ResumeMoney"
    end
    interactive.Send(".world", "common", sCmd, mData)
end

function CPlayer:RewardCoin(iVal,sReason,mArgs)
    --self.m_oActiveCtrl:RewardCoin(iVal,sReason,mArgs)
    local mData = {
        pid = self:GetPid(),
        val = iVal,
        reason = sReason,
        args = mArgs or {},
    }
    interactive.Send(".world","common","RewardCoin",mData)
end

--道具相关
function CPlayer:RewardItem(itemobj,sReason,mArgs)
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local retobj
    retobj = self.m_oItemCtrl:AddItem(itemobj,sReason,mArgs)
    --添加失败，放入邮件
    if retobj then
        self:SendItemMail(retobj)
    end
    return mResult
end
function CPlayer:ValidGive(sidlist,mArgs)
    local bSuc = self.m_oItemCtrl:ValidGive(sidlist,mArgs)
    return bSuc
end

function CPlayer:GiveItem(sidlist,sReason,mArgs)
    mArgs = mArgs or {}
    self.m_oItemCtrl:GiveItem(sidlist,sReason,mArgs)
end

function CPlayer:ValidRemoveItemAmount(sid, iAmount, mArgs)
    mArgs = mArgs or {}
    assert(iAmount > 0)
    if self:GetItemAmount(sid) >= iAmount then
        return true
    end
    if not mArgs.cancel_tip then
        global.oUIMgr:GS2CItemShortWay(self, sid)
    end
    return false
end

function CPlayer:RemoveItemAmount(sid, iAmount, sReason, mArgs)
    mArgs = mArgs or {}
    local bSuc = self.m_oItemCtrl:RemoveItemAmount(sid, iAmount, sReason, mArgs)
    return bSuc
end

function CPlayer:RemoveItem(iItemId,sReason,mArgs)
    mArgs = mArgs or {}
    local oItem = self.m_oItemCtrl:HasItem(iItemId)
    if not oItem then
        return false
    end
    local bSuc = self.m_oItemCtrl:RemoveItem(oItem,sReason,mArgs.refresh)
    return bSuc
end

function CPlayer:GetItemAmount(sid)
    local iAmount = self.m_oItemCtrl:GetItemAmount(sid)
    return iAmount
end

function CPlayer:GetPubAnalyData()
    return {
        account_id = self:GetAccount(),
        role_id = self:GetPid(),
        role_name = self:GetName(),
        role_level = self:GetGrade(),
        fight_point = self:GetPower(),
        ip = self:GetIP(),
        device_model = self:GetDevice(),
        os = self:GetClientOs(),
        version = self:GetClientVersion(),
        app_channel = self:GetChannel(),
        sub_channel = self:GetCpsChannel(),
        server= MY_SERVER_KEY,
        plat = self:GetPlatform(),
        profession = self:GetSchool(),
        udid = self:GetUdid(),
    }
end

function CPlayer:GetMaxGemCnt(mArgs)
    local res = require "base.res"
    local mData = res["daobiao"]["gem_level"]
    mArgs = mArgs or {}
    local iGrade = mArgs.grade or self:GetGrade()
    local iGemCnt = 0
    for iNeedGrade, mGem in pairs(mData) do
        if iGrade >= iNeedGrade and iGemCnt < mGem.gem_cnt then
            iGemCnt = mGem.gem_cnt
        end
    end
    return iGemCnt
end

function CPlayer:GetSchoolBranch()
    return self:GetData("school_branch",0)
end

function CPlayer:GetWeaponType()
    local iSchool = self:GetSchool()
    local iBranch = self:GetSchoolBranch()
    local mSchoolWeapon = res["daobiao"]["schoolweapon"]["weapon"][iSchool][iBranch]

    return mSchoolWeapon.weapon
end

function CPlayer:IsOverflowCoin(iType,iVal)
    local mCoinInfo = gamedefines.COIN_TYPE[iType]
    assert(mCoinInfo,string.format("MaxCoin %d",iType))
    local iMax = mCoinInfo.max
    return iMax >= iVal
end

function CPlayer:SetRemoteItemData(mRemoteArgs)
    self:SetInfo("remote_item_args",mRemoteArgs)
end

function CPlayer:GetRemoteItemData()
    return self:GetInfo("remote_item_args",{})
end

function CPlayer:ClearRemoteItemData()
    self:SetInfo("remote_item_args",nil)
end

function CPlayer:PacketDifferentItem(lItemList)
    return self.m_oItemCtrl:PacketDifferentItem(lItemList)
end

function CPlayer:PackEquipMgrAttr()
    return {
        equip_attr = self.m_oEquipMgr:PackRemoteData(),
        equip_power = self.m_oItemCtrl:GetWieldEquipPower(),
        equip_se = self.m_oItemCtrl:PackEquipStone()
    }
end

function CPlayer:PackItemShapeAmount()
    return self.m_oItemCtrl:PackItemShapeAmount()
end

function CPlayer:IsMaxStrengthLevel(iPos,mArgs)
    local  iMaxLv = self:GetInfo("equip_max_strength_level")
    if not iMaxLv then
        local sMaxLv = res["daobiao"]["global"]["equip_strength_max_level"]["value"]
        iMaxLv = tonumber(sMaxLv)
        self:SetInfo("equip_max_strength_level", iMaxLv)
    end
    if self:StrengthLevel(iPos,mArgs) >= iMaxLv then
        return true
    end
    return false
end

function CPlayer:StrengthLevel(iPos,mArgs)
    iPos = tostring(iPos)
    local mLevel
    if mArgs then
        mLevel = mArgs.equip_strength
    else
        mLevel = self:GetData("equip_strength",{})
    end
    local iLevel = mLevel[iPos] or 0
    return iLevel
end

function CPlayer:EquipStrength(iPos,iLevel, sReason,mArgs)
    local oEquip = self.m_oItemCtrl:GetEquip(iPos)
    oEquip:StrengthUnEffect(self)
    mArgs = mArgs or {}
    local mLevel = mArgs.equip_strength or {}
    iPos = tostring(iPos)
    local iBefore = mLevel[iPos] or 0
    mLevel[iPos] = iLevel
    self:SetData("equip_strength",mLevel)
    mArgs.equip_strength = mLevel
    oEquip:StrengthEffect(self)

    if table_in_list({1,3,8}, iLevel) then
        local sKey = string.format("装备突破%s级", iLevel)
        global.oAssistMgr:PushAchieve(self:GetPid(), sKey, {value = 1})
    end

    local mLog = {
        pid = self:GetPid(),
        pos = iPos,
        before_level = iBefore,
        after_level = iLevel,
        reason = sReason,
    }
    record.user("equip", "equip_strength", mLog)
end

function CPlayer:GetWeapon()
    local iWeapon = 0
    local oWeapon = self.m_oItemCtrl:GetEquip(1)
    if oWeapon then
        iWeapon = oWeapon:Model()
    end
    return iWeapon
end

function CPlayer:SkillShareUpdate()
    local mSkillLevel = self.m_oSkillCtrl:GetSkillLevel()
    self.m_oSkillMgr:UpdateSkillLevel(mSkillLevel)
    self.m_oSkillMgr:ShareUpdate()
end

function CPlayer:EquipShareUpdate()
    self.m_oEquipMgr:ShareUpdate()
end

function CPlayer:InitNewRole(mInfo)
    local mInitSkillData = res["daobiao"]["init_skill"]
    local iSchool = mInfo.school
    local iSchoolBranch = mInfo.school_branch
    local mSchool = loadskill.GetSchoolSkill(iSchool,iSchoolBranch)
    if mSchool then
        for _,iSkill in pairs(mSchool) do
            local mData = mInitSkillData[iSkill]
            local iLevel = mData["init_level"]
            self.m_oSkillCtrl:SetLevel(iSkill,iLevel,true)
        end
    end
    local mCultivate = loadskill.GetCultivateSkill()
    for _, iSk in ipairs(mCultivate) do
        self.m_oSkillCtrl:SetCultivateLevel(iSk, 0)
    end
end

---------------------------------world交互-----------------------------------------------

function CPlayer:WashSchoolSkill(sReason,mArgs)
    local iSchool = mArgs.school
    local iSchoolBranch = mArgs.school_branch
    local mSkill = loadskill.GetSchoolSkill(iSchool,iSchoolBranch)
    local mInitSkillData = res["daobiao"]["init_skill"]
    for _,iSkill in pairs(mSkill) do
        local oSk = self.m_oSkillCtrl:GetSkill(iSkill)
        if oSk then
            local iBefore = oSk:Level()
            oSk:SkillUnEffect(self)
            local mData = mInitSkillData[iSkill]
            local iLevel = mData["init_level"]
           self.m_oSkillCtrl:SetLevel(iSkill,iLevel)
           oSk:SkillEffect(self)
           self.m_oSkillCtrl:LogSkill("role_skill",iSkill, iBefore, oSk:Level(), sReason)
        end
    end
    self:SkillShareUpdate()
end

function CPlayer:ChangeWeapon()
    local iWeapon = self:GetWeapon()
    local m = self:GetData("model_info")
    m.weapon = iWeapon
    self:SetData("model_info",m)
    local mData = {
        pid = self:GetPid(),
        weapon = iWeapon
    }
    interactive.Send(".world", "item", "ChangeWeapon", mData)
end

function CPlayer:SendItemMail(oItem)
    local iPid = self:GetPid()
    local mData = {
        pid = iPid,
        item = oItem:Save()
    }
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = oItem.overflow_tips or string.format("你的背包已满，%s将以邮件的形式发送至邮箱，请及时领取", oItem:Name())
    oNotifyMgr:Notify(iPid, sMsg)
    interactive.Send(".world","item","SendItemMail",mData)
end

function CPlayer:SwitchSchool(iSchoolBranch)
    self:SetData("school_branch",iSchoolBranch)
    --切换武器
    self.m_oItemCtrl:SwitchWeapon(self)
    self:EquipShareUpdate()

    --切换门派技能
    local mInitSkillData = res["daobiao"]["init_skill"]
    local iSchool = self:GetSchool()
    local mSchoolSkill = loadskill.GetSchoolSkill(iSchool,iSchoolBranch)
    for _,iSkill in pairs(mSchoolSkill) do
        local oSk = self.m_oSkillCtrl:GetSkill(iSkill)
        if not oSk then
            local mData = mInitSkillData[iSkill]
            local iLevel = mData["init_level"]
            self.m_oSkillCtrl:SetLevel(iSkill,iLevel)
        else
            self.m_oSkillCtrl:GS2CRefreshSkill(oSk)
        end
    end
    self:SkillShareUpdate()
    self:UpdateFriendEquip({1})

    local iPos = 1
    local oWeapon = self.m_oItemCtrl:GetEquip(iPos)
    local iWeaponSid = oWeapon and oWeapon:SID() or 0
    local iWeaponTrace = oWeapon and oWeapon:TraceNo() or 0
    local mLog = {
        pid = self:GetPid(),
        name = self:GetName(),
        grade = self:GetGrade(),
        school = self:GetSchool(),
        branch = self:GetSchoolBranch(),
        weapon_sid = iWeaponSid,
        weapon_trace = iWeaponTrace,
    }
    record.user("player", "switch_branch", mLog)
end

function CPlayer:AddTeachTaskProgress(iTask,iProgress)
    local mData = {
        pid = self:GetPid(),
        task = iTask,
        progress = iProgress
    }
    interactive.Send(".world", "common", "AddTeachTaskProgress", mData)
end

function CPlayer:TriggerPartnerTask(iParId)
    local mData = {
        pid = self:GetPid(),
        parid = iParId,
    }
    interactive.Send(".world","common","TriggerPartnerTask",mData)
end

function CPlayer:ComposeAwakeItem(iAwakeSid, iCompose)
    local iPid = self:GetPid()
    local oAssistMgr = global.oAssistMgr
    local oAwake = loaditem.GetItem(iAwakeSid)
    if not iCompose or iCompose <= 0 then
        record.warning("ComposeAwakeItem, pid:%s,compose:%s", self:GetPid(), iCompose)
        return
    end
    if not oAwake:Composable() then
            local sMsg = string.format("%s不可合成", oAwake:Name())
            oAssistMgr:Notify(iPid, sMsg)
        return
    end

    if not self.m_oItemCtrl:ValidGive({{iAwakeSid, iCompose}},{cancel_tip = 1}) then
        oAssistMgr:Notify(iPid, "材料已达上限，合成失败。")
        return
    end

    local mCompose = oAwake:ComposeItemInfo()[1]
    local iCostSid = mCompose.sid
    local iAmount = mCompose.amount
    local iHave = self.m_oItemCtrl:GetItemAmount(iCostSid)
    local iCostAmount = iAmount * iCompose
    if iHave < iCostAmount then
        oAssistMgr:Notify(iPid, "道具不足，合成失败")
        return
    end

    local sReason = "觉醒道具合成"
    local mData = {}
    mData.pid = iPid
    mData.coin = oAwake:CoinCost() * iCompose
    mData.mArgs = {cancel_tip=1}
    mData.reason = sReason
    if mData.coin <= 0 then
        record.warning("ComposeAwakeItem, pid:%s,coin:%s", self:GetPid(), mData.coin)
        return
    end
    interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
        local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
        if oPlayer then
            oPlayer:DoComposeAwakeItem(m, iAwakeSid, iCompose)
        end
    end)
end

function CPlayer:DoComposeAwakeItem(m,iAwakeSid,iCompose)
    if m.success then
        local bFlag = true
        local oAwake = loaditem.GetItem(iAwakeSid)
        local mCompose = oAwake:ComposeItemInfo()[1]
        local iCostSid = mCompose.sid
        local iAmount = mCompose.amount
        local iHave = self.m_oItemCtrl:GetItemAmount(iCostSid)
        local iCostAmount = iAmount * iCompose
        if iHave < iCostAmount then
            bFlag = false
        end
        if not self.m_oItemCtrl:ValidGive({{iAwakeSid, iCompose}},{cancel_tip = 1}) then
            bFlag = false
        end
        if bFlag then
            self.m_oItemCtrl:RemoveItemList({{iCostSid, iCostAmount}}, m.reason)
            self.m_oItemCtrl:GiveItem({{iAwakeSid, iCompose}}, m.reason, {cancel_show = 1})
        end
        self:DoResultMoney(bFlag, m)
    end
end

--{{sid, amount}}
function CPlayer:ValidGivePartner(lPartner, mArgs)
    return self.m_oPartnerCtrl:ValidGive(lPartner, mArgs)
end

function CPlayer:ValidSchoolWeapon(iWeapon, mArgs)
    local res = require "base.res"
    local oAssistMgr = global.oAssistMgr

    local iSchool = self:GetSchool()
    local iBranch = self:GetSchoolBranch()
    local mData = res["daobiao"]["schoolweapon"]["weapon"][iSchool][iBranch]
    return mData.weapon == iWeapon
end

--list:{sid, amount, mArgs}
function CPlayer:GivePartner(lPartner, sReason, mArgs)
    return self.m_oPartnerCtrl:GivePartner(lPartner, sReason, mArgs)
end

function CPlayer:AddDrawPartner(mDraw)
    self.m_oPartnerCtrl:AddDrawPartner(mDraw)
end

function CPlayer:HasDrawPartner()
    return self.m_oPartnerCtrl:HasDrawPartner()
end

function CPlayer:ResetDrawPartner()
    self.m_oPartnerCtrl:AddDrawPartner(nil)
end

function CPlayer:AddSchedule(sCmd)
    interactive.Send(".world", "common", "AddSchedule", {
        pid = self:GetPid(),
        cmd = sCmd,
    })
end

function CPlayer:SynShareObj(mData)
    interactive.Send(".world", "common", "SynShareObj", {
        pid = self:GetPid(),
        args = mData,
    })
end

function CPlayer:UpdateFriendEquip(lPos)
    local mNet = {}
    lPos = lPos or {}
    if not next(lPos) then
        for iPos = 1, 6 do
            table.insert(lPos, iPos)
        end
    end
    for _, iPos in ipairs(lPos) do
        local oEquip = self.m_oItemCtrl:GetEquip(iPos)
        mNet[iPos] = oEquip:PackItemInfo()
    end
    if next(mNet) then
        interactive.Send(".world", "friend", "UpdateFriendEquip",{pid = self:GetPid(), equips = mNet})
    end
end