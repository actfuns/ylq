--import module
local skynet = require "skynet"
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"


local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "奖励找回"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_OpenRecord = {}
    return o
end

function CHuodong:Save()
    local mData = {}
    mData["open"] = self.m_OpenRecord
    return mData
end

function CHuodong:Load(mData)
    self.m_OpenRecord = mData["open"] or {}
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:RecordOpen(sName)
    local iDay = get_dayno()
    local idx = assert(self:Name2IDX(sName))
    local m = self.m_OpenRecord[idx]
    if not m or m["day"] ~iDay then
        self.m_OpenRecord[idx] = {day=iDay,open=1}
    else
        m["open"] =  m["open"] + 1
    end
    self:Dirty()
end


function CHuodong:GetBackData(oPlayer)
    return oPlayer.m_oHuodongCtrl:GetData("RewardBack",{})
end

function CHuodong:SetBackData(oPlayer,mData)
    oPlayer.m_oHuodongCtrl:SetData("RewardBack",mData)
end

function CHuodong:OnLogin(oPlayer,bReEnter)
    self:CheckRewardBack(oPlayer)
end

function CHuodong:NewDayRefresh(oPlayer)
    self:CheckRewardBack(oPlayer)
end

function CHuodong:ConfigData()
    local res = require "base.res"
    return res["daobiao"]["huodong"][self.m_sName]["config"]["data"]
end

function CHuodong:Name2IDX(sName)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["config"]["name2id"]
    return mData[sName]
end

function CHuodong:GetGradeLimit(sName)
    if sName == "question2" then
        sName = "question"
    end
    return global.oWorldMgr:QueryControl(sName,"open_grade")
end


function CHuodong:CheckRewardBack(oPlayer)
    local mData = self:GetBackData(oPlayer)
    local iLastLoginDay = mData["login"]
    local iNowDay = get_dayno()
    if not iLastLoginDay then
        mData["login"] = iNowDay
        self:SetBackData(oPlayer,mData)
        self:RefreshRewardBack(oPlayer)
        return
    end
    if iLastLoginDay >= iNowDay then
        self:RefreshRewardBack(oPlayer)
        return
    end
    local iGrade = oPlayer:GetGrade()
    local mBakList = {}
    -- 如果是昨天登录过,那么,查一下那些完成了,否在就全部奖励给他
    if iNowDay - iLastLoginDay == 1 then
        mBakList = mData["Bak"] or {}
        mData["Bak"] = {}
    end

    local mConfig = self:ConfigData()
    local mReward = {}
    local sBack = ""
    for idx,m in pairs(mConfig) do
        if m["open_limit"] ==  0 then
            local mRecord = self.m_OpenRecord[idx]
            if not mRecord or mRecord["day"] ~= iNowDay - 1 then
                goto continue
            end
        end
        local mbak = mBakList[idx] or {}
        local iLimit = m["limit"]
        local iLeft = iLimit - (mbak["cnt"] or 0 )
        if iLeft > 0 and iGrade >= self:GetGradeLimit(m["name"]) then
            mReward[idx] = {left = iLeft,}
            sBack = sBack..string.format(" (%d,%d) ",idx,iLeft)
        end
        ::continue::
    end

    mData["reward"] = mReward
    mData["login"] = get_dayno()
    self:SetBackData(oPlayer,mData)
    if sBack ~= "" then
        local mLog = {
            pid = oPlayer:GetPid(),
            back = sBack,
        }
        record.user("rewardback","build",mLog)
    end
    self:RefreshRewardBack(oPlayer)

end


function CHuodong:GetRewardBack(oPlayer,idx,vip,bnsend)
    self:GetFreeReward(oPlayer,idx,bnsend)
    if vip == 1 then
        self:GetVipReward(oPlayer,idx,bnsend)
    end
end


function CHuodong:ShortcutRewardBack(oPlayer,vip)
    local mData = self:GetBackData(oPlayer)
    local mReward = mData["reward"] or {}
    for idx,m in pairs(mReward) do
        self:GetRewardBack(oPlayer,idx,vip,true)
    end
    self:RefreshRewardBack(oPlayer)
end

function CHuodong:GetFreeReward(oPlayer,idx,bnsend)
    local mData = self:GetBackData(oPlayer)
    local iPid = oPlayer:GetPid()
    local m = mData["reward"][idx]
    if not m or m["free"] or mData["login"] ~= get_dayno() then
        return false
    end
    local iLeft = m["left"]
    local mConfig = self:ConfigData()
    local mInfo = mConfig[idx]
    if not mInfo then
        return false
    end

    local mReward = mInfo["free_reward"]
    m["free"] = iLeft
    self:SetBackData(oPlayer,mData)
    for i=1,iLeft do
        for _,iReward in ipairs(mReward) do
            self:Reward(iPid,iReward)
        end
    end
    self:UserLog(oPlayer,mInfo["name"],iLeft,0)
    if not bnsend then
        self:RefreshRewardBack(oPlayer)
    end
    return true
end


function CHuodong:GetVipReward(oPlayer,idx,bnsend)
    local mConfig = self:ConfigData()
    local mInfo = mConfig[idx]
    if not mInfo then
        return false
    end
    local mData = self:GetBackData(oPlayer)
    local mReward = mData["reward"][idx]
    local iLeft = mReward["left"]
    if mReward["vip"] then
        return false
    end
    local iCostVal = mInfo["cost"] * iLeft
    if not oPlayer:ValidGoldCoin(iCostVal,{tip="水晶不足"}) then
        return false
    end
    mReward["vip"] = iLeft
    self:SetBackData(oPlayer,mData)
    oPlayer:ResumeGoldCoin(iCostVal , "奖励找回")
    local iPid = oPlayer:GetPid()
    local mRewardList = mInfo["gold_reward"]
    for i=1,iLeft do
        for _,iReward in ipairs(mRewardList) do
            self:Reward(iPid,iReward)
        end
    end
    self:UserLog(oPlayer,mInfo["name"],iLeft,iCostVal)
    if not bnsend then
        self:RefreshRewardBack(oPlayer)
    end
end

function CHuodong:UserLog(oPlayer,sName,iCnt,iCost)
    local mLog = {
    pid = oPlayer:GetPid(),
    name = sName,
    cnt = iCnt,
    cost = iCost,
    }
    record.user("rewardback","reward",mLog)
end

function CHuodong:PlayRecord(oPlayer,sName,iCnt)
    local idx = self:Name2IDX(sName)
    if not idx then
        record.warning(string.format("rewardback record %s %s",sName,iCnt))
        return
    end
    local mData = self:GetBackData(oPlayer)
    if mData["login"] ~= get_dayno() then
        record.warning(string.format("rewardback record login_day %s %s %s %s",sName,iCnt,mData["login"],get_dayno()))
        return
    end
    local mConfig = self:ConfigData()
    local mInfo = mConfig[idx]
    if not mInfo then
        return false
    end
    local mBak = mData["Bak"] or {}
    if not mBak[idx] then
        mBak[idx] = {cnt = 0}
    end
    mBak[idx]["cnt"] = math.min(mBak[idx]["cnt"] + iCnt,mInfo["limit"])
    mData["Bak"] =  mBak
    self:SetBackData(oPlayer,mData)
end

function CHuodong:RefreshRewardBack(oPlayer)
    local mData =  self:GetBackData(oPlayer)
    local mReward = mData["reward"] or {}
    local mRewardPack = {}
    local mConfig = self:ConfigData()
    for idx,m in pairs(mReward) do
        local mInfo = mConfig[idx]
        if mInfo then
            local mPack = {sid=idx,free=0,vip=0}
            if not m["free"] then
                mPack["free"] = 1
            end
            if not m["vip"] then
                mPack["vip"]  = mInfo["cost"] * m["left"]
            end
            mPack["left"] = m["left"]
            table.insert(mRewardPack,mPack)
        end
    end
    oPlayer:Send("GS2CRefreshRewardBack",{info=mRewardPack})
end


function CHuodong:TestOP(oPlayer,iFlag,...)
    local args={...}
    local oNotifyMgr = global.oNotifyMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    if iFlag == 100 then
        local help = [[
        101-强制生成奖励
        102 - 将今天的参加记录设定为上一天参加
        103 - 增加参加记录
        104 - 查看数据
        105 - 设定玩法为昨天开启过
        ]]
        oChatMgr:HandleMsgChat(oPlayer,help)
    elseif iFlag == 101 then
        local mData = self:GetBackData(oPlayer)
        mData["login"] = get_dayno() - 10
        self:SetBackData(oPlayer,mData)
        self:CheckRewardBack(oPlayer)
    elseif iFlag == 102 then
        local mData = self:GetBackData(oPlayer)
        mData["login"] = get_dayno() - 1
        self:SetBackData(oPlayer,mData)
        self:CheckRewardBack(oPlayer)
    elseif iFlag == 103 then
        local name = args[1]
        oPlayer:RecordPlayCnt(name,1)
        oNotifyMgr:Notify(pid,"记录增加成功")
    elseif iFlag == 104 then
        local iNow = get_dayno()
        local s = string.format(" 当前 : %d\n",iNow)
        for idx,m in pairs(self.m_OpenRecord) do
            s = s..string.format("编号:%d 在%d天前开启\n",idx,iNow-m["day"])
        end
        local mData = self:GetBackData(oPlayer)
        if not mData then
            s = s.."null player data"
        else
            for idx,m in pairs(mData["Bak"] or {}) do
                s= s..string.format("玩家完成编号:%d ,完成次数%d\n",idx,m["cnt"])
            end
        end
        oChatMgr:HandleMsgChat(oPlayer,s)
    elseif iFlag == 105 then
        local name = args[1]
        local idx = self:Name2IDX(name)
        if not idx then
            return
        end
        local m = self.m_OpenRecord[idx]
        if not m then
            self:RecordOpen(name)
        end
        local m = self.m_OpenRecord[idx]
        if m then
            m["day"] = get_dayno() - 1
            oNotifyMgr:Notify(pid,"设定成功")
        end
    elseif iFlag == 106 then
        local mConfig = self:ConfigData()
        for idx,m in pairs(mConfig) do
            print("name:",m["name"],self:GetGradeLimit(m["name"]))
        end
    elseif iFlag == 107 then
        print ("---",self:GetBackData(oPlayer))
    end
end




