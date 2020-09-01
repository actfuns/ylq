--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"
local extend = require "base/extend"
local router = require "base.router"

local gamedefines = import(lualib_path("public.gamedefines"))
local analy = import(lualib_path("public.dataanaly"))

function NewChatMgr(...)
    local o=CChatMgr:New(...)
    o:_HandleBroadCastGongGao()
    return o
end

CChatMgr = {}
CChatMgr.__index = CChatMgr
inherit(CChatMgr,logic_base_cls())

function CChatMgr:New()
    local o = super(CChatMgr).New(self)
    o.m_mThousandsCall = {}     --千里传音
    o.m_BanChatAct = {}
    o.m_BanChatRole = {}
    return o
end

function CChatMgr:Init()
    self:InitBanInfo()
    self:Schedule()
end

function CChatMgr:HandleWorldChat(oPlayer, sMsg)
    if string.len(sMsg) == 0 then
        return
    end
    local oNotifyMgr =global.oNotifyMgr
    local mAmountColor = res["daobiao"]["othercolor"]["amount"]
    local iType = gamedefines.CHANNEL_TYPE.WORLD_TYPE
    local mChat = res["daobiao"]["chatconfig"][iType]
    assert(mChat, string.format("HandleWorldChat:chat config not exist, id:%d", iType))
    local pid = oPlayer:GetPid()
    local iGrade = oPlayer:GetGrade()
    local iSayTime = oPlayer.m_oActiveCtrl:GetData("world_chat", 0)
    local iNow = get_time()
    local iGradeLimit = formula_string(mChat.grade_limit, {})
    local iChatGap = formula_string(mChat.talk_gap, {})
    local iCostEnergy = formula_string(mChat.energy_cost, {})
    local iHaveEnergy = oPlayer.m_oActiveCtrl:GetData("energy")
    if iGrade < iGradeLimit then
        local sMsg = string.format("等级需达到%s级", mAmountColor.color)
        sMsg = string.format(sMsg, iGradeLimit)
        oNotifyMgr:Notify(pid, sMsg)
        return
    end
    local iRemainTime = iSayTime+iChatGap - iNow
    if iRemainTime > 0 then
        local sMsg = string.format("发言过快，%s秒后才能发言", mAmountColor.color)
        sMsg = string.format(sMsg, iRemainTime)
        oNotifyMgr:Notify(pid, sMsg)
        return
    end
    -- 先不加活力
    if true or iHaveEnergy >= iCostEnergy then
        --oPlayer.m_oActiveCtrl:SetData("energy", iHaveEnergy - iCostEnergy)
        self:SendWOrldChat(oPlayer,sMsg)
        oPlayer.m_oActiveCtrl:SetData("world_chat", iNow)
        self:LogAnaly(oPlayer,iType,sMsg)
    else
        local sMsg = string.format("活力不足，世界发言需要消耗%s点活力", mAmountColor.color)
        sMsg = string.format(sMsg, iCostEnergy)
        oNotifyMgr:Notify(pid, sMsg)
    end
end

function CChatMgr:SendWOrldChat(oPlayer,sMsg)
    local oNotifyMgr =global.oNotifyMgr
    local mRoleInfo = {pid=0}
    if oPlayer then
        mRoleInfo ={
            pid = oPlayer:GetPid(),
            name = oPlayer:GetName(),
            grade = oPlayer:GetGrade(),
            shape = oPlayer:GetModelInfo().shape,
        }
    end
    oNotifyMgr:SendWorldChat(sMsg, mRoleInfo)
end


function CChatMgr:HandleSysChat(sMsg, iTag, iHorse)
    iTag = iTag or gamedefines.SYS_CHANNEL_TAG.NOTICE_TAG
    iHorse = iHorse or 0
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendSysChat(sMsg, iTag, iHorse)
end

function CChatMgr:HandleTeamChat(oPlayer, sMsg,  bSys,iExtraArgs)
    if string.len(sMsg) == 0 then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local iTeamID = oPlayer:TeamID()
    if  iExtraArgs  and iExtraArgs == 1 then
        iTeamID = 1
    end
    local iType = gamedefines.CHANNEL_TYPE.TEAM_TYPE
    local mChat = res["daobiao"]["chatconfig"][iType]
    assert(mChat, string.format("HandleWorldChat:chat config not exist, id:%d", iType))
    if not bSys then
        local pid = oPlayer:GetPid()
        local iGrade = oPlayer:GetGrade()
        local iSayTime = oPlayer.m_oActiveCtrl:GetData("team_chat", 0)
        local iNow = get_time()
        local iGradeLimit = formula_string(mChat.grade_limit, {})
        local iChatGap = formula_string(mChat.talk_gap, {})
        if iGrade < iGradeLimit then
            oNotifyMgr:Notify(pid, string.format("等级需达到%s级", iGradeLimit))
            return
        end
        local iRemainTime = iSayTime+iChatGap - iNow
        if iRemainTime > 0 then
            oNotifyMgr:Notify(pid, string.format("发言过快，%s秒后才能发言", iRemainTime))
            return
        end
    end
    if iTeamID then
        local mRoleInfo = {pid = 0} --系统
        if not bSys then
            if iTeamID == 1 then
                local iSayTime = oPlayer.m_oActiveCtrl:GetData("global_team_chat",0)
                local iNow = get_time()
                local iChatGap = formula_string(mChat.global_talk_gap,{})
                local iRemainTime = iSayTime+iChatGap - iNow
                if iRemainTime > 0 then
                    oNotifyMgr:Notify(oPlayer:GetPid(), string.format("刚刚发布组队信息，请等待%s秒后再次发布", iRemainTime))
                    return
                end
                oPlayer.m_oActiveCtrl:SetData("global_team_chat", get_time())
            else
                mRoleInfo.pid = oPlayer:GetPid()
                mRoleInfo.grade = oPlayer:GetGrade()
                mRoleInfo.name = oPlayer:GetName()
                mRoleInfo.shape = oPlayer:GetModelInfo().shape
                oPlayer.m_oActiveCtrl:SetData("team_chat",get_time())
            end
            self:LogAnaly(oPlayer,iType,sMsg)
        end
        oNotifyMgr:SendTeamChat(sMsg, iTeamID, mRoleInfo)
    end
end

function CChatMgr:HandleBroadCastTeamChat(oPlayer,lMessage,sMsg,mArgs,iExtraArgs)
    local oNotifyMgr = global.oNotifyMgr
    local iTeamID = oPlayer:TeamID()
    if  iExtraArgs  and iExtraArgs == 1 then
        iTeamID = 1
    end
    local mRoleInfo = {pid = 0} --系统
    oNotifyMgr:BroadCastTeamNotify(iTeamID,lMessage,sMsg,mArgs,mRoleInfo)
end

function CChatMgr:HandleCurrentChat(oPlayer, sMsg, bSys)
    --后面还有观战聊天
    if string.len(sMsg) == 0 then
        return
    end
    local iType = gamedefines.CHANNEL_TYPE.CURRENT_TYPE
    local oNotifyMgr = global.oNotifyMgr
    local mChat = res["daobiao"]["chatconfig"][iType]
    assert(mChat, string.format("HandleWorldChat:chat config not exist, id:%d", iType))
    if not bSys then
        local pid = oPlayer:GetPid()
        local iGrade = oPlayer:GetGrade()
        local iSayTime = oPlayer.m_oActiveCtrl:GetData("current_chat", 0)
        local iNow = get_time()
        local iGradeLimit = formula_string(mChat.grade_limit, {})
        local iChatGap = formula_string(mChat.talk_gap, {})
        if iGrade < iGradeLimit then
            oNotifyMgr:Notify(pid, string.format("等级需达到%s级", iGradeLimit))
            return
        end
        local iRemainTime = iSayTime+iChatGap - iNow
        if iRemainTime > 0 then
            oNotifyMgr:Notify(pid, string.format("发言过快，%s秒后才能发言", iRemainTime))
            return
        end
        self:LogAnaly(oPlayer,iType,sMsg)
    end
    --战斗/观战
    local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oWar then
        local mNet={}
        mNet["type"] = iType
        mNet["cmd"] = sMsg
        mNet["role_info"] = {
            pid = oPlayer:GetPid(),
            grade = oPlayer:GetGrade(),
            name = oPlayer:GetName(),
            shape = oPlayer:GetModelInfo().shape,
        }
        oWar:SendCurrentChat(oPlayer, mNet)
        return
    end
    --非战斗
    local oSceneMgr = global.oSceneMgr
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene then
        local mRoleInfo = { pid = 0}
        if not bSys then
            mRoleInfo.pid = oPlayer:GetPid()
            mRoleInfo.grade = oPlayer:GetGrade()
            mRoleInfo.name = oPlayer:GetName()
            mRoleInfo.shape = oPlayer:GetModelInfo().shape
            oPlayer.m_oActiveCtrl:SetData("current_chat", get_time())
        end
        local mNet = {
            role_info = mRoleInfo,
            type = iType,
            cmd = sMsg,
        }
        oScene:SendCurrentChat(oPlayer, mNet)
    end
end

--消息频道
function CChatMgr:HandleMsgChat(oPlayer, sMsg)
    local iType = gamedefines.CHANNEL_TYPE.MSG_TYPE
    if oPlayer then
        oPlayer:Send("GS2CConsumeMsg", {type = iType, content = sMsg})
    end
end

--千里传音
function CChatMgr:HandleThousandsCall(oPlayer, iTag, sMsg)
    local oNotifyMgr = global.oNotifyMgr
    local res = require "base.res"
    local mChuanyin = res["daobiao"]["chat"]["chuanyin"][iTag]
    assert(mChuanyin, string.format("chat/chatconfig chuanyin id:%d not exist!", iTag))
    local pid = oPlayer:GetPid()
    local iMsgAmount = #self.m_mThousandsCall
    if iMsgAmount >= 10 then
        oNotifyMgr:Notify(pid, "使用千里传音的过多，请稍后尝试")
    end
    local mItem = mChuanyin.item
    local iHaveItem = oPlayer:GetItemAmount(mItem.item_id)
    if iHaveItem >= mItem.cost_amount then
        table.insert(self.m_mThousandsCall, sMsg)
        if iMsgAmount == 0 then
            local f = function()
                table.remove(self.m_mThousandsCall, 1)
                if #self.m_mThousandsCall > 0 then
                    self:DelTimeCb("ThousandsCall")
                    self:AddTimeCb("ThousandsCall", 5 * 1000, f)
                end
            end
            self:DelTimeCb("ThousandsCall")
            self:AddTimeCb("ThousandsCall", 5 * 1000, f)
            oNotifyMgr:SendThousandsCall()
        end
    else

    end
end

--自动播放公告
function CChatMgr:_HandleBroadCastGongGao()
    local f1
    f1 = function()
        self:BroadCastNotice()
        self:DelTimeCb("_HandleBroadCastGongGao")
        self:AddTimeCb("_HandleBroadCastGongGao", 5* 60 * 1000, f1)
    end
    f1()
end

function CChatMgr:BroadCastNotice()
    local mAllGonggao = res["daobiao"]["gonggao"]
    local lGonggaoID = table_key_list(mAllGonggao)
    local iMinID = math.min(table.unpack(lGonggaoID))
    local iMaxID =math.max(table.unpack(lGonggaoID))
    local iG = self.m_iGonggao or iMinID
    if iG > iMaxID then
        iG = iMinID
     end
    local mGonggao = mAllGonggao[iG]
    assert(mGonggao, string.format("gonggao config not exist,id:%d", iG))
    local sMsg = mGonggao.content
    local iTag = gamedefines.SYS_CHANNEL_TAG.NOTICE_TAG
    local iHorse = mGonggao.horse_race
    self:HandleSysChat(sMsg, iTag, iHorse)
    self.m_iGonggao = iG + 1
end

function CChatMgr:HandleOrgChat(oPlayer,sMsg)
    local iType = gamedefines.CHANNEL_TYPE.ORG_TYPE
    local mChat = res["daobiao"]["chatconfig"][iType]
    assert(mChat, string.format("CChatMgr:HandleOrgChat:chat config not exist, id"))
    local iSayTime = oPlayer.m_oActiveCtrl:GetData("org_chat", 0)
    local iGradeLimit = formula_string(mChat.grade_limit, {})
    local iChatGap = formula_string(mChat.talk_gap, {})
    if oPlayer:GetGrade() < iGradeLimit then
        oPlayer:NotifyMessage("等级未达到")
        return
    end
    local iRemainTime = iSayTime + iChatGap - get_time()
    if iRemainTime > 0 then
        oPlayer:NotifyMessage("发言过于频繁")
        return
    end
    oPlayer.m_oActiveCtrl:SetData("org_chat", get_time())
    local iOrgID = oPlayer:GetOrgID()
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendOrgChat(sMsg, iOrgID, oPlayer:PackRole2Chat())
    --global.oOrgMgr:HandleOrgChat(oPlayer:GetPid(),sMsg)
end

function CChatMgr:HandleTeamPVPChat(oPlayer, sMsg,  bSys,iExtraArgs)
    if string.len(sMsg) == 0 then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local iTeamID = oPlayer:TeamPVPID()
    local iType = gamedefines.CHANNEL_TYPE.TEAMPVP_TYPE

    if iTeamID then
        local mRoleInfo = {}
        mRoleInfo.pid = oPlayer:GetPid()
        mRoleInfo.grade = oPlayer:GetGrade()
        mRoleInfo.name = oPlayer:GetName()
        mRoleInfo.shape = oPlayer:GetModelInfo().shape
        if not bSys then
            local iSayTime = oPlayer.m_oActiveCtrl:GetData("teampvp_chat",0)
            local iNow = get_time()
            local iChatGap = 2
            local iRemainTime = iSayTime+iChatGap - iNow
            if iRemainTime > 0 then
                oNotifyMgr:Notify(oPlayer:GetPid(), "发言过于频繁")
                return
            end
            oPlayer.m_oActiveCtrl:SetData("teampvp_chat", get_time())

            self:LogAnaly(oPlayer,iType,sMsg)
        end
        oNotifyMgr:SendTeamPvpChat(sMsg, iTeamID, mRoleInfo)
    end
end

function CChatMgr:SendMsg2Org(sMsg, iOrgID, oPlayer)
    local mRoleInfo = {pid = 0}                                 --系统
    if oPlayer then
        mRoleInfo = oPlayer:PackRole2OrgChat()
    end
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendOrgChat(sMsg, iOrgID, mRoleInfo)
end

function CChatMgr:LogAnaly(oPlayer,iType,sMsg,iTarget)
    local mLog = oPlayer:GetPubAnalyData()
    mLog["chat_channel"] = iType
    mLog["content"] = sMsg
    mLog["target_role_id"] = iTarget or ""
    analy.log_data("chat",mLog)
end

function CChatMgr:BanChat(oPlayer, iTime)
    oPlayer.m_oActiveCtrl:SetBanChat(iTime)
end

function CChatMgr:IsBanChat(oPlayer)
    return oPlayer.m_oActiveCtrl:IsBanChat()
end

------------禁言处罚部分-----------------
function CChatMgr:InitBanInfo()
    local f1
    f1 = function ()
        self:DelTimeCb("InitBanInfo")
        self:InitBanInfo2()
    end
    self:AddTimeCb("InitBanInfo", 5*1000 , f1)
end

function CChatMgr:InitBanInfo2()
    router.Request("cs",".serversetter", "punish", "GetBanChatInfo", {}, function (mRecord,mData)
        mData = extend.Table.deserialize(mData)
        self:InitBanInfo3(mData)
    end)
end

function CChatMgr:InitBanInfo3(mData)
    self.m_BanChatAct = mData.act or {}
    self.m_BanChatRole = mData.role or {}
end

function CChatMgr:InActBan(sAccount)
    local iNowTime = get_time()
    local iEndTime = self.m_BanChatAct[sAccount] or 0
    if iNowTime < iEndTime then
        return iEndTime - iNowTime
    end
    return false
end

function CChatMgr:InRoleBan(pid)
    local iNowTime = get_time()
    local iEndTime = self.m_BanChatRole[tostring(pid)] or 0
    if iNowTime < iEndTime then
        return iEndTime - iNowTime
    end
    return false
end

function CChatMgr:SyncPunish(mArgs)
    local mList
    if mArgs.type == "banchatact" or mArgs.type == "cancelbanact" then
        mList = self.m_BanChatAct
    elseif mArgs.type == "banchatrole" or mArgs.type == "cancelbanrole" then
        mList = self.m_BanChatRole
    end
    mList[mArgs.key] = mArgs.value
    if mArgs.type == "banchatrole" then
        self:SendBanCharMail(mArgs.key)
    end
end

function CChatMgr:SendBanCharMail(iPid)
    iPid = tonumber(iPid)
    if iPid then
        local oMailMgr = global.oMailMgr
        local mMail, sMail = oMailMgr:GetMailInfo(65)
        oMailMgr:SendMail(0, sMail, iPid, mMail)
    end
end

function CChatMgr:ValidChat(oPlayer)
    local sAccount = oPlayer:GetAccount()
    local iPid = oPlayer:GetPid()
    local iTime = self:InActBan(sAccount)
    if iTime then
        oPlayer:NotifyMessage("您的账号处于禁言状态，将于"..get_second2string(iTime).."后解除")
        return false
    end
    local iTime = self:InRoleBan(iPid)
    if iTime then
        oPlayer:NotifyMessage("您的角色处于禁言状态，将于"..get_second2string(iTime).."后解除")
        return false
    end
    return true
end

function CChatMgr:Schedule()
    local f1
    f1 = function ()
        self:DelTimeCb("ClearOverTime")
        self:AddTimeCb("ClearOverTime", 50*60*1000 , f1)
        self:ClearOverTime()
    end
    f1()
end

function CChatMgr:ClearOverTime()
    local mAttrs = {"m_BanChatAct","m_BanChatRole"}
    local iNowTime = get_time()
    for _,sAttr in pairs(mAttrs) do
        local mDel = {}
        local mContent = self[sAttr] or {}
        for k,v in pairs(mContent) do
            if v < iNowTime then
                table.insert(mDel,k)
            end
        end
        for _,k in pairs(mDel) do
            mContent[k] = nil
        end
    end
end