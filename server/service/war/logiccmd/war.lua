--import module
local global = require "global"
local skynet = require "skynet"
local netproto = require "base.netproto"
local playersend = require "base.playersend"
local record = require "public.record"
local interactive = require "base.interactive"
local gamedefines = import(lualib_path("public.gamedefines"))

ForwardNetcmds = {}

function ForwardNetcmds.C2GSWarSkill(oPlayer, mData)
        local l1 = mData.action_wlist
        local l2 = mData.select_wlist
        local iSkill = mData.skill_id

        local iWid = l1[1]
        local iMy = oPlayer:GetWid()
        local oWar = oPlayer:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if oAction and (oAction:GetWid() == iMy  or oAction:GetData("owner") == iMy)  then
            oAction:Set("action_skill",iSkill)
            oAction:SetBoutArgs("action_skill",iSkill)
            oWar:AddBoutCmd(iWid,{
                cmd = "skill",
                data = {
                    action_wlist = l1,
                    select_wlist = l2,
                    skill_id = iSkill,
                }})
            oWar:FinishOperate(oAction)
        end
end

function ForwardNetcmds.C2GSDebugPerform(oPlayer, mData)
    --[[
    local oWar = oPlayer:GetWar()
    local sDebug = mData["debug"]
    --"51201_1_10时间:2307"
    local t = {}
    for sk,mgi,v,time in string.gmatch(sDebug,"(%S+)_(%S+)_(%S+)时间:(%S+)") do
        t["skill"]=tonumber(sk)
        t["mgi"]=tonumber(mgi)
        t["time"]=tonumber(time)
    end
    table.insert(oWar.m_DebugClientTime,t)
    ]]
end


function ForwardNetcmds.C2GSWarNormalAttack(oPlayer, mData)
        local iActionWid = mData.action_wid
        local iSelectWid = mData.select_wid

        local oWar = oPlayer:GetWar()
        local oAction = oWar:GetWarrior(iActionWid)
        if oAction then
            oWar:FinishOperate(iActionWid,mData, {
                cmd = "normal_attack",
                data = {
                    action_wid = iActionWid,
                    select_wid = iSelectWid,
                }
            })
        end
end

function ForwardNetcmds.C2GSWarEscape(oPlayer, mData)
        local iActionWid = mData.action_wid
        local oWar = oPlayer:GetWar()
        if iActionWid == 0 then
            iActionWid = oPlayer:GetWid()
        end
        oWar:OnWarEscape(oPlayer,iActionWid)
end

function ForwardNetcmds.C2GSWarDefense(oPlayer, mData)
        local iActionWid = mData.action_wid

        local oWar = oPlayer:GetWar()
        local oAction = oWar:GetWarrior(iActionWid)
        if oAction then
            oWar:FinishOperate(oAction, oPlayer,{
                cmd = "defense",
                data = {
                    action_wid = iActionWid,
                }
            })
        end
end

function ForwardNetcmds.C2GSWarProtect(oPlayer, mData)

end

function ForwardNetcmds.C2GSWarStop(oPlayer,mData)
    local oWar = oPlayer:GetWar()
    if oWar and oWar:IsSinglePlayer() then
        oWar:PlayerStop()
    end
end

function ForwardNetcmds.C2GSWarStart(oPlayer,mData)
    local oWar = oPlayer:GetWar()
    if oWar and oWar:IsSinglePlayer() then
        oWar:PlayerStart()
    end
end

function ForwardNetcmds.C2GSWarPartner(oPlayer,mData)
    local oActionMgr = global.oActionMgr
    local iActionWid = oPlayer:GetWid()
    local oWar = oPlayer:GetWar()
    local mPartner = mData.partner
    oActionMgr:WarPartner(oPlayer,mPartner)
end

function ForwardNetcmds.C2GSWarPrepareCommand(oPlayer,mData)
    local oWar = oPlayer:GetWar()
    local iActionWid = oPlayer:GetWid()
    local oAction = oWar:GetWarrior(iActionWid)
    if not oAction then
        return
    end
    if not oWar:IsConfig() then
        return
    end
    oPlayer:Set("fight_partner",{})
    local mPartner = mData["partner_list"]
    local iCamp = oPlayer:GetCampId()
    local oCamp = oWar:GetCamp(iCamp)
    for _,mInfo in pairs(mPartner) do
        local iPartnerId = mInfo["parid"] or 0
        local iPos = mInfo["pos"] or 0
        local oPartner = oCamp:GetPartnerByID(iActionWid,iPartnerId)
        if not oPartner then
            return
        end
        local oPartner = oWar:GetWarriorByPos(iCamp,iPos)
        if oPartner and (not oPartner:IsPartner() or oPartner:GetData("owner") ~= oPlayer:GetWid()) then
            return
        end
    end

    oWar:AddWarConfigCmd(iActionWid)
    local oCamp = oAction:GetCamp()
    if oCamp:IsSinglePlayer() then
        oWar:PreparePartnerCommand(oPlayer,mPartner)
    end
end

function ForwardNetcmds.C2GSWarTarget(oPlayer,mData)
    local iWid = mData.select_wid
    local iType = mData.type
    oPlayer:SetWarTarget(iType,iWid)
end

function ForwardNetcmds.C2GSWarAutoFight(oPlayer,mData)
    local iType = mData.type
    if not oPlayer:IsPlayer() then
        return
    end
    local oWar = oPlayer:GetWar()
    if iType == 0 then
        oWar:CancleAutoFight(oPlayer)
    elseif iType == 1 then
        oPlayer:AutoFight()
    elseif iType == 2 then
        local oWar = oPlayer:GetWar()
        if oWar:IsStop() then
            return
        end
        oPlayer:AutoFight()
    elseif iType == 3 then
        oPlayer:NowFight()
    end
end

function ForwardNetcmds.C2GSChangeAutoSkill(oPlayer,mData)
    local iWid = mData.wid
    local iAutoSkill = mData.auto_skill
    local oWar = oPlayer:GetWar()
    if iWid == oPlayer:GetWid() then
        oPlayer:SetData("auto_skill",iAutoSkill)
        oPlayer:AutoSkillStatusChange()
        oPlayer:Set("action_skill",iAutoSkill)
        if oWar:GetWarType() == "dailytrain" then
            interactive.Send(".world", "dailytrain", "SetAutoSkill", {skill = iAutoSkill, pid = oPlayer.m_iPid})
        end
    else
        local oPartner = oWar:GetWarrior(iWid)
        if not oPartner or not oPartner:IsPartner() then
            return
        end
        oPartner:SetAutoSkill(iAutoSkill,true)
        oPartner:Set("action_skill",iAutoSkill)
    end
end

function ForwardNetcmds.C2GSSelectCmd(oPlayer,mData)
    local oWar = oPlayer:GetWar()
    if oWar then
        local wid = mData["wid"]
        local skill = mData["skill"]
        local oWarrior = oWar:GetWarrior(wid)
        if oWarrior then
            oWar:SyncOperateCmd(oWarrior,skill)
        end
    end
end

function ForwardNetcmds.C2GSNextBoutStart(oPlayer,mData)
end

function ForwardNetcmds.C2GSNextActionEnd(oPlayer,mData)
    local oWar = oPlayer:GetWar()
    local iActionID = mData.action_id
    if iActionID ~= oWar.m_ActionId then
        return
    end
    if oWar:IsSinglePlayer() or oWar:IsPVEWar() then
        oWar:NextActionStart()
    else
        oWar:AddActionEnd(oPlayer)
        oWar:CheckStartNextAction()
    end
end

function ForwardNetcmds.C2GSWarSetPlaySpeed(oPlayer,mData)
    local oWar = oPlayer:GetWar()
    if not oWar then
        return
    end
    local iSpeed = mData["play_speed"]
    if iSpeed == oPlayer:GetPlaySpeed() then
        return
    end
    if oWar:IsSinglePlayer() then
        oPlayer:SetPlaySpeed(iSpeed)
    elseif oWar:IsPVEWar() then
        if not oPlayer:GetData("is_team_leader") then
            --oPlayer:Notify("战斗加速同步队长的加速状态，请让队长进行修改")
            return
        end
        for pid,wid in pairs(oWar.m_mPlayers) do
            local o = oWar:GetPlayerWarrior(pid)
            if o then
                o:SetPlaySpeed(iSpeed)
            end
        end
    end
end

function ForwardNetcmds.C2GSWarBattleCommand(oPlayer,mData)
    oPlayer:BattleCommand(mData["wid"],mData["cmd"])
end

function ForwardNetcmds.C2GSCleanWarBattleCommand(oPlayer,mData)
    oPlayer:CleanBattleCommand(mData["wid"])
end

function C2GSEndFilmBout(mRecord, mData)
    local iWarId = mData["war_id"]
    local m = mData["data"]
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar.m_sWarType ~= "warfilm" then
        return
    end
    oWar:NextFilmBout(m.bout or 0)
end



function ConfirmRemote(mRecord, mData)
    local iWarId = mData.war_id
    local sType = mData.war_type
    local mArgs = mData.remote_args
    local oWarMgr = global.oWarMgr
    oWarMgr:ConfirmRemote(iWarId,sType,mArgs.remote,mArgs.extra_arg)
end

function RemoveRemote(mRecord, mData)
    local iWarId = mData.war_id
    local oWarMgr = global.oWarMgr
    oWarMgr:RemoveWar(iWarId)
end

function EnterPlayer(mRecord, mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local iCamp = mData.camp_id
    local mInfo = mData.data
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    assert(oWar, string.format("EnterPlayer error war: %d %d", iWarId, iPid))
    playersend.ReplacePlayerMail(iPid)
    oWar:EnterPlayer(iPid, iCamp, mInfo)
end

function LeavePlayer(mRecord, mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        oWar:LeavePlayer(iPid)
    end
end

function ReEnterPlayer(mRecord, mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    assert(oWar, string.format("ReEnterPlayer error war: %d %d", iWarId, iPid))
    playersend.ReplacePlayerMail(iPid)
    local oPlayer = oWar:GetPlayerWarrior(iPid)
    if not oPlayer then
        return
    end
    if oWar:IsWarEnd() and oWar.m_bEndEffect then
        oPlayer:SendAll("GS2CWarResult",{
            war_id = oWar:GetWarId(),
            win_side = 1,
            })
        return
    end
    oWar:ReEnterPlayer(iPid)
end

function EnterObserver(mRecord, mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    assert(oWar, string.format("EnterObserver error war: %d %d", iWarId, iPid))
    playersend.ReplacePlayerMail(iPid)
    oWar:EnterObserver(iPid)
end

function LeaveObserver(mRecord, mData)
    local iWarId = mData.war_id
    local iPid = mData.pid

    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    assert(oWar, string.format("LeaveObserver error war: %d %d", iWarId, iPid))
    oWar:LeaveObserver(iPid)
end

function NotifyDisconnected(mRecord, mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        local oPlayerWarrior = oWar:GetPlayerWarrior(iPid)
        if oPlayerWarrior then
            oPlayerWarrior:Disconnected()
        end
        local oObserver = oWar:GetObserver(iPid)
        if oObserver then
            oObserver:Disconnected()
        end
        oWar:CheckStartNextAction()
    end
end

function WarStart(mRecord, mData)
    local iWarId = mData.war_id
    local mInfo = mData.info
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        oWar:WarStart(mInfo)
    end
end

function WarPrepare(mRecord, mData)
    local iWarId = mData.war_id
    local mInfo = mData.info
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        oWar:WarPrepare(mInfo)
    end
end

function RemoteSerialWar(mRecord,mData)
    local iWarId = mData.war_id
    local mInfo = mData.info
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar and oWar:GetWarType() == "serialwar" then
        oWar:StartSerialWar(mInfo)
    end
end

function PreparePartner(mRecord,mData)
    local iWarId = mData.war_id
    local mInfo = mData.info
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        oWar:PreparePartner(mInfo)
    end
end

function PrepareRomWar(mRecord,mData)
    local iWarId = mData.war_id
    local mInfo = mData.info
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        oWar:PrepareRomWar(mInfo)
    end
end

function WarStartConfig(mRecord,mData)
    local iWarId = mData.war_id
    local mInfo = mData.info
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        oWar:WarStartConfig(mInfo)
    end
end

function TestCmd(mRecord, mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local sCmd = mData.cmd
    local m = mData.data

    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    local oPlayer = oWar:GetPlayerWarrior(iPid)
    if oWar then
        if sCmd == "wartimeover" then
            oWar:BoutProcess()
        elseif sCmd == "warend" then
            if oWar.m_iWarResult ~= 0 then
                return
            end
            oWar.m_iWarResult = m["war_result"] or 1
            oWar:WarEndEffect()
        elseif sCmd == "win" then
            if oWar.m_iWarResult ~= 0 then
                return
            end
            oWar.m_iWarResult = oPlayer:GetCampId()
            oWar:WarEndEffect()
        elseif sCmd == "fail" then
            if oWar.m_iWarResult ~= 0 then
                return
            end
            oWar.m_iWarResult = oPlayer:GetEnemyCampId()
            oWar:WarEndEffect()
        elseif sCmd == "setwarattr" then
            local oPlayer = oWar:GetPlayerWarrior(iPid)
            if oPlayer then
                oPlayer:SetTestData(m["attr"], m["val"])
            end
        elseif sCmd == "addsp" then
            oWar:AddSP(1,m.sp)
        elseif sCmd == "addbuff" then
            local iWid = m["wid"]
            local iBout = m["bout"] or 5
            local oAction = oWar:GetWarrior(iWid)
            if not oAction then
                return
            end
            oAction:SetBoutArgs("suspend",iBout)
        elseif sCmd == "wardebug" then
            oWar:DebugWarrior()
        elseif sCmd == "playerwarskill" then
            local oPlayer = oWar:GetPlayerWarrior(iPid)
            if not oPlayer then
                return
            end
            for iSkill,iLv in pairs(m) do
                if not oPlayer:GetPerform(iSkill) then
                    oPlayer:SetPerform(iSkill,iLv)
                end
            end
        elseif sCmd == "SetHP" then
            for wid,iHP in pairs(m) do
                iHP = tonumber(iHP)
                wid = tonumber(wid)
                local o = oWar:GetWarrior(wid)
                if o then
                    o:SetData("hp",iHP)
                    o:ModifyHp(0)
                end
            end
        elseif sCmd == "addplayerbuff" then
            local iBuff = m["buff"]
            local iBout = m["bout"]
            local mArgs = {
                level = 1,
                attack = oPlayer:GetWid(),
                buff_bout = oWar.m_iBout,
            }
            oPlayer.m_oBuffMgr:AddBuff(iBuff,iBout,mArgs)
        end

    end
end

function Forward(mRecord, mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local sCmd = mData.cmd
    local m = netproto.ProtobufFunc("default", sCmd, mData.data)

    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        local oPlayer = oWar:GetPlayerWarrior(iPid)
        if oPlayer then
            local oWar = oPlayer:GetWar()
            if oWar and sCmd ~= "C2GSDebugPerform" then
                oWar:HeartBeat(iPid)
            end
            local func = ForwardNetcmds[sCmd]
            if func then
                func(oPlayer, m)
            end
        end
    end
end

function WarChat(mRecord, mData)
    local iWarId = mData.war_id
    local mNet = mData.net
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        oWar:SendAll("GS2CChat", mNet)
    end
end

function ForceRemoveWar(mRecord,mData)
    local iWarId = mData.war_id
    local iWarResult = mData.war_result
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        oWar.m_iWarResult = iWarResult or 2
        oWar:WarEnd()
    end
end

function AddTerraWarsDefenderCmd(oPlayer,mData)
    local iWarId = mData.war_id
    local iPid = mData.pid
    local oWarMgr = global.oWarMgr
    local oWar = oWarMgr:GetWar(iWarId)
    if oWar then
        local oPlayerWarrior = oWar:GetPlayerWarrior(iPid)
        if oPlayerWarrior then
            local iActionWid = oPlayerWarrior:GetWid()
            local oAction = oWar:GetWarrior(iActionWid)
            if not oAction then
                return
            end
            if not oWar:IsConfig() then
                return
            end
            oWar:AddWarConfigCmd(iActionWid)
        end
    end
end