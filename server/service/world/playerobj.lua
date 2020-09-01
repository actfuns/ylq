--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"
local res = require "base.res"
local record = require "public.record"
local cjson = require "cjson"
local httpuse = require "public.httpuse"
local colorstring = require "public.colorstring"
local router = require "base.router"

local gamedb = import(lualib_path("public.gamedb"))
local ppower = import(lualib_path("public.ppower"))
local analy = import(lualib_path("public.dataanaly"))
local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))
local playernet = import(service_path("netcmd/player"))
local playerctrl = import(service_path("playerctrl.init"))
local skillmgr = import(service_path("skillmgr"))
local loadtask = import(service_path("task/loadtask"))
local equipmgr = import(service_path("equipmgr"))
local loadskill = import(service_path("skill/loadskill"))
local bigpacket = import(lualib_path("public.bigpacket"))
local loaditem = import(service_path("item.loaditem"))
local stonemgr = import(service_path("stonemgr"))

function NewPlayer(...)
    local o = CPlayer:New(...)
    return o
end

OPEN_CPOWER = 1

PropHelperFunc = {}

function PropHelperFunc.open_day(oPlayer)
    return global.oWorldMgr:GetOpenDays()
end

function PropHelperFunc.grade(oPlayer)
    return oPlayer:GetGrade()
end

function PropHelperFunc.systemsetting(oPlayer)
    return oPlayer:GetSystemSetting()
end

function PropHelperFunc.name(oPlayer)
    return oPlayer:GetName()
end

function PropHelperFunc.title_info(oPlayer)
    return oPlayer:PackTitleInfo()
end

function PropHelperFunc.goldcoin(oPlayer)
    return oPlayer:GetProfile():GoldCoin()
end

function PropHelperFunc.coin(oPlayer)
    local iCoin = oPlayer.m_oActiveCtrl:GetData("coin")
    local iFrozen = oPlayer:GetFrozenMoney("coin")
    return math.max(iCoin - iFrozen, 0)
end

function PropHelperFunc.medal(oPlayer)
    return oPlayer.m_oActiveCtrl:GetData("medal")
end

function PropHelperFunc.color_coin(oPlayer)
    return oPlayer:GetProfile():ColorCoin()
end

function PropHelperFunc.exp(oPlayer)
    return oPlayer.m_oActiveCtrl:GetData("exp")
end

function PropHelperFunc.chubeiexp(oPlayer)
    return oPlayer.m_oActiveCtrl:GetData("chubeiexp")
end

function PropHelperFunc.max_hp(oPlayer)
    return oPlayer:GetMaxHp()
end

function PropHelperFunc.hp(oPlayer)
    return oPlayer:GetHp()
end

function PropHelperFunc.attack(oPlayer)
    return oPlayer:GetAttack()
end

function PropHelperFunc.defense(oPlayer)
    return oPlayer:GetDefense()
end

function PropHelperFunc.speed(oPlayer)
    return oPlayer:GetSpeed()
end

function PropHelperFunc.critical_ratio(oPlayer)
    return oPlayer:GetCirticalRatio()
end

function PropHelperFunc.res_critical_ratio(oPlayer)
    return oPlayer:GetResCriticalRatio()
end

function PropHelperFunc.critical_damage(oPlayer)
    return oPlayer:GetCriticalDamage()
end

function PropHelperFunc.cure_critical_ratio(oPlayer)
    return oPlayer:GetCureCriticalRatio()
end

function PropHelperFunc.abnormal_attr_ratio(oPlayer)
    return oPlayer:GetAbnormalAttrRatio()
end

function PropHelperFunc.res_abnormal_ratio(oPlayer)
    return oPlayer:GetResAbnormalRatio()
end

function PropHelperFunc.model_info(oPlayer)
    return oPlayer:GetModelInfo()
end

function PropHelperFunc.school(oPlayer)
    return oPlayer:GetSchool()
end

function PropHelperFunc.coin_over(oPlayer)
    return oPlayer.m_oActiveCtrl:GetData("coin_over", 0)
end

function PropHelperFunc.followers(oPlayer)
    return oPlayer:GetFollowers()
end

function PropHelperFunc.power(oPlayer)
    return oPlayer:GetPower()
end

function PropHelperFunc.school_branch(oPlayer)
    return oPlayer.m_oBaseCtrl:GetData("school_branch")
end

function PropHelperFunc.skill_point(oPlayer)
    local iSchoolBranch = oPlayer.m_oBaseCtrl:GetData("school_branch")
    return oPlayer.m_oActiveCtrl:GetSkillPoint(iSchoolBranch)
end

function PropHelperFunc.upvote_amount(oPlayer)
    return oPlayer:GetUpvoteAmount()
end

function PropHelperFunc.arenamedal(oPlayer)
    return oPlayer:ArenaMedal()
end

function PropHelperFunc.org_offer(oPlayer)
    return oPlayer:GetOffer()
end

function PropHelperFunc.energy(oPlayer)
    return oPlayer:GetEnergy()
end

function PropHelperFunc.sex(oPlayer)
    return oPlayer:GetSex()
end

function PropHelperFunc.active(oPlayer)
    return oPlayer:Active()
end

function PropHelperFunc.org_fuben_cnt(oPlayer)
    return oPlayer:GetOrgFubenCnt()
end

function PropHelperFunc.trapmine_point(oPlayer)
    return oPlayer:TrapminePoint()
end

function PropHelperFunc.skin(oPlayer)
    return oPlayer:Skin()
end

function PropHelperFunc.kp_sdk_info(oPlayer)
    return oPlayer:GetKpSdkInfo()
end

function PropHelperFunc.travel_score(oPlayer)
    return oPlayer:GetTravelScore()
end
function PropHelperFunc.bcmd(oPlayer)
    return oPlayer:BattleCommand()
end


function PropHelperFunc.show_id(oPlayer)
    return oPlayer:GetShowId()
end

function PropHelperFunc.chatself(oPlayer)
    return oPlayer.m_oThisTemp:Query("chatself",false)
end

function PropHelperFunc.camp(oPlayer)
    return oPlayer:GetCamp()
end

local mSaveDbCmd = {
    ["main"] = "SavePlayerMain",
    ["basectrl"] = "SavePlayerBase",
    ["activectrl"] = "SavePlayerActive",
    ["timectrl"] = "SavePlayerTimeInfo",
    ["taskctrl"] = "SavePlayerTaskInfo",
    ["skillctrl"] = "SaveSkillInfo",
    ["schedulectrl"] = "SavePlayerSchedule",
    ["partnerctrl"] = "SavePlayerPartner",
    ["titlectrl"] = "SavePlayerTitle",
    ["statectrl"] = "SavePlayerState",
    ["huodongctrl"] = "SavePlayerHuodongInfo",
    ["handlebookctrl"] = "SavePlayerHandBook",
}

local function SaveDbFunc(self)
    local iPid = self:GetPid()
    local sSaveModule = "playerdb"
    if self:IsDirty() then
        local sCmd = mSaveDbCmd["main"]
        local mData = {
            pid = self:GetPid(),
            data = self:Save()
        }
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self:UnDirty()
    end
    if self.m_oBaseCtrl:IsDirty() then
        local sCmd = mSaveDbCmd["basectrl"]
        local mData = {
            pid = self:GetPid(),
            data = self.m_oBaseCtrl:Save(),
        }
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self.m_oBaseCtrl:UnDirty()
    end
    if self.m_oActiveCtrl:IsDirty() then
        local sCmd = mSaveDbCmd["activectrl"]
        local mData = {
            pid = self:GetPid(),
            data = self.m_oActiveCtrl:Save(),
        }
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self.m_oActiveCtrl:UnDirty()
    end
    if self.m_oTimeCtrl:IsDirty() then
        local sCmd = mSaveDbCmd["timectrl"]
        local mData = {
            pid = self:GetPid(),
            data = self.m_oTimeCtrl:Save(),
        }
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self.m_oTimeCtrl:UnDirty()
    end
    if self.m_oTaskCtrl:IsDirty() then
        local sCmd = mSaveDbCmd["taskctrl"]
        local mData = {
            pid = self:GetPid(),
            data = self.m_oTaskCtrl:Save(),
        }
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self.m_oTaskCtrl:UnDirty()
    end
    if self.m_oScheduleCtrl:IsDirty() then
        local mData = {
            pid = self:GetPid(),
            data = self.m_oScheduleCtrl:Save(),
        }
        local sCmd = mSaveDbCmd["schedulectrl"]
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self.m_oScheduleCtrl:UnDirty()
    end
    if self.m_oPartnerCtrl:IsDirty() then
        local mData = {
            pid = self:GetPid(),
            data = self.m_oPartnerCtrl:Save(),
        }
        local sCmd = mSaveDbCmd["partnerctrl"]
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self.m_oPartnerCtrl:UnDirty()
    end
     if self.m_oTitleCtrl:IsDirty() then
        local mData = {
            pid = self:GetPid(),
            data = self.m_oTitleCtrl:Save(),
        }
        local sCmd = mSaveDbCmd["titlectrl"]
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self.m_oTitleCtrl:UnDirty()
    end
    if self.m_oStateCtrl:IsDirty() then
         local mData = {
            pid = self:GetPid(),
            data = self.m_oStateCtrl:Save(),
         }
         local sCmd = mSaveDbCmd["statectrl"]
         gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
         self.m_oStateCtrl:UnDirty()
    end
    if self.m_oHuodongCtrl:IsDirty() then
        local mData = {
            pid = self:GetPid(),
            data = self.m_oHuodongCtrl:Save(),
         }
        local sCmd = mSaveDbCmd["huodongctrl"]
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self.m_oHuodongCtrl:UnDirty()
    end
    if self.m_oHandBookCtrl:IsDirty() then
        local mData = {
            pid = self:GetPid(),
            data = self.m_oHandBookCtrl:Save(),
         }
        local sCmd = mSaveDbCmd["handlebookctrl"]
        gamedb.SaveDb(iPid,"common", "SaveDb",{module = sSaveModule,cmd = sCmd,data = mData})
        self.m_oHandBookCtrl:UnDirty()
    end
    local oProfile = self:GetProfile()
    if oProfile then
        oProfile:SaveDb()
    end
end

CPlayer = {}
CPlayer.__index = CPlayer
CPlayer.m_sClassType = "player"
inherit(CPlayer, datactrl.CDataCtrl)

function CPlayer:New(mConn, mRole)
    local o = super(CPlayer).New(self)

    o.m_iNetHandle = mConn.handle
    o.m_sIP = mConn.ip

    o.m_sBornServer = mRole.born_server or get_server_tag()
    o.m_sRoleToken = mRole.role_token
    o.m_sAccountToken = mRole.account_token
    o.m_iPid = mRole.pid
    o.m_sAccount = mRole.account

    o.m_sMac = mRole.mac
    o.m_sDevice = mRole.device
    o.m_iPlatform = mRole.platform
    o.m_iBornPlatform = mRole.born_platform
    o.m_iQrcode = mRole.is_qrcode
    o.m_iChannel = mRole.channel
    o.m_sCpsChannel = mRole.cps
    o.m_sIMEI = mRole.imei
    o.m_sPublisher = mRole.publisher

    o.m_iCreateTime = mRole.create_time or 0
    o.m_iSceneModel = mRole.scene_model or 1
    o.m_sUdid = mRole.udid or ""
    o.m_sClientOs = mRole.client_os or ""
    o.m_sClientVersion = mRole.client_version

    o.m_oBigPacketMgr = bigpacket.CBigPacketMgr:New()

    o.m_iDisconnectedTime = nil
    o.m_fHeartBeatTime = get_time()
    o.m_iLogoutJudgeTime = 20*60
    o.m_iTestLogoutJudgeTimeMode = nil

    o.m_oBaseCtrl = playerctrl.NewBaseCtrl(o.m_iPid)
    o.m_oActiveCtrl = playerctrl.NewActiveCtrl(o.m_iPid)
    o.m_oItemCtrl = playerctrl.NewItemCtrl(o.m_iPid)
    o.m_oThisTemp = playerctrl.NewThisTempCtrl(o.m_iPid)
    o.m_oToday = playerctrl.NewTodayCtrl(o.m_iPid)
    o.m_oThisWeek = playerctrl.NewWeekCtrl(o.m_iPid)
    o.m_oSeveralDay = playerctrl.NewSeveralDayCtrl(o.m_iPid)
    o.m_oTodayMorning = playerctrl.NewTodayMorningCtrl(o.m_iPid)
    o.m_oMonth = playerctrl.NewMonthCtrl(o.m_iPid)
    o.m_oTimeCtrl = playerctrl.NewTimeCtrl(o.m_iPid,{
        ["Today"] = o.m_oToday,
        ["Week"] = o.m_oThisWeek,
        ["ThisTemp"] = o.m_oThisTemp,
        ["SeveralDay"] = o.m_oSeveralDay,
        ["TodayMorning"] = o.m_oTodayMorning,
        ["Month"] = o.m_oMonth,
        })
    o.m_oTaskCtrl = playerctrl.NewTaskCtrl(o.m_iPid)
    o.m_oSkillCtrl = playerctrl.NewSkillCtrl(o.m_iPid)
    o.m_oSkillMgr = skillmgr.NewSkillMgr(o.m_iPid)
    o.m_oEquipMgr = equipmgr.NewEquipMgr(o.m_iPid)
    o.m_oScheduleCtrl = playerctrl.NewScheduleCtrl(o.m_iPid)
    o.m_oStateCtrl = playerctrl.NewStateCtrl(o.m_iPid)
    o.m_oPartnerCtrl = playerctrl.NewPartnerCtrl(o.m_iPid)
    o.m_oTitleCtrl = playerctrl.NewTitleCtrl(o.m_iPid)
    o.m_oHuodongCtrl = playerctrl.NewHuodongCtrl(o.m_iPid)
    o.m_oHandBookCtrl = playerctrl.NewHandBookCtrl(o.m_iPid)
    o.m_oStoneMgr = stonemgr.NewStoneMgr(o.m_iPid)
    o.m_mHouseAttr = {}
    o:ConfirmAssistRemote()
    o.m_cPower = ppower.NewCPower()
    return o
end

function CPlayer:Release()
    local iPid = self:GetPid()
    baseobj_safe_release(self.m_oBaseCtrl)
    baseobj_safe_release(self.m_oActiveCtrl)
    baseobj_safe_release(self.m_oItemCtrl)
    baseobj_safe_release(self.m_oTaskCtrl)
    baseobj_safe_release(self.m_oSkillCtrl)
    baseobj_safe_release(self.m_oScheduleCtrl)
    baseobj_safe_release(self.m_oStateCtrl)
    baseobj_safe_release(self.m_oPartnerCtrl)
    baseobj_safe_release(self.m_oTitleCtrl)
    baseobj_safe_release(self.m_oTimeCtrl)
    baseobj_safe_release(self.m_oHandBookCtrl)
    baseobj_safe_release(self.m_oEquipMgr)
    baseobj_safe_release(self.m_oSkillMgr)
    baseobj_safe_release(self.m_oStoneMgr)
    baseobj_safe_release(self.m_oHuodongCtrl)
    baseobj_safe_release(self.m_cPower)
    super(CPlayer).Release(self)
end

function CPlayer:ConfirmAssistRemote()
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local iRemoteAddr = oAssistMgr:SelectRemoteAssist(iPid)
    self.m_iRemoteAssistAddr = iRemoteAddr
end

function CPlayer:GetAssistRemote()
    return self.m_iRemoteAssistAddr
end

function CPlayer:ReInitRoleInfo(mConn, mRole)
    self.m_sIP = mConn.ip
    self.m_sMac = mRole.mac
    self.m_sDevice = mRole.device
    self.m_iPlatform = mRole.platform
    self.m_sRoleToken = mRole.role_token
    self.m_sAccountToken = mRole.account_token
end

function CPlayer:GetRoleToken()
    return self.m_sRoleToken
end

function CPlayer:GetAccountToken()
    return self.m_sAccountToken
end

function CPlayer:GetBornServer()
    return self.m_sBornServer
end

function CPlayer:GetBornServerKey()
    return make_server_key(self.m_sBornServer)
end

function CPlayer:GetNowServer()
    return self:GetData("now_server")
end

function CPlayer:SetNowServer()
    return self:SetData("now_server", get_server_tag())
end

function CPlayer:SetLogoutJudgeTime(i)
    self.m_iLogoutJudgeTime = i or 20*60
end

function CPlayer:GetLogoutJudgeTime()
    return self.m_iLogoutJudgeTime
end

function CPlayer:SetTestLogoutJudgeTimeMode(iMode)
    assert(table_in_list({0,1, 2, 3, 4,5}, iMode), string.format("SetTestLogoutJudgeTimeMode %d", iMode))
    self.m_iTestLogoutJudgeTimeMode = iMode
end

function CPlayer:GetTestLogoutJudgeTimeMode()
    return self.m_iTestLogoutJudgeTimeMode
end

function CPlayer:GetOfflineTrapmineLogoutTime()
    local iTime = 30 * 60
    if self:IsZskVip() or self:IsMonthCardVip() then
        iTime = 60 * 60
    end
    return iTime
end

function CPlayer:GetOffer()
    return self.m_oActiveCtrl:GetOffer()
end

function CPlayer:ValidOrgOffer(iOffer,mArgs)
    return self.m_oActiveCtrl:ValidOrgOffer(iOffer,mArgs)
end

function CPlayer:RewardOrgOffer(iOffer,sReason,mArgs)
    self.m_oActiveCtrl:RewardOrgOffer(iOffer,sReason,mArgs)
end

function CPlayer:ResumeOrgOffer(iOffer,sReason,mArgs)
    self.m_oActiveCtrl:ResumeOrgOffer(iOffer,sReason,mArgs)
end

function CPlayer:ValidEnergy(iEnergy,mArgs)
    return self.m_oActiveCtrl:ValidEnergy(iEnergy,mArgs)
end

function CPlayer:RewardEnergy(iEnergy,sReason,mArgs)
    self.m_oActiveCtrl:RewardEnergy(iEnergy,sReason,mArgs)
end

function CPlayer:ResumeEnergy(iEnergy,sReason,mArgs)
    self.m_oActiveCtrl:ResumeEnergy(iEnergy,sReason,mArgs)
end

function CPlayer:NotifyMessage(msg)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(self:GetPid(), msg)
end

function CPlayer:PackWarInfo()
    local mRet = {}
    mRet.pid = self.m_iPid
    mRet.grade = self:GetGrade()
    mRet.name = self:GetName()
    mRet.school = self:GetSchool()
    mRet.school_branch = self:GetSchoolBranch()
    mRet.hp = self:GetMaxHp()
    mRet.max_hp = self:GetMaxHp()
    mRet.model_info = self:GetModelInfo()
    mRet.attack = self:GetAttack()
    mRet.defense = self:GetDefense()
    mRet.critical_ratio = self:GetCirticalRatio()
    mRet.res_critical_ratio = self:GetResCriticalRatio()
    mRet.critical_damage = self:GetCriticalDamage()
    mRet.cure_critical_ratio = self:GetCureCriticalRatio()
    mRet.abnormal_attr_ratio = self:GetAbnormalAttrRatio()
    mRet.res_abnormal_ratio = self:GetResAbnormalRatio()
    mRet.speed = self:GetSpeed()
    mRet.perform = self:GetSchoolPerform()
    mRet.is_team_leader = self:IsTeamLeader()
    mRet.team_size = self:GetTeamSize()
    mRet.auto_skill = self.m_oActiveCtrl:GetAutoSkill()
    mRet.auto_skill_switch = self.m_oActiveCtrl:GetAutoSkillSwitch()
    mRet.protectors = self:GetProtectors()
    mRet.double_attack_suspend = self:IsDoubleAttackSuspend()
    mRet.systemsetting = self:GetSystemSetting()
    mRet.testman = self:GetData("testman")
    mRet.CanBCmd = self:CanBattleCommand()
    return mRet
end

function CPlayer:BattleCommand()
    local mData = self.m_oBaseCtrl:GetData("BattleCommand")
    local m = {}
    for k,v in pairs(mData) do
        table.insert(m,{idx=k,cmd=v})
    end
    return m
end

function CPlayer:CanBattleCommand()
    local oTeam = self:HasTeam()
    if not oTeam  then
        return 0
    end
    if oTeam:IsLeader(self:GetPid()) or oTeam:InWarBattleCmd(self:GetPid()) then
        return 1
    end
    return 0
end


function CPlayer:PackKuFuInfo()
    local mRet = {}
    mRet.pid = self.m_iPid
    mRet.grade = self:GetGrade()
    mRet.name = self:GetName()
    mRet.school = self:GetSchool()
    mRet.school_branch = self:GetSchoolBranch()
    mRet.mode_info = self:GetModelInfo()
    mRet.server_grade = global.oWorldMgr:GetServerGrade()
    mRet.avegrade = self:GetAveGrade()
    return mRet
end

function CPlayer:GetKFProxy()
    return global.oKFMgr:GetProxy(self:GetPid())
end


function CPlayer:GetNowWar()
    return self.m_oActiveCtrl:GetNowWar()
end

function CPlayer:SetNowWarInfo(mData)
    self.m_oActiveCtrl:SetNowWarInfo(mData)
end

function CPlayer:ClearNowWarInfo()
    self.m_oActiveCtrl:ClearNowWarInfo()
end


function CPlayer:GetFightPartner()
    return self.m_oPartnerCtrl:GetFightPartner()
end


function CPlayer:OnEnterWar(bReEnter)
end

function CPlayer:GetFollowers()
    local m = self.m_oActiveCtrl:GetData("follow_partner", {})
    local lRet = {}
    if next(m) then
        table.insert(lRet, table_deep_copy(m))
    end
    return lRet
end

function CPlayer:SetFollowerPartner(mFollow)
    mFollow = mFollow or {}
    self.m_oActiveCtrl:SetData("follow_partner", mFollow)
    self:PropChange("followers")
    self:SyncSceneInfo({followers = self:GetFollowers()})
end

function CPlayer:SetName(sName)
    self:SetData("name",sName)
    self:SyncSceneInfo({
        name = self:GetName(),
    })
    self:PropChange("name")
    self:AfterSetName(sName)
end

function CPlayer:AfterSetName(sName)
    global.oFriendMgr:RefreshFriendAttr(self,"name",sName)
    global.oRankMgr:OnUpdateName(self:GetPid(),sName)
    local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
    oHuodong:OnUpdateName(self)
    local oHuodong = global.oHuodongMgr:GetHuodong("clubarena")
    oHuodong:UpdateInfo(self)
end

function CPlayer:GetCamp()
    return self.m_oThisTemp:Query("camp",0)
end

function CPlayer:PackSceneInfo()
    local mRet = {}
    mRet.name = self:GetName()
    mRet.model_info = self:GetModelInfo()
    mRet.followers = self:GetFollowers()
    mRet.title_info = self:GetTitleInfo()
    mRet.scene_model = self:GetSceneModel()
    mRet.show_id = self:GetShowId()
    mRet.camp = self:GetCamp()
    return mRet
end

function CPlayer:SyncSceneInfo(m)
    local oNowScene = self.m_oActiveCtrl:GetNowScene()
    if oNowScene then
        oNowScene:SyncPlayerInfo(self, m)
    end
end

function CPlayer:SceneHide()
    local mData = {
        is_hide = 1,
    }
    self:SyncSceneInfo(mData)
end

function CPlayer:UnSceneHide()
    local mData = {
        is_hide = 0
    }
    self:SyncSceneInfo(mData)
end

function CPlayer:GetAccount()
    return self.m_sAccount
end

function CPlayer:GetPid()
    return self.m_iPid
end

function CPlayer:GetIP()
    return self.m_sIP or ""
end

function CPlayer:GetPlatform()
    return self.m_iPlatform or 0
end

function CPlayer:GetPlatformSign()
    local iPlatform = self:GetPlatform()
    local sPlatform = gamedefines.PLATFORM_DESC[iPlatform] or "PC"
    if table_in_list({"ROOTIOS","IOS"},sPlatform) then
        return "IOS"
    elseif table_in_list({"ANDROID","PC"},sPlatform) then
        return "ANDROID"
    end
end

function CPlayer:GetPlatformName()
    local sName = gamedefines.GetPlatformName(self.m_iBornPlatform)
    return sName or string.format("未知平台%s",self.m_iBornPlatform)
end

function CPlayer:GetBornPlatform()
    return self.m_iBornPlatform
end

function CPlayer:GetQrcode()
    return self.m_iQrcode
end

function CPlayer:GetPublisher()
    return self.m_sPublisher
end

function CPlayer:GetClientOs()
    return self.m_sClientOs
end

function CPlayer:GetUdid()
    return self.m_sUdid
end

function CPlayer:GetClientVersion()
    return self.m_sClientVersion or "1.0.0"
end

function CPlayer:GetChannel()
    return self.m_iChannel or 0
end

function CPlayer:GetCpsChannel()
    return self.m_sCpsChannel or ""
end

function CPlayer:GetKPChannel()
    local mChannel = res["daobiao"]['demichannel']
    local mData = mChannel[self:GetChannel()]
    if mData and mData.sdk == "kpsdk" then
        return mData.channel
    end
end

function CPlayer:GetIMEI()
    return self.m_sIMEI or ""
end

function CPlayer:GetDevice()
    return self.m_sDevice or ""
end

function CPlayer:GetMac()
    return self.m_sMac or ""
end

function CPlayer:IsCharge()
    if self:HistoryCharge() > 0 then
        return 1
    end
    return 0
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
        plat = self:GetBornPlatform(),
        profession = self:GetSchool(),
        udid = self:GetUdid(),
        is_recharge = self:IsCharge(),
        is_qrcode = self:GetQrcode(),
    }
end

function CPlayer:BaseMtbiInfo()
    return {
        account = self:GetAccount(),
        pid = self.m_iPid,
        name = self:GetName(),
        school = self:GetSchool(),
        grade = self:GetGrade(),
        ip = self:GetIP(),
        mac = self:GetMac(),
        channel = self:GetChannel(),
        subchannel = self:GetCpsChannel(),
        server = get_server_key(),
        plat = self:GetBornPlatform(),
        is_qrcode = self:GetQrcode(),
    }
end

function CPlayer:GetConn()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:GetConnection(self.m_iNetHandle)
end

function CPlayer:GetNetHandle()
    return self.m_iNetHandle
end

function CPlayer:SetNetHandle(iNetHandle)
    self.m_iNetHandle = iNetHandle
    if iNetHandle then
        self.m_iDisconnectedTime = nil
    else
        self.m_iDisconnectedTime = get_msecond()
        self:OnDisconnected()
    end
    self:OnConnectionChange()
end

function CPlayer:OnConnectionChange()
    global.oMailAddrMgr:OnConnectionChange(self)
end

function CPlayer:Send(sMessage, mData)
    playersend.Send(self:GetPid(),sMessage,mData)
end

function CPlayer:SendRaw(sData)
    playersend.SendRaw(self:GetPid(),sData)
end

function CPlayer:MailAddr()
    local oConn = self:GetConn()
    if oConn then
        return oConn:MailAddr()
    end
end

function CPlayer:LogoutData()
    local DurationTime = self.m_DurationTime or get_time()
    local mLog = {
        pid=self:GetPid(),
        name=self:GetName(),
        grade=self:GetGrade(),
        account = self:GetAccount(),
        channel = self:GetChannel(),
        duration = math.floor( (get_time() - DurationTime) // 60 ),
        platform=self:GetPlatformName(),
    }
    return mLog
end

function CPlayer:OnLogout()
    record.log_db("player", "logout", self:LogoutData())
    self:LogAnalyData("logout")

    self.m_oActiveCtrl:SetDisconnectTime()

    local oWorldMgr = global.oWorldMgr
    if self:IsSocialDisplay() then
        self:CancelSocailDisplay()
    end
    local mMgr = self:GetRefreshMgr()
    for _,sObj in pairs(mMgr) do
        local o=global[sObj]
        if o and o.OnLogout then
            o:OnLogout(self)
        end
    end

    local mOffline = {"Profile","Friend","Partner","Privy", "Travel"}
    for _,sOffline in pairs(mOffline) do
        local oOffline = oWorldMgr:GetOfflineObject(sOffline,self:GetPid())
        if oOffline then
            oOffline:OnLogout(self)
        end
    end

    self:UnRegisterClientUpdate()

    local mCtrl = self:GetRefreshCtrl()
    for _,sCtrl in pairs(mCtrl) do
        self[sCtrl]:OnLogout(self)
    end
    local iAssistRemote = self:GetAssistRemote()
    interactive.Send(iAssistRemote, "assist", "OnLogout", {
        pid = self:GetPid(),
    })
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:SetPlayerByShowId(self:GetShowId(), nil)
    self:Disconnect()
    self:DoSave()
end


function CPlayer:HandleBadBoy(sDebug)
    --just disconnect, not to logout
    record.warning("CPlayer HandleBadBoy pid:%d debug:%s", self:GetPid(), sDebug)
    self:Disconnect()
end

function CPlayer:Disconnect()
    --disconnect
    local oWorldMgr = global.oWorldMgr
    local oConn = self:GetConn()
    if oConn then
        oWorldMgr:KickConnection(oConn.m_iHandle)
    end
end

function CPlayer:LoginData(bReEnter)
    return {
        pid=self:GetPid(),
        name=self:GetName(),
        grade=self:GetGrade(),
        account = self:GetAccount(),
        channel = self:GetChannel(),
        reenter = bReEnter and 1 or 0,
        device=self:GetDevice(),
        platform=self:GetPlatformName(),
        mac = self:GetMac(),
        ip = self:GetIP(),
        fd = self:GetNetHandle(),
    }
end

function CPlayer:LogAnalyData(sType)
    if not self:GetProfile() then
        return
    end
    local iCurTime = get_time()
    local iActiveTime = self.m_AnalyActiveTime or iCurTime
    self.m_AnalyActiveTime = nil
    local mLog = self:GetPubAnalyData()
    mLog["gold"] = self:Coin()
    mLog["crystal"] = self:GoldCoin()
    mLog["online_time"] = iCurTime - iActiveTime
    if sType == "login" then
        mLog["operation"] = 1
    elseif sType == "logout" then
        mLog["operation"] = 2
    elseif sType == "disconnect" then
        mLog["operation"] = 3
    end
    analy.log_data("Login_outRole",mLog)
end

function CPlayer:GetSkillLevel(iSkill)
    return self.m_oSkillMgr:GetSkillLevel(iSkill)
end

function CPlayer:AssistOnLogin(bReEnter)
    local bInitNewRole = false
    if not self.m_oBaseCtrl:GetData("init_newrole") then
        bInitNewRole = true
    end
    local mData = {
        pid = self:GetPid(),
        reenter = bReEnter,
        school = self:GetSchool(),
        school_branch = self:GetSchoolBranch(),
        is_new = bInitNewRole,
    }
    local fCallback = function (mRecord,mData)
        self:AssistOnLoginCallback(mData)
    end
    interactive.Request(self.m_iRemoteAssistAddr, "assist", "OnLogin", mData,fCallback)
end

function CPlayer:AssistOnLoginCallback(mData)
    mData = mData or {}
    self:UpdateEquipShare()
    self:UpdateSkillShare()
    self:UpdateStoneShare()
    local oProfile = self:GetProfile()
    oProfile:SyncPlayerProp(self)
    self:ActivePropChange()
    self:SyncEquipData(mData.equip)
end

function CPlayer:OnLogin(bReEnter)
    record.user("player", "login", self:LoginData(bReEnter))
    self:GS2CLoginRole()
    self:RegisterClientUpdate()
    local iNowTime = get_time()
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    self:AssistOnLogin(bReEnter)
    self.m_oActiveCtrl:OnLogin(self,bReEnter)
    if not self.m_oBaseCtrl:GetData("init_newrole") then
        self.m_oBaseCtrl:SetData("init_newrole",1)
        self:InitNewRole()
    end

    if not bReEnter then
        self.m_DurationTime = iNowTime
        self:PreCheck()
        self.m_oScheduleCtrl:Refresh()
        self:SyncCBaseAttr()
    end

    local oProfile = self:GetProfile()
    oProfile:OnLogin(self,bReEnter)
    local oPrivy = self:GetPrivy()
    oPrivy:OnLogin(self,bReEnter)
    local oTravel = self:GetTravel()
    oTravel:OnLogin(self,bReEnter)

    self.m_fHeartBeatTime = get_time()

    oWorldMgr:OnLogin(self, bReEnter)

    local oSceneMgr = global.oSceneMgr
    oSceneMgr:OnLogin(self,bReEnter)

    local oWar = self.m_oActiveCtrl:GetNowWar()
    if oWar then
        local oWarMgr = global.oWarMgr
        oWarMgr:OnLogin(self, bReEnter)
    end

    oNotifyMgr:OnLogin(self, bReEnter)

    local oTitleMgr = global.oTitleMgr
    oTitleMgr:OnLogin(self,bReEnter)

    if not bReEnter then
        self:AfterSendLogin()
    end

    self.m_oTaskCtrl:OnLogin(self,bReEnter)
    self.m_oBaseCtrl:OnLogin(self,bReEnter)
    self.m_oScheduleCtrl:OnLogin(self, bReEnter)
    self.m_oStateCtrl:OnLogin(self,bReEnter)
    self.m_oTitleCtrl:OnLogin(self, bReEnter)
    self.m_oHuodongCtrl:OnLogin(self,bReEnter)
    self.m_oHandBookCtrl:OnLogin(self, bReEnter)

    local mMgr = self:GetRefreshMgr()
    for _,sObj in pairs(mMgr) do
        if not table_in_list({"oWarMgr","oSceneMgr"},sObj) then
            local o = global[sObj]
            if o and o.OnLogin then
                o:OnLogin(self,bReEnter)
            end
        end
    end
    local oHouseMgr = global.oHouseMgr
    oHouseMgr:OnLogin(self,bReEnter)

    if not bReEnter then
        self:Schedule()
        global.oPayMgr:DealUntreatedOrder(self)
        global.oMergerMgr:OnLogin(self)
    end

    self:GS2CTodayInfo()

    self:LogAnalyData("login")
    self.m_AnalyActiveTime = get_time()

    local oOffsetMgr = global.oOffsetMgr
    oOffsetMgr:OnLogin(self)
    self:PushGameShareInfo()

    if not self.m_oToday:Query("first_login") then
        self:TodayFirstLogin(bReEnter)
    else
        self:TodayNotFirstLogin(bReEnter)
    end
    global.oInsideFuli:OnLogin(self)
end

function CPlayer:ConfigSaveFunc()
    local iPid = self:GetPid()
    self:ApplySave(function ()
        local oWorldMgr = global.oWorldMgr
        local obj = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if obj then
            SaveDbFunc(obj)
        else
            record.warning("playerobj save fail: %d", iPid)
        end
    end)
end

function CPlayer:OnDisconnected()
    self:LogAnalyData("disconnect")
    local oWorldMgr = global.oWorldMgr
    local mMgr = self:GetRefreshMgr()
    for _,sMgr in pairs(mMgr) do
        local o = global[sMgr]
        if o and o.OnDisconnected then
            o:OnDisconnected(self)
        end
    end
    local mCtrl = self:GetRefreshCtrl()
    for _,sCtrl in pairs(mCtrl) do
        self[sCtrl]:OnDisconnected(self)
    end

    local mOffline = {"Profile","Friend","Partner","Privy", "Travel"}
    for _,sOffline in pairs(mOffline) do
        local oOffline = oWorldMgr:GetOfflineObject(sOffline,self:GetPid())
        if oOffline then
            oOffline:OnDisconnected(self)
        end
    end

end

function CPlayer:GetRefreshMgr()
    return {
        "oBackendMgr",
        "oWarMgr",
        "oTeamMgr",
        "oMailMgr",
        "oInterfaceMgr",
        "oNotifyMgr",
        "oFriendMgr",
        "oHuodongMgr",
        "oOrgMgr",
        "oSceneMgr",
        "oAchieveMgr",
        "oImageMgr",
        "oFuliMgr",
        --"oProxyWarMgr",
        "oRankMgr",
        "oKaopuMgr",
        "oKFMgr",
    }
end

function CPlayer:GetRefreshCtrl()
    return {
        "m_oBaseCtrl",
        "m_oTaskCtrl",
        "m_oScheduleCtrl",
        "m_oStateCtrl",
        "m_oTitleCtrl",
        "m_oHandBookCtrl",
    }
end

function CPlayer:PreCheck()
    if not self.m_oBaseCtrl:GetData("model_info") then
        local mModelInfo = {
            shape = 0,
            scale = 0,
            color = {0,},
            mutate_texture = 0,
            weapon = 0,
            adorn = 0,
        }
        self.m_oBaseCtrl:SetData("model_info", mModelInfo)
    end
    if not self.m_oBaseCtrl:GetData("school") then
        local mSchool = res["daobiao"]["school"]
        local lSchool = {1,2,3}
        local iSchool = lSchool[math.random(#lSchool)]
        local o = mSchool[iSchool]
        self.m_oBaseCtrl:SetData("school", o.id)
    end

    if not self.m_oActiveCtrl:GetData("scene_info") then
        local mSceneInfo = {
            map_id = 101000,
            pos = {
                x = 27,
                y = 25,
                z = 0,
                face_x = 0,
                face_y = 0,
                face_z = 0,
            },
        }
        self.m_oActiveCtrl:SetData("scene_info", mSceneInfo)
    end
    if self:GetGrade() < 1 then
        self.m_oBaseCtrl:SetData("grade", 1)
    end
    if not self.m_oActiveCtrl:GetData("hp") or self.m_oActiveCtrl:GetData("hp") > self:GetMaxHp() then
        self.m_oActiveCtrl:SetData("hp", self:GetMaxHp())
    end
    self:RecoverTrapminePoint()
end

function CPlayer:InitNewRole()
    local oHouseMgr = global.oHouseMgr
    oHouseMgr:InitHouse(self.m_iPid)
    --self.m_oItemCtrl:InitEquip(self)
    self:InitNewRoleTask()
    self:InitNewRoleItem()
    self:InitNewRoleDrawCard()

    local iShape = self:GetShape()
    local shapes = self.m_oActiveCtrl:GetData("shape_list", {})
    if not table_in_list(shapes, iShape) then
        self:AddShape(iShape, "InitNewRole")
    end
end

function CPlayer:AfterSendLogin()
end

function CPlayer:InitNewRoleTask()
    local mGlobalSetting = res["daobiao"]["global"]
    local taskid = tonumber(mGlobalSetting.first_task.value)
    local taskobj = loadtask.CreateTask(taskid)
    if taskobj then
        self.m_oTaskCtrl:AddTask(taskobj)
    end
end

function CPlayer:InitNewRoleItem()
    local mGlobalSetting = res["daobiao"]["global"]
    local sNewRoleItem = mGlobalSetting.newrole_item.value
    if sNewRoleItem == "0" then
        return
    end
    local mNewRoleItem = split_string(sNewRoleItem,",")
    if mNewRoleItem and #mNewRoleItem>0 then
        for _,sItemInfo in pairs(mNewRoleItem) do
            local mItemInfo = split_string(sItemInfo,"|")
            local iItemId = tonumber(mItemInfo[1])
            local iAmount = tonumber(mItemInfo[2])
            local oItem = loaditem.ExtCreate(iItemId)
            oItem:SetAmount(iAmount)
            self:RewardItem(oItem,"newrole_item",{cancel_tip = true})
        end
    end
end

function CPlayer:InitNewRoleDrawCard()
    self.m_oActiveCtrl:SetData("free_wuhun", 0)
    self.m_oActiveCtrl:SetData("wuhun_baodi_count", {})

    local res = require "base.res"
    local mData = res["daobiao"]["partner"]["wuhun_baodi"][1]
    local mBaodi = {wave = 1, num = 3, count = 0}
    if mData then
        mBaodi.num = mData.count or mBaodi.num
    end
    self.m_oActiveCtrl:SetData("wuhun_card_baodi", mBaodi)
end

function CPlayer:Save()
    local mData = {}
    mData.name = self:GetData("name")
    mData.now_server = self:GetData("now_server")
    return mData
end

function CPlayer:Load(mData)
    self:SetData("name", mData.name or string.format("DEBUG%d", self:GetPid()))
    self:SetData("now_server", mData.now_server or get_server_tag())
end

function CPlayer:RegisterClientUpdate()
    interactive.Send(".clientupdate", "common", "Register", {
        pid = self:GetPid(),
        info = {
            pid = self:GetPid(),
        },
    })
end

function CPlayer:UnRegisterClientUpdate()
    interactive.Send(".clientupdate", "common", "UnRegister", {
        pid = self:GetPid(),
    })
end

function CPlayer:Schedule()
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetPid()
    local f1
    f1 = function ()
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:DelTimeCb("_CheckHeartBeat")
            oPlayer:AddTimeCb("_CheckHeartBeat", 10*1000, f1)
            oPlayer:_CheckHeartBeat()
        end
    end
    f1()
    local f2
    f2 = function ()
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:DelTimeCb("_CheckSelf")
            oPlayer:AddTimeCb("_CheckSelf",5*1000,f2)
            oPlayer:_CheckSelf()
        end
    end
    f2()
    local f3
    f3 = function ()
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:DelTimeCb("_KeepAccountToken")
            oPlayer:AddTimeCb("_KeepAccountToken",10*1000,f3)
            oPlayer:KeepAccountTokenAlive()
        end
    end
    f3()

    local f4
    f4 = function ()
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:DelTimeCb("_CheckMail")
            oPlayer:AddTimeCb("_CheckMail",60*1000,f4)
            oPlayer:_CheckMail()
        end
    end
    f4()
end

function CPlayer:KeepAccountTokenAlive()
    local sToken = self:GetAccountToken()
    if not sToken or sToken == "" then
        return
    end
    local mContent = {token = sToken}
    local iNo = string.match(sToken, "%w+_(%d+)")
    local sServiceName = string.format(".loginverify%s",iNo)
    router.Send("cs",sServiceName,"common","GSKeepTokenAlive",mContent)
end

function CPlayer:ClientHeartBeat()
    self.m_fHeartBeatTime = get_time()
    self:Send("GS2CHeartBeat", {time = math.floor(self.m_fHeartBeatTime)})
end

function CPlayer:_CheckHeartBeat()
    assert(not is_release(self), "_CheckHeartBeat fail")
    local iTestMode = self:GetTestLogoutJudgeTimeMode()
    local iJudgeTime = self:GetLogoutJudgeTime()
    local fTime = get_time()
    if iJudgeTime < 0 then
        return
    end
    local iTime = iJudgeTime
    if iTestMode then
        if iTestMode == 1 then
            iTime = -1
        elseif iTestMode == 2 then
            iTime = 2 * 60
        elseif iTestMode == 3 then
            iTime = 1 * 60
        elseif iTestMode == 4 then
            iTime = 0
        elseif iTestMode == 5 then  --离线探索
            iTime = self:GetOfflineTrapmineLogoutTime()
        end
    end
    if iTime < 0 then
        return
    end
    if fTime - self.m_fHeartBeatTime >= iTime then
        local oWorldMgr = global.oWorldMgr
        oWorldMgr:Logout(self:GetPid())
    end
end

function CPlayer:IsDull(iTime)
    local iTestMode = self:GetTestLogoutJudgeTimeMode()
    ----离线探索
    if iTestMode and iTestMode == 5 then
        return false
    end
    local iTime = iTime or 60 * 3
    local iDullTime = self:DullTime()
    if iDullTime >= iTime then
        return true
    end
    return false
end

function CPlayer:DullTime()
    return get_time() - self.m_fHeartBeatTime
end

function CPlayer:_CheckSelf()
    assert(not is_release(self), "_CheckSelf fail")
    self.m_oTaskCtrl:_CheckSelf()
    local oTeamMgr = global.oTeamMgr
    oTeamMgr:CheckLeaderDull(self)
    local iPid = self:GetPid()
    local oHuodong = global.oHuodongMgr:GetHuodong("trapmine")
    if oHuodong then
        oHuodong:CheckDull(iPid)
    end
end

function CPlayer:_CheckMail()
    local oMailBox = self:GetMailBox()
    oMailBox:CheckTimeOut()
end

--道具相关
function CPlayer:RewardItem(itemobj,sReason,mArgs)
    --record.user("item","rewarditem",{reason = sReason,sid=itemobj:SID(),amount=itemobj:GetAmount()})
    mArgs = mArgs or {}
    local oNotifyMgr = global.oNotifyMgr
    local iAmount = itemobj:GetAmount()
    local mResult = {}
    local retobj
    if itemobj:SID() < 10000 then
        mResult.virtual = 1
        local oRealObj = itemobj:RealObj()
        if oRealObj then
            if mArgs.clientshow then
                self:Send("GS2CClientShowReward",{type = 1,sid = oRealObj.m_SID,value=iAmount,bind = itemobj:IsBind()})
                mArgs.cancel_tip = true
            end
            retobj = self.m_oItemCtrl:AddItem(oRealObj,sReason,mArgs)
        else
            if mArgs.clientshow then
                self:Send("GS2CClientShowReward",{type = 1,sid = itemobj.m_SID,value=itemobj:GetData("value",iAmount),bind = itemobj:IsBind()})
                mArgs.cancel_tip = true
            end
            mResult.virtual_reward = itemobj:Reward(self,sReason,mArgs)
            return mResult
        end
    else
        if mArgs.clientshow then
            mArgs.cancel_tip = true
            self:Send("GS2CClientShowReward",{type = 1,sid = itemobj.m_SID,value=iAmount,bind = itemobj:IsBind()})
        end
        retobj = self.m_oItemCtrl:AddItem(itemobj,sReason,mArgs)
    end
    --添加失败，放入邮件
    local bSendMailLater = false
    if mArgs and mArgs.bSendMailLater then
        bSendMailLater = mArgs.bSendMailLater
    end
    if retobj then
        mResult.retobj  = retobj
        if not bSendMailLater  then
            local iMailId = 1
            local sMsg = retobj.overflow_tips or string.format("你的背包已满，%s将以邮件的形式发送至邮箱，请及时领取", itemobj:Name())
            local oMailMgr = global.oMailMgr
            local mData, name = oMailMgr:GetMailInfo(iMailId)
            oMailMgr:SendMail(0, name, self:GetPid(), mData, {}, {retobj})
            oNotifyMgr:Notify(self:GetPid(), sMsg)
        end
    end
    return mResult
end

function CPlayer:AssistGiveItem(sidlist,sReason,mArgs)
    self.m_oItemCtrl:AssistGiveItem(sidlist,sReason,mArgs)
end

--ItemList:{sid:amount}
function CPlayer:ValidGive(sidlist, mArgs)
    local bSuc = self.m_oItemCtrl:ValidGive(sidlist, mArgs)
    return bSuc
end

function CPlayer:GiveItem(sidlist,sReason,mArgs,fCallback)
    mArgs = mArgs or {}
    self.m_oItemCtrl:GiveItem(sidlist,sReason,mArgs,fCallback)
end

function CPlayer:GetItemAmount(sid)
    local iAmount = self.m_oItemCtrl:GetItemAmount(sid)
    return iAmount
end

function CPlayer:RemoveItemAmount(sid, iAmount, sReason, mArgs,fCallback)
    self.m_oItemCtrl:RemoveItemAmount(sid, iAmount, sReason,mArgs,fCallback)
end

function CPlayer:HasItem(id)
    return self.m_oItemCtrl:HasItem(id)
end

function CPlayer:RemoveItem(iItemId,sReason,mArgs)
    local oItem = self.m_oItemCtrl:HasItem(iItemId)
    if not oItem then
        return false
    end
    local bSuc = self.m_oItemCtrl:RemoveItem(oItem,sReason,mArgs.refresh)
    return bSuc
end

function CPlayer:SyncEquipData(mEquipData)
    mEquipData = mEquipData or {}
    self:UpdateEquipShare()
    local mEquipSE = mEquipData.equip_se
    if mEquipSE then
        self.m_oItemCtrl:SetEquipSE(mEquipSE)
    end
end

function CPlayer:SyncItemAmount(mShape)
    self.m_oItemCtrl:SyncItemAmount(mShape)
end

function CPlayer:CheckUpGrade()
    local mUpGrade = res["daobiao"]["upgrade"]
    local iGrade = self:GetGrade()
    local i = iGrade + 1
    local oWorldMgr = global.oWorldMgr
    local iMaxGrade = oWorldMgr:GetMaxPlayerGrade()
    while true do
        local m = mUpGrade[i]
        if not m then
            break
        end
        if self:GetGrade() >= iMaxGrade then
            break
        end
        if self:GetExp() < m.player_exp then
            break
        end
        self:UpGrade()
        i = i + 1
    end
    if self:GetGrade() > iGrade then
        self:OnCheckUpGrade()
    end
end

function CPlayer:OnCheckUpGrade()
    local oRankMgr = global.oRankMgr
    oRankMgr:PushDataToGradeRank(self)
    self:RefreshProfile()
    global.oFriendMgr:RefreshGrade(self)
    self:SyncRoleData2DataCenter()
    self.m_oActiveCtrl:SetData("upgrade_time",get_time())
    self:PropChange("kp_sdk_info")

    local mArgs = {
        grade = self:GetGrade(),
        power = self:GetPower(),
    }
    self:SyncTosOrg(mArgs)
end

function CPlayer:UpGrade()
    local iNextGrade = self:GetGrade() + 1
    self.m_oBaseCtrl:SetData("grade", iNextGrade)
    self:PropChange("grade")

    self.m_oActiveCtrl:SetData("hp",self:GetMaxHp())

    self:ActivePropChange()
    self:OnUpGrade(iNextGrade)
end

function CPlayer:OnUpGrade(iGrade)
    self.m_oBaseCtrl:OnUpGrade(iGrade)
    self.m_oTaskCtrl:OnUpGrade(iGrade)
    local oTeamMgr = global.oTeamMgr
    oTeamMgr:UpdatePlayer(self,{UpGrade = true})
    global.oHuodongMgr:OnUpGrade(self, iGrade)
    if iGrade == global.oWorldMgr:QueryControl("switchschool", "open_grade") then
        self.m_oItemCtrl:GiveSecondEquip(self)
    end
    if iGrade == global.oWorldMgr:QueryControl("trapmine", "open_grade") then
        self.m_oActiveCtrl:SetData("trapmine_point_day", get_dayno())
        self:RewardTrapminePoint(50, "初始探索点", {cancel_tip = 1})
    end
    if iGrade == global.oWorldMgr:QueryControl("forge_fuwen", "open_grade") then
        self.m_oItemCtrl:OpenFuWenPlan(self,1)
    end
    if iGrade == global.oWorldMgr:QueryControl("fuwenswitch", "open_grade") then
        self.m_oItemCtrl:OpenFuWenPlan(self,2)
    end
    if iGrade == global.oWorldMgr:QueryControl("parsoul", "open_grade") then
        self.m_oPartnerCtrl:OpenParSoul(self)
    end

    local iSchool = self:GetSchool()
    local mData = res["daobiao"]["roleattr"]
    local mRoleData = mData[iSchool]
    local iPoint =  mRoleData[self:GetGrade() - 1]["skill_point"]
    self.m_oActiveCtrl:AddSkillPoint(iPoint, "角色升级")
    self:SyncTosOrg({grade=true})
    self.m_oScheduleCtrl:OnUpGrade(self)
    global.oFuliMgr:OnUpGrade(self)
    self:SyncAssistPlayerData({grade=self:GetGrade()})
    self.m_oHuodongCtrl:OnUpGrade(iGrade)
    record.user("player","upgrade",{
        pid=self:GetPid(),
        platform=self:GetPlatformName(),
        channel=self:GetChannel(),
        name=self:GetName(),
        grade=iGrade,
        school = iSchool,
    })
    global.oAchieveMgr:PushAchieve(self:GetPid(),"主角等级",{value=iGrade})
    local iTotalAdd = self:GetUpgradeEnergy()
    if iTotalAdd > 0 then
        self:RewardEnergy(iTotalAdd,"体力",{cancel_show = true})
    end
    self:SyncCBaseAttr()
end

function CPlayer:RewardCoin(iVal,sReason,mArgs)
    self.m_oActiveCtrl:RewardCoin(iVal,sReason,mArgs)
end

function CPlayer:ValidCoin(iVal,mArgs)
    return self.m_oActiveCtrl:ValidCoin(iVal,mArgs)
end

function CPlayer:ResumeCoin(iVal, sReason, mArgs)
    return self.m_oActiveCtrl:ResumeCoin(iVal, sReason, mArgs)
end

function CPlayer:RewardMedal(iVal,sReason,mArgs)
    self.m_oActiveCtrl:RewardMedal(iVal,sReason,mArgs)
end


function CPlayer:Active()
    return self.m_oActiveCtrl:GetData("active",0)
end

function CPlayer:RewardActive(iVal,sReason,mArgs)
    return self.m_oActiveCtrl:RewardActive(iVal,sReason,mArgs)
end

function CPlayer:ResumeActive(iVal,sReason,mArgs)
    return self.m_oActiveCtrl:ResumeActive(iVal,sReason,mArgs)
end

function CPlayer:ValidActive(iVal,mArgs)
    return self.m_oActiveCtrl:ValidActive(iVal,mArgs)
end

function CPlayer:Skin()
    return self.m_oActiveCtrl:GetData("skin",0)
end

function CPlayer:RewardSkin(iVal,sReason,mArgs)
    return self.m_oActiveCtrl:AddSkin(iVal,sReason,mArgs)
end

function CPlayer:ResumeSkin(iVal,sReason,mArgs)
    return self.m_oActiveCtrl:ResumeSkin(iVal,sReason,mArgs)
end

function CPlayer:ValidSkin(iVal,mArgs)
    return self.m_oActiveCtrl:ValidSkin(iVal,mArgs)
end



function CPlayer:ResumeMedal(iVal, sReason, mArgs)
    mArgs = mArgs or {}
    return self.m_oActiveCtrl:ResumeMedal(iVal, sReason, mArgs)
end

function CPlayer:RewardExp(iVal,sReason,mArgs)
    return self.m_oActiveCtrl:RewardExp(iVal,sReason,mArgs)
end

function CPlayer:ChargeGoldCoin(iValue,sReason,mArgs)
    self:GetProfile():ChargeGoldCoin(iValue,sReason,mArgs)
end

function CPlayer:AddHistoryCharge(iVal)
    self:GetProfile():AddHistoryCharge(iVal)
end

function CPlayer:HistoryCharge()
    local oProfile = self:GetProfile()
    return oProfile:HistoryCharge()
end

function CPlayer:IsFirstCharge()
    if self.m_oBaseCtrl:IsFirstCharge() then
        return true
    end
    return false
end

function CPlayer:AfterChargeGold(iVal, sReason, mArgs)
    if iVal >= 6 then
        self.m_oBaseCtrl:SetFirstCharge()
    end
    global.oFuliMgr:AfterChargeGold(self, iVal, sReason)
    global.oAchieveMgr:PushAchieve(self:GetPid(),"累计充值",{value=iVal})
    local oHuodong = global.oHuodongMgr:GetHuodong("chargescore")
    if oHuodong then
        oHuodong:AfterCharge(self,iVal)
    end
end

function CPlayer:RewardGoldCoin(iVal,sReason,mArgs)
    local oRW = self:GetProfile()
    oRW:AddGoldCoin(iVal,sReason,mArgs)
end

function CPlayer:AddChubeiExp(iVal, sReason)
    sReason = sReason or ""
    self.m_oActiveCtrl:AddChubeiExp(iVal, sReason)
end

function CPlayer:ValidGoldCoin(iVal, mArgs)
    local oProfile = self:GetProfile()
    local bFlag = oProfile:ValidGoldCoin(iVal, mArgs)
    return bFlag
end

function CPlayer:ResumeGoldCoin(iVal,sReason,mArgs)
    local oProfile = self:GetProfile()
    oProfile:ResumeGoldCoin(iVal,sReason,mArgs)
end

function CPlayer:ValidTrapminePoint(iVal, mArgs)
    return self.m_oActiveCtrl:ValidTrapminePoint(iVal, mArgs)
end

function CPlayer:ResumeTrapminePoint(iVal, sReason, mArgs)
    self.m_oActiveCtrl:ResumeTrapminePoint(iVal, sReason, mArgs)
end

function CPlayer:RewardTrapminePoint(iVal, sReason, mArgs)
    self.m_oActiveCtrl:RewardTrapminePoint(iVal, sReason, mArgs)
end

function CPlayer:ValidTravelScore(iVal, mArgs)
    return self.m_oActiveCtrl:ValidTravelScore(iVal, mArgs)
end

function CPlayer:AddTravelScore(iVal,sReason,mArgs)
    self.m_oActiveCtrl:AddTravelScore(iVal, sReason, mArgs)
    self:PropChange("travel_score")
end

function CPlayer:GetTravelScore()
    return self.m_oActiveCtrl:GetData("travel_score", 0)
end

function CPlayer:ColorCoin()
    return self:GetProfile():ColorCoin()
end

function CPlayer:RewardColorCoin(iVal,sReason,mArgs)
    self:GetProfile():RewardColorCoin(iVal,sReason,mArgs)
end

function CPlayer:ValidColorCoin(iVal,mArgs)
    return self:GetProfile():ValidColorCoin(iVal,mArgs)
end

function CPlayer:ResumeColorCoin(iVal, sReason, mArgs)
    self:GetProfile():ResumeColorCoin(iVal, sReason, mArgs)
end

function CPlayer:FrozenMoney(sType, iVal, sReason, iTime)
    local oProfile = self:GetProfile()
    return oProfile:FrozenMoney(sType,iVal, sReason, iTime)
end

function CPlayer:GetFrozenMoney(sMoneyType)
    local oProfile = self:GetProfile()
    return oProfile:GetFrozenMoney(sMoneyType)
end

function CPlayer:RewardArenaMedal(iVal,sReason,args)
    self.m_oActiveCtrl:RewardArenaMedal(iVal,sReason,args)
    self:PropChange("arenamedal")
end

function CPlayer:ResumeArenaMedal(iVal,sReason,mArgs)
    mArgs = mArgs or {}
    self.m_oActiveCtrl:ResumeArenaMedal(iVal,sReason,mArgs)
    self:PropChange("arenamedal")
end

function CPlayer:ValidArenaMedal(iVal,mArgs)
    return self.m_oActiveCtrl:ValidArenaMedal(iVal,mArgs)
end

function CPlayer:ArenaMedal()
    return self.m_oActiveCtrl:GetData("arena",0)
end

function CPlayer:ArenaScore()
    return self.m_oBaseCtrl:GetData("ArenaScore",1000)
end

function CPlayer:SetArenaScore(iScore)
    self.m_oBaseCtrl:SetData("ArenaScore",iScore)
    global.oAchieveMgr:PushAchieve(self:GetPid(),"比武场积分",{value=iScore})
end

function CPlayer:Medal()
    return self.m_oActiveCtrl:GetData("medal")
end

function CPlayer:Coin()
    return self.m_oActiveCtrl:GetData("coin")
end

function CPlayer:GoldCoin()
    return self:GetProfile():GoldCoin()
end

function CPlayer:TrapminePoint()
    return self.m_oActiveCtrl:GetData("trapmine_point")
end


function CPlayer:IsOverflowCoin(iType,iVal)
    local imax = self.m_oActiveCtrl:MaxCoin(iType)
    return imax> iVal
end

function CPlayer:GetGrade()
    return self.m_oBaseCtrl:GetData("grade")
end

function CPlayer:GetAveGrade()
    local oOffline = self:GetOfflinePartner()
    local lGrade = {}
    if oOffline then
        lGrade = oOffline:GetTopGrade(4)
    end
    table.insert(lGrade,self:GetGrade())
    if #lGrade == 5 then
        return math.ceil(table_count_value(lGrade) / 5)
    else
        return math.max(table.unpack(lGrade))
    end
end

function CPlayer:GetSystemSetting()
    return self.m_oBaseCtrl:GetData("systemsetting")
end

function CPlayer:GetExp()
    return self.m_oActiveCtrl:GetData("exp")
end

function CPlayer:GetShape()
    return self:GetModelInfo().shape
end

function CPlayer:GetName()
    return self:GetData("name")
end

function CPlayer:GetSex()
    return self.m_oBaseCtrl:GetData("sex")
end

function CPlayer:GetSchool()
    return self.m_oBaseCtrl:GetData("school")
end

function CPlayer:GetSchoolBranch()
    return self.m_oBaseCtrl:GetData("school_branch")
end

function CPlayer:GetEnergy()
    return self.m_oActiveCtrl:GetData("energy",self.m_oActiveCtrl:GetInitRoleEnergy())
end

function CPlayer:GetModelInfo()
    local m = self.m_oBaseCtrl:GetData("model_info")
    local mRet = {}
    mRet.shape = m.shape
    mRet.scale = m.scale
    mRet.color = m.color
    mRet.mutate_texture = m.mutate_texture
    mRet.weapon = m.weapon
    mRet.adorn = m.adorn
    return mRet
end

function CPlayer:GetMaxHp()
    return self:GetAttr("maxhp",0)
end

function CPlayer:GetHp()
    return self.m_oActiveCtrl:GetData("hp",0)
end

function CPlayer:GetSpeed()
    return self:GetAttr("speed")
end

function CPlayer:GetAttack()
    return self:GetAttr("attack")
end

function CPlayer:GetDefense()
    return self:GetAttr("defense")
end

function CPlayer:GetCirticalRatio()
    return self:GetAttr("critical_ratio")
end

function CPlayer:GetResCriticalRatio()
    return self:GetAttr("res_critical_ratio")
end

function CPlayer:GetCriticalDamage()
    return self:GetAttr("critical_damage")
end

function CPlayer:GetCureCriticalRatio()
    return self:GetAttr("cure_critical_ratio")
end

function CPlayer:GetAbnormalAttrRatio()
    return self:GetAttr("abnormal_attr_ratio")
end

function CPlayer:GetResAbnormalRatio()
    return self:GetAttr("res_abnormal_ratio")
end

function CPlayer:ExecuteCPower(sFun,...)
    local oSum = self.m_cPower
    local func = oSum[sFun]
    func(oSum,...)
end

function CPlayer:GetCPower()
    if not self.m_sSchool then
        self.m_sSchool = "school" .. self:GetSchool()
    end
    return math.floor(self.m_cPower:GetPower(self.m_sSchool))
end

function CPlayer:GetLPower()
    local oPubMgr = global.oPubMgr
    local iPower = 0
    local iSchool = self:GetSchool()
    local mPower = res["daobiao"]["school_convert_power"][iSchool]
    assert(mPower, string.format("player power err: %s, %s", self.m_iPid, iSchool))

    local mAttrName = res["daobiao"]["attrname"]
    for sAttr, mAttr in pairs(mAttrName) do
        local iMul = mPower[sAttr] / 100
        iPower = iPower + (self:GetAttr(sAttr) - oPubMgr:PowerBaseVal(sAttr)) * iMul
    end
    iPower = iPower + self.m_oEquipMgr:GetWieldEquipPower()
    return math.floor(iPower)
end

function CPlayer:GetPower()
    if self.m_TestPower then
        return self.m_TestPower
    end
    local iPower
    if OPEN_CPOWER == 1 then
        iPower = self:GetCPower()
    else
        iPower = self:GetLPower()
    end
    if self.m_CurPower ~= iPower then
        self:OnPowerChange(iPower)
    end
    self.m_CurPower = iPower
    return iPower
end

function CPlayer:OnPowerChange(iPower)
    global.oAchieveMgr:PushAchieve(self:GetPid(),"玩家战力",{power=iPower})
    self:PushAchieve("玩家战力", {power =iPower})
    global.oOrgMgr:SyncPlayerData(self:GetPid(), {power = iPower})
    self:SyncAssistPlayerData({power=iPower})
end

function CPlayer:OnPartnerPowerChange(iPartnerPower)
    global.oOrgMgr:SyncPlayerData(self:GetPid(), {partnerpower = iPartnerPower})
end

function CPlayer:GetUpvoteAmount()
    return self:GetProfile():GetUpvoteAmount()
end

function CPlayer:IsUpvote(iTargetPid)
    return self:GetProfile():IsUpvote(iTargetPid)
end

--综合战力
function CPlayer:GetWarPower()
    local iPower = self:GetPower()
    local oOffline = self:GetOfflinePartner()
    return self:GetPower() + oOffline:CountTop4Power()
end

function CPlayer:GetCAttr(sAttr)
    return math.floor(self.m_cPower:GetAttr(sAttr))
end

function CPlayer:GetLAttr(sAttr)
    local iValue = self:GetBaseAttr(sAttr) * (10000 + self:GetBaseRatio(sAttr)) / 10000 + self:GetAttrAdd(sAttr) + self:GetTestAttr(sAttr)
    iValue = math.floor(iValue)
    return iValue
end

function CPlayer:GetAttr(sAttr)
    if OPEN_CPOWER == 1 then
        return self:GetCAttr(sAttr) + self:GetTestAttr(sAttr)
    end
    return self:GetLAttr(sAttr)
end

function CPlayer:SyncCBaseAttr()
    local iSchool = self:GetSchool()
    local iGrade = self:GetGrade()
    local mData = res["daobiao"]["roleattr"]
    local mRoleData = mData[iSchool]
    mRoleData = mRoleData[iGrade]
    self:ExecuteCPower("SetBaseAttr",mRoleData)
end

function CPlayer:GetBaseAttr(sAttr)
    local iRet = 0
    local iSchool = self:GetSchool()
    local iGrade = self:GetGrade()
    iGrade = math.max(iGrade,1)
    local mAttrs = {"speed","maxhp","attack","defense","critical_ratio","res_critical_ratio","critical_damage","cure_critical_ratio","abnormal_attr_ratio","res_abnormal_ratio"}
    if table_in_list(mAttrs,sAttr) then
        local mData = res["daobiao"]["roleattr"]
        local mRoleData = mData[iSchool]
        iRet = iRet + mRoleData[iGrade][sAttr]
    else
        iRet = iRet + self.m_oBaseCtrl:GetData(sAttr,0)
    end
    return iRet
end

function CPlayer:GetCBaseRatio(sAttr)
    return math.floor(self.m_cPower:GetBaseRatio(sAttr))
end

function CPlayer:GetLBaseRatio(sAttr)
    local iRatio = self.m_oSkillMgr:GetRatioApply(sAttr) + self.m_oEquipMgr:GetRatioApply(sAttr) + self.m_oStoneMgr:GetRatioApply(sAttr)
    return math.floor(iRatio)
end

function CPlayer:GetBaseRatio(sAttr)
    if OPEN_CPOWER == 1 then
        return self:GetCBaseRatio(sAttr)
    end
    return self:GetLBaseRatio(sAttr)
end

function CPlayer:GetCAttrAdd(sAttr)
    return math.floor(self.m_cPower:GetAttrAdd(sAttr))
end

function CPlayer:GetLAttrAdd(sAttr)
    local iValue = 0
    iValue = iValue + self.m_oSkillMgr:GetApply(sAttr)  + self.m_oEquipMgr:GetApply(sAttr) + self.m_oStoneMgr:GetApply(sAttr)
    return math.floor(iValue)
end

function CPlayer:GetAttrAdd(sAttr)
    if OPEN_CPOWER == 1 then
        return self:GetCAttrAdd(sAttr)
    end
    return self:GetLAttrAdd(sAttr)
end

function CPlayer:GetTestAttr(sAttr)
    local mTestAttr = self.m_oActiveCtrl:GetData("test_attr", {})
    return mTestAttr[sAttr] or 0
end

function CPlayer:GetSchoolPerform()
    local mPerform = {}
    local iSchool = self:GetSchool()
    local iSchoolBranch = self:GetSchoolBranch()
    local mSkill = loadskill.GetSchoolSkill(iSchool,iSchoolBranch)
    for _,iSkill in pairs(mSkill) do
        local iLevel = self:GetSkillLevel(iSkill)
        local oSk = loadskill.GetSkill(iSkill)
        if iLevel and iLevel > 0 and oSk and oSk:UnLockGrade() <= self:GetGrade() then
            mPerform[iSkill] = iLevel
        end
    end
    for iSE, iLevel in pairs(self.m_oItemCtrl:GetEquipSEList()) do
        mPerform[iSE] = iLevel
    end
    local mTestPerform = self.m_oActiveCtrl:GetInfo("TestPerform",{})
    for pfid,iLevel in pairs(mTestPerform) do
        mPerform[pfid] = iLevel
    end
    return mPerform
end

function CPlayer:GetOfflinePartner()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:GetOfflinePartner(self.m_iPid)
end

function CPlayer:GetProfile()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:GetProfile(self.m_iPid)
end

function CPlayer:RefreshProfile()
    self:GetProfile():SyncPlayerData(self)
end

function CPlayer:GetPrivy()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:GetPrivy(self:GetPid())
end

function CPlayer:GetShowId()
    local oProfile = self:GetProfile()
    return oProfile:GetShowId()
end

function CPlayer:GetFriend()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:GetFriend(self.m_iPid)
end

function CPlayer:GetProtectors()
    local mProtectors = {}
    if not self:IsSingle() then
        local lMember = self:HasTeam():GetTeamMember()
        mProtectors = self:GetFriend():GetProtectFriends(lMember)
    end
    return mProtectors
end

function CPlayer:GetTravel()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:GetTravel(self:GetPid())
end

function CPlayer:GS2CLoginRole()
    local iPid = self:GetPid()
    local mNet = {
        account = self:GetAccount(),
        pid = iPid,
        role = self:RoleInfo(),
        role_token = self:GetRoleToken(),
        is_gm = self:IsGM(),
        channel = self:GetChannel(),
        xg_account = get_server_cluster()..tostring(iPid),
    }
    self:Send("GS2CLoginRole", mNet)
end

function CPlayer:IsGM()
    local oGMMgr = global.oGMMgr
    local iPid = self:GetPid()
    if not is_production_env() then
        return true
    end
    if oGMMgr:IsGM(iPid) then
        return true
    end
    return false
end

function CPlayer:RoleInfo(m)
    local mRet = {}
    if not m then
        m = PropHelperFunc
    end
    for k, _ in pairs(m) do
        local f = assert(PropHelperFunc[k], string.format("RoleInfo fail f get %s", k))
        mRet[k] = f(self)
    end
    return net.Mask("base.Role", mRet)
end

function CPlayer:ActivePropChange()
    local oRankMgr = global.oRankMgr
    oRankMgr:PushDataToWarPowerRank(self)
    self:PropChange("max_hp","attack","defense","hp","critical_ratio","res_critical_ratio",
        "cure_critical_ratio","abnormal_attr_ratio","res_abnormal_ratio","speed", "power","critical_damage")
end

function CPlayer:PropChange(...)
    local l = table.pack(...)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:SetPlayerPropChange(self:GetPid(), l)
end

function CPlayer:ClientPropChange(m)
    local mRole = self:RoleInfo(m)
    self:Send("GS2CPropChange", {
        role = mRole,
    })
    self:UpdateTeamMemInfo(mRole)
end

function CPlayer:AddTask(taskobj,npcobj)
    self.m_oTaskCtrl:AddTask(taskobj,npcobj)
end

function CPlayer:GetTeamLeader()
    local oTeam = self:HasTeam()
    if not oTeam then return end

    local oWorldMgr = global.oWorldMgr
    local iLeader = oTeam:Leader()
    return oWorldMgr:GetOnlinePlayerByPid(iLeader)
end

function CPlayer:TeamID()
    return self.m_oActiveCtrl:GetInfo("TeamID")
end

function CPlayer:TeamPVPID()
    local oHuodong = global.oHuodongMgr:GetHuodong("teampvp")
    local oTeam = oHuodong:GetTeam(self)
    if oTeam then
        return oTeam.m_ID
    end
end

function CPlayer:TeamType()
    local oTeam = self:HasTeam()
    if not oTeam then
        return false
    end
    return oTeam.m_Type
end

function CPlayer:HasTeam()
    local iTeamID = self:TeamID()
    if not iTeamID then
        return false
    end
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    return oTeam
end

function CPlayer:IsTeamLeader()
    local oTeam = self:HasTeam()
    if not oTeam then
        return false
    end
    return oTeam:IsLeader(self.m_iPid)
end

function CPlayer:HasShortLeave()
    local oTeam = self:HasTeam()
    if not oTeam then
        return false
    end
    return oTeam:HasShortLeave()
end

function CPlayer:IsTeamShortLeave()
    local oTeam = self:HasTeam()
    if not oTeam then
        return false
    end
    return oTeam:IsShortLeave(self:GetPid())
end

function CPlayer:IsSingle()
    local oTeam = self:HasTeam()
    local pid = self:GetPid()

    if not oTeam  then
        return true
    end
    if oTeam:IsShortLeave(pid) then
        return true
    end
    return false
end

function CPlayer:SceneTeamMember()
    local oTeam = self:HasTeam()
    if not oTeam then
        return
    end
    local m = oTeam:GetTeamMember()
    local ret = {}
    for iPos,pid in pairs(m) do
        ret[pid] = iPos
    end
    return ret
end

function CPlayer:SceneTeamShort()
    local oTeam = self:HasTeam()
    if not oTeam then
        return
    end
    local m = oTeam:GetTeamShort()
    local ret = {}
    for iPos,pid in pairs(m) do
        ret[pid] = iPos
    end
    return ret
end

function CPlayer:GetTeamMember()
    local oTeam = self:HasTeam()
    if not oTeam then
        return
    end
    local m = oTeam:GetTeamMember()
    return m
end

function CPlayer:AllMember()
    local oTeam = self:HasTeam()
    if not oTeam then
        return {self:GetPid(),}
    end
    local m = oTeam:GetTeamMember()
    return m
end

function CPlayer:GetTeamSize()
    local oTeam = self:HasTeam()
    if not oTeam then
        return 0
    end
    return oTeam:TeamSize()
end

function CPlayer:GetTeamMemberSize()
    local oTeam = self:HasTeam()
    if not oTeam then
        return 0
    end
    return oTeam:MemberSize()
end

function CPlayer:GetTeamInfo( )
    local oTeam = self:HasTeam()
    if oTeam then
        local mTeamInfo = {}
        mTeamInfo["team_id"] = self:TeamID()
        mTeamInfo["team_size"] = oTeam:TeamSize()
        return mTeamInfo
    end
end

function CPlayer:SetAutoMatching(iTargetID,bMatchSuccess)
    if not (bMatchSuccess and self:GetAutoMatchTargetID() == 1) then
        self.m_oActiveCtrl:SetInfo("auto_targetid", iTargetID)
    end
    if iTargetID then
        self:Send("GS2CNotifyAutoMatch", {player_match = 1})
    else
        self:Send("GS2CNotifyAutoMatch", {player_match= 0})
    end
end

function CPlayer:GetAutoMatchTargetID()
    return self.m_oActiveCtrl:GetInfo("auto_targetid")
end

function CPlayer:NewDay(iDay)
    local DurationTime = self.m_DurationTime or get_time()
    self.m_DurationTime = get_time()
    record.user("player","newday",{
        pid=self:GetPid(),
        platform=self:GetPlatformName(),
        channel=self:GetChannel(),
        account=self:GetAccount(),
        duration = math.floor( (get_time() - DurationTime) // 60 ),
    })
    self:RecoverTrapminePoint()
    self:Send("GS2CNewDay",{})
    self:GS2CTodayInfo()
    self:TodayFirstLogin()
    self.m_oScheduleCtrl:Refresh()
    self.m_oScheduleCtrl:GS2CLoginSchedule(self)
    self.m_oHuodongCtrl:NewDay()
    self.m_oTaskCtrl:NewDay()
    self:PropChange("org_fuben_cnt", "open_day")
    local oHuodong = global.oHuodongMgr:GetHuodong("dailysign")
    if oHuodong then
        oHuodong:NewDayRefresh(self)
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("rewardback")
    if oHuodong then
        oHuodong:NewDayRefresh(self)
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("charge")
    if oHuodong then
        oHuodong:SendClientChargeReward(self)
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("welfare")
    if oHuodong then
        oHuodong:NewDayRefresh(self)
    end
end

--5点刷新接口
function CPlayer:NewHour5(iDay,iHour)
    local iShimenType = 4
    local oTask = self.m_oTaskCtrl:HasTaskType(iShimenType)
    if oTask then
        oTask:SetData("Ring",1)
        oTask:Refresh()
    end
end

function CPlayer:NewHour19(iDay, iHour)
    --
end

function CPlayer:TodayFirstLogin(bReEnter)
    self.m_oToday:Set("first_login", 1)
    local iLoginDay = self.m_oActiveCtrl:GetData("count_login_day", 0)
    self.m_oActiveCtrl:SetData("count_login_day", iLoginDay + 1)
    self.m_oActiveCtrl:GS2CLoginRewardInfo()

    local mMgr = {"oFuliMgr"}
    for _,sObj in pairs(mMgr) do
        local o = global[sObj]
        if o then
            o:TodayFirstLogin(self)
        end
    end

    record.user("loginreward", "login_day", {
        pid = self:GetPid(),
        name = self:GetName(),
        grade = self:GetGrade(),
        old_login_day = iLoginDay,
        now_login_day = self.m_oActiveCtrl:GetData("count_login_day",0),
        reason = "每日登录",
        })
end

function CPlayer:TodayNotFirstLogin()
    self.m_oActiveCtrl:GS2CLoginRewardInfo()
end

function CPlayer:ChangeWeapon(iWeapon)
    local m = self.m_oBaseCtrl:GetData("model_info")
    m.weapon = iWeapon
    self.m_oBaseCtrl:SetData("model_info",m)
    self:PropChange("model_info")
    self:SyncSceneInfo({
        model_info = m,
    })
end

function CPlayer:GetWeapon()
    local m = self.m_oBaseCtrl:GetData("model_info",{})
    return m.weapon
end

function CPlayer:StrengthLevel(iPos)
    iPos = tostring(iPos)
    local mLevel = self.m_oActiveCtrl:GetData("equip_strength",{})
    local iLevel = mLevel[iPos] or 0
    return iLevel
end

function CPlayer:EquipStrength(iPos,iLevel, sReason)
    local mLevel = self.m_oActiveCtrl:GetData("equip_strength",{})
    iPos = tostring(iPos)
    local iBefore = mLevel[iPos] or 0
    mLevel[iPos] = iLevel
    self.m_oActiveCtrl:SetData("equip_strength",mLevel)
    local mLog = {
        pid = self:GetPid(),
        pos = iPos,
        before_level = iBefore,
        after_level = iLevel,
        reason = sReason,
    }
    record.user("equip", "equip_strength", mLog)
end

function CPlayer:IsMaxStrengthLevel(iPos)
    local  iMaxLv = self:GetInfo("equip_max_strength_level")
    if not iMaxLv then
        local sMaxLv = res["daobiao"]["global"]["equip_strength_max_level"]["value"]
        iMaxLv = tonumber(sMaxLv)
        self:SetInfo("equip_max_strength_level", iMaxLv)
    end
    if self:StrengthLevel(iPos) >= iMaxLv then
        return true
    end
    return false
end

function CPlayer:ValidResetSkillPoint(iCostType)
    local iOpenGrade = global.oWorldMgr:QueryControl("reset_skill_point", "open_grade")
    if iOpenGrade > self:GetGrade() then
        self:NotifyMessage("等级不足")
        return false
    end
    local mGlobalSetting = res["daobiao"]["global"]
    local iShape = tonumber(mGlobalSetting["wash_schoolskill_itemid"]["value"])
    if iCostType == 1 then
        if self:GetItemAmount(iShape) < 1 then
            self:NotifyMessage("道具不足")
            return false
        end
    else
        local oItem = loaditem.GetItem(iShape)
        local iBuyPrice = oItem:BuyPrice()
        if not self:ValidGoldCoin(iBuyPrice) then
            return false
        end
    end
    return true
end

function CPlayer:GetSkillPoint()
    local iSchoolBranch = self.m_oBaseCtrl:GetData("school_branch")
    return self.m_oActiveCtrl:GetSkillPoint(iSchoolBranch)
end

function CPlayer:ResetSkillPoint(iCostType)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local mGlobalSetting = res["daobiao"]["global"]
    local iShape = tonumber(mGlobalSetting["wash_schoolskill_itemid"]["value"])
    local iAmount = 1
    local sReason = "角色门派技能重置"
    local iPid = self:GetPid()
    local mArgs = {
        school = self:GetSchool(),
        school_branch = self:GetSchoolBranch(),
    }
    if iCostType == 1 then
        local fCallback = function (mRecord,mData)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer:_TrueResetSkillPoint(mData,iShape,0,sReason)
            end
        end
        self.m_oSkillCtrl:WashSchoolSkill(iShape,iAmount,sReason,mArgs,fCallback)
    else
        local oItem = loaditem.GetItem(iShape)
        local iBuyPrice = oItem:BuyPrice()
        self:ResumeGoldCoin(iBuyPrice,sReason,mArgs)
        local fCallback = function (mRecord,mData)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer:_TrueResetSkillPoint(mData,0,iBuyPrice,sReason)
            end
        end
        self.m_oSkillCtrl:WashSchoolSkill(0,iAmount,sReason,mArgs,fCallback)
    end
end

function CPlayer:_TrueResetSkillPoint(mData,iShape, iConsumeGold, sReason)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    self.m_oSkillMgr:ShareUpdate()
    self:ActivePropChange()
    self.m_oActiveCtrl:ResetSkillPoint(sReason)
    local iRemainGold = self:GoldCoin()
    self.m_oActiveCtrl:LogAnalySkillReset(self,iBeforePoint,{[iShape]=1}, iConsumeGold, iRemainGold)
end

function CPlayer:ValidSwitchSchool(iSchoolBranch)
    if not table_in_list({1,2},iSchoolBranch) then
        return false
    end
    local iBranch = self:GetSchoolBranch()
    if iBranch == iSchoolBranch then
        return false
    end
    local iOpenGrade = global.oWorldMgr:QueryControl("switchschool", "open_grade")
    if self:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

--切换流派
function CPlayer:SwitchSchool(iSchoolBranch)
    self.m_oBaseCtrl:SetSchoolBranch(iSchoolBranch)
    local iPid = self:GetPid()
    local oWorldMgr = global.oWorldMgr
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer:SwitchWeaponCallback(iSchoolBranch,mData)
    end
    --切换武器
    self.m_oItemCtrl:SwitchSchool(self,iSchoolBranch,fCallback)
end

function CPlayer:SwitchWeaponCallback(iSchoolBranch,mData)
    local iNormalAttackId = self.m_oSkillCtrl:GetSchoolNormalAttackId(self)
    self.m_oActiveCtrl:SetAutoSkill(iNormalAttackId)
    local mArgs = mData.args or {}
    local iWeapon = mArgs.weapon
    self:ChangeWeapon(iWeapon)
    self:UpdateEquipShare()
    self:UpdateSkillShare()
    self:ActivePropChange()
    self:SyncEquipData(mArgs.equip)
end

function CPlayer:GetMailBox()
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:GetMailBox(self.m_iPid)
end

function CPlayer:GetMaxGemCnt()
    local mData = res["daobiao"]["gem_level"]
    local lGemUnlockGrade = table_key_list(mData)
    table.sort(lGemUnlockGrade)
    local iGrade = self:GetGrade()
    local iMinGrade = 0
    for i = #lGemUnlockGrade, 1, -1 do
        if lGemUnlockGrade[i] <= iGrade then
            iMinGrade = lGemUnlockGrade[i]
            break
        end
    end
    mData = mData[iMinGrade]
    if mData then
        return mData["gem_cnt"] or 0
    else
        return 0
    end
end

function CPlayer:GetWeaponType()
    local iSchool = self:GetSchool()
    local iBranch = self:GetSchoolBranch()
    local mSchoolWeapon = res["daobiao"]["schoolweapon"]["weapon"][iSchool][iBranch]

    return mSchoolWeapon.weapon
end

function CPlayer:IsDoubleAttackSuspend()
    return true
end

function CPlayer:PackSimpleRoleInfo()
    local mRole = {}
    mRole["pid"] = self.m_iPid
    mRole["name"] = self:GetName()
    mRole["grade"] = self:GetGrade()
    mRole["model_info"] = self:GetModelInfo()
    mRole["school"] = self:GetSchool()
    mRole["school_branch"] = self:GetSchoolBranch()
    return mRole
end

function CPlayer:PackTitleInfo()
    return self:GetTitleInfo()
end

function CPlayer:GetTitleInfo()
    return self.m_oTitleCtrl:GetTitleInfo()
end

function CPlayer:AddTitle(iTid, createTime, ... )
    self.m_oTitleCtrl:AddTitle(self, iTid, createTime, ... )
end

function CPlayer:CheckTitleAdjust(iTid,...)
    local oTitle = self:GetTitle(iTid)
    if oTitle then
        oTitle:CheckAdjust(...)
    end
end

function CPlayer:RemoveTitles(tidList)
    self.m_oTitleCtrl:RemoveTitles(self, tidList)
end

function CPlayer:GetTitle(iTid)
    return self.m_oTitleCtrl:GetTitleByTid(iTid)
end

function CPlayer:GetOrgID()
    return global.oOrgMgr:GetPlayerOrgInfo(self:GetPid(),"orgid",0)
end

function CPlayer:GetOrgStatus()
    return global.oOrgMgr:GetPlayerOrgInfo(self:GetPid(),"orgstatus",0)
end

function CPlayer:GetOrgName()
    return global.oOrgMgr:GetPlayerOrgInfo(self:GetPid(),"orgname","")
end

function CPlayer:GetOrgPos()
    return global.oOrgMgr:GetPlayerOrgInfo(self:GetPid(),"orgpos",0)
end

function CPlayer:GetOrgExp()
    return global.oOrgMgr:GetPlayerOrgInfo(self:GetPid(),"orgexp",0)
end

function CPlayer:GetOrgLevel()
    return global.oOrgMgr:GetPlayerOrgInfo(self:GetPid(),"orglevel",0)
end

function CPlayer:GetOrgSFlag()
    return global.oOrgMgr:GetPlayerOrgInfo(self:GetPid(),"orgsflag","")
end

function CPlayer:SyncTosOrg(mArgs)
    local mData = {}
    mData["power"] = mArgs["power"] and self:GetWarPower()
    mData["name"] = mArgs["name"] and self:GetName()
    mData["grade"] = mArgs["grade"] and self:GetGrade()
    mData["logout_time"] = mArgs["logout_time"] and get_time()
    mData["offer"] = mArgs["offer"] and self:GetOffer()
    if mArgs["team"] then
        if self:HasTeam() then
            mData["team"] = true
        else
            mData["team"] = false
        end
    end
    mData["school_branch"] = mArgs["school_branch"] and self:GetSchoolBranch()

    global.oOrgMgr:SyncPlayerData(self:GetPid(), mData)
end

function CPlayer:SyncTitleName(iTid, name)
    self.m_oTitleCtrl:SyncTitleName(self, iTid, name)
end

function CPlayer:SyncRoleData2DataCenter()
    safe_call(self.UpdateDataCenterRoleInfo, self)
end

function CPlayer:UpdateDataCenterRoleInfo()
    local mContent = {}
    mContent.pid = self:GetPid()
    mContent.icon = self:GetShape()
    mContent.grade = self:GetGrade()
    mContent.school = self:GetSchool()
    mContent.name = self:GetName()
    router.Send("cs",".datacenter","common","UpdateRoleInfo",mContent)
end

function CPlayer:LogData()
    return {pid=self:GetPid(), name=self:GetName(), grade=self:GetGrade()}
end

function CPlayer:ValidAddTeam()
    local iOpenGrade = tonumber(res["daobiao"]["global_control"]["team"]["open_grade"])
    if self:GetGrade() < iOpenGrade then
        return false,gamedefines.ADDTEAMFAIL_CODE.GRADE_LIMIT
    end
    local mTaskStatus = self:GetData("TaskStatus",{})
    if #mTaskStatus > 0 then
        return false,gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK
    else
        local oTeam = self:HasTeam()
        if oTeam and oTeam.m_Type == gamedefines.TEAM_CREATE_TYPE.LILIAN then
            return false,gamedefines.ADDTEAMFAIL_CODE.LILIANING
        end
    end
    if self:IsInHouse() then
        return false, gamedefines.ADDTEAMFAIL_CODE.IN_HOUSE
    end
    if self.m_oActiveCtrl:GetData("task_show",0) == 1 then
        return false,gamedefines.ADDTEAMFAIL_CODE.ON_TASKSHOW
    end
    if self:IsPrepareTerrawars() then
        return false,gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS
    end
    if self:IsOnConvoy() then
        return false,gamedefines.ADDTEAMFAIL_CODE.CONVOY
    end
    if self:IsOnSceneQuestion() then
        return false,gamedefines.ADDTEAMFAIL_CODE.SCENE_QUESTION
    end
    return true
end

function CPlayer:IsOnConvoy()
    local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
    if oHuodong:IsOnGame(self.m_iPid) then
        return true
    end
    return false
end

function CPlayer:IsPrepareTerrawars()
    local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
    return oHuodong:IsPrepare(self:GetPid())
end

function CPlayer:PackRole2Chat()
    local mRoleInfo = {}
    mRoleInfo.pid = self:GetPid()
    mRoleInfo.grade = self:GetGrade()
    mRoleInfo.name = self:GetName()
    mRoleInfo.shape = self:GetModelInfo().shape
    return mRoleInfo
end

function CPlayer:AddSchedule(schedule, mArgs)
    if type(schedule) == "number" then
        self.m_oScheduleCtrl:Add(schedule, mArgs)
    else
        self.m_oScheduleCtrl:AddByName(schedule, mArgs)
    end
end

function CPlayer:RecordPlayCnt(sName,iCnt)
    local oHuodong = global.oHuodongMgr:GetHuodong("rewardback")
    oHuodong:PlayRecord(self,sName,iCnt)
end


function CPlayer:UpdateTeamMemInfo(mRole)
    local oTeam = self:HasTeam()
    if oTeam then
        local oMem = oTeam:GetMember(self.m_iPid)
        if oMem then
            oMem:Update(mRole)
        end
    end
end

--{{sid, amount, agrs}}
function CPlayer:GivePartner(lPartner,sReason, mArgs)
    self.m_oPartnerCtrl:GivePartner(lPartner, sReason, mArgs)
end

function CPlayer:PackPartnerItemData()
    return self.m_oPartnerCtrl:PackPartnerItemData()
end

function CPlayer:PackTreasureInfo()
    local iTreasureReward = 0
    if self.m_oToday:Query("legendboy_triggertimes",0) >= 1 then
        iTreasureReward = 1
    end
    local mNpc = self.m_oHuodongCtrl:GetNpcByType("legendboynpc")
    if #mNpc > 0 then
        iTreasureReward = 1
    end
    return {
        treasure_cnt = self.m_oActiveCtrl:GetTreasureTotalTimes(),
        treasure_reward = iTreasureReward
    }
end

function CPlayer:PackAssistPlayerData()
    local mStableData = {
        school = self:GetSchool(),
        sex = self:GetSex(),
        account = self:GetAccount(),
        channel = self:GetChannel(),
        mac = self:GetMac(),
        device = self:GetDevice(),
        imei = self:GetIMEI(),
        platform = self:GetPlatform(),
        client_version = self:GetClientVersion(),
        client_os = self:GetClientOs(),
        udid = self:GetUdid(),
    }
    local mAssistData = {
        pid = self:GetPid(),
        name = self:GetName(),
        grade = self:GetGrade(),
        model_info = self:GetModelInfo(),
        school_branch = self:GetSchoolBranch(),
        stable_data = mStableData,
        power = self:GetPower(),
        equip_strength = self.m_oActiveCtrl:GetData("equip_strength",{}),
    }
    return mAssistData
end

function CPlayer:SyncAssistPlayerData(mData)
    local iAssistRemote = self:GetAssistRemote()
    local iPid = self:GetPid()
    interactive.Send(iAssistRemote,"common","SyncPlayerData",{
        pid = iPid,
        data = mData
    })
end

function CPlayer:PackItemAssistData()
    local oWorldMgr = global.oWorldMgr
    local bHaveTeam = false
    if self:HasTeam() then
        bHaveTeam = true
    end
    local iPartnerTravel = 0
    local oTravel = self:GetTravel()
    if oTravel:IsSpeeding() then
        iPartnerTravel = 1
    end
    local oNowScene = self.m_oActiveCtrl:GetNowScene()
    local mData = {
        partner_item = self:PackPartnerItemData(),
        grade = self:GetGrade(),
        sex = self:GetSex(),
        glod = self:Coin(),
        gold_coin = self:GoldCoin(),
        org_offer = self:GetOffer(),
        energy = self:GetEnergy(),
        skin = self:Skin(),
        server_grade = oWorldMgr:GetServerGrade(),
        has_team = bHaveTeam,
        pos_info = self.m_oActiveCtrl:GetNowPos(),
        map_id = oNowScene:MapId(),
        treasure_info = self:PackTreasureInfo(),
        partner_travel = iPartnerTravel,
    }
    return mData
end

function CPlayer:AddOrgWish(iTarget)
    local mGive = self.m_oToday:Query("give_org_wish",{})
    mGive[iTarget] = 1
    self.m_oToday:Set("give_org_wish",mGive)
    self:ClientPropChange({["give_org_wish"] = true})
end

function CPlayer:AddOrgEquipWish(iTarget)
    local mGive = self.m_oToday:Query("give_org_equip",{})
    mGive[iTarget] = 1
    self.m_oToday:Set("give_org_equip",mGive)
    self:ClientPropChange({["give_org_equip"] = true})
end

function CPlayer:GetNowPos()
    return self.m_oActiveCtrl:GetNowPos()
end

function CPlayer:RecoverTrapminePoint()
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:QueryControl("trapmine", "open_grade") <= self:GetGrade() then
        local iOldDay = self.m_oActiveCtrl:GetData("trapmine_point_day", get_dayno())
        local iNowDay = get_dayno()
        local iSub = iNowDay - iOldDay
        if iSub > 0 then
            self.m_oActiveCtrl:SetData("trapmine_point_day", iNowDay)
            local sRecover = res["daobiao"]["global"]["trapmine_point_recover"]["value"]
            local iRecover = tonumber(sRecover)
            self:RewardTrapminePoint(iRecover * iSub, "凌晨恢复探索点",{cancel_tip=1})
        end
    end
end

function CPlayer:DelayLogoutTime(sReason)
    -- body
end

function CPlayer:GetCreateTime()
    local iTime = self.m_iCreateTime or get_time()
    return iTime
end

function CPlayer:GetUpGradeTime()
    local iTime = self.m_oActiveCtrl:GetData("upgrade_time") or get_time()
    return iTime
end

function CPlayer:GetKpSdkInfo()
    local mData = {
        create_time = self:GetCreateTime(),
        upgrade_time = self:GetUpGradeTime()
    }
    return mData
end

--正在探索
function CPlayer:IsTrapmining()
    local o = global.oHuodongMgr:GetHuodong("trapmine")
    if o then
        return o:IsTrapmining(self)
    end
    return false
end

--在宅邸中
function CPlayer:IsInHouse()
    local iPid = self:GetPid()
    local oHouseMgr = global.oHouseMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if oHouse and oHouse:InHouse(iPid) then
        return true
    end
    return false
end

function CPlayer:GS2CTodayInfo(m)
    if not m then
        m = {"trapmine_point_bought","energy_buytime","energy_receive","shimen_finish"}
    end
    local mRet = {}
    for _, sKey in pairs(m) do
        mRet[sKey] = self.m_oToday:Query(sKey)
    end
    self:Send("GS2CTodayInfo", {info = net.Mask("base.TodayInfo", mRet)})
end

function CPlayer:PushAchieve(sKey,mArgs)
    global.oAchieveMgr:PushAchieve(self:GetPid(),sKey,mArgs)
end

function CPlayer:PushBookCondition(sKey, mData)
    self.m_oHandBookCtrl:PushCondition( sKey, mData)
end

function CPlayer:SetSceneModel(iSceneModel)
    self.m_iSceneModel = iSceneModel
    self:SyncSceneInfo({
        scene_model = iSceneModel
    })
    self:Send("GS2CSceneModel",{
        scene_model = iSceneModel
    })
end

function CPlayer:GetSceneModel()
    return self.m_iSceneModel or 1
end

function CPlayer:GetOrgFubenCnt()
    local oHuodong = global.oHuodongMgr:GetHuodong("orgfuben")
    return oHuodong:GetOrgFubenCnt(self)
end

function CPlayer:Query(sKey, default)
    local mInfo = self.m_oBaseCtrl:GetData("other_info", {})
    return mInfo[sKey] or default
end

function CPlayer:Set(sKey, value)
    local mInfo = self.m_oBaseCtrl:GetData("other_info", {})
    mInfo[sKey] = value
    self.m_oBaseCtrl:SetData("other_info", mInfo)
end

function CPlayer:Add(sKey, value)
    local mInfo = self.m_oBaseCtrl:GetData("other_info", {})
    mInfo[sKey] = mInfo[sKey] or 0
    mInfo[sKey] = mInfo[sKey] + value
    self.m_oBaseCtrl:SetData("other_info", mInfo)
end

function CPlayer:FuliQuery(sKey, default)
    local mInfo = self.m_oBaseCtrl:GetData("fuli_info", {})
    return mInfo[sKey] or default
end

function CPlayer:FuliSet(sKey, value)
    local mInfo = self.m_oBaseCtrl:GetData("fuli_info", {})
    mInfo[sKey] = value
    self.m_oBaseCtrl:SetData("fuli_info", mInfo)
end

function CPlayer:FuliAdd(sKey, value)
    local mInfo = self.m_oBaseCtrl:GetData("fuli_info", {})
    mInfo[sKey] = mInfo[sKey] or 0
    mInfo[sKey] = mInfo[sKey] + value
    self.m_oBaseCtrl:SetData("fuli_info", mInfo)
end

function CPlayer:CheckCanLeaveOrg()
    local iOrgId = self:GetOrgID()
    if not iOrgId or iOrgId == 0 then
        return false,"暂无工会"
    end
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("terrawars")
    if oHuoDong:IsOnSetGuard(self:GetPid()) then
        return false,"正在据点战设置驻守伙伴"
    end
    return true
end

function CPlayer:InitShareObj(mData)
    local oRemoteItemShare = mData.item_share
    local oRemoteEquipShare = mData.equip_share
    local oRemoteSkillShare = mData.skill_share
    local oRemoteStoneShare = mData.stone_share
    local oRemotePartnerShare = mData.partner_share

    self.m_oItemCtrl:InitShareObj(oRemoteItemShare)
    self.m_oPartnerCtrl:InitShareObj(oRemotePartnerShare)
    self.m_oEquipMgr:InitShareObj(oRemoteEquipShare)
    self.m_oSkillMgr:InitShareObj(oRemoteSkillShare)
    self.m_oStoneMgr:InitShareObj(oRemoteStoneShare)
end

function CPlayer:UpdateEquipShare()
    self.m_oEquipMgr:ShareUpdate()
end

function CPlayer:UpdateSkillShare()
    self.m_oSkillMgr:ShareUpdate()
end

function CPlayer:UpdateStoneShare()
    self.m_oStoneMgr:ShareUpdate()
end

local ResumeMoneyFunc = {
    [gamedefines.COIN_FLAG.COIN_GOLD] = "ResumeGoldCoin",
    [gamedefines.COIN_FLAG.COIN_COIN] = "ResumeCoin",
}

function CPlayer:ResumeMoneyByType(iMoneyType,iVal,sReason,mArgs)
    local sFunc = ResumeMoneyFunc[iMoneyType]
    if sFunc then
        self[sFunc](self,iVal,sReason,mArgs)
    end
end

local GetMoneyFunc = {
    [gamedefines.COIN_FLAG.COIN_GOLD] = "GoldCoin",
    [gamedefines.COIN_FLAG.COIN_COIN] = "Coin",
}

function CPlayer:GetMoney(iMoneyType)
    local sFunc = GetMoneyFunc[iMoneyType]
    if sFunc then
        return self[sFunc](self)
    end
    return 0
end

function CPlayer:IsSocialDisplay()
    local m = self:GetInfo("social_display")
    if m then
        return true
    end
    return false
end

function CPlayer:CancelSocailDisplay()
    local oWorldMgr = global.oWorldMgr
    local m = self:GetInfo("social_display")
    if m then
        self:SetInfo("social_display", nil)
        self:SyncSceneInfo({social_display = {}})
        self:Send("GS2CSocialDisplayInfo", {})
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(m.target)
        if oTarget and oTarget:IsSocialDisplay() then
            oTarget:CancelSocailDisplay()
        end
    end
end

function CPlayer:IsInviteSocialDisplay()
    local m = self:GetInfo("social_display_invite")
    if m then
        return true
    end
    return false
end

function CPlayer:IsOutOfAoi(o)
    local mPos1 = self:GetNowPos()
    local mPos2 = o:GetNowPos()
    return ((mPos1.x - mPos2.x) ^ 2 + (mPos1.y - mPos2.y) ^ 2) > 12 ^ 2
end

function CPlayer:ShowKeepItem(lShowInfo)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local iRemoteAddr = oAssistMgr:SelectRemoteAssist(iPid)
    interactive.Send(iRemoteAddr, "common", "ShowKeepItem", {
        pid = iPid,
        key = key,
        value = value
    })
end

function CPlayer:GetPreLeaveOrgInfo()
    local oProfile = self:GetProfile()
    return oProfile:GetPreLeaveOrgInfo()
end

function CPlayer:GetPreLeaveOrgTime()
    local oProfile = self:GetProfile()
    local mInfo = oProfile:GetPreLeaveOrgInfo()
    return mInfo["leavetime"] or 0
end

function CPlayer:PackRole2OrgChat()
    local mRoleInfo = self:PackRole2Chat()
    -- local oOrg = self:GetOrg()
    -- if oOrg then
        -- mRoleInfo.position = oOrg:GetPosition(self:GetPid())
        -- mRoleInfo.honor = oOrg:GetOrgHonor(self:GetPid())
    -- end
    return mRoleInfo
end

function CPlayer:IsTodaySigned(sKey)
    assert(sKey, "IsTodaySigned: key not exist")
    local mSign = self.m_oToday:Query("daily_sign", {})
    local iSign = mSign[sKey] or 0
    return iSign == 1
end

function CPlayer:DailySign(sKey)
    assert(sKey, "DailySign: key not exist !")
    local mSign = self.m_oToday:Query("daily_sign", {})
    mSign[sKey] = 1
    self.m_oToday:Set("daily_sign", mSign)
    self.m_oActiveCtrl:DailySignIn(sKey)
    return true
end

function CPlayer:GetDailySignDay(sKey)
    return self.m_oActiveCtrl:GetDailySignDay(sKey)
end

function CPlayer:PackDailySignInfo(sKey)
    local mInfo = {}
    mInfo["key"] = sKey
    mInfo["sign_day"] = self:GetDailySignDay(sKey)
    mInfo["is_sign"] = self:IsTodaySigned(sKey)
    return mInfo
end

function CPlayer:OnLeaveScene(...)
    if self:IsSocialDisplay() then
        self:CancelSocailDisplay()
    end
end

function CPlayer:UpdateHouseAttr(mAttr)
    mAttr = mAttr or {}
    self.m_mHouseAttr = mAttr
    -- self:ActivePropChange()
    self.m_oPartnerCtrl:SyncHouseAttr(mAttr)
end

function CPlayer:LogAnalyGame(mLog,sGameName,mItemList,mCurrency,mPartnerExp,exp)
    exp = exp or 0
    mLog = mLog or {}
    mLog = table_combine(mLog,self:GetPubAnalyData())
    mLog["gamename"]=sGameName
    mLog["reward_detail"] = analy.datajoin(mItemList)
    mLog["reward_currency"] = analy.datajoin(mCurrency)
    mLog["reward_exp"] = exp
    mLog["reward_partnerexp"] = analy.datajoin(mPartnerExp)
    analy.log_data("Game_Reward",mLog)
end

function CPlayer:GetUpgradeEnergy()
    local iTotalAdd = res["daobiao"]["global"]["upgrade_energy"]["value"]
    return tonumber(iTotalAdd)
end

function CPlayer:ValidGameShare(sType)
    local res = require "base.res"
    local mData = res["daobiao"]["gameshare"]
    if not mData[sType] then
        return false
    end
    local mGameShare = self.m_oToday:Query("game_share",{})
    if mGameShare[sType] then
        return false
    end
    return true
end

function CPlayer:SetGameShare(sType)
    local mGameShare = self.m_oToday:Query("game_share",{})
    mGameShare[sType] = 1
    self.m_oToday:Set("game_share",mGameShare)
    local lGameShare = {}
    table.insert(lGameShare,{type=sType,value=1})
    self:Send("GS2CGameShare",{game_share=lGameShare})
end

function CPlayer:PushGameShareInfo()
    local res = require "base.res"
    local mGameShare = self.m_oToday:Query("game_share",{})
    local mData = res["daobiao"]["gameshare"]
    local lGameShare = {}
    for sType,mShareData in pairs(mData) do
        local iValue = mGameShare[sType] or 0
        table.insert(lGameShare,{type=sType,value=iValue})
    end
    self:Send("GS2CGameShare",{game_share=lGameShare})
end

--月卡用户
function CPlayer:IsMonthCardVip()
    local oHuodong = global.oHuodongMgr:GetHuodong("charge")
    if oHuodong:IsMonthCardVip(self:GetPid()) then
        return true
    end
    return false
end

--终身卡用户
function CPlayer:IsZskVip()
    local oHuodong = global.oHuodongMgr:GetHuodong("charge")
    if oHuodong:IsZskVip(self:GetPid()) then
        return true
    end
    return false
end

--sType:yk,zsk
function CPlayer:OnChargeCard(sType)
    local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
    oHuodong:OnChargeCard(self)
    self.m_oActiveCtrl:OnChargeCard(sType)
end

function CPlayer:RemoveTitlesByKey(sKey)
    self.m_oTitleCtrl:RemoveTitlesByKey(self,sKey)
end

function CPlayer:IsOrgLeader()
    return global.oOrgMgr:IsOrgLeader(self:GetPid())
end

function CPlayer:IsOnSceneQuestion()
    local oHuodong = global.oHuodongMgr:GetHuodong("question")
    if oHuodong then
        local o = oHuodong:GetQuestionObj(gamedefines.QUESTION_TYPE.SCENE)
        return o and o:OnQuestion(self)
    end
    return false
end

function CPlayer:GetCreateDay()
    local iCday = get_dayno(self:GetCreateTime())
    local iNday = get_dayno(get_time())
    return iNday - iCday
end

function CPlayer:ChangeShape(iShape)
    local iOld = self:GetShape()
    local shapes = self.m_oActiveCtrl:GetData("shape_list", {})
    if table_in_list(shapes, iShape) then
        local m = self:GetModelInfo()
        m.shape = iShape
        self.m_oBaseCtrl:SetData("model_info", m)
        self:PropChange("model_info")

        record.user("player", "changeshape", {
            pid = self:GetPid(),
            old = iOld,
            new = iShape,
            })
    end
    if not table_in_list(shapes, iOld) then
        self:AddShape(iOld, "切换皮肤")
    end
end

function CPlayer:AddShape(iShape, sReason)
    local shapes = self.m_oActiveCtrl:GetData("shape_list", {})
    if table_in_list(shapes, iShape) then
        return
    end
    local res = require "base.res"
    local mShape = res["daobiao"]["roleskin"][iShape]
    if not mShape then
        return
    end
    if self:GetSchool() ~= mShape.school then
        record.warning("AddShape school err, pid:%s, shape:%s, reason:%s", self:GetPid(), iShape, sReason)
        return
    end
    if self:GetSex() ~= mShape.sex then
        record.warning("AddShape sex err, pid:%s, shape:%s, reason:%s", self:GetPid(), iShape, sReason)
        return
    end
    table.insert(shapes, iShape)
    self.m_oActiveCtrl:SetData("shape_list", shapes)
    self:Send("GS2CShapeList", {shapes = table_value_list(shapes)})
    record.user("player", "addshape", {
        pid = self:GetPid(),
        shape = iShape,
        reason = sReason,
        })
end

function CPlayer:GetWuHunBaodi()
    local mBaodi = self.m_oActiveCtrl:GetData("wuhun_card_baodi", {})
    if not next(mBaodi) then
        local res = require "base.res"
        local mData = res["daobiao"]["partner"]["wuhun_baodi"][1]
        mBaodi = {wave = 1, num = 3, count = 0}
        if mData then
            mBaodi.num = mData.count or mBaodi.num
        end
        self.m_oActiveCtrl:SetData("wuhun_card_baodi", mBaodi)
    end
    return mBaodi
end

function CPlayer:SetWuHunBaodi(mBaodi)
    self.m_oActiveCtrl:SetData("wuhun_card_baodi", mBaodi)
end

function CPlayer:ValidWatchWar()
    local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
    if not oHuodong:ValidWatchWar(self) then
        return false,"据点战准备时无法观战"
    end
    return true
end

function CPlayer:RedeemCodeReward(sCode, iErr, iGift, iRedeem)
    local oHuodong = global.oHuodongMgr:GetHuodong("redeemcode")
    if oHuodong then
        oHuodong:RedeemCodeReward(self,sCode, iErr, iGift, iRedeem)
    end
end

function CPlayer:SendXGToken(mData)
    local sToken = mData["xg_token"]
    local iPid = self:GetPid()
    local iPlatform = self:GetPlatform()
    local mXGData = {
        pid = iPid,
        platform = iPlatform,
        token = sToken,
    }
    interactive.Send(".gamepush","common","OnLogin",mXGData)
end

function CPlayer:SyncTeamSceneInfo()
    if self:IsTeamShortLeave() then
        local oLeader = self:GetTeamLeader()
        if oLeader then
            local oScene = oLeader.m_oActiveCtrl:GetNowScene()
            if oScene then
                oScene:SyncSceneTeam(oLeader)
            end
        end
    end
end