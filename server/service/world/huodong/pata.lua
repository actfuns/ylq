--import module
local global  = require "global"
local extend = require "base.extend"
local res = require "base.res"
local record = require "public.record"
local interactive = require "base.interactive"

local analy = import(lualib_path("public.dataanaly"))
local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "地牢"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_SweepReward = {}
    o.m_SweepInfo = {}
    return o
end

function CHuodong:Init()
    self:TryStartRewardMonitor()
end

function CHuodong:NewHour(iWeekDay, iHour)
    if iHour == 0 then
        self:TryStopRewardMonitor()
        self:TryStartRewardMonitor()
    end
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Load(mData)
    mData = mData or {}
    self.m_SweepReward = mData["sweepreward"] or {}
    self.m_SweepInfo = mData["sweepinfo"] or {}
    self:AddTimeCb("LoadSweep", 5 * 1000, function ()
        self:LoadSweep()
    end)
end

function CHuodong:LoadSweep()
    self:DelTimeCb("LoadSweep")
    local iCurTime = get_time()
    for sPid,info in pairs(self.m_SweepInfo) do
        local iPid = tonumber(sPid)
        local iStart,iEnd,iTime,iTotal = table.unpack(info)
        local iEndTime = iTime+iTotal
        local iRest = iEndTime - iCurTime
        if iEndTime > iCurTime then
            local sTimeFlag = "PlayAction"..iPid
            self:AddTimeCb(sTimeFlag, iRest * 1000, function ()
                self:SweepFinish(iPid,iStart,iEnd)
            end)
        else
            self:SweepFinish(iPid,iStart,iEnd)
        end
    end
end

function CHuodong:Save()
    local mData = {}
    mData["sweepreward"] = self.m_SweepReward
    mData["sweepinfo"] = self.m_SweepInfo
    return mData
end

function CHuodong:KeepSwpRw(iPid,shapelist)
    self:Dirty()
    self.m_SweepReward[db_key(iPid)] = shapelist
end

function CHuodong:GetKeepSwpRw(iPid)
    return self.m_SweepReward[db_key(iPid)] or {}
end

function CHuodong:ValidLimit(oPlayer)
    local iLimitGrade = tonumber(res["daobiao"]["global"]["pata_grade"]["value"])
    local oNotifyMgr =global.oNotifyMgr
    if iLimitGrade > oPlayer:GetGrade() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"等级未达到")
        return true
    end
    if oPlayer:HasTeam() and not oPlayer:IsTeamShortLeave() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"组队中无法挑战地牢")
        return true
    end
    return false
end

function CHuodong:IsClose(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr =global.oNotifyMgr
    if oWorldMgr:IsClose("pata") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return true
    end
    return false
end

function CHuodong:C2GSPataOption(oPlayer,iOp,tArgs)
    local iPid = oPlayer:GetPid()
    if iOp == 1 then
        self:OpenPataUI(oPlayer)
    elseif iOp == 2 then
        self:ResetPataCnt(oPlayer)
    elseif iOp == 3 then
        local _,iLevel = self:GetPlayerSweepInfo(iPid)
        if iLevel and iLevel > 0 then
            oPlayer:Send("GS2CSweepLevel",{endlv=iLevel})
            return
        end
        local iCurlv = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1)
        local iEndlv = self:CalSweepLevel(oPlayer)
        if iEndlv <= iCurlv then
            return
        end
        local mNet = {endlv=iEndlv}
        oPlayer:Send("GS2CSweepLevel",mNet)
    elseif iOp == 4 then
    elseif iOp == 5 then
    elseif iOp == 6 then
        local shapelist = self:GetKeepSwpRw(iPid)
        self:KeepSwpRw(iPid)
        for _,info in pairs(shapelist) do
            local shape = info["shape"]
            local amount = info["amount"]
            for _,oItem in pairs(self:BuildRewardItemList({amount=amount},shape,{pid=iPid})) do
                oPlayer:RewardItem(oItem,self.m_sTempName)
            end
        end
        record.user("pata", "getrw", {
            pid = iPid,
            curlv = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1),
            reward = shapelist,
            name = oPlayer:GetName(),
            grade = oPlayer:GetGrade(),
        })
    end
end

function CHuodong:C2GSPataTgReward(oPlayer,iLevel)
    local iMaxlv = oPlayer.m_oActiveCtrl:GetData("pt_maxlv",1)
    if iMaxlv < iLevel then return end

    local idx = 2000 + iLevel
    if not self:GetItemRewardDataInPata(idx) then
        oPlayer:NotifyMessage("没有该通关奖励")
        return
    end

    local tglist = oPlayer.m_oActiveCtrl:GetData("pt_tglist",{})
    if table_in_list(tglist,iLevel) then
        oPlayer:NotifyMessage("您已领取过该通关奖励")
        return
    end
    table.insert(tglist,iLevel)
    self:RewardItemInPata(oPlayer,idx)

    oPlayer.m_oActiveCtrl:SetData("pt_tglist",tglist)
    oPlayer:Send("GS2CTgRewardResult",{
        level = iLevel,
    })

    record.user("pata", "fristrw", {
        pid=oPlayer:GetPid(),reward=idx,
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        curlv = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1),
    })
end

function CHuodong:OpenPataUI(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oFriend = oPlayer:GetFriend()
    local friends = oFriend:GetFriends()
    local frdidlist = {}
    for sPid,_ in pairs(friends) do
        table.insert(frdidlist,tonumber(sPid))
    end
    local info = {lv=0,time=0,pid=0,name="",shape=0}
    if #frdidlist <= 0 then
        self:OpenPataUI2(oPlayer,info)
        return
    end
    local iLv,iArriveTime = 0,999999999
    local iTot = 0
    local iLen = extend.Table.size(frdidlist)
    for _,iPid in pairs(frdidlist) do
        oWorldMgr:LoadProfile(iPid,function (oProfile)
            if oProfile:GetData("pt_maxlv",1) > iLv then
                iLv = oProfile:GetData("pt_maxlv",1)
                iArriveTime = oProfile:GetData("pt_time",0)
                info = {lv=iLv,time=iArriveTime,pid=iPid,name=oProfile:GetName(),shape=oProfile:GetModelInfo().shape}
            elseif iLv ~= 0 and oProfile:GetData("pt_maxlv",1) == iLv and oProfile:GetData("pt_time",0) < iArriveTime then
                iArriveTime = oProfile:GetData("pt_time",0)
                info = {lv=iLv,time=iArriveTime,pid=iPid,name=oProfile:GetName(),shape=oProfile:GetModelInfo().shape}
            end
            iTot = iTot + 1
            if iTot>=iLen then
                self:OpenPataUI2(oPlayer,info)
            end
        end)
    end
end

function CHuodong:OpenPataUI2(oPlayer,info)
    local mNet = {
            info = info,
            curlv = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1),
            maxlv = oPlayer.m_oActiveCtrl:GetData("pt_maxlv",1) ,
            restcnt = math.max(1 - oPlayer.m_oToday:Query("pt_reset",0) , 0),
            tglist = oPlayer.m_oActiveCtrl:GetData("pt_tglist",{}),
    }
    oPlayer:Send("GS2CPataUIInfo",mNet)
    self:PopSweepUI(oPlayer)
end

function CHuodong:SetPlayerLevel(oPlayer,iLevel)
    oPlayer.m_oActiveCtrl:SetData("pt_curlv",iLevel)
    if iLevel > oPlayer.m_oActiveCtrl:GetData("pt_maxlv",1) then
        oPlayer.m_oActiveCtrl:SetData("pt_maxlv",iLevel)
        local oWorldMgr = global.oWorldMgr
        local oProfile = oPlayer:GetProfile()
        oProfile:SetData("pt_maxlv",iLevel)
        oProfile:SetData("pt_time",get_time())
    end
end

function CHuodong:ResetPataCnt(oPlayer)
    if oPlayer.m_oToday:Query("pt_reset") == 1 then
        oPlayer:NotifyMessage("今日重置次数已使用完，明天再尝试吧。")
        return
    end
    if oPlayer.m_oActiveCtrl:GetData("pt_curlv",1) == 1 then
        oPlayer:NotifyMessage("地牢首层无法重置。")
        return
    end
    if oPlayer.m_oThisTemp:Query("pt_swptime") then
        oPlayer:NotifyMessage("正在扫荡中")
        return
    end
    self:SetPlayerLevel(oPlayer,1)
    oPlayer.m_oToday:Set("pt_reset",1)
    self:OpenPataUI(oPlayer)
    oPlayer.m_oPartnerCtrl:ResetPataCnt()
    record.user("pata", "reset", {pid=oPlayer:GetPid()})
end


function CHuodong:GetTollGateData(iFight)
    local mData = res["daobiao"]["tollgate"]["pata"][iFight]
    return mData
end

function CHuodong:EnterPataWar(oPlayer,iLevel,iSweep)
     if oPlayer.m_oActiveCtrl:GetNowWar() then
        return
    end
    local icurlv = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1)
    if iSweep == 0 then
        if icurlv >= 101  then
            oPlayer:NotifyMessage("您已达到地牢最底层，但权力永无止境，去挑战最高权威吧！")
            return
        end
        self:SendInviteInfo(oPlayer)
    elseif iSweep == 1 then
        self:SweepToFinal(oPlayer,true)
    elseif iSweep == 2 then
        self:SweepToFinal(oPlayer,false)
    end
end

function CHuodong:SweepToFinal(oPlayer,bAction)
    local iPid = oPlayer:GetPid()
    local pt_swpbglv = self:GetPlayerSweepInfo(iPid)
    local curlv = pt_swpbglv or oPlayer.m_oActiveCtrl:GetData("pt_curlv",1)
    local iLevel = self:CalSweepLevel(oPlayer)
    if iLevel <= curlv then
        return
    end
    local _,_,iBeginTime = self:GetPlayerSweepInfo(iPid)
    if bAction then
        if iBeginTime and iBeginTime > 0 then
            oPlayer:NotifyMessage("正在扫荡中")
            return
        end
        self:SetPlayerLevel(oPlayer,iLevel)
        self:SweepPlayAction(oPlayer,curlv,iLevel)
    else
        local iVal = tonumber(res["daobiao"]["global"]["pata_sweep_cost"]["value"])
        iVal = iVal * (iLevel-curlv)
        if iBeginTime and iBeginTime > 0 then
            iVal = iVal - (get_time()-iBeginTime)//15
            iVal = math.max(1,iVal)
        end
        if not oPlayer:ValidGoldCoin(iVal) then
            return
        end
        oPlayer:ResumeGoldCoin(iVal, "扫荡")
        self:SetPlayerLevel(oPlayer,iLevel)
        self:SweepFinish(iPid,curlv,iLevel,iVal)
    end
end

function CHuodong:CalSweepLevel(oPlayer)
    local iPower = oPlayer:GetWarPower()
    local pt_swpbglv = self:GetPlayerSweepInfo(oPlayer:GetPid())
    local iCurlv = pt_swpbglv or oPlayer.m_oActiveCtrl:GetData("pt_curlv",1)
    local iMaxlv = oPlayer.m_oActiveCtrl:GetData("pt_maxlv",1)
    local iCanSweep = iCurlv
    for iNo=iCurlv,iMaxlv do
        local mInfo = self:GetTollGateData(10000+iNo)
        if mInfo then
            iCanSweep = iNo
            if mInfo["recpower"] and mInfo["recpower"] > iPower then
                break
            end
        end
    end
    local mInfo = self:GetTollGateData(10000+iCanSweep)
    if iCanSweep == 1 then
        oPlayer:NotifyMessage("地牢首层，无法进行扫荡。")
    elseif iCanSweep <= iCurlv then
        oPlayer:NotifyMessage("尚未重置，无法进行扫荡。")
    end
    return iCanSweep
end

function CHuodong:OnLogin(oPlayer,reenter)
    local iLevel = oPlayer.m_oThisTemp:Query("pt_swplv",0)
    local iStart,iEnd,iTime,iTotal = self:GetPlayerSweepInfo(oPlayer:GetPid())
    if iStart then
        local infos = {}
        for iNo=iStart,iEnd-1 do
            table.insert(infos,{lv=iNo+1,costtime=15})
        end
        oPlayer:Send("GS2CSweepInfo",{infos=infos,begintime=iTime})
    end
end

function CHuodong:SetPlayerSweepInfo(iPid,iStart,iEnd,iStartTime,iTotalTime)
    self:Dirty()
    self.m_SweepInfo[db_key(iPid)] = {iStart,iEnd,iStartTime,iTotalTime}
end

function CHuodong:CleanPlayerSweepInfo(iPid)
    self:Dirty()
    self.m_SweepInfo[db_key(iPid)] = nil
end

function CHuodong:GetPlayerSweepInfo(iPid)
    return table.unpack(self.m_SweepInfo[db_key(iPid)] or {})
end

function CHuodong:SweepPlayAction(oPlayer,curlv,iLevel)
    local infos = {}
    local iTotalTime = 0
    for iNo=curlv,iLevel-1 do
        table.insert(infos,{lv=iNo+1,costtime=15})
        iTotalTime = iTotalTime + 15
    end

    local iPid = oPlayer:GetPid()
    local iCurTime = get_time()

    self:SetPlayerSweepInfo(iPid,curlv,iLevel,iCurTime,iTotalTime)
    oPlayer:Send("GS2CSweepInfo",{infos=infos,begintime=iCurTime})

    local sTimeFlag = "PlayAction"..oPlayer:GetPid()
    self:AddTimeCb(sTimeFlag, iTotalTime * 1000, function ()
        self:SweepFinish(iPid,curlv,iLevel)
    end)
end

function CHuodong:GetSweepRewardItem(curlv,iLevel)
    local shapelist = {}
    local tShape = {}
    local tRealObj = {}
    for iNo=curlv,iLevel do
        local idx = 1000+iNo
        local mRewardData = self:GetItemRewardDataInPata(idx)
        for _,data in pairs(mRewardData) do
            local iAmount = data["amount"]
            local sShape = data["sid"]
            local iShape = tonumber(sShape)
            tShape[sShape] = tShape[sShape] or 0
            tShape[sShape] = tShape[sShape] + iAmount
            if iShape and iShape > 10000 then
                tRealObj[sShape] = tRealObj[sShape] or 0
                tRealObj[sShape] = tRealObj[sShape] + iAmount
            end
        end
    end
    for shape,amount in pairs(tShape) do
        table.insert(shapelist,{shape=shape,amount=amount})
    end
    return shapelist,tRealObj
end

function CHuodong:PopSweepUI(oPlayer)
    local shapelist = self:GetKeepSwpRw(oPlayer:GetPid())
    if #shapelist <= 0 then
        return
    end
    local tItem,itemlist = {},{}
    for _,info in pairs(shapelist) do
        local shape = info["shape"]
        local amount = info["amount"]
        if not tonumber(shape) then
            local sid,sArg = string.match(shape,"(%d+)(.+)")
            sid = tonumber(sid)
            if sArg then
                sArg = string.sub(sArg,2,#sArg-1)
                local mArg = split_string(sArg,",")
                for _,sArg in ipairs(mArg) do
                    local key,value = string.match(sArg,"(.+)=(.+)")
                    if key == "value" then
                        amount = amount * value
                    end
                end
            end
            shape = sid
        else
            shape = tonumber(shape)
        end
        tItem[shape] = tItem[shape] or 0
        tItem[shape] = tItem[shape] + amount
    end
    for shape,amount in pairs(tItem) do
        table.insert(itemlist,{shape=shape,amount=amount})
    end
    local mNet = {itemlist=itemlist,curlv=oPlayer.m_oActiveCtrl:GetData("pt_curlv",1),}
    oPlayer:Send("GS2CPataRwItemUI",mNet)
end

function CHuodong:SweepFinish(iPid,curlv,iLevel,iVal)
    self:DelTimeCb("PlayAction"..iPid)
    local oWorldMgr = global.oWorldMgr
    local oPubMgr = global.oPubMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local shapelist,mItem = self:GetSweepRewardItem(curlv,iLevel-1)
    self:KeepSwpRw(iPid,shapelist)
    self:CleanPlayerSweepInfo(iPid)
    if oPlayer then
        local iCnt = iLevel
        for i = 1,iCnt do
            oPlayer:AddSchedule("pata")
        end
        self:PopSweepUI(oPlayer)
    end
    if oPlayer then
        record.user("pata", "swp", {
            pid=iPid,beginlv=curlv,endlv=iLevel,
            name = oPlayer:GetName(),
            grade = oPlayer:GetGrade(),
            power = oPlayer:GetPower()
        })
    else
        oWorldMgr:LoadProfile(iPid,function (oProfile)
            record.user("pata", "swp", {
                pid=iPid,beginlv=curlv,endlv=iLevel,
                name = oProfile:GetName(),
                grade = oProfile:GetGrade(),
                power = oProfile:GetPower()
            })
        end)
    end
    self:LogAnalySweepData(iPid,curlv,iLevel,iVal,mItem)
end

function CHuodong:LogAnalySweepData(iPid,iStart,iEnd,iVal,mItem)
    local mLog = {}
    mLog["start_end"] = string.format("%d-%d",iStart,iEnd)
    mLog["consume_crystal"] = iVal or 0
    mLog["reward_detail"] = analy.datajoin(mItem)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        mLog = table_combine(mLog,oPlayer:GetPubAnalyData())
        analy.log_data("dungeonSweep",mLog)
    else
        oWorldMgr:LoadProfile(iPid,function (oProfile)
            mLog = table_combine(mLog,oProfile:GetPubAnalyData())
            analy.log_data("dungeonSweep",mLog)
        end)
    end
end

function CHuodong:SendInviteInfo(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oFriend = oPlayer:GetFriend()
    local friends = oFriend:GetFriends()
    local frdidlist = {}
    for sPid,_ in pairs(friends) do
        table.insert(frdidlist,tonumber(sPid))
    end
    if #frdidlist <= 0 then
        oPlayer:Send("GS2CPataInviteInfo",{cnt=math.max(3-oPlayer.m_oToday:Query("pt_help",0),0),frdlist={}})
        return
    end
    local iTot = 0
    local iLen = extend.Table.size(frdidlist)
    local frdlist = {}
    for _,iPid in pairs(frdidlist) do
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oTarget then
            local oOfflinePartner = oWorldMgr:GetOfflinePartner(iPid)
            local oProfile = oTarget:GetProfile()
            table.insert(frdlist,{
                pid=iPid,
                power=oTarget:GetWarPower(),
                grade=oTarget:GetGrade(),
                name = oTarget:GetName(),
                shape = oTarget:GetShape(),
                ptncnt = oOfflinePartner:GetPtnCnt(),
                upvote = oProfile:IsUpvote(oPlayer:GetPid())
            })
            iTot = iTot + 1
            if iTot>=iLen then
                self:SendInviteInfo2(oPlayer,frdlist)
            end
        else
            oWorldMgr:LoadPartner(iPid,function (oOfflinePartner)
                oWorldMgr:LoadProfile(iPid,function (oProfile)
                    table.insert(frdlist,{
                        pid=iPid,
                        power=oProfile:GetWarPower(),
                        grade=oProfile:GetGrade(),
                        name = oProfile:GetName(),
                        shape = oProfile:GetModelInfo().shape,
                        ptncnt=oOfflinePartner:GetPtnCnt(),
                        upvote = oProfile:IsUpvote(oPlayer:GetPid())
                        }
                    )
                    iTot = iTot + 1
                    if iTot>=iLen then
                        self:SendInviteInfo2(oPlayer,frdlist)
                    end
                end
                )
            end
            )
        end
    end
end

function CHuodong:SendInviteInfo2(oPlayer,frdlist)
    local oWorldMgr = global.oWorldMgr
    oPlayer:Send("GS2CPataInviteInfo",{cnt=math.max(3-oPlayer.m_oToday:Query("pt_help",0),0),frdlist=frdlist})
end

function CHuodong:SendFrdPtnInfo(oPlayer,target)
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOfflinePartner(target)
    if oTarget then
        local mNet = {target=target,partlist=oTarget:GetPataPtnInfoList(10)}
        oPlayer:Send("GS2CPataFrdPtnInfo",mNet)
    else
        oWorldMgr:LoadPartner(target,function (oOfflinePartner)
            local mNet = {target=target,partlist=oOfflinePartner:GetPataPtnInfoList(10)}
            oPlayer:Send("GS2CPataFrdPtnInfo",mNet)
        end
        )
    end
end

function CHuodong:InviteFrdEnterWar(oPlayer,target,parid)
    if oPlayer.m_oActiveCtrl:GetNowWar() then
        return
    end
    local _,_,pt_swptime = self:GetPlayerSweepInfo(oPlayer:GetPid())
    if pt_swptime then
        oPlayer:NotifyMessage("正在扫荡中")
        return
    end
    local oWorldMgr = global.oWorldMgr
    if not tonumber(target) or not tonumber(parid) then
        return
    end
    if oPlayer.m_oToday:Query("pt_help",0) >= 3 then
        target = 0
        parid = 0
    end

    local iLevel = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1)
    if iLevel >= 101  then
        oPlayer:NotifyMessage("您已达到地牢最底层，但权力永无止境，去挑战最高权威吧！")
        return
    end
    local iFight = 10000 + iLevel
    local iRemoteAddr = oPlayer.m_oPartnerCtrl:GetRemoteAddr()
    interactive.Request(iRemoteAddr, "partner", "GetPataPartnerList", {pid = oPlayer:GetPid()}, function(mRecord, mData)
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(mData.pid)
        if oPlayer then
            local lPartner = oPlayer.m_oPartnerCtrl:NewPartnerList(mData.pid, mData.data)
            self:DoInviteFrdEnterWar(oPlayer, lPartner, target, parid, iFight)
        end
    end)
end

function CHuodong:DoInviteFrdEnterWar(oPlayer, lPartner, target, iParId, iFight)
    if oPlayer:GetNowWar() then
        return
    end
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local mEnterWarArg = {}
    local mFightPartner = lPartner
    local patalv = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1)
    mEnterWarArg.CurrentPartner = mFightPartner[1]
    mEnterWarArg.FightPartner = mFightPartner
    mEnterWarArg.extra_info = {{key="patalv",value=tostring(patalv)}}
    if target == 0 and iParId == 0 then
        local oWar = self:CreateWar(oPlayer:GetPid(),nil,iFight,{enter_arg=mEnterWarArg,war_friend=true})
        oWar.m_FriendID = 0
        return
    end
    local oTarget = oWorldMgr:GetOfflinePartner(target)
    if oTarget then
        local oWarInfo = oTarget:GetWarInfoByID(iParId)
        if not oWarInfo then
            oPlayer:NotifyMessage("该伙伴已删除")
            return
        end
        oWarInfo.parid = 999999
        oWarInfo.pos = nil
        self:DoInviteFrdEnterWar2(iPid,target,iFight,oWarInfo,mEnterWarArg)
    else
        oWorldMgr:LoadPartner(target, function (oOfflinePartner)
            local oWarInfo = oOfflinePartner:GetWarInfoByID(iParId)
            oWarInfo.parid = 999999
            oWarInfo.pos = nil
            self:DoInviteFrdEnterWar2(iPid,target,iFight,oWarInfo,mEnterWarArg)
        end)
    end
    if target ~= 0 and iParId ~= 0 then
        oPlayer.m_oToday:Add("pt_help",1)
        record.user("pata", "friend", {
                pid = oPlayer:GetPid(),
                name = oPlayer:GetName(),
                cnt = oPlayer.m_oToday:Query("pt_help",0)
        })
    end
end

function CHuodong:DoInviteFrdEnterWar2(iPid,iTarget,iFight,oWarInfo,mEnterWarArg)
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oTarget then
        local sFriendName = oTarget:GetName()
        oWarInfo.name = sFriendName
        mEnterWarArg.FrdPtnWarInfo = oWarInfo
        local oWar = self:CreateWar(iPid,nil,iFight,{enter_arg=mEnterWarArg,war_friend=true})
        oWar.m_FriendID = iTarget
    else
        oWorldMgr:LoadProfile(iTarget,function (oProfile)
            local sFriendName = oProfile:GetName()
            oWarInfo.name = sFriendName
            mEnterWarArg.FrdPtnWarInfo = oWarInfo
            local oWar = self:CreateWar(iPid,nil,iFight,{enter_arg=mEnterWarArg,war_friend=true})
            oWar.m_FriendID = iTarget
        end)
    end
end

function CHuodong:GetCreateWarArg(mArg)
    local mArg2 = table_copy(mArg)
    mArg2.war_type = gamedefines.WAR_TYPE.PATA_TYPE
    mArg2.remote_war_type = "pata"
    return mArg2
end

function CHuodong:ConfigWar(oWar,pid,npcobj,iFight)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    oWar:SetData("PATA_FLV",oPlayer.m_oActiveCtrl:GetData("pt_curlv",1))
end

function CHuodong:TransMonsterAble(oWar,sAttr,mArgs)
    mArgs = mArgs or {}
    local sValue = mArgs.value
    local mEnv = mArgs.env
    mEnv.FLV = oWar:GetData("PATA_FLV")
    local iValue = formula_string(sValue,mEnv)
    return iValue
end

function CHuodong:CheckItemRewardData(iItemReward)
    return res["daobiao"]["reward"][self.m_sName]["itemreward"][iItemReward]
end

function CHuodong:GetItemRewardDataInPata(iItemReward)
    local mData = res["daobiao"]["reward"][self.m_sName]["itemreward"][iItemReward][1]
    assert(mData,string.format("CTempl:GetItemRewardDataInPata err:%s %d", self.m_sName, iItemReward))
    return mData
end

function CHuodong:OnWarWin(oWar, pid, npcobj, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        local icurlv = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1)
        local iOldMaxlv = oPlayer.m_oActiveCtrl:GetData("pt_maxlv",1)
        self:SetPlayerLevel(oPlayer,icurlv+1)
        local iNewMaxlv = oPlayer.m_oActiveCtrl:GetData("pt_maxlv",1)
        local iFight = oWar.m_FightIdx
        local mFight = self:GetTollGateData(iFight)
        local mReward = mFight["rewardtbl"] or {}
        for _,info in ipairs(mReward) do
            self:Reward(oPlayer:GetPid(),info["rewardid"])
        end
        local itemlist = {}
        local mNewReward = self:GetKeep(oPlayer:GetPid(), "item", {})
        for sid,mUnit in pairs(mNewReward) do
            local amount = 0
            for _,cnt in pairs(mUnit) do
                amount = amount + cnt
            end
            table.insert(itemlist,{shape=sid,amount=amount})
        end
        self:OpenWarEndUI(oPlayer,1,itemlist)
        local oRankMgr = global.oRankMgr
        oRankMgr:PushDataToPataRank(oPlayer)
        oPlayer:AddSchedule("pata")
        record.user("pata", "warwin", {
            pid = pid, curlv = icurlv,
            reward = ConvertTblToStr(mReward),
            name = oPlayer:GetName(),
            grade = oPlayer:GetGrade(),
            power = oPlayer:GetPower()
        })
        local mItem = {}
        for _,info in pairs(itemlist) do
            mItem[info.shape] = mItem[info.shape] or 0
            mItem[info.shape] = mItem[info.shape] + info.amount
        end
        self:LogAnalyWarData(oWar,oPlayer,icurlv,icurlv+1,mItem,true)
        global.oAchieveMgr:PushAchieve(pid,"通关地牢层数",{value=oPlayer.m_oActiveCtrl:GetData("pt_maxlv",1)-1})
        self:TipGongGao(oPlayer,iOldMaxlv,iNewMaxlv)
    end
    global.oHandBookMgr:CheckCondition("pata", pid, mArgs)
end

function CHuodong:TipGongGao(oPlayer,iOldMaxlv,iNewMaxlv)
    local iText
    if iNewMaxlv == 50 and iOldMaxlv < 50 then
        iText = 1001
    elseif iNewMaxlv == 100 and iOldMaxlv < 100 then
        iText = 1002
    end
    if iText then
        local oNotifyMgr = global.oNotifyMgr
        local sMsg = self:GetTextData(iText)
        sMsg = string.gsub(sMsg,"$username",oPlayer:GetName())
        oNotifyMgr:SendPrioritySysChat("pata_char",sMsg,1)
    end
end

function CHuodong:RewardItemInPata(oPlayer,idx)
    local itemlist = self:GetItemRewardDataInPata(idx)
    local shapelist = {}
    for _,info in pairs(itemlist) do
        local iRecord = info["amount"]
        local sShape = info["sid"]
        for _,oItem in pairs(self:BuildRewardItemList(info,sShape,{pid=oPlayer:GetPid()})) do
            local sid = oItem:SID()
            local iColor = oItem:Quality()
            local sName = oItem:Name()
            oPlayer:RewardItem(oItem,self.m_sTempName)
            if oItem then
                if sid < 10000 then
                    iRecord = oItem:GetData("value")
                end
                table.insert(shapelist,{shape=sid,amount=iRecord})
            end
        end
    end
    return shapelist
end

function CHuodong:OnWarFail(oWar, pid, npcobj, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        self:OpenWarEndUI(oPlayer,0)
        local icurlv = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1)
        self:LogAnalyWarData(oWar,oPlayer,icurlv,icurlv,nil,false)
    end
end

function CHuodong:GetPartnerTypeList(oWar,oPlayer)
    local iPid = oPlayer:GetPid()
    local mOFPartner = oWar.m_OutFightPartner or {}
    local mPartnerID = mOFPartner[iPid] or {}
    local tResult
    for partID,_ in pairs(mPartnerID) do
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(partID)
        if oPartner then
            local iType = oPartner:SID()
            tResult = tResult or {}
            tResult[iType] = tResult[iType] or 0
            tResult[iType] = tResult[iType] + 1
        end
    end
    return tResult
end

function CHuodong:LogAnalyWarData(oWar,oPlayer,iStart,iEnd,mItem,bWin)
    local mLog = oPlayer:GetPubAnalyData()
    mLog["start_end"] = string.format("%d-%d",iStart,iEnd)
    mLog["partner_detail"] = analy.datajoin(self:GetPartnerTypeList(oWar,oPlayer))
    mLog["friend_role_id"] = oWar.m_FriendID and tostring(oWar.m_FriendID) or ""
    mLog["reward_detail"] = analy.datajoin(mItem)
    mLog["win_mark"] = bWin
    mLog["consume_time"] = oWar:GetWarDuration()
    analy.log_data("dungeonBattle",mLog)
end

function CHuodong:OpenWarEndUI(oPlayer,iWin,itemlist)
    itemlist = itemlist or {}
    local mNet = {
        iWin=iWin,
        itemlist = itemlist,
        curlv = oPlayer.m_oActiveCtrl:GetData("pt_curlv",1),
        invitecnt = math.max(3-oPlayer.m_oToday:Query("pt_help",0),0),
    }
    oPlayer:Send("GS2CPataWarUI",mNet)
end

function CHuodong:OnWarEnd(oWar, iPid, oNpc, mArgs,bWin)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:PushBookCondition("地牢战斗场数", {value = 1})
    end
end

function CHuodong:PopWarRewardUI(iWarid,mArgs)
    --
end

function CHuodong:RecordPataPtnHp(iPid,iParId,iRestHp)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:RecordPataPartnerHP(iParId, iRestHp)
    end
end

function CHuodong:TestOP(oPlayer,iFlag,...)
    local args = {...}
    local oNotify = global.oNotifyMgr
    local pid = oPlayer:GetPid()
    local oChatMgr = global.oChatMgr
    if iFlag == 100 then
        oChatMgr:HandleMsgChat(oPlayer,"101-进入pata战斗")
    elseif iFlag == 101 then
        local target,partid = ...
        self:InviteFrdEnterWar(oPlayer,target,partid)
    elseif iFlag == 102 then
        self:TipGongGao(oPlayer,100)
    end
end

function SetPataData(oPlayer,sAttr,val)
    oPlayer.m_oActiveCtrl:SetData(sAttr,val)
    record.user("pata", "offset", {pid=oPlayer:GetPid(), sAttr=sAttr , val=val})
end