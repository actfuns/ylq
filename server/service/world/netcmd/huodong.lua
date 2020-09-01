local global = require "global"


local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item/loaditem"))

function C2GSAnswerQuestion(oPlayer, mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("question")
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        local o = oHuodong:GetQuestionObj(mData.type)
        if o then
            if not o:IsOpenGrade(oPlayer) then
                global.oNotifyMgr:Notify(oPlayer:GetPid(), "未达答题开启等级")
                return
            end
            local iQuestion = mData.id
            local iAnswer = mData.answer
            o:Answer(oPlayer, iQuestion, iAnswer)
            if mData.type == gamedefines.QUESTION_TYPE.SCORE then
                oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30012,1)
            end
        end
    end
end

function C2GSQuestionEnterMember(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("question")
    local iPid = oPlayer:GetPid()
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        local o = oHuodong:GetQuestionObj(gamedefines.QUESTION_TYPE.SCORE)
        if o then
            if not o:IsOpenGrade(oPlayer) then
                oNotifyMgr:Notify(iPid, "未达开启等级")
                return
            end
            if o:Status() ~= gamedefines.QUESTION_STATUS.READY then
                oNotifyMgr:Notify(oPlayer:GetPid(), "不在活动时间内")
                return
            end
            o:EnterMember(oPlayer)
        end
    end
end

function C2GSQuestionEndReward(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("question")
    local iType = mData.type
    local iPid = oPlayer:GetPid()
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        local o = oHuodong:GetQuestionObj(gamedefines.QUESTION_TYPE.SCORE)
        if o then
            if o:Status() ~= gamedefines.QUESTION_STATUS.END then
                oNotifyMgr:Notify(iPid, "活动结束后领取")
                return
            end
            local iRank = o:GetRank(iPid)
            if not iRank then
                oNotifyMgr:Notify(iPid, "奖励已领取")
                return
            end
            if iType == 1 then
                o:GetRankReward(iPid, iRank)
            else
                o:SendRewardEmail(iPid, iRank)
            end
        end
    end
end

function C2GSApplyQuestionScene(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("question")
    local iPid = oPlayer:GetPid()
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        local o = oHuodong:GetQuestionObj(gamedefines.QUESTION_TYPE.SCENE)
        if o and o:Status() == gamedefines.QUESTION_STATUS.READY then
            if not o:IsOpenGrade(oPlayer) then
                oNotifyMgr:Notify(iPid, "未达开启等级")
                return
            end
            o:AddMember(oPlayer)
        else
            oPlayer:NotifyMessage("已过报名时间")
        end
    end
end

function C2GSEnterQuestionScene(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("question")
    local iPid = oPlayer:GetPid()
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        local o = oHuodong:GetQuestionObj(gamedefines.QUESTION_TYPE.SCENE)
        if o and o:Status() ~= gamedefines.QUESTION_STATUS.END then
            if not o:IsOpenGrade(oPlayer) then
                oNotifyMgr:Notify(iPid, "未达开启等级")
                return
            end
            o:EnterQtionScene(oPlayer)
        end
    end
end

function C2GSLeaveQuestionScene(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("question")
    local iPid = oPlayer:GetPid()
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        local o = oHuodong:GetQuestionObj(gamedefines.QUESTION_TYPE.SCENE)
        if o  then
            if not o:IsOpenGrade(oPlayer) then
                oNotifyMgr:Notify(iPid, "未达开启等级")
                return
            end
            o:LeaveQtionScene(oPlayer)
        end
    end
end

function C2GSOpenBossUI(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("worldboss")
    if oHuoDong then
        oHuoDong:OpenMainUI(oPlayer)
    end
end

function C2GSEnterBossWar(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("worldboss")
    if oHuoDong then
        oHuoDong:EnterScene(oPlayer)
    end
end


function C2GSCloseBossUI(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("worldboss")
    if oHuoDong then
        oHuoDong:CloseBossUI(oPlayer)
    end
end

function C2GSBossRemoveDeadBuff(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("worldboss")
    if oHuoDong then
        oHuoDong:BossRemoveDeadBuff(oPlayer)
    end
end

function C2GSLeaveWorldBossScene(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("worldboss")
    if oHuoDong then
        oHuoDong:LeaveScene(oPlayer)
    end
end

function C2GSFindWorldBoss(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("worldboss")
    if oHuoDong then
        oHuoDong:FindWorldBoss(oPlayer)
    end
end


function C2GSBuyBossBuff(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("worldboss")
    if oHuoDong then
        oHuoDong:AddState(oPlayer,mData.buff)
    end
end

function C2GSWorldBoossRank(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("worldboss")
    if oHuoDong then
        oHuoDong:RefreshWorldBoossRank(oPlayer)
    end
end


function C2GSPataOption(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local iOp = mData.iOp
    local oHuoDong = oHDMgr:GetHuodong("pata")
    if oHuoDong then
        if oHuoDong:ValidLimit(oPlayer) or oHuoDong:IsClose(oPlayer) then
            return
        end
        oHuoDong:C2GSPataOption(oPlayer,iOp,mData)
    end
end

function C2GSPataEnterWar(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local iLevel = mData.iLevel
    local iSweep = mData.iSweep
    local oHuoDong = oHDMgr:GetHuodong("pata")
    if oHuoDong then
        if oHuoDong:ValidLimit(oPlayer) or oHuoDong:IsClose(oPlayer) then
            return
        end
        oHuoDong:EnterPataWar(oPlayer,iLevel,iSweep)
    end
end

function C2GSPataInvite(oPlayer,mData)
    local target = mData.target
    local parid = mData.parid
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("pata")
    if oHuoDong then
        if oHuoDong:ValidLimit(oPlayer) or oHuoDong:IsClose(oPlayer) then
            return
        end
        oHuoDong:InviteFrdEnterWar(oPlayer,target,parid)
    end
end

function C2GSPataFrdInfo(oPlayer,mData)
    local target = mData.target
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("pata")
    if oHuoDong then
        if oHuoDong:ValidLimit(oPlayer) or oHuoDong:IsClose(oPlayer) then
            return
        end
        oHuoDong:SendFrdPtnInfo(oPlayer,target)
    end
end

function C2GSPataTgReward(oPlayer,mData)
    local iLevel = mData.level
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("pata")
    if oHuoDong then
        if oHuoDong:ValidLimit(oPlayer) or oHuoDong:IsClose(oPlayer) then
            return
        end
        oHuoDong:C2GSPataTgReward(oPlayer,iLevel)
    end
end

function C2GSGetEndlessList(oPlayer, mData)
    local oHuodongMgr = global.oHuodongMgr
    local iPid = oPlayer:GetPid()
    local oHuodong = oHuodongMgr:GetHuodong("endless_pve")
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        if not oHuodong:IsOpenGrade(oPlayer) then
            global.oNotifyMgr:Notify(iPid, "未达开启等级")
            return
        end
        oHuodong:GS2CEndlessFightList(oPlayer)
    end
end

function C2GSEndlessPVEStart(oPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oHuodongMgr = global.oHuodongMgr
    local iPid = oPlayer:GetPid()
    local iMode = mData["mode"]
    local oHuodong = oHuodongMgr:GetHuodong("endless_pve")
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        if not oHuodong:IsOpenGrade(oPlayer) then
            global.oNotifyMgr:Notify(iPid, "未达开启等级")
            return
        end
        oHuodong:StartEndlessPVE(oPlayer, iMode)
    end
end

function C2GSOpenEquipFB(oPlayer,mData)
    local iFB = mData.f_id
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    if oHuodong then
        oHuodong:OpenFubenUI(oPlayer,iFB )
    end
end


function C2GSEnterEquiFB(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    local iFloor = mData.floor
    if oHuodong then
        oHuodong:EnterGame(oPlayer,iFloor)
    end
end

function C2GSGooutEquipFB(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    if oHuodong then
        oHuodong:LeaveFuBen(oPlayer,"escape")
    end
end

function C2GSRefreshEquipFBScene(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    if oHuodong then
        oHuodong:RefreshScene(oPlayer)
    end
end

function C2GSSetAutoEquipFuBen(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    if oHuodong then
        oHuodong:SetAutoFuBen(oPlayer,mData.auto)
    end
end


function C2GSBuyEquipPlayCnt(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    if oHuodong then
        oHuodong:BuyEquipPlayCnt(oPlayer,mData.buy_cnt,mData.cost,mData.fb)
    end
end

function C2GSGetEquipFBReward(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    if oHuodong then
        oHuodong:GetVipReward(oPlayer,mData.floor,mData.equip)
    end
end

function C2GSSweepEquipFB(oPlayer, mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    if oHuodong then
        oHuodong:SweepFuBen(oPlayer, mData.floor, mData.count)
    end
end

function C2GSOpenEquipFBMain(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("equipfuben")
    if oHuodong then
        oHuodong:OpenMainUI(oPlayer)
    end
end


function C2GSOpenPEMain(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("pefuben")
    if oHuodong then
        oHuodong:OpenMainUI(oPlayer,mData.fb_id)
    end
end

function C2GSPEStartTurn(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("pefuben")
    if oHuodong then
        oHuodong:StartTurn(oPlayer,mData.fb_id)
    end
end

function C2GSPELock(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("pefuben")
    if oHuodong then
        oHuodong:LockEquip(oPlayer,mData.fb_id,mData.lock)
    end
end


function C2GSEnterPEFuBen(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("pefuben")
    if oHuodong then
        if mData.type == 1 then
            oHuodong:SweepFuBen(oPlayer, mData.fb_id, mData.floor)
        else
            oHuodong:EnterGame(oPlayer,mData.fb_id,mData.floor)
        end
    end
end

function C2GSBuyPEFuBen(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("pefuben")
    if oHuodong then
        oHuodong:BuyFuBenTimes(oPlayer,mData.times,mData.fb)
    end
end

function C2GSOpenPEFuBenSchedule(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("pefuben")
    if oHuodong then
        oHuodong:OpenSchedule(oPlayer)
    end
end

function  C2GSCostSelectPEFuBen(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("pefuben")
    if oHuodong then
        oHuodong:VIPSelectFuBen(oPlayer,mData.fb)
    end
end



----------------暗雷-------------------
function StartOfflineTrapmine(iPid,iMapId)
    local oWorldMgr = global.oWorldMgr
    local oHuodongMgr = global.oHuodongMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if not oScene:HasAnLei() or oScene:MapId() ~= iMapId then
        return
    end
    local oHuodong = oHuodongMgr:GetHuodong("trapmine")
    if not oHuodong then
        return
    end
    if not oHuodong:ValidStart(oPlayer,iMapId) then
        return
    end
    oHuodong:ClientStartOfflineTrapmine(oPlayer, iMapId)
end

function C2GSStartOfflineTrapmine(oPlayer,mData)
    local iMapId = mData.map_id
    local oHuodongMgr = global.oHuodongMgr
    local iPid = oPlayer:GetPid()
    local oHuodong = oHuodongMgr:GetHuodong("trapmine")
    if not oHuodong or oHuodong:IsClose(oPlayer) then
        return
    end
    if not oHuodong:IsOpenGrade(oPlayer) then
        global.oNotifyMgr:Notify(oPlayer:GetPid(), "未达开启等级")
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if not oScene:HasAnLei() or oScene:MapId() ~= iMapId then
        return
    end
    local oTrain = oHuodongMgr:GetHuodong("dailytrain")
    if oTrain then
        oTrain:QuitTrain(oPlayer)
    end
    if not oHuodong:IsOfflineTrapmine(iPid) then
        local oSceneMgr = global.oSceneMgr
        oSceneMgr:ClickOfflineTrapMineMap(oPlayer,iMapId)
        local iPid = oPlayer:GetPid()
        local fCallback = function ()
            StartOfflineTrapmine(iPid,iMapId)
        end
        oSceneMgr:QueryPos(iPid,fCallback)
    else
        local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
        if not oScene:HasAnLei() or oScene:MapId() ~= iMapId then
            return
        end
        if oHuodong:ValidStart(oPlayer, iMapId) then
            oHuodong:StartTrapmine(oPlayer, iMapId)
        end
    end
end

function C2GSCancelOfflineTrapmine(oPlayer, mData)
    local iMapId = mData.map_id
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if not oScene:HasAnLei() or oScene:MapId() ~= iMapId then
        return
    end
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("trapmine")
    local oTeam = oPlayer:HasTeam()
    if oHuodong then
        if not oTeam or oPlayer:IsTeamLeader() then
            oHuodong:StopTrapmine(oPlayer, iMapId)
        else
            if oTeam then
                global.oTeamMgr:LeaveTeam(oTeam,oPlayer)
            end
        end
        -- oHuodong:StopOfflineTrapmine(oPlayer:GetPid())
    end
end

function C2GSGetLoginReward(oPlayer, mData)
    local iDay = mData.day
    if iDay <= 0 then
        return
    end
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("loginreward")
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        if not oHuodong:IsOpenGrade(oPlayer) then
            global.oNotifyMgr:Notify(oPlayer:GetPid(), "未达可领取等级")
            return
        end
        oHuodong:GetReward(oPlayer,iDay)
    end
end

function C2GSAddFullBreedVal(oPlayer, mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("loginreward")
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        if not oHuodong:IsOpenGrade(oPlayer) then
            global.oNotifyMgr:Notify(oPlayer:GetPid(), "未达可领取等级")
            return
        end
        if oHuodong:ValidAddFullBreedVal(oPlayer) then
            oHuodong:AddFullBreedVal(oPlayer)
        end
    end
end

function C2GSGetBreedValRwd(oPlayer, mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("loginreward")
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        if not oHuodong:IsOpenGrade(oPlayer) then
            global.oNotifyMgr:Notify(oPlayer:GetPid(), "未达可领取等级")
            return
        end
        if oHuodong:ValidGetBreedValRwd(oPlayer) then
            oHuodong:GetBreedValRwd(oPlayer)
        end
    end
end

function C2GSBuyMingleiTimes(oPlayer,mData)
    local iBuyTime = mData.buy_time
    if iBuyTime == 0 then
        return
    end
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("minglei")
    if oHuodong then
        oHuodong:BuyMingleiTimes(oPlayer,iBuyTime)
    end
end

function C2GSNpcFight(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local iNpc = mData["npc_id"]
    local oNpc = global.oNpcMgr:GetObject(iNpc)
    if oNpc then
        local oHuodong = global.oHuodongMgr:GetHuodong("npcfight")
        if oHuodong then
            if oHuodong:IsClose(oPlayer) then
                return
            end
            if not oHuodong:IsOpenGrade(oPlayer) then
                global.oNotifyMgr:Notify(iPid, "未达开启等级")
                return
            end
            oHuodong:Fight(oPlayer, oNpc)
        end
    else
        oNotifyMgr:Notify(iPid, "挑战npc失败,npc不存在")
    end
end

function C2GSEnterYJFuben(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsClose("yjfuben") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return false
    end
    local iType = mData.itype
    iType = math.max(iType,1)
    local oHuodong = global.oHuodongMgr:GetHuodong("yjfuben")
    if oHuodong then
        oHuodong:EnterGame(oPlayer,iType)
    end
end

function C2GSBuyYJFuben(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsClose("yjfuben") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return false
    end
    local iAmount = mData.amount
    local oHuodong = global.oHuodongMgr:GetHuodong("yjfuben")
    if oHuodong then
        oHuodong:YJFuBenBuyCnt(oPlayer,iAmount)
    end
end

function C2GSYJFubenOp(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsClose("yjfuben") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return false
    end
    local action = mData.action
    local oHuodong = global.oHuodongMgr:GetHuodong("yjfuben")
    if oHuodong then
        oHuodong:YJFuBenOp(oPlayer,action)
    end
end

function C2GSYJFubenView(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsClose("yjfuben") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return false
    end
    local npcidx = mData.npcidx
    local oHuodong = global.oHuodongMgr:GetHuodong("yjfuben")
    if oHuodong then
        oHuodong:ShowFBMonster(oPlayer,npcidx)
    end
end

function C2GSYJFindNpc(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsClose("yjfuben") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return false
    end
    local npcidx = mData.npcidx
    local oHuodong = global.oHuodongMgr:GetHuodong("yjfuben")
    if oHuodong then
        oHuodong:FindGameNpc(oPlayer,npcidx)
    end
end

function C2GSGoToHelpTerra(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    local iTerraId = mData.id
    local iStartTime = mData.start_time
    oHuodong:GoToHelp(oPlayer,iTerraId,iStartTime)
end

function C2GSAttackTerra(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    local iTerraId = mData.id
    oHuodong:AttackTerra(oPlayer,iTerraId)
end

function C2GSTerrawarMain(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:OpenMainUI(oPlayer)
end

function C2GSTerrawarMapInfo(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    local iMapId = mData.map_id
    oHuodong:GetMapInfo(oPlayer,iMapId)
end

function C2GSTerrawarMine(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    local iTerraId = mData.id
    oHuodong:GetMyTerraInfo(oPlayer,iTerraId ~= 0 and iTerraId or nil)
end

function C2GSGetTerraInfo(oPlayer,mData)
    local iTerraId = mData.terraid
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    local iTerraId = mData.id
    oHuodong:ClickTerra(oPlayer,iTerraId)
end

function C2GSSetGuard(oPlayer,mData)
    local mParList = mData.par_id
    local iPid = oPlayer.m_iPid
    local iTerraId = mData.id
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:SetGuard(iPid,iTerraId,mParList)
end

function C2GSAutoSetGuard(oPlayer,mData)
    local iTerraId = mData.id
    local iPid = oPlayer.m_iPid
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:CheckPartnerSet(iPid,iTerraId)
end

function C2GSTerrawarOperate(oPlayer,mData)
    local iTerraId = mData.id
    local iOperate = mData.type
    local iPid = oPlayer.m_iPid
    local iNextCmd = mData.next_cmd
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:DoOperation(iPid,iTerraId,iOperate,iNextCmd)
end

function C2GSGetListInfo(oPlayer,mData)
    local iWarId = mData.id
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:GetListInfo(oPlayer,nil,iWarId)
end

function C2GSLeaveQueue(oPlayer,mData)

    local iTerraId = mData.id
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:LeaveQueue(oPlayer.m_iPid,iTerraId)
end

function C2GSHelpFirst(oPlayer,mData)
    local iTerraId = mData.id
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:HelpFirst(oPlayer,iTerraId)
end

function C2GSBuyLingli(oPlayer,mData)
    local iBuyTime = mData.buy_time
    local iTerraId = mData.terra_id
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:BuyLingli(oPlayer,iBuyTime,iTerraId)
end

function C2GSTerrawarOrgRank(oPlayer,mData)
    if not oPlayer:GetOrgID() then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"请先加入工会")
        return
    end
    local iPage = mData.page
    if iPage then
        return
    end
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("terrawars")
    oHuodong:GetTerrawarOrgRank(oPlayer,iPage)
end

function C2GSYJGuidanceReward(oPlayer,mData)
    if oPlayer.m_oActiveCtrl:GetData("YJGuidanceReward",0) >= 1 then
        return
    end
    local mInfo = oPlayer.m_oActiveCtrl:GetData("YJFirstInfo",{})
    if not next(mInfo) then
        return
    end
    local iItemId,iCount = table.unpack(mInfo)
    local oItem = loaditem.ExtCreate(iItemId)
    oItem:SetAmount(iCount)
    oPlayer:RewardItem(oItem,"首次月见副本碎片奖励")
    oPlayer.m_oActiveCtrl:SetData("YJGuidanceReward",1)
end

function C2GSGuideMingleiWar(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("minglei")
    oHuoDong:GuideMingleiWar(oPlayer)
end

function C2GSSocailDisplay(oPlayer, mData)
    local iDisplay = mData["id"]
    local iTargetPid = mData["target_pid"]
    local oHuodong = global.oHuodongMgr:GetHuodong("sociality")
    if oHuodong then
        if not oHuodong:IsOpenGrade(oPlayer) then
            oPlayer:NotifyMessage("未达开启等级")
            return
        end
        if oHuodong:IsClose(oPlayer) then
            return
        end
        if not oHuodong:ValidDisplaySociality(oPlayer, iTargetPid, iDisplay) then
            return
        end
        oHuodong:DisplaySociality(oPlayer, iTargetPid, iDisplay)
    end
end

function C2GSCancelSocailDisplay(oPlayer, mData)
    if oPlayer:IsSocialDisplay() then
        oPlayer:CancelSocailDisplay()
    end
end

function C2GSLeaveBattle(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
    oHuodong:LeaveBattle(oPlayer)
end

function C2GSOpenFieldBossUI(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
    oHuodong:OpenFieldBossUI(oPlayer)
end

function C2GSFieldBossInfo(oPlayer,mData)
    local iBossId = mData.bossid
    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
    oHuodong:GetFieldBossInfo(oPlayer,iBossId)
end

function C2GSFieldBossPk(oPlayer,mData)
    local iTarget = mData.target
    local oHuodong = global.oHuodongMgr:GetHuodong("fieldboss")
    oHuodong:ForcePk(oPlayer,iTarget)
end

function C2GSLeaveLegendFB(oPlayer,mData)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene.m_sType and oScene.m_sType == "caiquan" then
        local iGameID = oScene.m_CaiquanGame
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("game")
        local oGame = oHuodong:GetGame(iGameID)
        oGame:AbandonGame(oPlayer)
    end
end


function C2GSDailySign(oPlayer, mData)
    local sKey = mData.key
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("dailysign")
    if oHuodong then
        if oHuodong:IsClose(oPlayer, sKey) then
            return
        end
        if not oHuodong:IsOpenGrade(oPlayer, sKey) then
            return
        end
        oHuodong:DailySignIn(oPlayer, sKey)
    end
end

function C2GSGetOnlineGift(oPlayer,mData)
    local iRewardId = mData.rewardid
    local oHuodong = global.oHuodongMgr:GetHuodong("onlinegift")
    if oHuodong then
        oHuodong:ReceiveReward(oPlayer,iRewardId)
    end
end

function C2GSGetChapterInfo(oPlayer,mData)
    local iChapterId = mData.chapter
    local iType = mData.type
    oPlayer.m_oHuodongCtrl:GetChapterInfo(iChapterId,iType)
end

function C2GSFightChapterFb(oPlayer,mData)
    local iChapterId = mData.chapter
    local iLevel = mData.level
    local iType = mData.type
    local oHuodong = global.oHuodongMgr:GetHuodong("chapterfb")
    oHuodong:FightChapterFb(oPlayer,iChapterId,iLevel,iType)
end

function C2GSSweepChapterFb(oPlayer,mData)
    local iChapterId = mData.chapter
    local iLevel = mData.level
    local iType = mData.type
    local iCount = mData.count
    local oHuodong = global.oHuodongMgr:GetHuodong("chapterfb")
    oHuodong:SweepChapterFb(oPlayer,iChapterId,iLevel,iType,iCount)
end

function C2GSGetStarReward(oPlayer,mData)
    -- body
    local iChapterId = mData.chapter
    local iIndex = mData.index
    local iType = mData.type
    local oHuodong = global.oHuodongMgr:GetHuodong("chapterfb")
    oHuodong:GetStarReward(oPlayer,iChapterId,iType,iIndex)
end

function C2GSGetExtraReward(oPlayer,mData)
    local iChapterId = mData.chapter
    local iLevel = mData.level
    local iType = mData.type
    local oHuodong = global.oHuodongMgr:GetHuodong("chapterfb")
    oHuodong:GetExtraReward(oPlayer,iChapterId,iLevel,iType)
end

function C2GSChargeRewardGradeGift(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("charge")
    local iGrade = mData["grade"]
    local sType = "grade_gift1"
    oHuodong:TryRewardGradeGift(oPlayer,sType,iGrade)
end

function C2GSStarConvoy(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
    oHuodong:StarConvoy(oPlayer)
end

function C2GSGiveUpConvoy(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
    oHuodong:GiveUpConvoy(oPlayer)
end

function C2GSRefreshTarget(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
    oHuodong:RefreshTarget(oPlayer)
end

function C2GSChargeCardReward(oPlayer,mData)
end

function C2GSShowConvoy(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
    if oHuodong then
        oHuodong:ShowConvoyMainUI(oPlayer.m_iPid)
    end
end

function C2GSFightAttackMoster(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("msattack")
    if oHuodong then
        oHuodong:FightAttackMoster(oPlayer,mData.npcid)
    end
end

function C2GSReceiveEnergy(oPlayer,mData)
    local iIndex = mData.index
    oPlayer.m_oActiveCtrl:ReceiveEnergy(iIndex)
end

function C2GSContinueTraining(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("dailytrain")
    if oHuodong then
        oHuodong:StartTraning(oPlayer.m_iPid)
    end
end

function C2GSSetTrainReward(oPlayer,mData)
    local iClose = mData["close"]
    local oHuodong = global.oHuodongMgr:GetHuodong("dailytrain")
    if oHuodong then
        oHuodong:SetSwitch(oPlayer,iClose)
    end
end

function C2GSOrgWarGuide(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("orgwar")
    if oHuodong then
        oHuodong:C2GSOrgWarGuide(oPlayer)
    end
end

function C2GSOrgWarCanCelState(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("orgwar")
    if oHuodong then
        oHuodong:C2GSOrgWarCanCelState(oPlayer,mData.state)
    end
end

function C2GSOrgWarOption(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("orgwar")
    if oHuodong then
        local iCmd = mData.cmd
        oHuodong:C2GSOrgWarOption(oPlayer,iCmd)
    end
end

function C2GSOrgWarPK(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("orgwar")
    if oHuodong then
        local iTarget = mData.target
        oHuodong:C2GSOrgWarPK(oPlayer,iTarget)
    end
end

function C2GSSetHuntAutoSale(oPlayer,mData)
    local iAuto = mData["autosale"]
    local oHuodong = global.oHuodongMgr:GetHuodong("hunt")
    if oHuodong then
        oHuodong:SetAutoSale(oPlayer,iAuto)
    end
end

--召唤
function C2GSCallHuntNpc(oPlayer,mData)
    local iType = mData["type"]
    local oHuodong = global.oHuodongMgr:GetHuodong("hunt")
    if oHuodong then
        oHuodong:CallHuntNpc(oPlayer,iType)
    end
end

function C2GSHuntSoul(oPlayer,mData)
    local iLevel = mData["level"]
    local oHuodong = global.oHuodongMgr:GetHuodong("hunt")
    if oHuodong then
        oHuodong:HuntSoul(oPlayer,iLevel)
    end
end

function C2GSPickUpSoul(oPlayer,mData)
    local iCreateTime = mData["createtime"]
    local iId = mData["id"]
    local oHuodong = global.oHuodongMgr:GetHuodong("hunt")
    if oHuodong then
        oHuodong:PickUpSoul(oPlayer,iCreateTime,iId)
    end
end

function C2GSPickUpSoulByOneKey(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("hunt")
    if oHuodong then
        oHuodong:PickUpSoulByOneKey(oPlayer)
    end
end

function C2GSSaleSoulByOneKey(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("hunt")
    if oHuodong then
        oHuodong:SaleSoulByOneKey(oPlayer)
    end
end

function C2GSQuitTrain(oPlayer)
    local oHuodong = global.oHuodongMgr:GetHuodong("dailytrain")
    if oHuodong then
        oHuodong:QuitTrain(oPlayer)
    end
end

function C2GSHirePartner(oPlayer,mData)
    local iPartnerId = mData["parid"]
    local oHuodong = global.oHuodongMgr:GetHuodong("upcard")
    if oHuodong then
        if oHuodong:IsClose(oPlayer) then
            return
        end
        if not oHuodong:IsOpenGrade(oPlayer) then
            return
        end
        oHuodong:HirePartner(oPlayer,iPartnerId)
    end
end

function C2GSSendExpress(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("marry")
    if oHuodong then
        oHuodong:C2GSSendExpress(oPlayer,mData.content)
    end
end

function C2GSExpressResponse(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("marry")
    if oHuodong then
        oHuodong:C2GSExpressResponse(oPlayer,mData.result)
    end
end

function C2GSChangeLoversTitle(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("marry")
    if oHuodong then
        oHuodong:C2GSChangeLoversTitle(oPlayer,mData.postfix)
    end
end

function C2GSTerrawarsLog(oPlayer)
    local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
    if oHuodong then
        oHuodong:PackOrgLog(oPlayer)
    end
end

function C2GSTerraAskForHelp(oPlayer,mData)
    local iTerraId = mData["terraid"]
    local oHuodong = global.oHuodongMgr:GetHuodong("terrawars")
    if oHuodong then
        oHuodong:AskForHelp(iTerraId)
    end
end

function C2GSFindHuodongNpc(oPlayer,mData)
    local sHuodongName = mData["huodong_name"]
    local iNpcType = mData["npc_type"]
    local oHuodong = global.oHuodongMgr:GetHuodong(sHuodongName)
    if oHuodong then
        oHuodong:FindNpcPath(oPlayer,iNpcType)
    end
end

function C2GSFinishGetReward(oPlayer,mData)
    local sSysName = mData["sys_name"]
    global.oNotifyMgr:SendDelaySysMsg(sSysName,oPlayer.m_iPid)
end

--------------------------------等级礼包------------------------------
function C2GSReceiveFreeGift(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oNotifyMgr = global.oNotifyMgr
    local oHuodong = oHuodongMgr:GetHuodong("gradegift")
    if oHuodong then
        if oHuodong:IsOpenGrade(oPlayer) then
            oHuodong:ReceiveFreeGift(oPlayer, mData.grade)
        else
            oNotifyMgr:Notify(oPlayer:GetPid(), "等级不足")
        end
    end
end


--------------充值积分
function C2GSBuyCSItem(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("chargescore")
    if oHuodong then
        local iItemId = mData.id
        local iTimes = mData.times
        oHuodong:BuyItem(oPlayer,iItemId,iTimes)
    end
end


function C2GSReceiveAddCharge(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("addcharge")
    if oHuodong then
        oHuodong:ReceiveReward(oPlayer, mData.id)
    end
end

function C2GSDoMingleiCmd(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("minglei")
    if oHuodong then
        local iNpcid = mData["npcid"]
        local sCmd = mData["cmd"]
        local mAgrs = mData["args"]
        oHuodong:DoCmd(oPlayer,iNpcid,sCmd,mAgrs)
    end
end

function C2GSReceiveDayCharge(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("daycharge")
    if oHuodong then
        oHuodong:ReceiveReward(oPlayer, mData.id, mData.code)
    end
end

function C2GSGetTimeResumeReward(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("timelimitresume")
    if oHuodong then
        local iRewardId = mData.reward
        oHuodong:GetTimeResumeReward(oPlayer, iRewardId)
    end
end

function C2GSGetResumeRestoreReward(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("resume_restore")
    if oHuodong then
        oHuodong:GetResumeRestoreReward(oPlayer)
    end
end