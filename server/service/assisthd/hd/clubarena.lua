--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))


local assistbase = import(service_path("hd.hdbase"))

--[[
1.原则上玩家可以获得数据在这里获取，尽量不要与world玩家数据有太多依赖。
2.新人馆不属于club范畴，刷新新人数据为m_NewbieQueue里取
3.club为道馆,拥有post位置和master，这个post只作为索引使用，不会有太多作用。
4.member作为玩家冗余数据存在
]]


function NewAssistHD(sHuodongName)
    return CAssistHD:New(sHuodongName)
end



CLUB_AMOUNT = {
    [1] = 0,
    [2] = 250,
    [3] = 150,
    [4] = 60,
    [5] = 30,
    [6] = 10,
}

--[[
CLUB_AMOUNT = {
    [1] = 0,
    [2] = 10,
    [3] = 10,
    [4] = 10,
    [5] = 10,
    [6] = 10,

}
]]


NEWBIE = 1

CAssistHD = {}
CAssistHD.__index = CAssistHD
CAssistHD.m_sTempName = "武馆"
inherit(CAssistHD, assistbase.CAssistHD)

function CAssistHD:New(sHuodongName)
    local o = super(CAssistHD).New(self, sHuodongName)
    o.m_Init = 0
    o.m_ClubList = {} --武馆信息列表
    o.m_Member = {} -- 玩家字典
    o.m_NewbieQueue = {}
    o.m_NewbieLimit = 1000
    --o.m_NewbieLimit = 5
    o.m_Limit = 4
    o.m_NewBieChoice = 5
    o.m_TmpWar = {}
    o.m_NiewBieRobot = {3001,3002,3003,3004,3005,3006}
    return o
end

function CAssistHD:NeedSave()
    return true
end

function CAssistHD:Save()
    local mData = {}
    mData["init"] = self.m_Init
    local mClub = {}
    for iClub,obj in pairs(self.m_ClubList) do
        mClub[iClub] = obj:Save()
    end
    mData["club"] = mClub
    local mMember = {}
    for pid,obj in pairs(self.m_Member) do
        mMember[pid] = obj:Save()
    end
    mData["member"] = mMember
    mData["newbie"] = self.m_NewbieQueue
    return mData
end


function CAssistHD:Load(mData)
    self.m_Init = mData["init"] or 0
    for iClub,m in pairs(mData["club"] or {}) do
        local obj = NewCClub(iClub)
        obj:Load(m)
        self.m_ClubList[iClub] = obj
    end

    for pid,m in pairs(mData["member"] or {}) do
        local oMember  = NewCMember(pid,m)
        oMember:Load(m)
        self.m_Member[pid] = oMember
    end
    self.m_NewbieQueue = mData["newbie"] or {}
end

function CAssistHD:LoadFinish()
    local f = function ()
        self:CheckAutoReward()
    end
    self:AddTimeCb("CheckAutoReward",30*1000,f)
    if self.m_Init ~= 0 then
        return
    end

    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["robot"]
    self:Dirty()
    self.m_Init = 1
    local mNumLimit = {}
    local fFind = function(iClub,iPost)
        for iNo,m in pairs(mData) do
            if m["club"] == iClub then
                local iNum = m["amount"]
                if iPost == 0 and m["master"] == 1   then
                    return m
                elseif iPost ~=0 and m["master"] ~= 1  and (mNumLimit[iNo] or 0)  < iNum then
                    mNumLimit[iNo] =  (mNumLimit[iNo] or 0)  + 1
                    return m
                end
            end
        end
    end


    for i=2,6 do
        local obj = NewCClub(i)
        self.m_ClubList[i] = obj
        local iLimit = obj:Limit()
        for iPost = 1,iLimit do
            local mRobot = fFind(i,iPost)
            local m = {
                robot = mRobot["id"],
                pid = 0,
                }
            obj.m_Member[iPost] = {}
            obj:AddMember(iPost,m)
        end
        local mRobot = fFind(i,0)
        local m = {
            robot = mRobot["id"],
            pid = 0,
            }
        obj:AddMaster(m)
    end
end

function CAssistHD:CheckFixClubRobot(iClub)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["robot"]
    local mNumLimit = {}
    local fFind = function(iClub,iPost)
        for iNo,m in pairs(mData) do
            if m["club"] == iClub then
                local iNum = m["amount"]
                if iPost == 0 and m["master"] == 1   then
                    return m
                elseif iPost ~= 0 and m["master"] ~= 1  and (mNumLimit[iNo] or 0)  < iNum then
                    mNumLimit[iNo] =  (mNumLimit[iNo] or 0)  + 1
                    return m
                end
            end
        end
    end
    local oClub = self:GetClub(iClub)
    if oClub then
        local iLimit =  oClub:Limit()
        for iPost = 0,iLimit do
            local mInfo
            if iPost == 0 then
                mInfo = oClub:GetMaster()
            else
                mInfo = oClub:GetMember(iPost)
            end
            if mInfo and mInfo["robot"] then
                local robotid = mInfo["robot"]
                mNumLimit[robotid] = mNumLimit[robotid] or 0
                mNumLimit[robotid] = mNumLimit[robotid] + 1
            end
        end
        for iPost = 0,iLimit do
            local mInfo
            if iPost == 0 then
                mInfo = oClub:GetMaster()
            else
                mInfo = oClub:GetMember(iPost)
            end
            if not mInfo or table_count(mInfo) <= 0 then
                local mRobot = fFind(iClub,iPost)
                local m = {
                    robot = mRobot["id"],
                    pid = 0,
                }
                if iPost == 0 then
                    oClub:AddMaster(m)
                else
                    oClub.m_Member[iPost] = {}
                    oClub:AddMember(iPost,m)
                end
            end
        end
    end
end

function CAssistHD:MergeFrom(mFromData)
    self:Dirty()
    self.m_Init = 0
    return true
end

function CAssistHD:NewHour(iWeekDay, iHour)
    for iClub,_ in ipairs(CLUB_AMOUNT) do
        local oClub = self:GetClub(iClub)
        if oClub then
            local mInfo = oClub:GetMaster()
            if not mInfo["robot"] then
                local iPid = mInfo["pid"]
                if iPid then
                    self:Send2WorldUpdate(iPid)
                end
            end
        end
    end
end

function CAssistHD:Send2WorldUpdate(iPid)
    interactive.Send(".world","clubarena","UpdateInfo",{pid=iPid})
end

function CAssistHD:RewardDay()
    local mRewardList = {}
    for iClub,oClub in pairs(self.m_ClubList) do
        local mlist = oClub:MemberList(true)
        for _, m in pairs(mlist) do
            if not m[2]["robot"] then
                table.insert(mRewardList,{iClub,m[2]["pid"]})
            end
        end
    end
    return mRewardList
end

function CAssistHD:AddNewbie(pid)
    if not table_in_list(self.m_NewbieQueue,pid) then
        table.insert(self.m_NewbieQueue,pid)
        self:Dirty()
        self:CheckNewbieLen()
    end
end

function CAssistHD:CheckNewbieLen()
    if #self.m_NewbieQueue > self.m_NewbieLimit then
        for i= 1,10 do
            local iPid = table.remove(self.m_NewbieQueue,1)
            local oPlayer = self:GetMember(iPid)
            if oPlayer then
                self:DeleteMember(iPid)
            end
        end
        self:Dirty()
    end
end


function CAssistHD:DeleteNewbie(pid)
    extend.Array.remove(self.m_NewbieQueue,pid)
end


function CAssistHD:GetMember(pid)
    return self.m_Member[pid]
end

function CAssistHD:AddMember(o)
    self.m_Member[o:GetPid()] = o
    self:Dirty()
end

function CAssistHD:DeleteMember(iPid)
    local obj =  self.m_Member[iPid]
    self.m_Member[iPid] = nil
    self:Dirty()
    if obj then
        baseobj_delay_release(obj)
    end
end

function CAssistHD:GetClub(iClub)
    return self.m_ClubList[iClub]
end

function CAssistHD:RobotInfo(iR)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["robot"]
    return assert(mData[iR])
end

function CAssistHD:ClubInfo(iR)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["config"]
    return assert(mData[iR])
end



function CAssistHD:GetRewardInfo(iClub)
     local res = require "base.res"
    local mData = assert(res["daobiao"]["huodong"][self:ResName()]["config"][iClub])
    return mData
end

function CAssistHD:CreateNewMember(iPid,mData)
    if self.m_Member[iPid] then
        return self.m_Member[iPid]
    end
    local oMember  = NewCMember(iPid,mData)
    self:AddMember(oMember)
    self:AddNewbie(iPid)
    return oMember
end


function CAssistHD:GetClubFightInfo(mData)
    local iPid = mData.pid
    local iClub = mData["club"]
    local mResult = {}
    self:CheckFixClubRobot(iClub)
    if iClub ==  NEWBIE then
        mResult["fight"] = self:ChooseNewbie(mData)
    else
        mResult["fight"] = self:ChooseEnemy(mData,iClub)
    end
    return mResult
end

function CAssistHD:FilterFailEnemy(iClub,mFight)
    local mNewFight = {}
    local oClub = self:GetClub(iClub)
    for idx,m in ipairs(mFight) do
        if not m["win"] then
            local iPid = m["pid"]
            local bFilter = false
            local iPost = m["post"]
            local iPid = m["pid"]
            if iPid ~= 0  and oClub then
                local m = oClub:GetMember(iPost)
                if not m or m["pid"] ~= iPid then
                    bFilter = true
                end
            end
            if not bFilter then
                mNewFight[idx] = m
            end
        end
    end
    return mNewFight
end



function CAssistHD:UpdateInfo(mData)
    local iPid = mData["pid"]
    local mInfo = mData["data"]
    local oMember = self:GetMember(iPid)
    if oMember then
        oMember:SetData("name",mInfo["name"])
        oMember:SetData("org",mInfo["org"])
        oMember:SetData("power",mInfo["power"])
        oMember:SetData("model",mInfo["model"])
    end
end

function CAssistHD:ChooseEnemy(mData,iClub)
    -- 每次打开时，需要剔除无效的信息，再重新整理
    local mFight = self:FilterFailEnemy(iClub,mData["fight"] or {})
    local oClub = self:GetClub(iClub)
    local mInfo = oClub:GetMaster()
    local iOwner = mData["pid"]
    local mPlayer
    local mMaster
    if mInfo["robot"] then
        mPlayer = self:RobotInfo(mInfo["robot"])
        mMaster = self:PackRobotFightInfo(mPlayer,iClub,0)
    else
        mPlayer = self:GetMember(mInfo["pid"])
        mMaster = self:PackPlayerFightInfo(mPlayer,iClub,0)
    end
    if mPlayer["robot"] then
        mMaster["robot"] = mPlayer["robot"]
    end
    if  table_count(mFight) >= self.m_Limit then
        return {new= 0,fight = mFight,master=mMaster}
    end


    local mTarget = {}
    local mRobot = oClub:ChooseRobot(self.m_Limit)
    if mRobot and #mRobot > 0 then
        for _ , iPost in ipairs(mRobot) do
            table.insert(mTarget,{post=iPost,})
            if #mTarget >= self.m_Limit then
                break
            end
        end
    end

    if #mTarget < self.m_Limit then
        local iNeed = self.m_Limit - #mTarget
        local mList = oClub:SortMember()
        local iN = #mList
        -- 玩家可能小于9，则取1
        local x = math.max(math.floor(iN/10),1)
        local f = function(n)
            local ret = {}
            for i=1,n do
                local m = table.remove(mList,1)
                if m then
                    table.insert(ret,m)
                end
            end
            return ret
        end

        -- 策划选取范围规则
        local mPostList = {f(x),f(2*x),f(3*x),f(4*x),}
        for i=1,iNeed do
            local mPost = mPostList[i]
            if #mPost > 0 then
                local m = extend.Random.random_choice(mPost)
                table.insert(mTarget,{post=m[3],pid=m[2]})
                if #mTarget > self.m_Limit then
                    break
                end
            end
        end
        -- 排除自身
        local inf = function (m,mList)
            for i,info in pairs(mList) do
                if m[3] == info["post"] then
                    return true
                end
            end
            return false
        end

        for iPost,m in ipairs(mTarget) do
            if m["pid"] == iOwner then
                for _,info in ipairs(oClub:SortMember()) do
                    if not inf(info,mTarget) then
                        mTarget[iPost] = {post=info[3],pid=info[2]}
                        break
                    end
                end
                break
            end
        end

        --这里依然有可能不足4
        if #mTarget < 4 then
            for _,info in ipairs(oClub:SortMember()) do
                if not inf(info,mTarget) then
                    table.insert(mTarget,{post=info[3],pid=info[2]})
                    if #mTarget == 4 then
                        break
                    end
                end
            end
        end


    end

    assert(#mTarget == 4)

    local mResult = {}
    for _,m in ipairs(mTarget) do
        local mInfo = oClub:GetMember(m["post"])

        local mPlayer
        local mPack
        if mInfo["robot"] then
            mPlayer = self:RobotInfo(mInfo["robot"])
            mPack = self:PackRobotFightInfo(mPlayer,iClub,m["post"])
            mPack["robot"] = mInfo["robot"]
        else
            mPlayer = self:GetMember(m["pid"])

            mPack = self:PackPlayerFightInfo(mPlayer,iClub,m["post"])
        end
        table.insert(mResult,mPack)
    end

    local fInList = function (m,mFight)
        for i,info in pairs(mFight) do
            if m["post"] == info["post"] then
                return true
            end
        end
        return false
    end

    for idx,m in ipairs(mResult) do
        if not fInList(m,mFight) then
            for i=1,self.m_Limit do
                if not mFight[i] then
                    mFight[i] = m
                    break
                end
            end
        end
    end

    return {new=1,fight=mFight,master=mMaster}
end


function CAssistHD:PackRobotFightInfo(mPlayer,iClub,iPost)
    return {
                pid = mPlayer["pid"] or 0,
                name = mPlayer["name"] or "",
                orgname = mPlayer["org"] or "",
                post = iPost,
                club = iClub or NEWBIE,
                power  = mPlayer["power"],
                --shape = mPlayer["shape"],
                model =  {
                    shape = mPlayer["shape"],
                    weapon = mPlayer["wpmodel"],
                    scale = 0,
                    color = {0,},
                    mutate_texture = 0,
                    adorn = 0,
                    },
                robot = mPlayer["id"],
            }
end


function CAssistHD:PackPlayerFightInfo(oPlayer,iClub,iPost)
    return {
                pid = oPlayer:GetPid(),
                name = oPlayer:GetData("name"),
                orgname =  oPlayer:GetData("org",""),
                post = iPost,
                club = iClub or NEWBIE,
                power  = oPlayer:GetData("power"),
                model = oPlayer:GetData("model"),
            }
end


function CAssistHD:ChooseNewbie(mData)
    local iTarget = mData["pid"]
    local mFight = self:FilterFailEnemy(NEWBIE,mData["fight"] or {})
    if  table_count(mFight) >= self.m_NewBieChoice then
        return {new=0,fight = mFight}
    end
    local exculelist = {iTarget,}
    local mTarget = {}
    for _,m in ipairs(mFight) do
        table.insert(exculelist,m["pid"])
        table.insert(mTarget,m)
    end
    local mList = extend.Random.sample_list(self.m_NewbieQueue,10)
    for _ , pid in ipairs(mList) do
        if not table_in_list(exculelist,pid) then
            local mPlayer = self:GetMember(pid)
            if mPlayer then
                local m = self:PackPlayerFightInfo(mPlayer,NEWBIE,0)
                table.insert(mTarget,m)
                if #mTarget >= self.m_NewBieChoice then
                    break
                end
            else
                record.warning(string.format("err choose newbie %s",pid))
            end
        end
    end

    if #mTarget < self.m_NewBieChoice then
        local iNeed = self.m_NewBieChoice - #mTarget
        for i=1,iNeed do
            local iRobot = extend.Random.random_choice(self.m_NiewBieRobot)
            local mPlayer = self:RobotInfo(iRobot)
            local mNiewBie = self:PackRobotFightInfo(mPlayer,NEWBIE,0)
            table.insert(mTarget,mNiewBie)
        end
    end

    local fInList = function (m,mFight)
        for i,info in pairs(mFight) do
            if m["pid"] ~= 0 and m["pid"] == info["pid"] then
                return true
            end
        end
        return false
    end
    for idx,m in pairs(mTarget) do
        if not fInList(m,mFight) then
            for i=1,self.m_NewBieChoice do
                if not mFight[i] then
                    mFight[i] = m
                    break
                end
            end
        end
    end
    return{new=1,fight = mFight }
end


function CAssistHD:LockWar(mData)
    local mResult = {}
    local iPid = mData["pid"]
    local iClub = mData["club"]
    local iPost = mData["post"]
    local iTarget = mData["target"]
    local oClub1 = self:GetClub(iClub)
    local iMyClub = NEWBIE
    local iMyPost = 0
    local bWar1,bWar2
    local oClub2
    local oPlayer = self:GetMember(iPid)
    local bCheckPost = false
    local bMaster1 = false
    local bMaster2 = false
    local oTarget  = self:GetMember(iTarget)
    if oPlayer then
        iMyClub = oPlayer:Club()
        iMyPost = oPlayer:Post()
        bMaster1 = oPlayer:IsMaster()
        oClub2 = self:GetClub(iMyClub)
    end
    if oTarget then
        bMaster2 = oTarget:IsMaster()
    elseif iPost == 0 and iClub ~= NEWBIE then
        bMaster2 = true
    end
    if bMaster2 and bMaster1 then
        return {ok=false,err=6}
    end

    if oClub1 then
        bWar1 = oClub1:IsInWar(iPost)
        local m = oClub1:GetMember(iPost)
        if not m or m["pid"] ~= iTarget then
            return {ok=false,err=4}
        end
    else
        bWar1 = self.m_TmpWar[iTarget]
    end
    if oClub2 then
        bWar2 = oClub2:IsInWar(iMyPost)
    else
        bWar2 = self.m_TmpWar[iPid]
    end

    if bWar1 or bWar2 then
        return {ok =false,war1=bWar1,war2=bWar2}
    end
    if iClub > iMyClub and math.abs(iMyClub-iClub) > 1 then
        return {ok =false,err=1}
    end


    if iMyClub ~= NEWBIE and iMyClub == iClub and iPost == iMyPost then
        return {ok=false,err=2}
    end

    --[[
    if  iClub ~= iMyClub and  iClub ~= NEWBIE and iPost == 0  then
        if iMyClub < iClub or  (iMyPost ~=0 and iMyClub ~= NEWBIE ) or iMyClub == NEWBIE then
            return {ok=false,err=3}
        end
    end
    ]]


    local m
    if oClub1 then
        oClub1:InWar(iPost)
         m = oClub1:GetMember(iPost)
    else
        m = {pid = iTarget}
        if iTarget ~=0 then
            self.m_TmpWar[iTarget] = iPid
        end
    end
    if oClub2 then
        oClub2:InWar(iMyPost)
    else
        self.m_TmpWar[iPid] = iTarget
    end
    return {ok=true,info = m,myclub = iMyClub,mypost=iMyPost,club = iClub,target=iTarget}
end

function CAssistHD:UnLockWar(mData)
    local iPid = mData["pid"] or 0
    local iClub = mData["club"]
    local iPost = mData["post"]
    local iTarget = mData["target"] or 0
    local oClub1 = self:GetClub(iClub)
    local iMyClub = NEWBIE
    local iMyPost = 0
    local oClub2
    local oPlayer = self:GetMember(iPid)
    if oPlayer then
        iMyClub = oPlayer:Club()
        iMyPost = oPlayer:Post()
    end
    oClub2 = self:GetClub(iMyClub)
    if oClub1 then
        oClub1:CleanWar(iPost)
    else
        self.m_TmpWar[iTarget] = nil
    end
    if oClub2 then
        oClub2:CleanWar(iMyPost)
    else
        self.m_TmpWar[iPid] = nil
    end
end

-- 启服时，会在30秒后进又检查 ，每1秒检查一次，由于量的限制，不会有太多消耗，不放心的话可以调成2-3秒
function CAssistHD:CheckAutoReward()
    self:DelTimeCb("CheckAutoReward")
    local f = function ()
        self:CheckAutoReward()
    end
    self:AddTimeCb("CheckAutoReward",1000,f)
    local mRewardList = {}
    local iNow = get_time()
    for iClub,oClub in pairs(self.m_ClubList) do
        local mInfo = self:GetRewardInfo(iClub)
        local iReward = mInfo["reward_time"]
        local iNum = (iNow - oClub.m_RewardTime ) // mInfo["auto_reward"]
        if iNum > 0  then
            local mMaster = oClub:GetMaster()
            oClub:ResetTime()
            if mMaster["pid"] ~=0 then
                local iCoin = iNum * iReward
                oClub:AddCoin(iCoin)
                table.insert(mRewardList,{mMaster["pid"] ,iClub,iCoin})
            end
        end
    end
    if #mRewardList > 0 then
        interactive.Send(".world","clubarena","GiveAutoReward",{reward=mRewardList})
    end
end

function CAssistHD:OnWarEnd(mData)
    local mMy = mData["player"]
    local iTarget = mData["target"]
    local iWin = mData["win"]
    local iPid = mMy["pid"]
    local iTargetClub = mData["club"]
    local iPost = mData["post"]
    local oPlayer = self:GetMember(iPid)
    local oTarget = self:GetMember(iTarget)
    local bMaster = iPost == 0

    if not oPlayer then
        oPlayer  = NewCMember(iPid,mMy["data"])
        self:AddMember(oPlayer)
    end
    local iMyClub = oPlayer:Club()
    local bMyMaster = oPlayer:IsMaster()
    local iMyPost = oPlayer:Post()
    local oClub1 = self:GetClub(iMyClub)
    local oClub2 = self:GetClub(iTargetClub)
    local bWar1,bWar2
    if oClub1 then
        bWar1 = oClub1:InWar(iMyPost)
        oClub1:CleanWar(iMyPost)
    else
        self.m_TmpWar[iPid] = nil
    end

    if oClub2 then
        bWar2 = oClub2:InWar(iPost)
        oClub2:CleanWar(iPost)
    else
        self.m_TmpWar[iTarget] = nil
    end

    self.m_Result = {
        club1 = iMyClub,
        club2 = iTargetClub,
        updown1 = 0,
        updown2 = 0,
        post1 = iMyClub,
        post2 = iTargetClub,
    }

    -- 对方也是新手
    if iTargetClub == NEWBIE then
        return self.m_Result
    end
    if math.abs(iMyClub - iTargetClub) > 1 then
        --record.error(string.format("club over %s %s - %s %s",iMyClub,iTargetClub,iPid,iTarget))
        return self.m_Result
    end

    if iMyClub == iTargetClub then
        if not bMaster or iWin ~= 1 then
            return self.m_Result
        end
        --同馆下，对方是馆主
        self:PromoteMaster(oPlayer)
        self.m_Result.updown1 = 3
    else
        --对方高一级
        if iTargetClub > iMyClub then
            --都是馆员，互换等级
            if not bMyMaster and not bMaster then
                if iWin ~= 1 then
                     -- 失败不变
                    return self.m_Result
                end
                self:MemberTransposition(oPlayer,iTargetClub,iPost)
            end
            if bMyMaster and iWin == 1 then
                    self:MasterPromote(iMyClub,iTargetClub,iPost)
            end
            --[[
            elseif bMyMaster and bMaster then
                馆主不能打馆主
                if iWin == 1 then
                    self:MasterTransposition(oPlayer,iTargetClub)
                end
                ]]
        else -- 对方低一级
            if not bMyMaster and not bMaster then
                if iWin == 0 then -- 失败降级
                    self:MemberTransposition(oPlayer,iTargetClub,iPost)
                end
            elseif bMyMaster and bMaster then
                --[[--馆主不能打馆主
                if iWin == 0 then
                    self:MasterTransposition(oPlayer,iTargetClub)
                end
                ]]
            elseif bMaster then
                if iWin == 1 then
                    self:PromoteMasterAndSort(oPlayer,iTargetClub)
                end
            end
        end
    end
    return self.m_Result
end



--player 升级,oTarget降级
function CAssistHD:MemberTransposition(oPlayer,iTargetClub,iPost2)
    local iPost1 = oPlayer:Post()
    local iMyClub = oPlayer:Club()
    local oClub1 = self:GetClub(iMyClub)
    local oClub2 = self:GetClub(iTargetClub)
    local m2 = oClub2:PopMember(iPost2)
    local m1
    if oClub1 then
        m1 = oClub1:PopMember(iPost1)
    end
    if iMyClub == NEWBIE then
        self:DeleteNewbie(oPlayer:GetPid())
    end
    if m1 then
        oClub2:AddMember(iPost2,m1)
    else
        oClub2:AddMember(iPost2,{pid=oPlayer:GetPid()})
    end
    if oClub1 then
        oClub1:AddMember(iPost1,m2)
    else
        if not m2["robot"] then --非机器人
            self:AddNewbie(m2["pid"])
        end
    end
    local iu1 = 1
    local iu2 = 2
    if iMyClub > iTargetClub then
        iu1 = 2
        iu2 = 1
    end
    self.m_Result = {
    club1 = iTargetClub,
    club2 = iMyClub,
    updown1 = iu1,
    updown2 = iu2,
    post1 = iPost2,
    post2 = iPost1,
    }
end


--馆主打高级官员，馆主变机器人，馆主变官员，位置一直排序置换
function CAssistHD:MasterPromote(iMyClub,iTargetClub,iPost)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self:ResName()]["robot"]
    local mRobot
    for iNo,m in pairs(mData) do
        if m["club"] == iMyClub and m["master"] == 1 then
            mRobot = {
                robot = m["id"],
                pid = 0,
            }
        end
    end
    if not mRobot then
        record.error(string.format("clubarena - MasterPromote %s",iMyClub))
        return
    end
    local oClub1 = self:GetClub(iMyClub)
    local oClub2 = self:GetClub(iTargetClub)
    local mMaster = oClub1:PopMaster()
    oClub1:AddMaster(mRobot)
    local mTarget = oClub2:PopMember(iPost)
    local mPop = mTarget
    oClub2:AddMember(iPost,mMaster)
    local iTargetPost,iChangeClub
    local iPopPost
    for i = iTargetClub-1,2,-1 do
        mPop,iPopPost = self:InsertAndPopMember(i,mPop)
        if not iTargetPost then
            iTargetPost = iPopPost
            iChangeClub = i
        end
    end

    self.m_Result = {
        club1 = iTargetClub,
        club2 = iChangeClub,
        updown1 = 1,
        updown2 = 2,
        post1 = iPost,
        post2 = iTargetPost or -1,
    }

end

-- 插入新成员，弹出淘汰成员,如果有机器人，则马上淘汰机器人
function CAssistHD:InsertAndPopMember(iClub,m)
    local oClub = self:GetClub(iClub)
    local mList = oClub:ChooseRobot(1)
    if mList and  #mList > 0 then
        local iPost = mList[1]
        local mFailer = oClub:PopMember(iPost)
        oClub:AddMember(iPost,m)
        return mFailer
    end
    local mList = oClub:SortMember()
    local mLaster = mList[#mList]
    local iPost = mLaster[3]
    local mFailer = oClub:PopMember(iPost)
    oClub:AddMember(iPost,m)
    return mFailer,iPost
end


--互换馆主
function CAssistHD:MasterTransposition(oPlayer,iTargetClub)
    local iClub = oPlayer:Club()
    local oClub1 = self:GetClub(iClub)
    local oClub2 = self:GetClub(iTargetClub)
    local m1 = oClub1:PopMaster()
    local m2 = oClub2:PopMaster()
    oClub1:AddMaster(m2)
    oClub2:AddMaster(m1)
    self.m_Result = {
    club1 = iTargetClub,
    club2 = iClub,
    updown1 = iTargetClub > iClub and 1 or 2,
    updown2 = iTargetClub > iClub and 2 or 1,
    post1 = 0,
    post2 = 0,
    }
end

--升级馆主
function CAssistHD:PromoteMaster(oPlayer)
    local oClub = self:GetClub(oPlayer:Club())
    local iPost = oPlayer:Post()
    local m1 = oClub:PopMember(iPost)
    local m2 = oClub:PopMaster()
    oClub:AddMaster(m1)
    oClub:AddMember(iPost,m2)
    local sMasterName = ""
    if m2["robot"] then
        local mInfo = self:RobotInfo(m2["robot"])
        sMasterName = mInfo["name"]
    else
        local oInfo = self:GetMember(m2["pid"])
        sMasterName = oInfo:GetData("name","")
    end
    local mClubInfo = self:ClubInfo(oPlayer:Club())
    local sMyName = oPlayer:GetData("name","")
    local sText = self:GetTextData(2001)
    sText = string.gsub(sText,"ROLE",sMyName)
    sText = string.gsub(sText,"MASTER",sMasterName)
    sText = string.gsub(sText,"CLUB",mClubInfo["desc"])
    interactive.Send(".world","clubarena","Notify",{text=sText,type=1})
    if not m2["robot"] then
        local sText = self:GetTextData(2002)
        sText = string.gsub(sText,"ROLE",sMyName)
        sText = string.gsub(sText,"CLUB",mClubInfo["desc"])
        sText = string.gsub(sText,"club2",mClubInfo["desc"])
        interactive.Send(".world","clubarena","Notify",{text=sText,type=2,target=m2["pid"]})
    end
end


--打低一级馆主,变成馆主
function CAssistHD:PromoteMasterAndSort(oPlayer,iTargetClub)
    local iClub1 = oPlayer:Club()
    local oClub1 = self:GetClub(iClub1)
    local oClub2 = self:GetClub(iTargetClub)
    local iMyPost = oPlayer:Post()
    local mMaster = oClub2:PopMaster()
    local m1 = oClub1:PopMember(iMyPost)
    oClub2:AddMaster(m1)

    local mPop = mMaster
    local iPopPost
    for iCurClub = iTargetClub,2,-1 do
        mPop,iPopPost = self:InsertAndPopMember(iCurClub,mPop)
    end

    local u1 = 4
    local u2 = 0
    self.m_Result = {
    club1 = iTargetClub,
    club2 = iTargetClub,
    updown1 = u1,
    updown2 = u2,
    post1= 0 ,
    post2 = iSelectPost or -1,
    }

    local sMyName = oPlayer:GetData("name","")
    local sMasterName = ""
    if mMaster["robot"] then
        local mInfo = self:RobotInfo(mMaster["robot"])
        sMasterName = mInfo["name"]
    else
        local oInfo = self:GetMember(mMaster["pid"])
        sMasterName = oInfo:GetData("name","")
    end
    local mClubInfo = self:ClubInfo(iTargetClub)
    local sText = self:GetTextData(2001)
    sText = string.gsub(sText,"ROLE",sMyName)
    sText = string.gsub(sText,"MASTER",sMasterName)
    sText = string.gsub(sText,"CLUB",mClubInfo["desc"])
    interactive.Send(".world","clubarena","Notify",{text=sText,type=1})
end

function  CAssistHD:OpenMainUI(iPid)
    local oPlayer = self:GetMember(iPid)
    local mResult = {club=NEWBIE,coin=0}
    if oPlayer then
        mResult["club"] = oPlayer:Club()
        mResult["master"] = oPlayer:IsMaster()
        local oClub = self:GetClub(mResult["club"])
        if oClub then
            if oClub:IsMaster(iPid) then
                mResult["coin"] = oClub.m_RecordCoin
            end
        end
    end

    mResult["name"] = {}
    for iClub=2,6 do
        local oClub = self:GetClub(iClub)
        local m = oClub:GetMaster()
        local name
        if m["robot"] then
            local mInfo = self:RobotInfo(m["robot"])
            name = mInfo["name"]
        else
            local oPlayer = self:GetMember(m["pid"])
            name = oPlayer:GetData("name")
        end
        table.insert(mResult["name"],name)
    end
    return  mResult
end



function NewCClub(bid)
    return CClub:New(bid)
end

CClub  = {}
CClub.__index = CClub
inherit(CClub, datactrl.CDataCtrl)

function CClub:New(id)
    local o = super(CClub).New(self)
    o.m_ID = id
    o.m_Member = {}
    o.m_RobotList = {}
    o.m_Master = {}
    o.m_RewardTime = get_time()
    o.m_RecordCoin = 0
    return o
end

function CClub:Save()
    local mData = {}
    local mMember = {}
    for iPost,m in pairs(self.m_Member) do
        mMember[iPost] = self:dumps(m)
    end
    mData["member"] = mMember
    mData["master"] = self:dumps(self.m_Master)
    mData["robot"] = self.m_RobotList
    mData["t"] = self.m_RewardTime
    mData["coin"] = self.m_RecordCoin
    return mData
end

function CClub:Load(mData)
    self.m_Member = {}
    for iPost,m in pairs(mData["member"] or {}) do
        self.m_Member[iPost] = self:loads(m)
    end
    self.m_Master = self:loads(mData["master"] or {})
    self.m_RobotList = mData["robot"]
    self.m_RewardTime = mData["t"] or get_time()
    self.m_RecordCoin = mData["coin"] or 0
end

function CClub:AddCoin(iCoin)
    self.m_RecordCoin = self.m_RecordCoin + iCoin
    self:Dirty()
end

function CClub:dumps(m)
    return {m["pid"],m["robot"]}
end

function CClub:loads(m)
    return {pid=m[1],robot=m[2]}
end

function CClub:Assist()
    local oAssistDHMgr = global.oAssistDHMgr
    return oAssistDHMgr:GetHuodong("clubarena")
end

function CClub:Dirty()
    self:Assist():Dirty()
end

function CClub:Limit()
    return CLUB_AMOUNT[self.m_ID]
end

function CClub:ID()
    return self.m_ID
end


function CClub:ResetTime()
    self.m_RewardTime = get_time()
    self:Dirty()
end

function CClub:MemberList(bMaster)
    bMaster = bMaster or false
    local mResult = {}
    for iPost,m in pairs(self.m_Member) do
        if next(m) then
            table.insert(mResult,{iPost,m})
        end
    end
    if bMaster then
        if next(self.m_Master) then
            table.insert(mResult,{0,self.m_Master})
        end
    end
    return mResult
end

function CClub:GetMember(iPost)
    if iPost == 0 then
        return self.m_Master
    end
    return self.m_Member[iPost]
end

function CClub:HasPost(iPost)
    if self.m_Member[iPost] then
        return true
    else
        return false
    end
end


function CClub:AddMember(iPost,mData)
    if iPost == 0 then
        self:AddMaster(mData)
        return
    end
    assert(table_count(self.m_Member[iPost]) == 0 ,string.format("clbuarena add member not be nil %s",self.m_ID))
    self.m_Member[iPost] = mData
    if mData["robot"] then
        table.insert(self.m_RobotList,iPost)
    end
    if mData["pid"] and mData["pid"] ~= 0 then
        local oPlayer = assert(self:Assist():GetMember(mData["pid"]))
        oPlayer:SetClub(self:ID())
        oPlayer:SetPost(iPost)
    end
    self:Dirty()
end

function CClub:PopMember(iPost)
    if iPost == 0 then
        return self:PopMaster()
    end
    local mData = self.m_Member[iPost]
    self.m_Member[iPost] = {}
    if mData["robot"] then
        extend.Array.remove(self.m_RobotList,iPost)
    end
    if mData["pid"] ~=0 then
        local oPlayer = assert(self:Assist():GetMember(mData["pid"]),string.format("getmember %s %s %s",self.m_Club,mData["pid"],iPost))
        oPlayer:SetClub(NEWBIE)
        oPlayer:RmPost()
    end
    self:Dirty()
    return mData
end

function CClub:AddMaster(mData)
    assert(table_count(self.m_Master) == 0 ,string.format("clbuarena add member not be nil %s",self.m_ID))
    if mData["pid"] and  mData["pid"]  ~= 0 then
        local oPlayer = assert(self:Assist():GetMember(mData["pid"]))
        oPlayer:SetClub(self:ID())
        oPlayer:SetPost(0)
    end
    self.m_RecordCoin = 0
    self:Dirty()
    self.m_Master = mData
    self:ResetTime()
end

function CClub:PopMaster()
    local mData = self.m_Master

    if mData["pid"] ~=0 then
        local oPlayer = assert(self:Assist():GetMember(mData["pid"]),string.format("clubarena null master: %s %s",mData["pid"],self:ID()))
        oPlayer:SetClub(NEWBIE)
        oPlayer:SetPost(0)
    end
    self.m_Master = {}
    self:Dirty()
    return mData
end

function CClub:GetMaster()
    return self.m_Master
end


function CClub:SortMember()
    local oHuodong = self:Assist()
    local sortlist = {}
    for iPost,m in pairs(self.m_Member) do
        local iPid = m["pid"]
        local iPower = 0
        if iPid and iPid ~= 0 then
            local obj = assert(oHuodong:GetMember(iPid))
            iPower = obj:GetData("power",0)
            table.insert(sortlist,{iPower,iPid,iPost})
        end
    end
    table.sort(sortlist,function(a1,a2)
        return a1[1] > a2[1]
        end)
    return sortlist
end

function CClub:ChooseRobot(iLimit)
    if #self.m_RobotList == 0 then
        return
    end
    return extend.Random.sample_list(self.m_RobotList,iLimit)
end

function CClub:IsMaster(id)
    return self.m_Master["pid"] == id
end

function CClub:IsInWar(iPost)
    if iPost == 0 then
        return self.m_Master["war"]
    end
    return self.m_Member[iPost]["war"]
end

function CClub:InWar(iPost)
    if iPost == 0 then
        if table_count(self.m_Master) > 0 then
            self.m_Master["war"] = true
        end
        return
    end
    if table_count(self.m_Member[iPost]) > 0 then
        self.m_Member[iPost]["war"] = true
    end
end

function CClub:CleanWar(iPost)
    if iPost == 0 then
        self.m_Master["war"] = nil
        return
    end
    self.m_Member[iPost]["war"] = nil
end





function NewCMember(iPid,mData)
    return CMember:New(iPid,mData)
end


CMember  = {}
CMember.__index = CMember
inherit(CMember, datactrl.CDataCtrl)

function CMember:New(pid,mData)
    local o = super(CMember).New(self)
    o.m_Pid = pid
    o.m_Post = 0
    o.m_Club = NEWBIE
    o.m_mData = mData
    return o
end

function CMember:GetPid()
    return self.m_Pid
end

function CMember:Save()
    local mData = {}
    mData["d"] = self.m_mData
    mData["p"] = self.m_Post
    mData["c"] = self.m_Club
    return mData
end

function CMember:Load(mData)
    self.m_mData = mData["d"] or {}
    self.m_Post = mData["p"]
    self.m_Club = mData["c"]
end


function CMember:Assist()
    local oAssistDHMgr = global.oAssistDHMgr
    return oAssistDHMgr:GetHuodong("clubarena")
end

function CMember:Dirty()
    self:Assist():Dirty()
end

function CMember:RmPost()
    local iPost = self.m_Post
    self.m_Post = 0
    self:Dirty()
    return iPost
end

function CMember:SetPost(iPost)
    self.m_Post = iPost
    self:Dirty()
end

function CMember:Post()
    return self.m_Post
end

function CMember:SetClub(iClub)
    self.m_Club = iClub
    self:Dirty()
end

function CMember:Club()
    return self.m_Club
end

function CMember:Power()
    self:GetData("power",0)
end

function CMember:IsMaster()
    return self.m_Post == 0 and self:Club() ~= NEWBIE
end


