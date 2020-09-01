--import module
local skynet = require "skynet"
local global  = require "global"
local extend = require "base.extend"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))

local huodongbase = import(service_path("huodong.huodongbase"))
local netteam = import(service_path("netcmd.team"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

local MAX_BUY_CNT = 1

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "yjfuben"
CHuodong.m_sTempName = "月见行者"
inherit(CHuodong, huodongbase.CHuodong)


function CHuodong:Init()
    self:TryStartRewardMonitor()
    self.m_iScheduleID = 1012
    self.m_GameList = {}
    self.m_Player2GameID = {}
    self.m_GameID = 0
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.mosterlist = self.m_MonsterList or {}
    return mData
end

function CHuodong:Load(mData)
    mData = mData or {}
    self.m_MonsterList = mData.mosterlist
end

function CHuodong:LoadFinish()
    if not self.m_MonsterList then
        self:ConfigFightMonster()
    end
end

function CHuodong:GenerateList(mSet,iSelect,mDel)
    local mTmp,mResult = {},{}
    for _,iNo in ipairs(mSet) do
        if not table_in_list(mDel,iNo) then
            table.insert(mTmp,iNo)
        end
    end
    for iNo=1,iSelect do
        if #mTmp <= 0 then
            break
        end
        local idx = math.random(#mTmp)
        local iMosterID = table.remove(mTmp,idx)
        table.insert(mResult,iMosterID)
    end
    return mResult
end

function CHuodong:MakeMonsterList(iStart,iEnd)
    local mList = {}
    for iNo=iStart,iEnd do
        table.insert(mList,iNo)
    end
    return mList
end

function CHuodong:ConfigMosterDetail(iWave,mDel)
    local mWareData = {}
    local iShift = 1000
    local mList
    local mHave = {}
    local mAG = self:MakeMonsterList(1001,1016)
    mAG = list_combine(mAG,self:MakeMonsterList(1101,1117))
    local mBG = self:MakeMonsterList(1021,1037)
    mBG = list_combine(mBG,self:MakeMonsterList(1201,1216))
    local mCG = self:MakeMonsterList(1041,1046)
    if iWave == 1 then
        mList = self:GenerateList(mAG,3,mDel)
    elseif iWave == 2 then
        mList = self:GenerateList(mBG,1,mDel)
        mList = list_combine(mList,self:GenerateList(mAG,2,mDel))
    elseif iWave == 3 then
        mList = self:GenerateList(mBG,2,mDel)
        mList = list_combine(mList,self:GenerateList(mCG,1,mDel))
    end
    for iNo,iMosterID in pairs(mList) do
        if iWave == 3 then
            if iNo == 3 then
                table.insert(mWareData,{monsterid=iMosterID*100+7,count=1})
            else
                table.insert(mWareData,{monsterid=iMosterID*100+#mWareData+3,count=1})
                table.insert(mWareData,{monsterid=iMosterID*100+#mWareData+3,count=1})
            end
        else
            table.insert(mWareData,{monsterid=iMosterID*100+#mWareData+1,count=1})
            table.insert(mWareData,{monsterid=iMosterID*100+#mWareData+1,count=1})
        end
        if iMosterID > 1040 and iMosterID <= 1046 then
            table.insert(mHave,iMosterID)
        end
    end

    return mWareData,mHave
end

function CHuodong:ShowFBMonster(oPlayer,iNpcIdx)
    local idx = iNpcIdx - 1000
    local mMonsterData = self.m_MonsterList[idx]
    local monsterlist = {}
    for iWave,mInfo in pairs(mMonsterData) do
        local shapelist = {}
        for iNo,mInfo2 in pairs(mInfo) do
            local iMosterID = mInfo2["monsterid"] // 100
            local mData = self:GetMonsterData(iMosterID)
            if iNo%2 == 1 then
                table.insert(shapelist,mData["model_id"])
            end
        end
        table.insert(monsterlist,{shapelist=shapelist})
    end
    local npclist = {}
    for iNo=1001,1004 do
        local mData = self:GetNpcBossInfo(iNo)
        mData.dead = false
        table.insert(npclist,mData)
    end
    oPlayer:Send("GS2CYJFubenView",{monsterlist=monsterlist,npclist=npclist})
end

function CHuodong:ConfigFightMonster()
    local mMonsterData = {}
    local mDel = {}
    for iNpc=1,4 do
        local mTmp = {}
        for iWave=1,3 do
            local mData,mHave = self:ConfigMosterDetail(iWave,mDel)
            mDel=list_combine(mDel,mHave)
            table.insert(mTmp,mData)
        end
        table.insert(mMonsterData,mTmp)
    end
    self:Dirty()
    self.m_MonsterList = mMonsterData
    record.user("yjfuben","monster",{info=ConvertTblToStr(mMonsterData)})
end

function CHuodong:GetWarMonster(oWar,iFight)
    local iPid = oWar:GetData("CreatePid")
    local iNpc = iFight - 1000
    return self.m_MonsterList[iNpc]
end

function CHuodong:PacketNpcInfo(iNpcIdx)
    local mArgs = super(CHuodong).PacketNpcInfo(self,iNpcIdx)
    local iNpc = iNpcIdx - 1000
    local mData = self.m_MonsterList[iNpc]
    local mTmp = mData[3][5]
    local monsterid = mTmp["monsterid"] // 100
    local mData = self:GetMonsterData(monsterid)
    local mModel = mArgs.model_info
    mModel.shape = mData["model_id"] or mModel.shape
    mModel.adorn = mData["ornament_id"] or mModel.adorn
    mModel.weapon = mData["wpmodel"] or mModel.weapon
    mModel.color = mData["mutate_color"] or mModel.color
    mModel.mutate_texture = mData["mutate_texture"] or mModel.mutate_texture
    mArgs.model_info = mModel
    mArgs.name = mData["name"] or mArgs.name
    local mNpcData = self:GetTempNpcData(iNpcIdx)
    mArgs.pos_info.face_y = mNpcData["rotateY"] or mArgs.pos_info.face_y
    return mArgs
end

function CHuodong:GetNpcBossInfo(iNpcIdx)
    local mNet = {idx=iNpcIdx}
    local iNpc = iNpcIdx - 1000
    local mData = self.m_MonsterList[iNpc]
    local mTmp = mData[3][5]
    local monsterid = mTmp["monsterid"] // 100
    local mData = self:GetMonsterData(monsterid)
    mNet.bossid = monsterid
    mNet.name = mData.name
    mNet.shape = mData.model_id
    return mNet
end

function CHuodong:TransMonsterAble(oWar,sAttr,mArgs)
    local iPid = oWar:GetData("CreatePid")
    local oGame = self:GetGameObj(iPid)
    if not oGame then return 100000 end
    local mEnv = mArgs.env or {}

    local iDiff = oGame:GetDiffType()
    local iNpcNum = math.max(5-oGame:GetLiveNpcNum(),1)
    local iWave = mEnv.wave or 1

    local res = require "base.res"
    local mOther = res["daobiao"]["huodong"]["yjfuben"]["other"]
    local iKey = iDiff * 100 + iNpcNum * 10 + iWave
    local mConfig = mOther[iKey] or {}
    local iMul = tonumber(mConfig.mul) or 1

    mEnv.mul = iMul
    mArgs.env = mEnv

    return math.floor(super(CHuodong).TransMonsterAble(self,oWar,sAttr,mArgs))
end

function CHuodong:CreateMonster(oWar,iMonsterIdx,npcobj, mArgs)
    local iPos = iMonsterIdx % 100
    iMonsterIdx = iMonsterIdx // 100
    local oMonster = super(CHuodong).CreateMonster(self,oWar,iMonsterIdx,npcobj,mArgs)
    oMonster:SetAttr("pos",iPos)
    return oMonster
end


function CHuodong:LookShiZhe(npcobj,oPlayer)
    if oPlayer:GetGrade() < self:GetGradeLimit(1) then
        local sText = npcobj:GetText()
        npcobj:Say(oPlayer:GetPid(),sText)
        return
    end
    self:GS2CMainYJFuben(oPlayer)
end

function CHuodong:GetTollGateData(iFight)
    local res = require "base.res"
    local mData = res["daobiao"]["tollgate"]["yjfuben"][iFight]
    return mData
end

function CHuodong:OnLogin(oPlayer,reenter)
    self:GS2CEnterYJFuben(oPlayer)
end

function CHuodong:OnLogout(oPlayer)
    if self:GetGameObj(oPlayer:GetPid()) and oPlayer:HasTeam() then
        netteam.C2GSLeaveTeam(oPlayer)
    end
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
        self:ConfigFightMonster()
    end
end

function CHuodong:GetGradeLimit(iType)
    local res = require "base.res"
    local mGradeLimit = res["daobiao"]["huodong"]["yjfuben"]["gradelimit"]
    return mGradeLimit[iType]["grade"]
end

function CHuodong:ValidEnterGame(oPlayer, iType)
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsClose("yjfuben") then
        oPlayer:NotifyMessage("该功能正在维护，已临时关闭。请您留意系统公告。")
        return false
    end

    local iLimit = self:GetGradeLimit(iType)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        if oTeam:HasShortLeave() then
            oPlayer:NotifyMessage(self:GetTextData(1003))
            return false
        end
        if oTeam:HasOffline() then
            oPlayer:NotifyMessage("队伍中有离线队员")
            return false
        end
        local mem = oTeam:GetTeamMember()
        local lName = {}
        for _,mid in pairs(mem) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem and oMem:GetGrade() < iLimit then
                table.insert(lName,oMem:GetName())
            end
        end
        local bValid = true
        if #lName > 0 then
            local sText = self:GetTextData(1002)
            sText = string.gsub(sText,"$username",list_join(lName,"、"))
            sText = string.gsub(sText,"$grade",iLimit)

            for _,mid in pairs(mem) do
                local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
                if oMem then
                    oMem:NotifyMessage(sText)
                end
            end
            bValid = false
        end
        lName = {}
        for _,mid in pairs(mem) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem and self:GetYJFuBenCnt(oMem) >= self:GetYJFuBenLimit(oMem) then
                table.insert(lName,oMem:GetName())
            end
        end
        if #lName > 0 then
            local sText = self:GetTextData(1004)
            sText = string.gsub(sText,"$username",list_join(lName,"、"))
            oPlayer:NotifyMessage(sText)
            for _,mid in pairs(mem) do
                local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
                if oMem and self:GetYJFuBenCnt(oMem) >= self:GetYJFuBenLimit(oMem) then
                    self:GS2CMainYJFuben(oMem,2)
                end
            end
            bValid = false
        end
        if not bValid then
            return false
        end
        for _,mid in pairs(mem) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem and self:GetGameObj(oMem:GetPid()) then
                table.insert(lName,oMem:GetName())
            end
        end
        if #lName > 0 then
            local sText = self:GetTextData(1005)
            sText = string.gsub(sText,"$username",list_join(lName,"、"))
            oPlayer:NotifyMessage(sText)
            return false
        end
    else
        if oPlayer:GetGrade() < iLimit then
            local sText = self:GetTextData(1001)
            sText = string.gsub(sText,"$grade",iLimit)
            oPlayer:NotifyMessage(sText)
            return false
        end
        if self:GetYJFuBenCnt(oPlayer) >= self:GetYJFuBenLimit(oPlayer) then
            oPlayer:NotifyMessage("本日挑战次数已达到上限")
            return false
        end
        if self:GetGameObj(oPlayer:GetPid()) then
            oPlayer:NotifyMessage("您已经在副本中")
            return false
        end
    end

    return true
end

function CHuodong:GetGameObj(iPid)
    local iGameID = self:GetPlayerGameID(iPid)
    if iGameID then
        return self.m_GameList[iGameID]
    end
end

function CHuodong:ClearGameObj(iPid)
    local iGameID = self:GetPlayerGameID(iPid)
    if not iGameID then
        record.warning("player no GameID ".. iPid)
        return
    end
    local oGame = self.m_GameList[iGameID]
    self.m_GameList[iGameID] = nil
    if oGame then
        baseobj_safe_release(oGame)
    end
end

function CHuodong:ResetFuBenInfo(oPlayer)
    oPlayer.m_oThisTemp:Delete("yj_boss")
    oPlayer.m_oThisTemp:Delete("yj_point")
    oPlayer.m_oThisTemp:Set("yj_boss", 0 , 4000)
    oPlayer.m_oThisTemp:Set("yj_point", 0 , 4000)
end

function CHuodong:SendReward(lRankData,lPreRankData)
    local oTitleMgr = global.oTitleMgr
    for _, mData in ipairs(lPreRankData) do
        local iRank = mData.rank
        local iPid = mData.pid
        if iRank == 1 then
            oTitleMgr:RemoveTitles(iPid, {1014})
        elseif iRank == 2 then
            oTitleMgr:RemoveTitles(iPid, {1015})
        elseif iRank == 3 then
            oTitleMgr:RemoveTitles(iPid, {1016})
        end
    end
    for _, mData in ipairs(lRankData) do
        local iRank = mData.rank
        local iPid = mData.pid
        if iRank <= 10 then
            global.oAchieveMgr:PushAchieve(iPid,"梦魇狩猎结算时排名小于10次数",{value=1})
        end
        if iRank == 1 then
            self:RewardItemInYJ(iPid,3001,iRank)
            oTitleMgr:AddTitle(iPid, 1014)
        elseif iRank == 2 then
            self:RewardItemInYJ(iPid,3002,iRank)
            oTitleMgr:AddTitle(iPid, 1015)
        elseif iRank == 3 then
            self:RewardItemInYJ(iPid,3003,iRank)
            oTitleMgr:AddTitle(iPid, 1016)
        elseif iRank <=10 and iRank>=4 then
            self:RewardItemInYJ(iPid,3004,iRank)
        elseif iRank <= 20 and iRank >= 11 then
            self:RewardItemInYJ(iPid,3005,iRank)
        end
    end
end

function CHuodong:RewardItemInYJ(iPid,idx,iRank)
    local mReward = self:GetItemRewardData(idx)
    mReward = mReward[1]

    local mItem = {}
    for _,info in pairs(mReward) do
        for _,oItem in pairs(self:BuildRewardItemList(info,info["sid"],{pid=iPid})) do
            table.insert(mItem,oItem)
        end
    end
    local oMailMgr = global.oMailMgr
    local mData, name = oMailMgr:GetMailInfo(27)
    mData.context = string.gsub(mData.context,"$rank",iRank)
    oMailMgr:SendMail(0, name, iPid, mData, {}, mItem)
end

function CHuodong:GenGameID()
    self.m_GameID = self.m_GameID + 1
    if self.m_GameID > 10000000 then
        self.m_GameID = 1
    end
    return self.m_GameID
end

function CHuodong:SetPlayerGameID(iPid,iGameID)
    self.m_Player2GameID[iPid] = iGameID
end

function CHuodong:ClearPlayerGameID(iPid)
    self.m_Player2GameID[iPid] = nil
end

function CHuodong:GetPlayerGameID(iPid)
    return self.m_Player2GameID[iPid]
end

function CHuodong:OpenTeamEnterUI(oPlayer,iType)
    local oTeam = oPlayer:HasTeam()
    local mMem = oPlayer:GetTeamMember()
    local sMsg = "是否进入【"..self:GetDiffName(iType).."】梦魇副本？"
    local mNet = {
        msg = sMsg,
        mem = {},
        stype = "yjfuben",
        timeout = 15,
    }

    local func = function(oP,mArgs)
        local iAnswer = mArgs.answer
        if iAnswer then
                local oHuodongMgr = global.oHuodongMgr
                local oHuodong = oHuodongMgr:GetHuodong("yjfuben")
                if oHuodong then
                    oHuodong:TeamEnterOption(oP,iAnswer,sMsg,mMem,iType)
                end
        end
    end

    local oWorldMgr = global.oWorldMgr
    for _,iMid in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(iMid)
        if oMem then
            oMem:Send("GS2CTeamEnterGameUIClose",{})
            table.insert(mNet.mem,{info=oMem:PackSimpleRoleInfo(),state=0})
        end
    end

    oTeam.m_YjEnterEnsure = {}
    oTeam.m_YjRefuse = {}

    local oCbMgr = global.oCbMgr
    for _,iMid in pairs(mMem) do
        oCbMgr:SetCallBack(iMid,"GS2CTeamEnterGameUI",mNet,nil,func)
    end

    local iPid = oPlayer:GetPid()
    local iTeamID = oTeam:TeamID()
    local sTimeFlag = "YJTeamEnterOver"..iTeamID
    if self:GetTimeCb(sTimeFlag) then
        return
    end
    self:AddTimeCb(sTimeFlag, 15*1000, function ()
        self:DelTimeCb(sTimeFlag)
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:TeamEnterEnd(oPlayer,mMem)
        end
    end)
end

function CHuodong:TeamEnterOption(oPlayer,iAnswer,sMsg,mMem,iType)
    local iPid = oPlayer:GetPid()
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local iTeamID = oTeam:TeamID()
    local sTimeFlag = "YJTeamEnterOver"..iTeamID
    if not  self:GetTimeCb(sTimeFlag) then
        return
    end

    local mEnsure = oTeam.m_YjEnterEnsure
    local mRefuse = oTeam.m_YjRefuse
    if iAnswer == 1  then
        table.insert(mEnsure,iPid)
    else
        table.insert(mRefuse,iPid)
        oTeam:NotifyAllMem(oPlayer:GetName().."拒绝进入")
    end
    local mNet = {
        msg = sMsg,
        mem = {},
        stype = "yjfuben",
    }
    local oWorldMgr = global.oWorldMgr
    for _,iMid in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(iMid)
        if oMem then
            local iState = 0
            if table_in_list(mEnsure,iMid) then
                iState = 1
            elseif table_in_list(mRefuse,iMid) then
                iState = 2
            end
            table.insert(mNet.mem,{info=oMem:PackSimpleRoleInfo(),state=iState})
        end
    end

    for _,iMid in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(iMid)
        if oMem then
            oMem:Send("GS2CUpdateTeamEnterGameUI",mNet)
        end
    end

    if #mEnsure >= #mMem then
        self:DelTimeCb(sTimeFlag)
        for _,iMid in pairs(mMem) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(iMid)
            if oMem then
                oMem:Send("GS2CTeamEnterGameUIClose",{})
            end
        end
        local oLeader = oPlayer:GetTeamLeader()
        if not self:ValidEnterGame(oLeader,iType) then
            return
        end
        if oLeader then
            self:EnterGame2(oLeader,iType)
        end
    elseif #mEnsure + #mRefuse >= #mMem then
        self:DelTimeCb(sTimeFlag)
        for _,iMid in pairs(mMem) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(iMid)
            if oMem then
                oMem:Send("GS2CTeamEnterGameUIClose",{})
            end
        end
    end
end

function CHuodong:TeamEnterEnd(oLeader,mMem)
    local oTeam = oLeader:HasTeam()
    if not oTeam then
        return
    end
    local mEnsure = oTeam.m_YjEnterEnsure
    local mRefuse = oTeam.m_YjRefuse
    local oWorldMgr = global.oWorldMgr
    for _,iMid in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(iMid)
        if oMem then
            oMem:Send("GS2CTeamEnterGameUIClose",{})
            if not table_in_list(mEnsure,iMid) and not table_in_list(mRefuse,iMid) then
                oTeam:NotifyAllMem(oMem:GetName().."拒绝进入")
            end
        end
    end
end

function CHuodong:ValidOption(oPlayer)
    if oPlayer:HasTeam() and not oPlayer:IsTeamLeader() then
        oPlayer:NotifyMessage("只有队长及个人才能进行此操作")
        return false
    end
    return true
end

function CHuodong:EnterGame(oPlayer,iType)
    if not self:ValidOption(oPlayer) then
        return
    end
    if not self:ValidEnterGame(oPlayer,iType) then
        return
    end
    if oPlayer:HasTeam() then
        self:OpenTeamEnterUI(oPlayer,iType)
    else
        self:EnterGame2(oPlayer,iType)
    end
end

function CHuodong:EnterGame2(oPlayer,iType)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        oTeam:CancleAutoMatch()
    end

    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()

    local iGameID = self:GenGameID()
    local oGame = NewGame(iGameID,{iType=iType})
    local mem = oPlayer:GetTeamMember()
    if mem then
        oGame:SetTeamGame()
    else
        mem = {iPid}
    end
    self.m_GameList[iGameID] = oGame
    oGame:CreateHDScene()
    oGame:EnterScene(oPlayer)
    for _,mid in pairs(mem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
        if oMem then
            self:SetPlayerGameID(oMem:GetPid(),iGameID)
            self:ResetFuBenInfo(oMem)
            self:GS2CEnterYJFuben(oMem)
            global.oAchieveMgr:PushAchieve(mid,"进入梦魇副本次数",{value=1})
            record.user("yjfuben","entergame",{pid=mid})
        end
    end

    local sTimeFlag = "YJFubenEnd"..iGameID
    self:DelTimeCb(sTimeFlag)
    self:AddTimeCb(sTimeFlag, 3600*1000, function ()
        self:DelTimeCb(sTimeFlag)
        self:FubenKick(iGameID,true)
    end)
end

function CHuodong:FubenKick(iGameID,bTips)
    local oGame = self.m_GameList[iGameID]
    if not oGame then return end

    local oWorldMgr = global.oWorldMgr
    local oScene = oGame:GetScene()
    local mPlayer = oScene:GetPlayers()
    for _,mid in pairs(mPlayer) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
        if oMem then
            oMem:NotifyMessage("副本时间已到")
            local oWar = oMem.m_oActiveCtrl:GetNowWar()
            if oWar and oWar.m_YJFuBen then
                oWar:TestCmd("warend",oMem:GetPid(),{war_result=2})
            end
        end
    end
    local sTimeFlag = "YJFubenLeave"..iGameID
    self:DelTimeCb(sTimeFlag)
    self:AddTimeCb(sTimeFlag, 2*1000, function ()
        self:DelTimeCb(sTimeFlag)
        local oWorldMgr = global.oWorldMgr
        for _,mid in pairs(mPlayer) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
            if oMem and oMem:IsTeamLeader() then
                self:LeaveFuBen(oMem)
            elseif oMem and not oMem:HasTeam() then
                self:LeaveFuBen(oMem)
            end
        end
    end)
end

function CHuodong:GetWarConfig(sKey,mData,oPlayer,...)
    if sKey == "war_config" then
        if oPlayer and oPlayer.m_YJAutoWar then
            return 0
        end
    end
    return super(CHuodong).GetWarConfig(self,sKey,mData,oPlayer,...)
end

function CHuodong:ConfigWar(oWar,pid,npcobj,iFight,mInfo)
    oWar.m_YJFuBen = true
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer and not oPlayer.m_YJAutoWar then
        oWar.m_NeedConfig = true
    end
end

function CHuodong:BalancePoint(oPlayer,mArgs)
    local oGame = self:GetGameObj(oPlayer:GetPid())
    local iWave = mArgs.current_wave
    if oGame and iWave >= 3 then
        local iDiff = oGame:GetDiffType()
        local iPoint = (iDiff-1)*100 + iWave * 100
        self:AddYJPoint(oPlayer,iPoint)
        if self:IsFightWinAllBoss(oPlayer) then
            local iRest = 3600 - oGame:GetCostTime()
            iRest = math.max(iRest,0)
            iPoint = iRest // 60 * 10
            self:AddYJPoint(oPlayer,iPoint)
        end
    end
end

function CHuodong:GetCreateWarArg(mArg)
    local mArg2 = table_copy(mArg)
    mArg2.remote_war_type = "yjfuben"
    mArg2.war_type = gamedefines.WAR_TYPE.YJFUBEN_TYPE
    return mArg2
end

function CHuodong:CreateWar(pid,npcobj,iFight,mInfo)
    local oWar = super(CHuodong).CreateWar(self,pid,npcobj,iFight,mInfo)
    oWar.m_iLeaveType = 2
    return oWar
end

function CHuodong:ValidFight(pid,npcobj,iFight)
    if pid then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        local oGame = self:GetGameObj(pid)
        if oPlayer and oGame then
            if oGame:IsTeamGame() and not oPlayer:IsTeamLeader() then
                oPlayer:NotifyMessage("只有队长能进行此操作")
                return false
            end
            if oGame:IsTeamGame() and oPlayer:HasShortLeave() then
                oPlayer:NotifyMessage("队伍中尚有暂离队员")
                return false
            end
            if not oGame:IsTeamGame() and oPlayer:HasTeam() then
                return false
            end
        end
    end
    return super(CHuodong).ValidFight(self,pid,npcobj,iFight)
end

function CHuodong:WinHandlePlayer(oPlayer, iFight, iNpcIdx, mArgs)
    local iPid = oPlayer:GetPid()
    local oGame = self:GetGameObj(iPid)
    if oGame then
        local iDiff = oGame:GetDiffType()
        iFight = 1000 * iDiff + iFight % 1000
    end
    local mFight = self:GetTollGateData(iFight)
    local mReward = mFight["rewardtbl"]
    for _,info in ipairs(mReward) do
        self:Reward(oPlayer:GetPid(),info["rewardid"])
    end
    if iNpcIdx then
        self:ChangeBoosFlag(oPlayer,iNpcIdx)
    end
    self:BalancePoint(oPlayer,mArgs)
    if self:IsFightWinAllBoss(oPlayer) then
        self:PushRankData(oPlayer)
        global.oAchieveMgr:PushAchieve(iPid,"通关梦魇副本次数",{value=1})
    end
    self:MarkFitMosterFlag(oPlayer,iNpcIdx)
    if mArgs.bout and mArgs.bout <= 10 then
        global.oAchieveMgr:PushAchieve(iPid,"消灭梦魇回合数小于10次数",{value=1})
    end
    global.oAchieveMgr:PushAchieve(iPid,"击败梦魇怪物次数",{value=1})
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30030,1)
    oPlayer:AddSchedule("yjfuben")
    self:LogAnalyGame("yjfuben",oPlayer)
end

function CHuodong:OnWarEnd(oWar, iPid, oNpc, mArgs, bWin)
    mArgs = mArgs or {}
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end
    if bWin then
        local oGame = self:GetGameObj(oPlayer:GetPid())
        if oGame and mArgs.current_wave >= 3 then
            oGame:AddCostTime(get_time() - mArgs.star_time)
        end
    end
    local iFight = oWar.m_FightIdx
    local iNpcIdx
    if oNpc then
        iNpcIdx = oNpc.m_NpcIdx
    end
    local mem = oPlayer:GetTeamMember()
    mem = mem or {iPid}
    for _,mid in pairs(mem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
        if oMem then
            if bWin then
                self:WinHandlePlayer(oMem,iFight,iNpcIdx,mArgs)
            end
            self:GS2CEnterYJFuben(oMem)
        end
    end
    if bWin then
        if oPlayer.m_YJAutoWar then
            self:AutoWar(oPlayer)
        end
    elseif not bWin then
        self:CanCelAutoWar(oPlayer)
    end
    self:CheckFinnalWar(oPlayer)
end

function CHuodong:CheckFinnalWar(oPlayer)
    local iPid = oPlayer:GetPid()
    local oGame = self:GetGameObj(iPid)
    if not self:IsFightWinAllBoss(oPlayer) or not oGame then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local iDiff = oGame:GetDiffType()
    local mMem = oPlayer:GetTeamMember()
    mMem = mMem or {iPid}
    for _,mid in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
        if oMem then
            oMem.m_oThisTemp:Set("yj_fanpai",iDiff,20)
        end
    end

    local iScendID = oPlayer.m_oActiveCtrl:GetNowSceneID()
    local sTimeFlag = "QuitYJ"..iPid
    self:AddTimeCb(sTimeFlag, 10*1000, function ()
        self:DelTimeCb(sTimeFlag)
        local oWorldMgr = global.oWorldMgr
        local oScene = self:GetHDScene(iScendID)
        if oScene then
            local mMem = oScene:GetPlayers() or {}
            for _,mid in ipairs(mMem) do
                local oMem = oWorldMgr:GetOnlinePlayerByPid(mid)
                if oMem and self:GetGameObj(mid) then
                    self:FanPaiStart(oMem)
                end
                if oMem and oMem:IsTeamLeader() then
                    self:LeaveFuBen(oMem)
                elseif oMem and oMem:IsSingle() then
                    self:LeaveFuBen(oMem)
                end
            end
        end
    end)
end

function CHuodong:MarkFitMosterFlag(oPlayer,iNpcIdx)
    if not iNpcIdx then return end
    local mNet = {idx=iNpcIdx}
    local iNpc = iNpcIdx - 1000
    local mData = self.m_MonsterList[iNpc]
    local iFlag = oPlayer.m_oActiveCtrl:GetData("yj_fitflag",0)
    local iTotal = (1<<39) - 1
    if iTotal <= iFlag then
        return
    end
    local mRecord = {}
    for iWave,mMonster in pairs(mData) do
        for _,mInfo in pairs(mMonster) do
            local iMosterID = mInfo["monsterid"] // 100
            table.insert(mRecord,iMosterID)
            if iMosterID >= 1041 then
                iMosterID = iMosterID - 7
            elseif iMosterID >= 1021 then
                iMosterID = iMosterID - 4
            end
            local idx = iMosterID - 1001
            if idx>=0 and idx<39 then
                iFlag = iFlag | (1<<idx)
            end
        end
    end
    oPlayer.m_oActiveCtrl:SetData("yj_fitflag",iFlag)
    if iTotal == iFlag then
        global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"消灭梦魇狩猎中所有怪物次数",{value=1})
    end

    record.user("yjfuben","beatboss",{pid=oPlayer:GetPid(),info=ConvertTblToStr(mRecord)})
end

function CHuodong:GetDiffDoublingRatio()
    local res = require "base.res"
    local mDoubling = res["daobiao"]["huodong"]["yjfuben"]["doubling"]
    local mResult = {}
    for _,mInfo in ipairs(mDoubling) do
        table.insert(mResult,mInfo.ratio)
    end
    return mResult
end

function CHuodong:FanPaiStart(oPlayer)
    local iDiff = oPlayer.m_oThisTemp:Query("yj_fanpai")
    if not iDiff then
        return
    end
    oPlayer.m_oThisTemp:Delete("yj_fanpai")
    local iReward
    if iDiff == 1 then
        iReward = 2001
    elseif iDiff == 2 then
        iReward = 2002
    elseif iDiff == 3 then
        iReward = 2003
    end
    local mRewardItem = table_copy(self:GetItemRewardData(iReward))
    mRewardItem = mRewardItem[1]
    local func = function (oPlayer,oGame)
        local mItem = oGame:GetEarnItem()
        oPlayer:LogAnalyGame({},"yjfanpai",mItem)
    end
    local mArgs = {
        pid = oPlayer:GetPid(),
        num = 4,
        rewarditem = mRewardItem,
        reason = "月见行者翻牌",
        overtime = 15,
        endgame = func,
        mul = 3,
        addratio = self:GetDiffDoublingRatio(),
        tip = self:GetTextData(1006),
    }
    local oTeam = oPlayer:HasTeam()
    mArgs.mem = {oPlayer:GetPid()}
    if oTeam then
        mArgs.mem = oTeam:GetTeamMember()
    end
    global.oMiniGameMgr:GameStart(oPlayer,"drawcard",mArgs)
end

function CHuodong:PushRankData(oPlayer)
    local mData = {}
    mData.pid = oPlayer:GetPid()
    mData.name = oPlayer:GetName()
    mData.shape = oPlayer:GetModelInfo().shape
    mData.school = oPlayer:GetSchool()
    mData.point = self:GetYJPoint(oPlayer)
    mData.time = get_time()
    if mData.point <= 0 then
        return
    end
    global.oRankMgr:PushDataToRank("yjfuben", mData)
end

function CHuodong:GS2CMainYJFuben(oPlayer,iType)
    iType = iType or 1
    local mNet = {
        remain_times = self:GetYJFuBenLimit(oPlayer)-self:GetYJFuBenCnt(oPlayer),
        buy_times = math.max(MAX_BUY_CNT-self:GetYJBuyCnt(oPlayer) ,0),
        type = iType,
    }
    oPlayer:Send("GS2CMainYJFuben",mNet)
end

function CHuodong:FindGameNpc(oPlayer,iNpcIdx)
    local oGame = self:GetGameObj(oPlayer:GetPid())
    if oGame then
        oGame:FindGameNpc(oPlayer,iNpcIdx)
    end
end

function CHuodong:GetDiffName(iType)
    if iType == 1 then
        return "普通"
    elseif iType ==  2 then
        return "困难"
    elseif iType ==  3 then
        return "地狱"
    end
end

function CHuodong:GS2CEnterYJFuben(oPlayer)
    local mNet = {}
    local oGame = self:GetGameObj(oPlayer:GetPid())
    if oGame then
        local iType = oGame:GetDiffType()
        mNet.npclist = oGame:PackNpcList()
        mNet.end_time = oGame:GetEndTime()
        mNet.autowar = oPlayer.m_YJAutoWar and true or false
        mNet.stip = "梦魇副本　"..self:GetDiffName(iType)
        oPlayer:Send("GS2CEnterYJFuben",mNet)
    end
end

function CHuodong:AddYJPoint(oPlayer,iPoint)
    oPlayer.m_oThisTemp:Add("yj_point",iPoint)
    record.user("yjfuben","addpoint",{pid=oPlayer:GetPid(),add=iPoint,point=self:GetYJPoint(oPlayer)})
end

function CHuodong:GetYJPoint(oPlayer)
    return oPlayer.m_oThisTemp:Query("yj_point",0)
end

function CHuodong:AddYJFuBenCnt(oPlayer)
    if oPlayer.m_oThisTemp:Query("yj_boss",0) <= 0 then
        return
    end
    oPlayer.m_oToday:Add("yj_cnt",1)
    record.user("yjfuben","fubencnt",{pid=oPlayer:GetPid(),cnt=self:GetYJFuBenCnt(oPlayer)})
end

function CHuodong:GetYJFuBenCnt(oPlayer)
    return oPlayer.m_oToday:Query("yj_cnt",0)
end

function CHuodong:AddYJFuBenLimit(oPlayer,iAmount)
    if oPlayer.m_oToday:Query("yj_cnt_limit",0) == 0 then
        oPlayer.m_oToday:Add("yj_cnt_limit",2)
    end
    oPlayer.m_oToday:Add("yj_cnt_limit",iAmount)
    record.user("yjfuben","cntlimit",{pid=oPlayer:GetPid(),limit=self:GetYJFuBenLimit(oPlayer)})
end

function CHuodong:GetYJFuBenLimit(oPlayer)
    local iCnt = oPlayer.m_oToday:Query("yj_cnt_limit",2)
    local oHuodong = global.oHuodongMgr:GetHuodong("charge")
    local mConfig = oHuodong:GetPrivilege()["yjfuben"]
    if oPlayer:IsMonthCardVip() then
        iCnt = iCnt + mConfig["yk"]
    end
    if oPlayer:IsZskVip() then
        iCnt = iCnt + mConfig["zsk"]
    end
    return  iCnt
end

function CHuodong:AddYJBuyCnt(oPlayer,iAmount)
   oPlayer.m_oToday:Add("yj_buy",iAmount)
end

function CHuodong:GetYJBuyCnt(oPlayer)
    return oPlayer.m_oToday:Query("yj_buy",0)
end

function CHuodong:YJFuBenBuyCnt(oPlayer,iAmount)
    if self:GetYJBuyCnt(oPlayer) + iAmount > MAX_BUY_CNT then
        oPlayer:NotifyMessage("超过购买上限")
        return
    end
    local iCost = iAmount*180
    if not oPlayer:ValidGoldCoin(iCost) then
        return
    end
    oPlayer:ResumeGoldCoin(iCost, "高级副本购买次数")
    self:AddYJBuyCnt(oPlayer,iAmount)
    self:AddYJFuBenLimit(oPlayer,iAmount)
    oPlayer:NotifyMessage("购买成功")
    self:GS2CMainYJFuben(oPlayer)
end

function CHuodong:YJFuBenOp(oPlayer,iAction)
    if iAction == 2 and oPlayer:HasTeam() and not oPlayer:IsTeamLeader() then
        netteam.C2GSLeaveTeam(oPlayer)
        return
    end
    if table_in_list({1,2,3},iAction) and not self:ValidOption(oPlayer) then
        return
    end
    if iAction == 1 then
        self:AutoWar(oPlayer)
        self:GS2CEnterYJFuben(oPlayer)
    elseif iAction == 2 then
        self:LeaveFuBen(oPlayer)
    elseif iAction == 3 then
        self:CanCelAutoWar(oPlayer)
        self:GS2CEnterYJFuben(oPlayer)
    elseif iAction == 4 then
        self:FanPaiStart(oPlayer)
    end
end

function CHuodong:AutoWar(oPlayer)
    local oGame = self:GetGameObj(oPlayer:GetPid())
    if not oGame then
        return
    end
    oPlayer.m_YJAutoWar = true
    oGame:AutoWar(oPlayer)
end

function CHuodong:CanCelAutoWar(oPlayer)
    oPlayer.m_YJAutoWar = nil
end

function CHuodong:HaveWinBoss(oPlayer,iNpcIdx)
    local iFlag = oPlayer.m_oThisTemp:Query("yj_boss",0)
    local idx = iNpcIdx - 1000
    idx = 1 << (idx - 1)
    iFlag = iFlag & idx
    if iFlag > 0 then
        return true
    end
    return false
end

function CHuodong:ChangeBoosFlag(oPlayer,iNpcIdx)
    local iFlag = oPlayer.m_oThisTemp:Query("yj_boss",0)
    local idx = iNpcIdx - 1000
    idx = 1 << (idx-1)
    iFlag = iFlag | idx
    oPlayer.m_oThisTemp:Set("yj_boss",iFlag)
end

function CHuodong:IsFightWinAllBoss(oPlayer)
    return oPlayer.m_oThisTemp:Query("yj_boss",0) == 15
end

function CHuodong:LeaveFuBen(oPlayer)
    self:GobackRealScene(oPlayer:GetPid())
end

function CHuodong:TestOP(oPlayer,iFlag,...)
    if iFlag == 100 then
        -- local oChatMgr = global.oChatMgr
        -- oChatMgr:HandleMsgChat(oPlayer,"101-创建场景并进入")
    elseif iFlag == 102 then
        self:ConfigFightMonster()
    elseif iFlag == 103 then
        local iDiff = tonumber(...)
        oPlayer.m_oThisTemp:Set("yj_fanpai",iDiff,20)
        self:FanPaiStart(oPlayer)
    elseif iFlag == 104 then
        oPlayer.m_TestYj = true
    elseif iFlag == 105 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
    elseif iFlag == 106 then
        self:GS2CMainYJFuben(oPlayer,2)
    end
end

function NewGame(pid,mArg)
    return CGame:New(pid,mArg)
end

CGame = {}
CGame.__index = CGame
inherit(CGame, datactrl.CDataCtrl)

function CGame:New(pid,mArg)
    local o = super(CGame).New(self)
    o.m_ID = pid
    o.m_SceneID = 0
    o.m_NPCList= {}
    o.m_EndTime = get_time() + 3600
    o.m_DiffType = mArg.iType
    o.m_CostTime = 0
    o.m_bTeam = false
    return o
end

function CGame:SetTeamGame()
    self.m_bTeam = true
end

function CGame:IsTeamGame()
    return self.m_bTeam
end

function CGame:GetCostTime()
    return self.m_CostTime
end

function CGame:AddCostTime(iTime)
    iTime = math.min(iTime,100000)
    self.m_CostTime = self.m_CostTime + iTime
end

function CGame:GetDiffType()
    return self.m_DiffType
end

function CGame:GetEndTime()
    return self.m_EndTime
end

function CGame:Huodong()
    local oHuodongMgr = global.oHuodongMgr
    return oHuodongMgr:GetHuodong("yjfuben")
end

function CGame:CreateHDScene()
    if self.m_SceneID ~= 0 then
        return
    end
    local oHuodong = self:Huodong()
    local oScene = oHuodong:CreateVirtualScene(1001)
    oScene.m_fVaildLeave = VaildLeaveScene
    oScene.m_OnLeave = OnLeaveScene
    oScene.m_OnLeaveTeam = OnLeaveTeam
    oScene:SetLimitRule("team",1)
    oScene:SetLimitRule("transfer",1)
    oScene:SetLimitRule("shortleave",1)
    oScene:SetLimitRule("allowback",1)
    for iNo=1001,1004 do
        self:CreateNpc(iNo,oScene)
    end
    self.m_SceneID = oScene:GetSceneId()
end

function CGame:GetScene()
    if not self.m_SceneID then
        return
    end
    local oSceneMgr = global.oSceneMgr
    return oSceneMgr:GetScene(self.m_SceneID)
end

function CGame:ClearResource()
    local oHuodong = self:Huodong()
    for _,nid in pairs(self.m_NPCList) do
        local npcobj = oHuodong:GetNpcObj(nid)
        if npcobj then
            oHuodong:RemoveTempNpc(npcobj)
        end
    end
    self.m_SceneID = 0
    self.m_NPCList= {}
end

function CGame:Release()
    self:ClearResource()
    local oHuodong = self:Huodong()
    oHuodong:RemoveSceneById(self.m_SceneID)
    super(CGame).Release(self)
end

function CGame:EnterScene(oPlayer)
    local oHuodong = self:Huodong()
    oHuodong:TransferPlayerBySceneID(oPlayer:GetPid(),self.m_SceneID,20,1)
end

function CGame:CreateNpc(idx,oScene)
    local oHuodong = self:Huodong()
    local oSceneMgr = global.oSceneMgr
    local npcobj = oHuodong:CreateTempNpc(idx)
    npcobj.m_ShowMode = 0
    npcobj.m_NpcIdx = idx
    local x,y = oSceneMgr:RandomPos(oScene:MapId())
    self.m_NPCList[idx] = npcobj.m_ID
    local mPosInfo = npcobj:PosInfo()
    oHuodong:Npc_Enter_Scene(npcobj,oScene:GetSceneId(),mPosInfo)
    return npcobj
end

function CGame:AutoWar(oPlayer)
    local oHuodong = self:Huodong()
    local target,dis
    for _,nid in pairs(self.m_NPCList) do
        local npcobj = oHuodong:GetNpcObj(nid)
        if npcobj and not oHuodong:HaveWinBoss(oPlayer,npcobj.m_NpcIdx) then
            local mPos = npcobj:PosInfo()
            local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
            local dx = mNowPos.x - mPos.x
            local dy = mNowPos.y - mPos.y
            local len = dx*dx + dy*dy
            if not target then
                target = nid
                dis = len
            elseif dis > len then
                target = nid
                dis = len
            end
        end
    end
    if target then
        local npcobj = oHuodong:GetNpcObj(target)
        local oSceneMgr = global.oSceneMgr
        local mPos = npcobj:PosInfo()
        oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),npcobj.m_iMapid,mPos.x,mPos.y,npcobj.m_ID,1,1)
    end
end

function CGame:PackNpcList()
    local mNpc = {}
    local oHuodong = self:Huodong()
    for idx,nid in pairs(self.m_NPCList) do
        local npcobj = oHuodong:GetNpcObj(nid)
        local mData = oHuodong:GetNpcBossInfo(idx)
        if npcobj then
            mData.dead = false
        else
            mData.dead = true
        end
        table.insert(mNpc,mData)
    end
    return mNpc
end

function CGame:FindGameNpc(oPlayer,iNpcIdx)
    local oHuodong = self:Huodong()
    if not oHuodong:ValidOption(oPlayer) then
        return
    end
    local nid = self.m_NPCList[iNpcIdx]
    local oHuodong = self:Huodong()
    local npcobj = oHuodong:GetNpcObj(nid)
    if npcobj then
        local oSceneMgr = global.oSceneMgr
        local mPos = npcobj:PosInfo()
        oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),npcobj.m_iMapid,mPos.x,mPos.y,npcobj.m_ID,1,1)
    end
end

function CGame:GetLiveNpcNum()
    local iCnt = 0
    local oHuodong = self:Huodong()
    for _,nid in pairs(self.m_NPCList) do
        local npcobj = oHuodong:GetNpcObj(nid)
        if npcobj then
            iCnt = iCnt + 1
        end
    end
    return iCnt
end

-- 只有玩家离场才清理资源
function OnLeaveScene(oScene,oPlayer)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("yjfuben")
    local iPid = oPlayer:GetPid()
    local oGame = oHuodong:GetGameObj(iPid)
    if oGame then
        local oScene = oGame:GetScene()
        if oScene:GetPlayersCnt() <= 0 then
            oGame:ClearResource()
            oHuodong:ClearGameObj(iPid)
        end
        oHuodong:AddYJFuBenCnt(oPlayer)
        oHuodong:ClearPlayerGameID(iPid)
    else
        record.info("yjfuben have no game pid: "..iPid)
    end
    oPlayer:Send("GS2CLeaveYJFuben",{})
    oHuodong:CanCelAutoWar(oPlayer)
end

function OnLeaveTeam(oScene,oPlayer)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("yjfuben")
    if oHuodong then
        local iPid = oPlayer:GetPid()
        local sTimeFlag = "LeaveTime"..iPid
        oHuodong:DelTimeCb(sTimeFlag)
        oHuodong:AddTimeCb(sTimeFlag, 200, function ()
            oHuodong:DelTimeCb(sTimeFlag)
            local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oHuodong:LeaveFuBen(oPlayer)
            end
        end)
    end
end

function VaildLeaveScene(oScene,oPlayer)
    if oPlayer.m_YJCanFly then
        oPlayer.m_YJCanFly = nil
        return true
    end
    oPlayer:NotifyMessage("场景禁止传送")
    return false
end