-- import module
local global = require "global"
local extend = require "base.extend"
local res = require "base.res"
local record = require "public.record"
local fstring = require "public.colorstring"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))
local loaditem = import(service_path("item.loaditem"))
local datactrl = import(lualib_path("public.datactrl"))

local QUESTION_TYPE = gamedefines.QUESTION_TYPE
local QUESTION_STATUS = gamedefines.QUESTION_STATUS
local RIGHT = 1
local WRONG = 0
local BROADCAST_TIPS = 4 * 60

local random = math.random

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_mList = {}
    local o = CRandomQuestion:New(QUESTION_TYPE.RANDOM)
    self.m_mList[QUESTION_TYPE.RANDOM] = o
    o = CScoreQuestion:New(QUESTION_TYPE.SCORE)
    self.m_mList[QUESTION_TYPE.SCORE] = o
    o = CSceneQuestion:New(QUESTION_TYPE.SCENE)
    self.m_mList[QUESTION_TYPE.SCENE] = o
    self.m_ScheduleMap = {question=2001,fool=1008 }
    self.m_iScheduleID  = 2001
end

function CHuodong:NewDay(iWeekDay)
    self:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_CLOSE)
end


function CHuodong:OnLogin(oPlayer, bReEnter)
    for iType, obj in pairs(self.m_mList) do
        if obj and obj.OnLogin then
            if obj:IsOpenGrade(oPlayer) then
                obj:OnLogin(oPlayer, bReEnter)
            end
        end
    end
end

function CHuodong:GetQuestionObj(iType)
    return self.m_mList[iType]
end

function CHuodong:NewHour(iWeekDay, iHour)
    for _, iType in pairs(QUESTION_TYPE) do
        local o = self:GetQuestionObj(iType)
        if o and o.NewHour and not self:IsClose() then
            o:NewHour(iWeekDay, iHour)
        end
    end
end

function CHuodong:IsClose(oPlayer)
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsClose("question") then
        if oPlayer then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(oPlayer:GetPid(), "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        end
        return true
    end
    return false
end

function CHuodong:TestOP(oPlayer, iCmd, ...)
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local iPid = oPlayer:GetPid()
    local mArgs = {...}
    if iCmd == 100 then
        oChatMgr:HandleMsgChat(oPlayer, "101-开启随机答题")
        oChatMgr:HandleMsgChat(oPlayer, "102-开启积分答题")
        oChatMgr:HandleMsgChat(oPlayer, "103-开启学霸答题")
    elseif iCmd == 101 then
        local o = self:GetQuestionObj(QUESTION_TYPE.RANDOM)
        if not o:ValidGMStart(oPlayer) then
            o:End()
            oNotifyMgr:Notify(iPid, "取消突击答题")
            return
        end
        local iStartSec, iStaySec = table.unpack(mArgs)
        iStartSec = iStartSec or 60
        iStaySec = iStaySec or 180
        if iStartSec <= 0 or iStaySec <= 0 then
            global.oNotifyMgr:Notify(oPlayer:GetPid(), "时间需大于0")
            return
        end
        o:TipStart(0, iStartSec or 60, iStaySec or 180)
    elseif iCmd == 102 then
        local o = self:GetQuestionObj(QUESTION_TYPE.SCORE)
        if not o:ValidGMStart(oPlayer) then
            o:OnEnd()
            oNotifyMgr:Notify(iPid, "取消学渣答题")
            return
        end
        local iStartSec, iStaySec, iCount = table.unpack(mArgs)
        iStartSec = iStartSec or 60
        iStaySec = iStaySec or 30
        iCount = iCount or 20
        if iStartSec <= 0 or iStaySec <= 0 or iCount <= 0 then
            global.oNotifyMgr:Notify(oPlayer:GetPid(), "时间和题数需大于0")
            return
        end
        o.m_iStaySec = iStaySec
        o.m_iCount = iCount
        o:TipStart(0, iStartSec, iStaySec)
    elseif iCmd == 103 then
        local o = self:GetQuestionObj(QUESTION_TYPE.SCENE)
        if not o:ValidGMStart(oPlayer) then
            o:OnEnd()
            o:GS2CNotifyQuestion(o:PackStatusInfo())
            o:TrueEnd()
            oNotifyMgr:Notify(iPid, "取消学霸答题")
            return
        end
        local iStartSec, iStaySec, iCount = table.unpack(mArgs)
        iStartSec = iStartSec or 60
        iStaySec = iStaySec or 10
        iCount = iCount or 20
        if iStartSec <= 0 or iStaySec <= 0 or iCount <= 0 then
            global.oNotifyMgr:Notify(oPlayer:GetPid(), "时间和题数需大于0")
            return
        end
        o.m_iStaySec = iStaySec
        o.m_iCount = iCount
        o:TipStart(0, iStartSec, iStaySec)
    elseif iCmd == 104 then
        local iType, iMember = table.unpack(mArgs)
        iMember = iMember or 20
        if iMember > 0 then
            -- if iType == QUESTION_TYPE.SCORE then
            --     SCORE_MAX_MEM = iMember
            --     oNotifyMgr:Notify(iPid, string.format("学渣人数改为:%s", iMember))
            -- elseif iType == QUESTION_TYPE.SCENE then
            --     SCENE_MAX_MEM = iMember
            --     oNotifyMgr:Notify(iPid, string.format("学霸人数改为:%s", iMember))
            -- else
            --     oNotifyMgr:Notify(iPid, "类型不存在")
            -- end
        else
            oNotifyMgr:Notify(iPid, "数量不可以小于0")
        end
    end
    -- o:Add(iTipSec, iStartSec, iStartStay)
end


CQuestion = {}
CQuestion.__index = CQuestion
inherit(CQuestion, logic_base_cls())

function CQuestion:New(iQuestionType)
    local o = super(CQuestion).New(self)
    o.m_iType = iQuestionType
    o.m_iQuestion = 0
    o.m_iID = 0
    o.m_iTime = 0
    o.m_iQuestionEndTime = 0
    o.m_iEndTime = 0
    o.m_iStatusEndTime = 0
    o.m_mIDPool = {}
    o.m_iStatus = QUESTION_STATUS.END
    o.m_mAnswerPlayer = {}
    o:InitPool()
    return o
end

function CQuestion:InitPool()
    local mData = res["daobiao"]["question_pool"]
    self.m_mIDPool = table_key_list(mData)
end

function CQuestion:ClearData()
    self.m_iQuestion = 0
    self.m_iID = 0
    self.m_iTime = 0
    self.m_mIDPool = {}
    self.m_iStatus = QUESTION_STATUS.END
    self.m_mAnswerPlayer = {}
    self:InitPool()
end

function CQuestion:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        self:ClearData()
    end
end

function CQuestion:ValidGMStart(oPlayer)
    if self:Status() == QUESTION_STATUS.END then
        return true
    end
    local oNotifyMgr = global.oNotifyMgr
    local iEndSeconds = math.max(0, self.m_iEndTime - get_time())
    if iEndSeconds == 0 then
        return true
    end
    -- oNotifyMgr:Notify(oPlayer:GetPid(), string.format("不可重复开启答题,%s 秒后可开启", iEndSeconds))
    return false
end

function CQuestion:Type()
    return self.m_iType
end

function CQuestion:Status()
    return self.m_iStatus
end

function CQuestion:GetTextData(iText, args)
    return fstring.GetTextData(iText, {"huodong", "question"}, args)
end

function CQuestion:OnQuestion(oPlayer)
    return false
end

function CQuestion:GetHuodong()
    local oHuodongMgr = global.oHuodongMgr
    return oHuodongMgr:GetHuodong("question")
end

function CQuestion:Add(iTipSec, iStartSec, iStartStay)
    local f1
    f1 = function ()
        self:TipStart(iTipSec, iStartSec, iStartStay)
    end
    self:DelTimeCb("AddQuestion")
    self:AddTimeCb("AddQuestion", iTipSec * 1000, f1)
end

function CQuestion:TipStart(iTipSec, iStartSec, iStartStay)
    self:DelTimeCb("AddQuestion")
    self.m_iStatus = QUESTION_STATUS.READY
    self.m_iStatusEndTime = get_time() + iStartSec - iTipSec
    local f1
    f1 = function ()
        self:Start(iStartStay)
    end
    self:DelTimeCb("Start")
    self:AddTimeCb("Start", iStartSec * 1000, f1)
    self:LogStatus("READY")
end

function CQuestion:Start(iStartStay)
    self:DelTimeCb("Start")
    self.m_iStatus = QUESTION_STATUS.START
    local iEndStamp = get_time() + iStartStay
    self:OnStart(iEndStamp)
    local f1
    f1 = function ()
        self:End()
    end
    self:DelTimeCb("QuestionEnd")
    self:AddTimeCb("QuestionEnd", iStartStay * 1000, f1)
    self:LogStatus("START")
end

function CQuestion:StatusContent()
    return ""
end

function CQuestion:PackStatusInfo(sContent, iEndTime)
    return {
        type = self:Type(),
        desc = sContent or self:StatusContent(),
        status = self:Status(),
        end_time = iEndTime or self.m_iStatusEndTime,
        server_time = get_time(),
    }
end

function CQuestion:OnStart(iEndStamp)
    self.m_iID = self:DispatchID()
    self.m_iTime = get_time()
    local iQuestion = self:GetQuestionID()
    local mQuestion = self:GetQuestionData(iQuestion)
    self.m_iQuestion = mQuestion.id
    self.m_mAnswer = extend.Random.random_size(mQuestion.answer, #mQuestion.answer)

    local mNet = self:PackQuestionInfo(iEndStamp)
    self:GS2CQuestionInfo(mNet)

end

function CQuestion:PackQuestionInfo(iEndStamp)
    local mQuestion = self:GetQuestionData(self.m_iQuestion)
    local mNet = {}
    mNet["id"] = self.m_iID
    mNet["type"] = self:Type()
    mNet["desc"] = mQuestion.question
    local lAnswer = {}
    for id, sAnswer in ipairs(self.m_mAnswer) do
        table.insert(lAnswer, sAnswer)
    end
    mNet["answer_list"] = lAnswer
    mNet["end_time"] = iEndStamp
    mNet["server_time"] = get_time()
    self.m_iQuestionEndTime = iEndStamp
    local iReward = mQuestion.random_reward
    if self:Type() == QUESTION_TYPE.SCORE then
        iReward = mQuestion.score_reward
    end
    local oHuodong = self:GetHuodong()
    local mReward = oHuodong:GetRewardData(iReward)
    local sCoin = mReward.coin
    if sCoin and sCoin ~= "" then
        mNet["base_reward"] = formula_string(sCoin, {})
    end

    return mNet
end

function CQuestion:End()
end

function CQuestion:OnEnd()
    self.m_iStatus = QUESTION_STATUS.END
    self:DelTimeCb("AddQuestion")
    self:DelTimeCb("OnTipStart")
    self:DelTimeCb("Start")
    self:DelTimeCb("OnEnd")
    self:DelTimeCb("NextQuestion")
    self:DelTimeCb("QuestionEnd")
end

function CQuestion:SendRewardEmail(iPid, iReward, iMail, iRank)
    local oMailMgr = global.oMailMgr
    local mData, sName = oMailMgr:GetMailInfo(iMail)
    if iRank then
        mData.context = string.format(mData.context, iRank)
    end
    local oHuodong = self:GetHuodong()
    oHuodong:RewardByMail(iPid, iReward, {
        name = sName,
        mailinfo = mData,
        })

    local mLog = {
        pid = iPid,
        mailid = iMail,
        reward = iReward,
        qtype = self:TypeName(),
        rank = iRank or 0,
    }
    record.user("question", "sendmail", mLog)
end

function CQuestion:GetAnswerRemainCD(oPlayer)
    return 0
end

function CQuestion:ValidAnswer(oPlayer, iID)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if self:Status() == QUESTION_STATUS.END then
        oNotifyMgr:Notify(iPid, "活动已结束")
        return false
    end
    if not self.m_mAnswer then
        oNotifyMgr:Notify(iPid, "活动已结束")
        return false
    end
    if iID ~= self.m_iID then
        oNotifyMgr:Notify(iPid, "该题已结束")
        return false
    end

    local iRemainCD = self:GetAnswerRemainCD(oPlayer)
    if iRemainCD > 0 then
        oNotifyMgr:Notify(iPid, string.format("您答题过于频繁，请%s秒后再试", iRemainCD))
        return
    end
    return true
end

function CQuestion:Answer(oPlayer, iID, iAnswer)
    if not self:ValidAnswer(oPlayer, iID) then
        return
    end
    local iPid = oPlayer:GetPid()
    local sAnswer = self.m_mAnswer[iAnswer]
    if not sAnswer then
        return
    end
    self:AddSchedule(oPlayer)
    self:OnAnswer(oPlayer, sAnswer)
    local mData = self:GetQuestionData(self.m_iQuestion)
    if sAnswer == mData.answer[1] then
        self:Correct(oPlayer, iAnswer)
    else
        self:Wrong(oPlayer, iAnswer)
    end
end

function CQuestion:AddSchedule(oPlayer)
    if self:Type() ==  QUESTION_TYPE.SCORE then
        oPlayer:AddSchedule("question")
        oPlayer:RecordPlayCnt("question",1)
    end
end

function CQuestion:DispatchID()
    local iID = self.m_iID + 1
    self.m_iID = iID
    return iID
end

function CQuestion:OnAnswer(oPlayer, sMsg)
    -- body
end

function CQuestion:Correct(oPlayer, iAnswer)
    -- body
end

function CQuestion:Wrong(oPlayer, iAnswer)
    -- body
end

function CQuestion:GetQuestionID()
    if not next(self.m_mIDPool) then
        self:InitPool()
    end
    local iLen = #self.m_mIDPool
    assert(iLen > 0, "CQuestion:GetQuestionID question pool is nil")
    local idx = math.random(iLen)
    local iQuestion = self.m_mIDPool[idx]
    self.m_mIDPool[idx] = self.m_mIDPool[iLen]
    self.m_mIDPool[iLen] = nil

    return iQuestion
end

function CQuestion:GetQuestionData(iQuestion)
    local mData = res["daobiao"]["question_pool"][iQuestion]
    assert(mData, string.format("question data err: %s", iQuestion))

    return mData
end

function CQuestion:GetMemberLimit(sType)
    local mData = res["daobiao"]["question_member"][sType]
    return mData and mData.limit
end

function CQuestion:GS2CNotifyQuestion(mData)
    local oWorldMgr = global.oWorldMgr
    local mOnline = oWorldMgr:GetOnlinePlayerList()
    for iPid, oPlayer in pairs(mOnline) do
        if self:IsOpenGrade(oPlayer) then
            oPlayer:Send("GS2CNotifyQuestion", mData)
        end
    end
end

function CQuestion:GS2CQuestionInfo(mData)

end

function CQuestion:TypeName()
    return ""
end

function CQuestion:IsOpenGrade(oPlayer)
    return true
end

function CQuestion:OpenGrade()
    return 36
end

function CQuestion:BroadCast(sCmd, lPid, mData)
    local oWorldMgr = global.oWorldMgr
    for _, iPid in ipairs(lPid) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send(sCmd, mData)
        end
    end
end

function CQuestion:LogStatus(sStatus)
    local mLog = {
        qtype = self:TypeName(),
        status = sStatus,
    }
    record.user("question", "question_status", mLog)
end

function CQuestion:LogAnswer(oPlayer,iAnswer,iCorrect)
    local mLog = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        qtype = self:TypeName(),
        idx = self.m_iID,
        qid = self.m_iQuestion,
        answer = iAnswer,
        correct = iCorrect,
        content = self.m_mAnswer[iAnswer] or "nil",
    }
    record.user("question", "answer_question", mLog)
end






------------------------突击答题------------------------------------
CRandomQuestion = {}
CRandomQuestion.__index = CRandomQuestion
inherit(CRandomQuestion, CQuestion)

function CRandomQuestion:New(iQuestionType)
    local o = super(CRandomQuestion).New(self, iQuestionType)
    o.m_mList = {}
    return o
end

function CRandomQuestion:OnLogin(oPlayer, bReEnter)
    local iPid = oPlayer:GetPid()
    if self:Status() == QUESTION_STATUS.READY then
        oPlayer:Send("GS2CNotifyQuestion", self:PackStatusInfo())
    elseif self:Status() == QUESTION_STATUS.START then
        oPlayer:Send("GS2CNotifyQuestion", self:PackStatusInfo())
        local mNet = self:PackQuestionInfo(self.m_iQuestionEndTime)
        oPlayer:Send("GS2CQuestionInfo", mNet)
        local mAnswerInfo = self.m_mList[iPid]
        if mAnswerInfo and mAnswerInfo.answer then
            local mNet = {}
            mNet["id"] = self.m_iID
            mNet["type"] = self:Type()
            mNet["result"] = 1
            mNet["answer"] = mAnswerInfo.answer_idx
            mNet["time"] = mAnswerInfo.time
            self:GS2CAnswerResult(mNet, iPid)
        end
    end
end

function CRandomQuestion:NewHour(iWeekDay, iHour)
    super(CRandomQuestion).NewHour(self, iWeekDay, iHour)
    local mTimeData = self:GetOpenTimeData()
    for _, mData in pairs(mTimeData) do
        local mTimeList = split_string(mData.lower_time, ":", tonumber)
        local iLowHour, iLowMinute = table.unpack(mTimeList)
        if iHour == iLowHour - 1 then
            mTimeList = split_string(mData.upper_time, ":", tonumber)
            local iUpperHour, iUpperMinute = table.unpack(mTimeList)
            local iStartStamp = get_hourtime({factor=1, hour=iLowHour}).time
            iStartStamp = iStartStamp + iLowMinute * 60
            local iEndStamp = get_hourtime({factor=1, hour=iUpperHour}).time
            iEndStamp = iEndStamp + iUpperMinute * 60
            assert(iEndStamp > iStartStamp, string.format("random question err: %s", mData.id))
            local iStartSec = math.random(iEndStamp - iStartStamp) + 60 * 60
            local iTipSec = iStartSec - 1 * 60
            local iStaySec = 3 * 60
            self:Add(iTipSec, 1 * 60, iStaySec)
            break
        end
    end
end

function CRandomQuestion:ClearData()
    super(CRandomQuestion).ClearData(self)
    for iPid, _ in pairs(self.m_mList) do
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:SetInfo("random_question_answer", false)
        end
    end
    self.m_mList = {}
end

function CRandomQuestion:TypeName()
    return "突击测验"
end

function CRandomQuestion:TipStart(iTipSec, iStartSec, iStartStay)
    super(CRandomQuestion).TipStart(self, iTipSec, iStartSec, iStartStay)
    self.m_iEndTime = self.m_iStatusEndTime + iStartStay
    self:GS2CNotifyQuestion(self:PackStatusInfo())
end

function CRandomQuestion:Start(iStartStay)
    super(CRandomQuestion).Start(self, iStartStay)
    local mNet = self:PackStatusInfo()
    self:GS2CNotifyQuestion(mNet)
end

function CRandomQuestion:End()
    self:DelTimeCb("QuestionEnd")
    local iPid
    local iTime = get_time()
    for pid, mData in pairs(self.m_mList) do
        if mData.answer and mData.time < iTime then
            iPid = pid
            iTime = mData.time
        end
    end

    if iPid then
        self:OnEnd(iPid)
    end
    local mNet = self:PackStatusInfo(nil, get_time() + 5)
    self:GS2CNotifyQuestion(mNet)
    self:ClearData()
    self:LogStatus("END")
end

function CRandomQuestion:OnEnd(iPid)
    super(CRandomQuestion).OnEnd(self)
    local oWorldMgr = global.oWorldMgr
    self:SendRewardEmail(iPid, 1009, 4)
    oWorldMgr:LoadProfile(iPid, function(obj)
        self:OnEnd1(obj)
    end)
end

function CRandomQuestion:OnEnd1(obj)
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local oNotifyMgr = global.oNotifyMgr
    local args = {
        {"&role&", obj:GetName()},
    }
    local sMsg = self:GetTextData(1001, args)
    -- oChatMgr:HandleSysChat(sMsg, nil, nil, mExclude)
    oNotifyMgr:SendPrioritySysChat("question_char",sMsg,0,{},{grade = self:OpenGrade()})
    oNotifyMgr:Notify(obj:GetPid(), sMsg)
end

function CRandomQuestion:OnAnswer(oPlayer, sMsg)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local mAnswerInfo = self.m_mList[iPid] or {}
    if mAnswerInfo.answer then
        return
    end
    local mRoleInfo ={
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        shape = oPlayer:GetModelInfo().shape,
    }
    local iOpenGrade = global.oWorldMgr:QueryControl("random_question", "open_grade")
    sMsg = string.format("{link14,1,%s}回答：%s", iOpenGrade, sMsg)
    oNotifyMgr:SendWorldChat(sMsg, mRoleInfo, {})
    local bAnswer = self.m_mAnswerPlayer[iPid]
    if not bAnswer then
        self.m_mAnswerPlayer[iPid] = true
        oPlayer:PushBookCondition("参与突击测验", {value = 1})
    end
end

function CRandomQuestion:GetAnswerRemainCD(oPlayer)
    local iNow = get_time()
    local iCDStamp = oPlayer:GetInfo("random_question_cd", 0)
    local iRemainCD = math.max(iCDStamp + 3 - iNow, 0)
    return iRemainCD
end

function CRandomQuestion:Correct(oPlayer, iAnswer)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local mAnswerInfo = self.m_mList[iPid] or {}
    if mAnswerInfo.answer then
        oNotifyMgr:Notify(iPid, "已答过该题")
        return
    end

    local sReason = "随机答题奖励"
    local mQuestion = self:GetQuestionData(self.m_iQuestion)
    local oHuodong = self:GetHuodong()
    local mReward = oHuodong:GetRewardData(mQuestion.random_reward)
    local iCoin = tonumber(mReward.coin)
    if iCoin > 0 then
        oPlayer:RewardCoin(iCoin, sReason)
    end
    local iExp = oHuodong:TransReward(oPlayer,mReward.exp, mArgs)
    if iExp and iExp > 0 then
        oPlayer:RewardExp(iExp, sReason)
    end

    local iNow = get_time()
    mAnswerInfo.answer = true
    mAnswerInfo.time = iNow
    mAnswerInfo.answer_idx = iAnswer
    self.m_mList[iPid] = mAnswerInfo
    oPlayer:SetInfo("random_question_cd", iNow)

    local mNet = {}
    mNet["id"] = self.m_iID
    mNet["type"] = self:Type()
    mNet["result"] = 1
    mNet["answer"] = iAnswer
    mNet["time"] = mAnswerInfo.time

    self:GS2CAnswerResult(mNet, iPid)
    oNotifyMgr:Notify(iPid, "回答正确，太棒了。")
    local mLog = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        idx = self.m_iID,
        qid = self.m_iQuestion,
        qtype = self:TypeName(),
        score = 0,
        coin = iCoin or 0,
        exp = iExp or 0,
    }
    record.user("question", "correct_reward", mLog)
    local iCorrect = 1
    self:LogAnswer(oPlayer,iAnswer,iCorrect)
end

function CRandomQuestion:Wrong(oPlayer, iAnswer)
    local iPid = oPlayer:GetPid()
    local iNow = get_time()
    local mAnswerInfo = self.m_mList[iPid] or {}
    mAnswerInfo.answer = mAnswerInfo.answer or false
    mAnswerInfo.time = iNow
    self.m_mList[iPid] = mAnswerInfo
    oPlayer:SetInfo("random_question_cd", iNow)

    local mNet = {}
    mNet["id"] = self.m_iID
    mNet["type"] = self:Type()
    mNet["result"] = 0
    mNet["answer"] = iAnswer
    mNet["time"] = mAnswerInfo.time

    self:GS2CAnswerResult(mNet, iPid)
    global.oNotifyMgr:Notify(iPid, "回答错误，请继续作答。")
    local iCorrect = 0
    self:LogAnswer(oPlayer,iAnswer,iCorrect)
end

function CRandomQuestion:GetOpenTimeData()
    local mData = res["daobiao"]["question_time"]
    return mData
end

function CRandomQuestion:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iOpenGrade = oWorldMgr:QueryControl("random_question", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CRandomQuestion:OpenGrade()
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("random_question", "open_grade")
    return iOpenGrade
end

function CRandomQuestion:StatusContent()
    local iStatus = self:Status()
    if iStatus == QUESTION_STATUS.READY then
        return "[44efe9]突击测验[-]即将开始哦"
    elseif iStatus ==  QUESTION_STATUS.START  then
        return "[44efe9]突击测验[-]正在进行中"
    elseif iStatus == QUESTION_STATUS.END then
        return "[44efe9]突击测验[-]已结束，我们下次再见"
    end
    return ""
end

function CRandomQuestion:GS2CNotifyQuestion(mNet)
    super(CRandomQuestion).GS2CNotifyQuestion(self, mNet)
end

function CRandomQuestion:GS2CQuestionInfo(mNet)
    local oWorldMgr = global.oWorldMgr
    local mOnline = oWorldMgr:GetOnlinePlayerList()
    for iPid, oPlayer in pairs(mOnline) do
        if self:IsOpenGrade(oPlayer) then
            oPlayer:Send("GS2CQuestionInfo", mNet)
        end
    end
end

function CRandomQuestion:GS2CAnswerResult(mNet, iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CAnswerResult", mNet)
    end
end








----------------------------学渣答题------------------------------------

CScoreQuestion = {}
CScoreQuestion.__index = CScoreQuestion
inherit(CScoreQuestion, CQuestion)

function CScoreQuestion:New(iQuestionType)
    local o = super(CScoreQuestion).New(self, iQuestionType)
    o.m_iTeamID = 0
    o.m_iCount = 20
    o.m_iStaySec = 15   --题目停留时间
    o.m_iUniqueID = 1
    o.m_iCurQuetionRank = 0
    o.m_mTeam = {}
    o.m_mScoreRank = {}
    o.m_mPlayerTeam = {}
    return o
end

function CScoreQuestion:DispatchRank()
    self.m_iCurQuetionRank = self.m_iCurQuetionRank + 1
    return self.m_iCurQuetionRank
end

function CScoreQuestion:NewHour(iWeekDay, iHour)
    if table_in_list({1,3,5,7}, iWeekDay) and iHour == 12 then
        local iTipSec = 0--1 * 60 * 60
        local iStartSec = iTipSec + 10 * 60
        local iStaySec = 15
        self:TipStart(iTipSec, iStartSec, iStaySec)
    end
end

function CScoreQuestion:OnLogin(oPlayer, bReEnter)
    local iPid = oPlayer:GetPid()
    if self:Status() == QUESTION_STATUS.READY then
        oPlayer:Send("GS2CNotifyQuestion", self:PackStatusInfo())
        local iTeam = self.m_mPlayerTeam[iPid]
        if iTeam then
            self:GS2CScoreRankInfoList(iPid, iTeam)
        end
    elseif self:Status() == QUESTION_STATUS.START then
        local iTeam = self.m_mPlayerTeam[iPid]
        if not iTeam then
            return
        end
        self:GS2CNotifyQuestion(self:PackStatusInfo())
        local mNet = self:PackQuestionInfo(self.m_iQuestionEndTime)
        oPlayer:Send("GS2CQuestionInfo", mNet)
        self:GS2CScoreRankInfoList(iPid, iTeam)
    end
end

function CScoreQuestion:ClearData()
    super(CScoreQuestion).ClearData(self)
    self.m_iTeamID = 0
    self.m_iCount = 20
    self.m_iCurQuetionRank = 0
    self.m_iUniqueID = 1
    self.m_mTeam  = {}
    self.m_mPlayerTeam = {}
end

function CScoreQuestion:TypeName()
    return "学渣答题"
end

function CScoreQuestion:DispatchTeamID()
    self.m_iTeamID = self.m_iTeamID + 1
    return self.m_iTeamID
end

function CScoreQuestion:AddRank(iPid, iRank)
    self.m_mScoreRank = self.m_mScoreRank or {}
    self.m_mScoreRank[iPid] = iRank
end

function CScoreQuestion:GetRank(iPid)
    return self.m_mScoreRank[iPid]
end

function CScoreQuestion:RemoveRank(iPid)
    self.m_mScoreRank[iPid] = nil
end

function CScoreQuestion:ClearRank()
    self.m_mScoreRank = {}
end

function CScoreQuestion:GetTeam(iTeam)
    return self.m_mTeam[iTeam]
end

function CScoreQuestion:GetTeamRank(iTeam)
    local mTeam = self:GetTeam(iTeam)
    local iRank = 0
    if mTeam then
        for iPid, mInfo in pairs(mTeam) do
            if mInfo.rank > iRank then
                iRank = mInfo.rank
            end
        end
    end
    return iRank
end

function CScoreQuestion:EnterMember(oPlayer)
    local iPid = oPlayer:GetPid()
    local iTeam = self.m_mPlayerTeam[iPid]
    if iTeam then
        record.warning(string.format("%s,has team:%s", oPlayer:GetPid(),iTeam))
        return
    end

    local iMaxTeamID = self:GetMaxTeamID()
    if iMaxTeamID then
        local mTeam = self:GetTeam(iMaxTeamID)
        if table_count(mTeam) >=  self:GetMemberLimit("score") then
            self:CreateNewTeam(oPlayer)
        else
            local iTeamRank = self:GetTeamRank(iMaxTeamID)
            local iNow = get_time()
            local mInfo = {
                pid = iPid,
                answer = false,
                success = 0,
                time = iNow,
                score = 0,
                question_idx = 0,
                rank = iTeamRank + 1,
            }
            mTeam[iPid] = mInfo
            self.m_mPlayerTeam[iPid] = iMaxTeamID
            local lPid = table_key_list(mTeam)
            self:BroadCast("GS2CScoreInfoChange", lPid, {
                id = iMaxTeamID,
                score_info = self:PackScoreInfo(mTeam, oPlayer)
                })
            -- oPlayer:SetInfo("score_question_teamid", iMaxTeamID)
            self:GS2CScoreRankInfoList(iPid, iMaxTeamID)
            self:LogEnter(oPlayer,iMaxTeamID)
        end
    else
        self:CreateNewTeam(oPlayer)
    end
    oPlayer:PushAchieve("参与学渣的逆袭次数", {value = 1})
    oPlayer:PushBookCondition("参加学渣的逆袭", {value = 1})
end

function CScoreQuestion:GetMaxTeamID()
    local lID = table_key_list(self.m_mTeam)
    if next(lID) then
        return math.max(table.unpack(lID))
    end
    return nil
end

function CScoreQuestion:CreateNewTeam(oPlayer)
    local iTeam = self:DispatchTeamID()
    local iNow = get_time()
    local iPid = oPlayer:GetPid()
    local mInfo = {
        pid = iPid,
        answer = false,
        success = 0,
        time = iNow,
        score = 0,
        question_idx = 0,
        rank = 1,
    }
    local mTeam = {}
    mTeam[iPid] = mInfo
    self.m_mTeam[iTeam] = mTeam
    self.m_mPlayerTeam[iPid] = iTeam
    self:GS2CScoreRankInfoList(iPid, iTeam)
    -- oPlayer:SetInfo("score_question_teamid", iTeam)
    self:LogEnter(oPlayer, iTeam)
end

function CScoreQuestion:OnTipStart(iTipSec, iStartSec, iStartStay)
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(1003)
    oNotifyMgr:SendPrioritySysChat("question_char",sMsg, 1, {}, {grade = self:OpenGrade()})
    if self:Status() == QUESTION_STATUS.READY then
        self:DelTimeCb("OnTipStart")
        self:AddTimeCb("OnTipStart", BROADCAST_TIPS * 1000, function()
            local oHuodong = self:GetHuodong()
            local oQuestion = oHuodong:GetQuestionObj(QUESTION_TYPE.SCORE)
            if oQuestion and oQuestion:Status() == QUESTION_STATUS.READY then
                oQuestion:OnTipStart(iTipSec, iStartSec, iStartStay)
            end
        end)
    end
end

function CScoreQuestion:TipStart(iTipSec, iStartSec, iStartStay)
    super(CScoreQuestion).TipStart(self, iTipSec, iStartSec, iStartStay)

    self.m_iEndTime = self.m_iStatusEndTime + iStartStay * self.m_iCount
    local mNet = self:PackStatusInfo("[44efe9]学渣的逆袭[-]即将开始\n要先点我提前分组哦~喵")
    self:GS2CNotifyQuestion(mNet)
    local oHuodong = self:GetHuodong()
    oHuodong:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_START)
    self:OnTipStart(iTipSec, iStartSec, iStartStay)
end

function CScoreQuestion:Start(iStartStay)
    super(CScoreQuestion).Start(self, iStartStay)
    self.m_iStatusEndTime = get_time() + iStartStay * self.m_iCount

    local mNet = self:PackStatusInfo("[44efe9]学渣的逆袭[-]正在进行中")
    self:GS2CNotifyQuestion(mNet)
    global.oWorldMgr:RecordOpen("question")
end

function CScoreQuestion:PackStartInfo(sContent)
    local mNet = {}
    mNet["type"] = self:Type()
    mNet["desc"] = sContent
    mNet["status"] = QUESTION_STATUS.START
    mNet["end_time"] = self.m_iStatusEndTime
    mNet["server_time"] = get_time()
    return mNet
end

function CScoreQuestion:PackSignInfo(iEndStamp)
    local mNet = {}
    mNet["type"] = self:Type()
    mNet["desc"] = "报名成功,活动稍后开始~喵"
    mNet["status"] = QUESTION_STATUS.READY
    mNet["end_time"] = iEndStamp
    mNet["server_time"] = get_time()
    return mNet
end

function CScoreQuestion:End()
    self:DelTimeCb("QuestionEnd")
    self.m_iCount = self.m_iCount - 1
    if self.m_iCount > 0 then
        self:InitData()
        super(CScoreQuestion).Start(self, self.m_iStaySec or 15)
    else
        self:OnEnd()
    end
end

function CScoreQuestion:InitData()
    local oWorldMgr = global.oWorldMgr
    local iNow = get_time()
    for iTeam, mData in pairs(self.m_mTeam) do
        for iPid, mInfo in pairs(mData) do
            if not mInfo.answer then
                mInfo.success = 0
            end
            mInfo.answer = false
            mInfo.time = iNow
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer:SetInfo("score_question_cd", 0)
            end
        end
    end
    self.m_iCurQuetionRank = 0
    self.m_iUniqueID = self.m_iUniqueID + 1
end

function CScoreQuestion:OnAnswer(oPlayer, sAnswer)
    local iPid = oPlayer:GetPid()
    local bAnswer = self.m_mAnswerPlayer[iPid]
    if not bAnswer then
        self.m_mAnswerPlayer[iPid] = true
    end
end

function CScoreQuestion:OnEnd()
    super(CScoreQuestion).OnEnd(self)
    local oNotifyMgr = global.oNotifyMgr
    for iTeam, mTeam in pairs(self.m_mTeam) do
        local lTeam = {}
        for iPid, mInfo in pairs(mTeam) do
            table.insert(lTeam, {
                pid = iPid,
                score = mInfo.score,
                question_idx = mInfo.question_idx,
                rank = mInfo.rank,
                })
        end
        if next(lTeam) then
            table.sort(lTeam, function(m1, m2)
                if m1.score == m2.score then
                    if m1.question_idx == m2.question_idx then
                        return m1.rank < m2.rank
                    end
                    return m1.question_idx < m2.question_idx
                end
                return m1.score > m2.score
            end)
           for iRank, mInfo in ipairs(lTeam) do
                local iPid = mInfo.pid
                self:AddRank(iPid, iRank)
                self:GS2CQuestionEndReward(iPid, iRank, {status = 0,})
           end
        end
    end
    local mNet = self:PackStatusInfo(nil, get_time() + 5)
    self:GS2CNotifyQuestion(mNet)
    self:ClearData()
    self:TrueEnd()
    local oHuodong = self:GetHuodong()
    oHuodong:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_OVER)
    self:LogStatus("END")
end

function CScoreQuestion:TrueEnd()
    for iPid, iRank in pairs(self.m_mScoreRank) do
        self:SendRewardEmail(iPid, iRank)
        self:RemoveRank(iPid, iRank)
    end
    self:ClearRank()
end

function CScoreQuestion:StatusContent()
    local iStatus = self:Status()
    if iStatus == QUESTION_STATUS.READY then
        return "[44efe9]学渣的逆袭[-]即将开始\n要先点我提前分组哦~喵"
    elseif iStatus ==  QUESTION_STATUS.START  then
        return "[44efe9]学渣的逆袭[-]正在进行中"
    elseif iStatus == QUESTION_STATUS.END then
        return "[44efe9]学渣的逆袭[-]已结束，我们下次再见"
    end
    return ""
end

function CScoreQuestion:SendRewardEmail(iPid, iRank)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local mScoreReward = self:GetScoreReward(iRank)
    if mScoreReward then
        local iMail = 5
        super(CScoreQuestion).SendRewardEmail(self, iPid, mScoreReward.reward, iMail, iRank)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        self:RemoveRank(iPid, iRank)
        self:GS2CQuestionEndReward(iPid, iRank, {status=2,})
        oNotifyMgr:Notify(iPid, "排行榜奖励已通过邮件发放")
    end
end

function CScoreQuestion:GetRankReward(iPid, iRank)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        self:SendRewardEmail(iPid, iRank)
        return
    end
    local mScoreReward = self:GetScoreReward(iRank)
    local iReward = mScoreReward and mScoreReward.reward
    if iReward then
        local oHuodong = self:GetHuodong()
        oHuodong:Reward(iPid, iReward, mArgs)
        self:RemoveRank(iPid, iRank)
        self:GS2CQuestionEndReward(iPid, iRank, {status=1,})

        local mLog = {
            pid = iPid,
            rank = iRank,
            reward = iReward,
            qtype = self:TypeName(),
            reason = "领取学渣答题排名奖励",
        }
        record.user("question", "get_score_reward", mLog)
        oHuodong:LogAnalyGame("score_question",oPlayer)
    end
end

function CScoreQuestion:GetScoreReward(iRank)
    local mScoreReward = res["daobiao"]["score_question_reward"]
    for _, mData in pairs(mScoreReward) do
        if iRank >= mData.upper_rank and iRank <= mData.lower_rank then
            return mData
        end
    end
end

function CScoreQuestion:GetAnswerRemainCD(oPlayer)
    local iNow = get_time()
    local iCDStamp = oPlayer:GetInfo("score_question_cd", 0)
    local iRemainCD = math.max(iCDStamp + 3 - iNow, 0)
    return iRemainCD
end

function CScoreQuestion:Wrong(oPlayer, iAnswer)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    -- local iTeam = oPlayer:GetInfo("score_question_teamid")
    local iTeam = self.m_mPlayerTeam[iPid]
    if not iTeam then
        oNotifyMgr:Notify(iPid, "此次准备时间已结束,请留意活动开启时间")
        return
    end
    local mTeam = self:GetTeam(iTeam)
    if not mTeam then
        return
    end
    local mInfo = mTeam[iPid]
    if not mInfo then
        return
    end
    if mInfo.answer then
        oNotifyMgr:Notify(iPid, "已答过该题")
        return
    end
    local iNow = get_time()
    mInfo.success = 0
    mInfo.time = iNow
    mInfo.answer = false
    oPlayer:SetInfo("score_question_cd", iNow)

    local mRole = {}
    mRole["pid"] = iPid
    mRole["name"] = oPlayer:GetName()
    mRole["grade"] = oPlayer:GetGrade()
    mRole["model_info"] = oPlayer:GetModelInfo()
    local mNet = {}
    mNet["id"] = self.m_iID
    mNet["type"] = self:Type()
    mNet["result"] = 0
    mNet["answer"] = iAnswer
    mNet["time"] = mInfo.time
    mNet["role"] = mRole
    self:GS2CAnswerResult(mNet, iTeam)

    local iCorrect = 0
    self:LogAnswer(oPlayer,iAnswer,iCorrect)
end

function CScoreQuestion:Correct(oPlayer, iAnswer)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    -- local iTeam = oPlayer:GetInfo("score_question_teamid")
    local iTeam = self.m_mPlayerTeam[iPid]
    if not iTeam then
        oNotifyMgr:Notify(iPid, "准备时间已结束,请留意活动开启时间")
        return
    end
    local mTeam = self:GetTeam(iTeam)
    if not mTeam then
        return
    end
    local mInfo = mTeam[iPid]
    if not mInfo then
        return
    end
    if mInfo.answer then
        oNotifyMgr:Notify(iPid, "已答过该题")
        return
    end

    local iNow = get_time()
    mInfo.success = mInfo.success + 1
    mInfo.time = iNow
    mInfo.answer = true
    mInfo.question_idx = self.m_iUniqueID
    mInfo.rank = self:DispatchRank()
    mInfo.score = mInfo.score + self:CalScore(mTeam, iPid)

    local mReward = self:CalReward(mTeam, oPlayer)
    local sReason = "积分答题奖励"
    if mReward.coin > 0 then
        oPlayer:RewardCoin(mReward.coin, sReason)
    end
    if mReward.exp and mReward.exp > 0 then
        oPlayer:RewardExp(mReward.exp, sReason)
    end
    oPlayer:SetInfo("score_question_cd", iNow)

    local lPid = table_key_list(mTeam)
    self:BroadCast("GS2CScoreInfoChange", lPid,{
        id = iTeam,
        score_info = self:PackScoreInfo(mTeam, oPlayer)
        })
    local mRole = {}
    mRole["pid"] = iPid
    mRole["name"] = oPlayer:GetName()
    mRole["grade"] = oPlayer:GetGrade()
    mRole["model_info"] = oPlayer:GetModelInfo()
    local mNet = {}
    mNet["id"] = self.m_iID
    mNet["type"] = self:Type()
    mNet["result"] = 1
    mNet["answer"] = iAnswer
    mNet["time"] = mInfo.time
    mNet["reward"] = mReward.coin
    mNet["extra_info"] = mReward.extra
    mNet["role"] = mRole

    self:GS2CAnswerResult(mNet, iTeam)

    local mLog = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        idx = self.m_iID,
        qid = self.m_iQuestion,
        qtype = self:TypeName(),
        score = mInfo.score,
        coin = mReward.coin,
        exp = mReward.exp,
    }
    record.user("question", "correct_reward", mLog)
    local iCorrect = 1
    self:LogAnswer(oPlayer,iAnswer,iCorrect)
end

function CScoreQuestion:CalScore(mTeam, iPid)
    local mInfo = mTeam[iPid]
    local iScore = 100
    if mInfo.time - self.m_iTime <= 5 then
        iScore = iScore + 50
    end
    local iRank = mInfo.rank
    -- for p, m in pairs(mTeam) do
    --     if p ~= iPid and m.answer then
    --         iRank = iRank + 1
    --     end
    -- end

    if iRank <= 10 then
        iScore = iScore + (100 - (iRank - 1) * 10)
    end
    return iScore
end

function CScoreQuestion:CalReward(mTeam, oPlayer)
    local iPid = oPlayer:GetPid()
    local mInfo = mTeam[iPid]
    local mData = self:GetQuestionData(self.m_iQuestion)
    local iReward = mData.score_reward
    local oHuodong = self:GetHuodong()
    local mReward = oHuodong:GetRewardData(iReward)
    local mExtra = {}
    local iCoin = 0
    local mRet = {
        exp = oHuodong:TransReward(oPlayer,mReward.exp)
    }
    if mInfo.rank == 1 then
        mExtra.first = 1
        mExtra.reward = 200
        iCoin = tonumber(mReward.coin) * 3
    end
    local iSuccess = mInfo.success - 1
    if iSuccess > 0 then
        mExtra.right = mInfo.success
        mExtra.reward = math.max(mExtra.reward or 0, iSuccess * 2.5)
    end
    iCoin = math.max(iCoin, math.floor(mReward.coin * (100 + iSuccess * 2.5) / 100))
    mRet.coin = iCoin
    local sExtra = "{"
    for iKey, iVal in pairs(mExtra) do
        sExtra = sExtra .. string.format("%s=%s,",iKey,iVal)
    end
    sExtra = sExtra .. "}"
    mRet.extra = sExtra
    return mRet
end

function CScoreQuestion:GetOpenTimeData()
    local mData = res["daobiao"]["question_time"]
    return mData
end

function CScoreQuestion:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iOpenGrade = oWorldMgr:QueryControl("score_question", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CScoreQuestion:PackScoreInfo(mTeam, oPlayer)
    local mRet = {}
    local iPid = oPlayer:GetPid()
    local mInfo = mTeam[iPid]
    if mInfo then
        mRet["pid"] = iPid
        mRet["name"] = oPlayer:GetName()
        mRet["score"] = mInfo.score
        mRet["question_idx"] = mInfo.question_idx
        mRet["rank"] = mInfo.rank
        mRet["model_info"] = oPlayer:GetModelInfo()
    end

    return mRet
end

function CScoreQuestion:GS2CScoreInfoChange(oPlayer)
    local iPid = oPlayer:GetPid()
    local iTeam = self.m_mPlayerTeam[iPid]
    if iTeam then
        local mTeam = self:GetTeam(iTeam)
        if not mTeam then
            return
        end
        local mInfo = mTeam[iPid]
        if not mInfo then
            return
        end
        local mScoreInfo = self:PackScoreInfo(mTeam, oPlayer)
        oPlayer:Send("GS2CScoreInfoChange",{
            id = iTeam,
            score_info = mScoreInfo,
            })
    end
end

function CScoreQuestion:GS2CScoreRankInfoList(iPid, iTeam)
    local oWorldMgr = global.oWorldMgr
    local mTeam = self:GetTeam(iTeam)
    if mTeam then
        local iCount = table_count(mTeam)
        if iCount < 1 then
            oPlayer:Send("GS2CScoreRankInfoList", {type = self:Type()})
            return
        end
        local lPack = {}
        local idx = 1
        for iTarget, mInfo in pairs(mTeam) do
            oWorldMgr:LoadProfile(iTarget, function(obj)
                self:GS2CScoreRankInfoList1(iPid, idx, iCount, iTeam, lPack, obj, mInfo)
            end)
            idx = idx + 1
        end
    end
end

function CScoreQuestion:GS2CScoreRankInfoList1(iPid, idx, iCount, iTeam, lPack, obj, mInfo)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local mData = {
        pid = obj:GetPid(),
        name = obj:GetName(),
        score = mInfo.score,
        question_idx = mInfo.question_idx,
        rank = mInfo.rank,
        model_info = obj:GetModelInfo(),
    }
    lPack[idx] = mData
    if table_count(lPack) == iCount then
        oPlayer:Send("GS2CScoreRankInfoList", {
            id = iTeam,
            score_list = lPack,
            type = self:Type(),
            })
    end
end

function CScoreQuestion:GS2CNotifyQuestion(mNet)
    if self:Status() == QUESTION_STATUS.READY then
        super(CScoreQuestion).GS2CNotifyQuestion(self, mNet)
    else
        local oWorldMgr = global.oWorldMgr
        for iTeam, mTeam in pairs(self.m_mTeam) do
            for iPid, mInfo in pairs(mTeam) do
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    oPlayer:Send("GS2CNotifyQuestion", mNet)
                end
            end
        end
    end
end

function CScoreQuestion:GS2CQuestionInfo(mNet)
    local oWorldMgr = global.oWorldMgr
    for iTeam, mTeam in pairs(self.m_mTeam) do
        for iPid, mInfo in pairs(mTeam) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer:Send("GS2CQuestionInfo", mNet)
            end
        end
    end
end

function CScoreQuestion:GS2CAnswerResult(mNet, iTeam)
    local oWorldMgr = global.oWorldMgr
    local mTeam = self:GetTeam(iTeam)
    if not mTeam then
        return
    end
    for iPid, mInfo in pairs(mTeam) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send("GS2CAnswerResult", mNet)
        end
    end
end

function CScoreQuestion:GS2CQuestionEndReward(iPid,iRank,mData)
    local mScoreReward = self:GetScoreReward(iRank)
    if mScoreReward then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send("GS2CQuestionEndReward", mData)
        end
    end
end

function CScoreQuestion:LogEnter(oPlayer, iTeam)
    local mLog = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        teamid = iTeam or 0,
        qtype = "学渣答题",
    }
    record.user("question", "enter_member", mLog)
end







------------------------学霸答题-----------------------------------
CSceneQuestion = {}
CSceneQuestion.__index = CSceneQuestion
inherit(CSceneQuestion, CQuestion)

function CSceneQuestion:New(iQuestionType)
    local o = super(CSceneQuestion).New(self, iQuestionType)
    o.m_iCount = 20
    o.m_iStaySec = 10   --题目停留时间
    o.m_iUniqueID = 1
    o.m_iCurQuetionRank = 0
    -- o.m_iRank = 0
    o.m_mScene = {}
    o.m_mPlayerScene = {}
    return o
end


function CSceneQuestion:AddSchedule(oPlayer)
end

function CSceneQuestion:NewHour(iWeekDay, iHour)
    if table_in_list({2,4,6}, iWeekDay) and iHour == 12 then
        local iTipSec = 0--1 * 60 * 60
        local iStartSec = iTipSec + 10 * 60
        local iStaySec = 10
        self:TipStart(iTipSec, iStartSec, iStaySec)
    end
end

function CSceneQuestion:OnLogin(oPlayer, bReEnter)
    local iPid =oPlayer:GetPid()
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oNowScene.m_sType == "question"  then
        if self:Status() == QUESTION_STATUS.END then
            local oHuodong = self:GetHuodong()
            oHuodong:GobackRealScene(oPlayer:GetPid())
            self:RefreshScene(oPlayer)
        end
    end
    if self:Status() == QUESTION_STATUS.READY then
        oPlayer:Send("GS2CNotifyQuestion", self:PackStatusInfo())
        local iScene = self.m_mPlayerScene[iPid]
        if not iScene then
            return
        end
        local iStatus = 0
        if oNowScene:GetSceneId() == iScene then
            iStatus = 1
        end
        oPlayer:Send("GS2CQtionSceneStatus", {status = iStatus})
        self:GS2CScoreRankInfoList(iPid, iScene)
    elseif self:Status() ~= QUESTION_STATUS.END then
        local iScene = self.m_mPlayerScene[iPid]
        if not iScene then
            return
        end
        local iStatus = 0
        if oNowScene:GetSceneId() == iScene then
            iStatus = 1
        end
        oPlayer:Send("GS2CNotifyQuestion", self:PackStatusInfo(nil, self.m_iEndTime))
        oPlayer:Send("GS2CQtionSceneStatus", {status = iStatus})
        oPlayer:Send("GS2CQuestionInfo", self:PackQuestionInfo(self.m_iQuestionEndTime))
        self:GS2CScoreRankInfoList(iPid, iScene)
    end
end

function CSceneQuestion:ClearData()
    super(CSceneQuestion).ClearData(self)
    self.m_iCount = 20
    -- self.m_iRank = 0
    self.m_iCurQuetionRank = 0
    self.m_iUniqueID = 1
    self.m_mScene  = {}
    self.m_mPlayerScene = {}
end

function CSceneQuestion:DispatchRank()
    self.m_iCurQuetionRank = self.m_iCurQuetionRank or 0
    self.m_iCurQuetionRank = self.m_iCurQuetionRank + 1
    return self.m_iCurQuetionRank
end

function CSceneQuestion:InitPool()
    local mData = res["daobiao"]["scene_question"]
    self.m_mIDPool = table_key_list(mData)
end

function CSceneQuestion:GetQuestionData(iQuestion)
    local mData = res["daobiao"]["scene_question"][iQuestion]
    assert(mData, string.format("CSceneQuestion:GetQuestionData, id:%s", iQuestion))
    return mData
end

function CSceneQuestion:InitData()
    local iNow = get_time()
    for iScene, mScene in pairs(self.m_mScene) do
        for iPid, mInfo in pairs(mScene) do
            if not mInfo.answer then
                mInfo.success = 0
            end
            mInfo.answer = false
            mInfo.time = iNow
        end
    end
    -- self.m_iRank = 0
    self.m_iUniqueID = self.m_iUniqueID + 1
end

function CSceneQuestion:TypeName()
    return "学霸答题"
end

function CSceneQuestion:OnTipStart(iTipSec, iStartSec, iStartStay)
    local oNotifyMgr = global.oNotifyMgr
    local sMsg = self:GetTextData(1002)
    oNotifyMgr:SendPrioritySysChat("question_char",sMsg, 1, {}, {grade = self:OpenGrade()})
    if self:Status() == QUESTION_STATUS.READY then
        self:DelTimeCb("OnTipStart")
        self:AddTimeCb("OnTipStart", BROADCAST_TIPS * 1000, function()
            local oHuodong = self:GetHuodong()
            local oQuestion = oHuodong:GetQuestionObj(QUESTION_TYPE.SCENE)
            if oQuestion and oQuestion:Status() == QUESTION_STATUS.READY then
                oQuestion:OnTipStart(iTipSec, iStartSec, iStartStay)
            end
        end)
    end
end

function CSceneQuestion:TipStart(iTipSec, iStartSec, iStartStay)
    super(CSceneQuestion).TipStart(self, iTipSec, iStartSec, iStartStay)
    self.m_iEndTime = get_time() + iStartStay * self.m_iCount + (self.m_iCount - 1) * 5 + iStartSec
    self:GS2CNotifyQuestion(self:PackStatusInfo())
    local oHuodong = self:GetHuodong()
    oHuodong:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_START)
    self:OnTipStart(iTipSec, iStartSec, iStartStay)
end

function CSceneQuestion:Start(iStartStay)
    super(CSceneQuestion).Start(self, iStartStay)
    self.m_iStatusEndTime = get_time() + iStartStay
    self:GS2CNotifyQuestion(self:PackStatusInfo(nil, self.m_iEndTime))
    global.oWorldMgr:RecordOpen("question2")
end

function CSceneQuestion:End()
    self:DelTimeCb("QuestionEnd")
    self.m_iCount = self.m_iCount - 1
    self:End1()
    if self.m_iCount > 0 then
        self:WaitNext()
        self:DelTimeCb("NextQuestion")
        self:AddTimeCb("NextQuestion", 5 * 1000, function()
            local oHuodong = self:GetHuodong()
            local oQuestion = oHuodong:GetQuestionObj(QUESTION_TYPE.SCENE)
            if oQuestion then
                oQuestion:NextQuestion()
            end
        end)
    else
        self:DelTimeCb("TrueEnd")
        self:AddTimeCb("TrueEnd", 10 * 1000, function()
            self:TrueEnd()
        end)
        self:OnEnd()
    end
end

function CSceneQuestion:WaitNext()
    local iNow = get_time()
    self.m_iStatusEndTime = iNow + 5
    self.m_iStatus = QUESTION_STATUS.WAIT
    local mNet = self:PackStatusInfo(nil, self.m_iEndTime)
    self:GS2CNotifyQuestion(mNet)
end

function CSceneQuestion:End1()
    local oWorldMgr = global.oWorldMgr
    for iScene, mScene in pairs(self.m_mScene) do
        for iPid, mInfo in pairs(mScene) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
                if oScene:GetSceneId() == iScene then
                    self:CheckAnswer(oPlayer, iScene)
                end
            end
        end
    end
    for iScene, mScene in pairs(self.m_mScene) do
        for iPid, mInfo in pairs(mScene) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
                if oScene:GetSceneId() == iScene then
                    self:GS2CScoreRankInfoList(iPid, iScene)
                    self:GS2CSceneAnswerList(oPlayer, iScene)
                end
            end
        end
    end
end

function CSceneQuestion:NextQuestion()
    self:InitData()
    self:Start(self.m_iStaySec or 10)
    -- super(CSceneQuestion).Start(self, self.m_iStaySec or 25)
end

function CSceneQuestion:OnEnd()
    super(CSceneQuestion).OnEnd(self)
    self.m_iStatus = QUESTION_STATUS.END
    self:GS2CNotifyQuestion(self:PackStatusInfo(nil, get_time() + 5))
    self:SendRankReward()

    local oHuodong = self:GetHuodong()
    oHuodong:SetHuodongState(gamedefines.SCHEDULE_TYPE.GAME_OVER)
    self:LogStatus("END")
end

function CSceneQuestion:TrueEnd()
    local oWorldMgr = global.oWorldMgr
    local oHuodong = self:GetHuodong()
    for iScene, mScene in pairs(self.m_mScene) do
        for iPid, mInfo in pairs(mScene) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer.m_SceneQtFly = true
                local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
                if oScene:GetSceneId() == iScene then
                    oHuodong:GobackRealScene(iPid)
                end
            end
        end
        oHuodong:RemoveSceneById(iScene)
    end
    self:ClearData()
end

function CSceneQuestion:CheckAnswer(oPlayer, iScene)
    local oScene = self:SceneObject(iScene)
    local iMapId = oScene:MapId()
    local oHuodong = self:GetHuodong()
    oPlayer:AddSchedule("question2")
    oPlayer:RecordPlayCnt("question2",1)
    if oHuodong then
        local mPos = oPlayer.m_oActiveCtrl:GetNowPos()
        local sAnswer = self.m_mAnswer[1]
        local mQData = self:GetQuestionData(self.m_iQuestion)
        local mSData = oHuodong:GetSceneData(oScene.m_iIdx)
        if sAnswer == mQData.answer[1] then
            if mPos.x <= mSData.scope.left then
                self:Correct(oPlayer, 1, iScene)
            else
                self:Wrong(oPlayer, 1, iScene)
            end
        else
            if mPos.x >= mSData.scope.right then
                self:Correct(oPlayer, 2, iScene)
            else
                self:Wrong(oPlayer, 2, iScene)
            end
        end
    end
end

function CSceneQuestion:Correct(oPlayer, iAnswer, iScene)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local iNow = get_time()
    local mScene = self:GetScene(iScene)
    local mInfo = mScene[iPid] or {}
    mInfo.success = mInfo.success + 1
    mInfo.time = iNow
    mInfo.answer = true
    mInfo.question_idx = self.m_iUniqueID
    mInfo.rank = self:DispatchRank()
    mInfo.score = mInfo.score + self:CalScore(mScene, iPid)
    local mReward = self:CalReward(mScene, oPlayer)
    local sReason = "学霸答题奖励"
    if mReward.coin > 0 then
        oPlayer:RewardCoin(mReward.coin, sReason)
    end
    if mReward.exp and mReward.exp > 0 then
        oPlayer:RewardExp(mReward.exp, sReason)
    end
    mInfo.reward = mReward

    local mLog = {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        idx = self.m_iID,
        qid = self.m_iQuestion,
        qtype = self:TypeName(),
        score = mInfo.score,
        coin = mReward.coin,
        exp = mReward.exp,
    }
    record.user("question", "correct_reward", mLog)
    local iCorrect = 1
    self:LogAnswer(oPlayer,iAnswer,iCorrect)
end

function CSceneQuestion:CalScore(mScene, iPid)
    local iScore = 100
    local mInfo = mScene[iPid]
    local iSuccess = mInfo.success - 1
    if iSuccess > 0 then
        iScore = math.ceil(iScore * (1 + 0.05 * iSuccess))
    end
    return iScore
end

function CSceneQuestion:CalReward(mScene, oPlayer)
    local iPid = oPlayer:GetPid()
    local mInfo = mScene[iPid]
    local mData = self:GetQuestionData(self.m_iQuestion)
    local iReward = mData.reward
    local oHuodong = self:GetHuodong()
    local mReward = oHuodong:GetRewardData(iReward)
    local mExtra = {}
    local mRet = {
        exp = oHuodong:TransReward(oPlayer,mReward.exp)
    }
    local iSuccess = mInfo.success - 1
    if iSuccess > 0 then
        mExtra.right = mInfo.success
        mExtra.reward = math.max(mExtra.reward or 0, iSuccess * 2.5)
    end
    mRet.coin = math.floor(mReward.coin * (100 + iSuccess * 2.5) / 100)
    local sExtra = "{"
    for iKey, iVal in pairs(mExtra) do
        sExtra = sExtra .. string.format("%s=%s,",iKey,iVal)
    end
    sExtra = sExtra .. "}"
    mRet.extra = sExtra
    return mRet
end

function CSceneQuestion:Wrong(oPlayer, iAnswer, iScene)
    local iPid =oPlayer:GetPid()
    local mScene = self:GetScene(iScene)
    local mInfo = mScene[iPid]
    mInfo.success = 0
    mInfo.time = get_time()
    mInfo.answer = false
    mInfo.reward = {}
    mScene[iPid] = mInfo

    local iCorrect = 0
    self:LogAnswer(oPlayer,iAnswer,iCorrect)
end

function CSceneQuestion:SendRankReward()
    local oNotifyMgr = global.oNotifyMgr
    for iTeam, mScene in pairs(self.m_mScene) do
        local l = {}
        for iPid, mInfo in pairs(mScene) do
            table.insert(l, {
                pid = iPid,
                score = mInfo.score,
                question_idx = mInfo.question_idx,
                rank = mInfo.rank,
                })
        end
        if next(l) then
            table.sort(l, function(m1, m2)
                if m1.score == m2.score then
                    if m1.question_idx == m2.question_idx then
                        return m1.rank < m2.rank
                    end
                    return m1.question_idx < m2.question_idx
                end
                return m1.score > m2.score
            end)
            local iScore
            local iRank = 1
           for idx, mInfo in ipairs(l) do
                local iPid = mInfo.pid
                -- iScore = iScore or mInfo.score
                -- if iScore ~= mInfo.score then
                --     iRank = iRank + 1
                -- end
                self:SendRewardEmail(iPid, idx)
           end
        end
    end
end

function CSceneQuestion:SendRewardEmail(iPid, iRank)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local mScoreReward = self:GetScoreReward(iRank)
    if mScoreReward then
        local iMail = 59
        super(CSceneQuestion).SendRewardEmail(self, iPid, mScoreReward.reward, iMail, iRank)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oNotifyMgr:Notify(iPid, "排行榜奖励已通过邮件发放")
    end
end

function CSceneQuestion:GetScoreReward(iRank)
    local mScoreReward = res["daobiao"]["scene_question_reward"]
    for _, mData in pairs(mScoreReward) do
        if iRank >= mData.upper_rank and iRank <= mData.lower_rank then
            return mData
        end
    end
end

function CSceneQuestion:StatusContent()
    local iStatus = self:Status()
    if iStatus == QUESTION_STATUS.READY then
        return "[44efe9]学霸去哪儿[-]即将开始\n要先点我进行报名哦~喵"
    elseif iStatus == QUESTION_STATUS.START then
        return "[44efe9]学霸去哪儿[-]正在进行中"
    elseif iStatus == QUESTION_STATUS.END then
        return "[44efe9]学霸去哪儿[-]已结束，我们下次再见"
    elseif iStatus == QUESTION_STATUS.WAIT then
        return "[44efe9]学霸去哪儿[-]正在进行中"
    end
    return ""
end

function CSceneQuestion:GetScene(iScene)
    return self.m_mScene[iScene]
end


function CSceneQuestion:NewMemInfo(iPid, iScene)
    local iRank = self:DispatchRank()
    return {
        pid = iPid,
        answer = false,
        success = 0,
        time = get_time(),
        score = 0,
        question_idx = 0,
        rank = iRank + 1,
    }
end

function CSceneQuestion:GetMinMemScene()
    local iScene
    local iMinCount = self:GetMemberLimit("scene")
    for is, mScene in pairs(self.m_mScene) do
        local iCount = table_count(mScene)
        if iMinCount > iCount then
            iMinCount = iCount
            iScene = is
        end
    end
    return iScene
end

function CSceneQuestion:AddMember(oPlayer)
    local iPid = oPlayer:GetPid()
    local iScene= self.m_mPlayerScene[iPid]
    if iScene then
        record.info(string.format("%s,repeated apply:%s", oPlayer:GetPid(),iScene))
        return
    end
    local iScene = self:GetMinMemScene()
    if not iScene then
        iScene = self:CreateNewScene(oPlayer)
    end
    if iScene then
        local mInfo = self:NewMemInfo(iPid, iScene)
        local mScene = self:GetScene(iScene)
        mScene[iPid] = mInfo
        self.m_mScene[iScene] = mScene
        self.m_mPlayerScene[iPid] = iScene
        self:GS2CScoreRankInfoList(iPid, iScene)
        -- local lPid = table_key_list(mScene)
        -- if #lPid > 0 then
        --     self:BroadCast("GS2CScoreRankInfoList", lPid, self:PackScoreRankInfoList(iScene))
        -- end
        oPlayer:PushAchieve("参与学霸去哪儿次数", {value = 1})
    end
end

function CSceneQuestion:ValidEnterQtionScene(oPlayer)
    local iPid = oPlayer:GetPid()
    local iScene = self.m_mPlayerScene[iPid]
    if not iScene then
        oPlayer:NotifyMessage("未报名")
        return false
    end
    local mScene = self:GetScene(iScene)
    if not mScene then
        oPlayer:NotifyMessage("场景不存在")
        return false
    end
    if not oPlayer:IsSingle() then
        oPlayer:NotifyMessage("请先退出队伍")
        return false
    end
    if oPlayer:GetNowWar() then
        oPlayer:NotifyMessage("请先退出战斗")
        return false
    end

    local oHuodong = self:GetHuodong()
    if not oHuodong then
        oPlayer:NotifyMessage("活动已关闭")
        record.info("ValidEnterQtionScene, pid:%s huodong not exsit.", iPid)
        return false
    end

    if not self:IsOpenGrade(oPlayer) then
        oPlayer:NotifyMessage("未达开放等级")
        record.info("ValidEnterQtionScene, pid:%s not open grade", iPid)
        return false
    end

    return true
end

function CSceneQuestion:EnterQtionScene(oPlayer)
    if not self:ValidEnterQtionScene(oPlayer) then
        return
    end
    local iPid = oPlayer:GetPid()
    local iScene = self.m_mPlayerScene[iPid]
    local oScene = self:SceneObject(iScene)
    local oHuodong = self:GetHuodong()
    local mData = oHuodong:GetSceneData(oScene.m_iIdx)
    local mPos = mData["midscope"]
    oHuodong:TransferPlayerBySceneID(oPlayer:GetPid(),iScene
        ,mPos["x"],mPos["y"])
end

function CSceneQuestion:OnEnter(iPid)
    local iScene = self.m_mPlayerScene[iPid]
    if not iScene then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
        if oScene:GetSceneId() == iScene then
            oPlayer:Send("GS2CQtionSceneStatus", {status = 1})
            self:RefreshScene(oPlayer)
        end
    end
end

function CSceneQuestion:RefreshScene(oPlayer)
    local iPid = oPlayer:GetPid()
    local iScene = self.m_mPlayerScene[iPid]
    local mScene = self:GetScene(iScene)
    if mScene then
        local mNet = self:PackStatusInfo()
        self:GS2CScoreRankInfoList(iPid, iScene)
        if self:Status() == QUESTION_STATUS.START then
            oPlayer:Send("GS2CQuestionInfo", self:PackQuestionInfo(self.m_iQuestionEndTime))
        end
    end
end

function CSceneQuestion:SceneObject(iScene)
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(iScene)
    return oScene
end

function CSceneQuestion:LeaveQtionScene(oPlayer)
    local iPid = oPlayer:GetPid()
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iScene = self.m_mPlayerScene[iPid]
    if not iScene then
        return
    end
    if iScene ~= oScene:GetSceneId() then
        return
    end
    oPlayer.m_SceneQtFly = true
    local oHuodong = self:GetHuodong()
    oHuodong:GobackRealScene(iPid)

    local mNet
    if self:Status() == QUESTION_STATUS.READY then
        mNet = self:PackStatusInfo()
    elseif self:Status() ~= QUESTION_STATUS.END then
        mNet = self:PackStatusInfo(nil, self.m_iEndTime)
    end
    if mNet then
        oPlayer:Send("GS2CNotifyQuestion", mNet)
    end
end

function CSceneQuestion:OnLeaveScene(oPlayer)
    oPlayer:Send("GS2CQtionSceneStatus", {status = 0})
end

function CSceneQuestion:OnRemoteEvent(oPlayer)
    local oHuodong = global.oHuodongMgr:GetHuodong("question")
    local obj = oHuodong:GetQuestionObj(QUESTION_TYPE.SCENE)
    if obj then
        local iPid = oPlayer:GetPid()
        obj:OnEnter(iPid)
    end
end

function CSceneQuestion:VaildLeaveScene(oPlayer, oScene)
    if oPlayer.m_SceneQtFly then
        oPlayer.m_SceneQtFly = nil
        return true
    end
    oPlayer:NotifyMessage("场景禁止传送")
    return false
end

function CSceneQuestion:RandSceneIdx()
    local res = require "base.res"
    local oHuodong = self:GetHuodong()
    local mData = res["daobiao"]["huodong"][oHuodong.m_sName]["scene"]
    return table_random_key(mData)
end

function CSceneQuestion:CreateNewScene(oPlayer)
    local oHuodong = self:GetHuodong()
    if oHuodong then
        local idx = self:RandSceneIdx()
        local oScene = oHuodong:CreateVirtualScene(idx)
        local iScene = oScene:GetSceneId()
        self.m_mScene[iScene] = {}
        oScene.m_OnLeave = self.OnLeaveScene
        oScene.m_OnRemoteEvent = {self.OnRemoteEvent}
        oScene.m_fVaildLeave = self.VaildLeaveScene
        oScene.m_NoTransfer = 1
        oScene.m_sType = "question"
        oScene:SetLimitRule("team",1)
        oScene:SetLimitRule("transfer",1)
        oScene:SetLimitRule("war", 1)
        return iScene
    end
end

function CSceneQuestion:OnQuestion(oPlayer)
    local iScene = self.m_mPlayerScene[oPlayer:GetPid()]
    if iScene and self:Status() ~= QUESTION_STATUS.END then
        return true
    end
    return false
end

function CSceneQuestion:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iOpenGrade = oWorldMgr:QueryControl("scene_question", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CSceneQuestion:PackScoreInfo(mScene, oPlayer)
    local mRet = {}
    local iPid = oPlayer:GetPid()
    local mInfo = mScene[iPid]
    if mInfo then
        mRet["pid"] = iPid
        mRet["name"] = oPlayer:GetName()
        mRet["score"] = mInfo.score
        mRet["question_idx"] = mInfo.question_idx
        mRet["rank"] = mInfo.rank
        mRet["model_info"] = oPlayer:GetModelInfo()
    end
    return mRet
end

function CSceneQuestion:PackQuestionInfo(iEndStamp)
    local mQuestion = self:GetQuestionData(self.m_iQuestion)
    local mNet = {}
    mNet["id"] = self.m_iID
    mNet["type"] = self:Type()
    mNet["desc"] = mQuestion.question
    local lAnswer = {}
    for id, sAnswer in ipairs(self.m_mAnswer) do
        table.insert(lAnswer, sAnswer)
    end
    mNet["answer_list"] = lAnswer
    mNet["end_time"] = iEndStamp
    mNet["server_time"] = get_time()
    self.m_iQuestionEndTime = iEndStamp
    return mNet
end

function CSceneQuestion:PackScoreRankInfoList(iScene)
    local mScene =self:GetScene(iScene)
    if mScene then
        local oWorldMgr = global.oWorldMgr
        local lPack = {}
        for iPid, mInfo in pairs(mScene) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                local m = {
                    pid = oPlayer:GetPid(),
                    name = oPlayer:GetName(),
                    score = mInfo.score,
                    question_idx = mInfo.question_idx,
                    rank = mInfo.rank,
                    model_info = oPlayer:GetModelInfo(),
                }
                table.insert(lPack, m)
            end
        end
        return {
            id = iScene,
            score_list = lPack,
            type = self:Type(),
        }
    end
end

function CSceneQuestion:GS2CScoreRankInfoList(iPid, iScene)
    local oWorldMgr = global.oWorldMgr
    local mScene = self:GetScene(iScene)
    if mScene then
        local iCount = table_count(mScene)
        if iCount < 1 then
            oPlayer:Send("GS2CScoreRankInfoList", {type = self:Type()})
            return
        end
        local lPack = {}
        local idx = 1
        for iTarget, mInfo in pairs(mScene) do
            oWorldMgr:LoadProfile(iTarget, function(obj)
                self:GS2CScoreRankInfoList1(iPid, idx, iCount, iScene, lPack, obj, mInfo)
            end)
            idx = idx + 1
        end
    end
end

function CSceneQuestion:GS2CScoreRankInfoList1(iPid, idx, iCount, iScene, lPack, obj, mInfo)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local mData = {
        pid = obj:GetPid(),
        name = obj:GetName(),
        score = mInfo.score,
        question_idx = mInfo.question_idx,
        rank = mInfo.rank,
        model_info = obj:GetModelInfo(),
    }
    lPack[idx] = mData
    if table_count(lPack) == iCount then
        oPlayer:Send("GS2CScoreRankInfoList", {
            id = iScene,
            score_list = lPack,
            type = self:Type(),
            })
    end
end

function CSceneQuestion:GS2CNotifyQuestion(mNet)
    if self:Status() == QUESTION_STATUS.READY then
        super(CSceneQuestion).GS2CNotifyQuestion(self, mNet)
    else
        local oWorldMgr = global.oWorldMgr
        for iScene, mScene in pairs(self.m_mScene) do
            for iPid, mInfo in pairs(mScene) do
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    oPlayer:Send("GS2CNotifyQuestion", mNet)
                end
            end
        end
    end
end

function CSceneQuestion:GS2CQuestionInfo(mNet)
    local oWorldMgr = global.oWorldMgr
    for iScene, mScene in pairs(self.m_mScene) do
        for iPid, mInfo in pairs(mScene) do
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
                if oScene:GetSceneId() == iScene then
                    oPlayer:Send("GS2CQuestionInfo", mNet)
                end
            end
        end
    end
end

function CSceneQuestion:GS2CSceneAnswerList(oPlayer, iScene)
    local oWorldMgr = global.oWorldMgr
    local mScene = self:GetScene(iScene)
    if not mScene then
        return
    end
    local l = {}
    for iPid, mInfo in pairs(mScene) do
        local m = {}
        m.pid = iPid
        m.score = mInfo.score
        local mRwd = mInfo.reward or {}
        m.reward = mRwd.coin
        m.extra_info = mRwd.extra
        if mInfo.answer then
            m.result = 1
        end
        table.insert(l, m)
        -- mInfo.reward = {}
    end
    oPlayer:Send("GS2CSceneAnswerList", {results = l})
end

function CSceneQuestion:GS2CQuestionEndReward(iPid,iRank,mData)
    local mScoreReward = self:GetScoreReward(iRank)
    if mScoreReward then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send("GS2CQuestionEndReward", mData)
        end
    end
end