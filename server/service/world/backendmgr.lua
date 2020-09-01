local global = require "global"
local interactive = require "base.interactive"
local extend = require "base.extend"
local router = require "base.router"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local loaditem = import(service_path("item/loaditem"))

function NewBackendMgr(...)
    return CBackendMgr:New(...)
end


CBackendMgr = {}
CBackendMgr.__index = CBackendMgr
inherit(CBackendMgr, logic_base_cls())

function CBackendMgr:New()
    local o = super(CBackendMgr).New(self)
    return o
end

function CBackendMgr:RunGmCmd(iPid, sCmd)
    local oGMMgr = global.oGMMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    oGMMgr:ReceiveCmd(oPlayer, sCmd)
end

function CBackendMgr:OnlineExecute(iPid, sFunc, mArgs)
    local oPubMgr = global.oPubMgr
    oPubMgr:OnlineExecute(iPid, sFunc, mArgs)
end

function CBackendMgr:BanPlayerChat(oPlayer, iTime)
    local oChatMgr = global.oChatMgr
    oChatMgr:BanChat(oPlayer, iTime)
end

function CBackendMgr:BanPlayerLogin(iPid, iSecond)
    local mSaveData = {ban_time = get_time() + iSecond}
    local mData = {
        pid = iPid,
        data = mSaveData,
    }
    gamedb.SaveDb(iPid,"common", "SaveDb", {module="playerdb",cmd="SavePlayerMain",data = mData})
end

function CBackendMgr:FinePlayerMoney(oPlayer, iMoneyType, iVal)
    local iCnt = oPlayer:GetMoney(iMoneyType)
    iVal = math.min(iCnt, iVal)
    if iVal <= 0 then return end

    oPlayer:ResumeMoneyByType(iMoneyType, iVal, "gm处罚", {cancel_tip=true})
end

function CBackendMgr:RenamePlayer(oPlayer, sName)
    local oRenameMgr = global.oRenameMgr
    oRenameMgr:_TrueDoRenameSuccess(oPlayer:GetPid(), sName, {success=true})
end

function CBackendMgr:RemovePlayerItem(oPlayer, iItemSid, iCnt)
    assert(loaditem.GetItem(iItemSid), string.format("gm RemovePlayerItem:%s", iItemSid))

    if oPlayer:GetItemAmount(iItemSid) < iCnt then
        iCnt = oPlayer:GetItemAmount(iItemSid)
    end
    if iCnt <= 0 then return end

    oPlayer:RemoveItemAmount(iItemSid, iCnt, "gm删除道具")
end

function CBackendMgr:KickPlayer(iPid)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:Logout(iPid)
end

function CBackendMgr:ForceWarEnd(oPlayer, iFlag)
    local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oWar then
        if iFlag and iFlag < 0 then
            oWar:TestCmd("warfail",oPlayer:GetPid(),{})
        else
            oWar:TestCmd("warend",oPlayer:GetPid(),{})
        end
    end
end

function CBackendMgr:ForceLeaveTeam(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        oTeam:Leave(oPlayer:GetPid())
    end
end

function CBackendMgr:ForceChangeScene(oPlayer)
    local oSceneMgr = global.oSceneMgr
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        self:ForceLeaveTeam(oPlayer)
    end
    oSceneMgr:ChangeMap(oPlayer, 101000)
end

function CBackendMgr:PackPlayer2Backend(oPlayer)
    local mRet = {}
    mRet["pid"] = oPlayer:GetPid()
    mRet["base"] = self:BKPlayerBase(oPlayer)
    mRet["warinfo"] = self:BKPlayerWarInfo(oPlayer)
    mRet["money"] = self:BKPlayerMoneyInfo(oPlayer)
    mRet["task"] = self:BKPlayerTaskInfo(oPlayer)
    mRet["online"] = true
    return mRet
end

function CBackendMgr:BKPlayerBase(oPlayer)
    local oProfile = oPlayer:GetProfile()
    local mInfo = {}
    mInfo.name = oPlayer:GetName()
    mInfo.power = oPlayer:GetWarPower()
    mInfo.logintime = oPlayer.m_oActiveCtrl:GetData("login_time",0)
    -- 最后离线时间
    mInfo.offlinetime = oPlayer.m_oActiveCtrl:GetData("disconnect_time",0)
    mInfo.grade = oPlayer:GetGrade()
    mInfo.exp = oPlayer:GetExp()
    mInfo.shape = oPlayer:GetShape()
    mInfo.school = oProfile:GetSchoolName()
    -- 流派
    mInfo.schoolbranch = oProfile:GetSchoolBranchName()
    mInfo.org = oPlayer:GetOrgID()
    --历史充值彩晶 备忘
    mInfo.maxcaijing = oProfile:HistoryCharge()
    mInfo.scene = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos() or {}
    mInfo.x = mNowPos.x or 0
    mInfo.y = mNowPos.y or 0
    mInfo.title = oPlayer.m_oTitleCtrl:BackEndData()

    return mInfo
end

function CBackendMgr:BKPlayerWarInfo(oPlayer)
    local mInfo = {}
    mInfo.max_hp = oPlayer:GetMaxHp()
    mInfo.attack = oPlayer:GetAttack()
    mInfo.defense = oPlayer:GetDefense()
    mInfo.speed = oPlayer:GetSpeed()
    --暴击概率
    mInfo.critical_ratio = oPlayer:GetCirticalRatio()
    --暴击伤害
    mInfo.critical_damage = oPlayer:GetCriticalDamage()
    --抗暴
    mInfo.res_critical_ratio = oPlayer:GetResCriticalRatio()
    --治疗暴击
    mInfo.cure_critical_ratio = oPlayer:GetCureCriticalRatio()
    --异常命中
    mInfo.abnormal_attr_ratio = oPlayer:GetAbnormalAttrRatio()
    --异常抵抗
    mInfo.res_abnormal_ratio = oPlayer:GetResAbnormalRatio()
    return mInfo
end

function CBackendMgr:BKPlayerMoneyInfo(oPlayer)
    local mInfo = {}
    -- 彩晶备忘
    mInfo.caijing = 0
    --水晶
    mInfo.goldcoin = oPlayer:GoldCoin()
    --金币
    mInfo.coin = oPlayer:Coin()
    -- 爱心积分
    mInfo.love = 0
    --荣誉
    mInfo.arenamedal = oPlayer:ArenaMedal()
    --勋章
    mInfo.medal = oPlayer:Medal()
    --活跃
    mInfo.active = oPlayer:Active()
    --贡献
    mInfo.offer = oPlayer:GetOffer()
    --皮肤券
    mInfo.skin = oPlayer:Skin()
    --公会经验
    mInfo.orgexp = oPlayer:GetOrgExp()
    --技能点
    mInfo.skillpoint = oPlayer:GetSkillPoint()
    --成就点
    mInfo.achpoint = oPlayer:GetInfo("achpoint",0)
    --游历积分
    mInfo.travelscore = oPlayer:GetTravelScore()

    return mInfo
end

function CBackendMgr:FormatTimeToSec(iTime)
    local m = os.date("*t", iTime)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d",m.year,m.month,m.day,m.hour,m.min,m.sec)
end

function CBackendMgr:BKPlayerTaskInfo(oPlayer)
    local mInfo = {}
    local mList = oPlayer.m_oTaskCtrl:TaskList()
    for iTid,oTask in pairs(mList) do
        local iTime = oTask:GetAcceptTime()
        local sTime = "无"
        if iTime > 0 then
            sTime = self:FormatTimeToSec(oTask:GetAcceptTime())
        end
        table.insert(mInfo,{
            tid=iTid,name=oTask:Name(),
            type=oTask:TypeName(),
            time=sTime,
        })
    end
    return mInfo
end

function CBackendMgr:OnLogin(oPlayer,bReEnter)
end

function CBackendMgr:OnLogout(oPlayer)
    self:AllSendBackendLog(oPlayer)
end

function CBackendMgr:OnDisconnected(oPlayer)
end

function CBackendMgr:AllSendBackendLog(oPlayer)
    safe_call(self.AllSendBackendLog2,self,oPlayer)
end

function CBackendMgr:AllSendBackendLog2(oPlayer)
    self:SendBackendLog(oPlayer:GetPid(),"player","base",self:BKPlayerBase(oPlayer))
    self:SendBackendLog(oPlayer:GetPid(),"player","warinfo",self:BKPlayerWarInfo(oPlayer))
    self:SendBackendLog(oPlayer:GetPid(),"player","money",self:BKPlayerMoneyInfo(oPlayer))
    self:SendBackendLog(oPlayer:GetPid(),"player","task",self:BKPlayerTaskInfo(oPlayer))
end

--玩家登出时保存数据至后台数据库
--@param sTableName 表名，默认player
--@param sType 所存数据类型
--@param mData 数据，可以是map,可以是list

function CBackendMgr:SendBackendLog(iPid, sTableName, sType, mInfo)
    local mData = {
        pid = iPid,
        data = {[sType]=mInfo},
    }
    gamedb.SaveDb(iPid,"common", "SaveDb", {module="playerinfodb",cmd="SavePlayerInfo",data = mData})
end

function CBackendMgr:SearchPartner(sFunc,mData,callback)
    local iPid = mData["pid"]
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        callback(nil,{data={online=false}})
        return
    end
    local iRemoteAddr = oPlayer.m_oPartnerCtrl:GetRemoteAddr()
    interactive.Request(iRemoteAddr, "backend", sFunc, mData, callback)
end

function CBackendMgr:BanPlayerReport(oPlayer, iTime)
    oPlayer.m_oThisTemp:Set("banreport",1,iTime)
end

function CBackendMgr:ResumeCoin(oPlayer,iVal,sReason)
    iVal = math.min(iVal,oPlayer:Coin())
    oPlayer:ResumeCoin(iVal,sReason)
end

function CBackendMgr:BanPlayerChatSelf(oPlayer,iTime)
    oPlayer.m_oThisTemp:Set("chatself",true,iTime)
    oPlayer:PropChange("chatself")
end

function CBackendMgr:RewardYYBaoGift(iPid,iGid)
    local res = require "base.res"
    local mDbGift = res["daobiao"]["yybaogift"]
    local mConfig = mDbGift[iGid]
    if not mConfig then
        record.error("yybao gift err id ".. iGid .. " pid "..iPid)
        return
    end
    local mReward = mConfig["reward"]
    local mItem = {}
    for _,mInfo in pairs(mReward) do
        local sShape,iAmount = mInfo["sid"],mInfo["num"]
        local oItem = loaditem.ExtCreate(sShape)
        oItem:SetAmount(iAmount)
        table.insert(mItem,oItem)
    end
    local oMailMgr = global.oMailMgr
    local mMail, sMail
    local sType = mConfig["stype"]
    if sType == "day" then
        mMail, sMail = oMailMgr:GetMailInfo(79)
    elseif sType == "level" then
        mMail, sMail = oMailMgr:GetMailInfo(78)
    elseif sType == "custom" then
        mMail, sMail = oMailMgr:GetMailInfo(80)
    else
        return
    end
    oMailMgr:SendMail(0, sMail, iPid, mMail, {},mItem)

    local iTitle = mConfig["title"]
    if iTitle ~= 0 then
        local oTitleMgr = global.oTitleMgr
        oTitleMgr:AddTitle(iPid, iTitle)
    end
end

function CBackendMgr:RewardIOSGift(iPid,iGid)
    local res = require "base.res"
    local mDbGift = res["daobiao"]["qqgift"]
    local mConfig = mDbGift[iGid]
    if not mConfig then
        record.error("qq gift err id ".. iGid .. " pid "..iPid)
        return
    end
    local mReward = mConfig["reward"]
    local mItem = {}
    for _,mInfo in pairs(mReward) do
        local sShape,iAmount = mInfo["sid"],mInfo["num"]
        local oItem = loaditem.ExtCreate(sShape)
        oItem:SetAmount(iAmount)
        table.insert(mItem,oItem)
    end
    local oMailMgr = global.oMailMgr
    local mMail, sMail
    local sType = mConfig["stype"]
    if sType == "newman" then
        mMail, sMail = oMailMgr:GetMailInfo(83)
    elseif sType == "supervip" then
        mMail, sMail = oMailMgr:GetMailInfo(84)
    elseif sType == "openvip" then
        mMail, sMail = oMailMgr:GetMailInfo(85)
    elseif sType == "specialvip1" then
        mMail, sMail = oMailMgr:GetMailInfo(86)
    elseif sType == "specialvip2" then
        mMail, sMail = oMailMgr:GetMailInfo(87)
    else
        return
    end
    oMailMgr:SendMail(0, sMail, iPid, mMail, {},mItem)

    local iTitle = mConfig["title"]
    if iTitle ~= 0 then
        local oTitleMgr = global.oTitleMgr
        oTitleMgr:AddTitle(iPid, iTitle)
    end
end

function CBackendMgr:SetHuodongOpen(mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("limitopen")
    return oHuodong:SetOpenInfo(mData)
end

function CBackendMgr:QueryOpenHuodong(mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("limitopen")
    return oHuodong:PackBackInfo(mData)
end