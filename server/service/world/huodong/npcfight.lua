--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "npcfight"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
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

function CHuodong:OnLogin(oPlayer, bReEnter)
    self:GS2CNpcFightInfoList(oPlayer)
end

function CHuodong:IsClose(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if oWorldMgr:IsClose("npcfight") then
        oNotifyMgr:Notify(iPid, "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return true
    end

    return false
end

function CHuodong:IsOpenGrade(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("npcfight", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return false
    end
    return true
end

function CHuodong:Fight(oPlayer, oNpc)
    local iPid = oPlayer:GetPid()
    if not self:ValidFight(oPlayer, oNpc) then
        local iDialog = oNpc:Type() * 100 + 2
        self:GS2CDialog(iPid, oNpc, iDialog)
        return
    end

    local iDialog = self:CreateDialogID(oPlayer, oNpc)
    if iDialog then
        self:GS2CDialog(iPid, oNpc, iDialog)
    end
end

function CHuodong:ValidFight(oPlayer, oNpc)
    local iFight = self:GetNpcFightAmount(oPlayer, oNpc:CommonFightID())
    local iTotal  = oNpc:GetTotalFight()
    if iTotal == 0 then
        return false
    end
    local mData = oNpc:GetData(oNpc:Type())
    if oPlayer:GetGrade() < mData.fight_grade then
        return false
    end
    if not oPlayer:IsSingle() then
        return false
    end
    return true
end

function CHuodong:CreateDialogID(oPlayer, oNpc)
    local iNpcType = oNpc:Type()
    local iFight = self:GetNpcFightAmount(oPlayer, oNpc:CommonFightID())
    local iTotal  = oNpc:GetTotalFight()
    if iFight < iTotal then
        return iNpcType * 100
    else
        return iNpcType * 100 + 1
    end
end

function CHuodong:GetDialogInfo(iDialog)
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["dialog"]
    assert(mData,string.format("Not Dialog Config:%s",self.m_sName))
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CHuodong:GS2CDialog(iPid, oNpc, iDialog)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local iFight = self:GetNpcFightAmount(oPlayer, oNpc:CommonFightID())
    local mDialogInfo = self:GetDialogInfo(iDialog)
    local m = {}
    m["dialog"] = {{
        ["type"] = mDialogInfo["type"],
        ["pre_id_list"] = mDialogInfo["pre_id_list"],
        ["content"] = string.format(mDialogInfo["content"], iFight),
        ["voice"] = mDialogInfo["voice"],
        ["last_action"] = mDialogInfo["last_action"],
        ["next"] = mDialogInfo["next"],
        ["ui_mode"] = mDialogInfo["ui_mode"],
        ["status"] = mDialogInfo["status"],
    }}
    m["dialog_id"] = iDialog
    m["npc_id"] = oNpc.m_ID
    m["npc_name"] = oNpc:Name()
    m["shape"] = oNpc:Shape()
    m["rewards"] = self:GetFightRewardIds(oPlayer, oNpc:GetData(oNpc:Type()))

    local iNpc = oNpc:ID()
    local func = function(oPlayer, mData)
        if mData.answer == 1 then
            local oNpc = global.oNpcMgr:GetObject(iNpc)
            if oNpc then
                self:TrueFight(oPlayer,oNpc)
            end
        end
    end
    global.oCbMgr:SetCallBack(iPid,"GS2CDialog",m,nil,func)
end

function CHuodong:GetFightRewardIds(oPlayer, mNpcData)
    local iFight = self:GetNpcFightAmount(oPlayer, mNpcData.fight_common_id)
    local iTotal  = mNpcData.fight_total or 0
    if iFight < 0 or iFight >= iTotal then
        return {}
    end
    local iTollgate = mNpcData.id * 100 + iFight
    local lReward = self:GetTollGateData(iTollgate)["fallRewardId"] or {}
    return table_value_list(lReward)
end

function CHuodong:TrueFight(oPlayer, oNpc)
    if oPlayer:GetNowWar() then
        return
    end
    if not self:ValidFight(oPlayer, oNpc) then
        return
    end
    local iFight = self:GetNpcFightAmount(oPlayer, oNpc:CommonFightID())
    local iTotal  = oNpc:GetTotalFight()
    if iFight >= iTotal then
        return
    end
    local iPid = oPlayer:GetPid()
    local iNpcType = oNpc:Type()
    -- local iFight = self:GetNpcFightAmount(oPlayer,iNpcType)
    local iTollgate = iNpcType * 100 + iFight
    local oWar = self:CreateWar(iPid,nil,iTollgate,nil)
    oWar:SetData("fight", iTollgate)
    oWar:SetData("npc_type", oNpc:Type())
    oWar:SetData("npc_name", oNpc:Name())
    oWar:SetData("npc_common_fight", oNpc:CommonFightID())

    --pid|玩家id,npcid|导表id,tollgate|关卡id,remain|剩余次数
    record.user("npcfight", "warstart", {
        pid = iPid,
        npcid = iNpcType,
        tollgate = iTollgate,
        remain = iFight,
        })
end

function CHuodong:OnWarWin(oWar, iPid, oNpc, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        record.warning("%s:OnWarFail, pid:%s offline!", self.m_sName, iPid)
        return
    end
    local iTollgate = oWar:GetData("fight")
     if iTollgate then
        local mTollgate = self:GetTollGateData(iTollgate)
        for _, iReward in ipairs(mTollgate.fallRewardId) do
            self:TeamReward(iPid, iReward, mArgs)
        end
        local iCommon = oWar:GetData("npc_common_fight")
        local iHaveFight = self:GetNpcFightAmount(oPlayer,iCommon)
        self:SetNpcFightAmount(oPlayer, iCommon, iHaveFight + 1)
        local sKey = string.format("战胜%s", oWar:GetData("npc_name"))
        oPlayer:PushBookCondition(sKey, {value = 1})
        self:GS2CNpcFightInfoList(oPlayer)
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30025,1)
        oPlayer:PushAchieve("挑战NPC", {value = 1})

        self:LogWarEnd(oWar, oPlayer, 1)
        --pid|玩家id,npcid|导表id,reward|奖励id
        local iNpcType = oWar:GetData("npc_type")
        record.user("npcfight", "reward", {
            pid = iPid,
            npcid = iNpcType,
            reward = ConvertTblToStr(mTollgate.fallRewardId),
            })
     else
        local record = require "public.record"
        record.error("npcfight error:OnWarWin, tollgate id not exsit!")
     end
end

function CHuodong:OnWarFail(oWar, pid, npcobj, mArgs)
    super(CHuodong).OnWarFail(self, oWar, pid, npcobj, mArgs)

    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        record.warning("%s:OnWarFail, pid:%s offline!", self.m_sName, pid)
        return
    end
    self:LogWarEnd(oWar, oPlayer, 0)
end

function CHuodong:LogWarEnd(oWar, oPlayer, iResult)
     local iNpcType = oWar:GetData("npc_type")
    local iCommon = oWar:GetData("npc_common_fight")
    --pid|玩家id,npcid|导表id,tollgate|关卡id,remain|剩余次数,result|结果(1胜利)
    record.user("npcfight", "warend", {
        pid = oPlayer:GetPid(),
        npcid = iNpcType,
        tollgate = oWar:GetData("fight"),
        remain = self:GetNpcFightAmount(oPlayer, iCommon),
        result = iResult,
        })
end

function CHuodong:GetNpcFightAmount(oPlayer, iCommon)
    local mAmount = oPlayer.m_oActiveCtrl:GetData("npc_fight", {})
    return mAmount[db_key(iCommon)] or 0
end

function CHuodong:SetNpcFightAmount(oPlayer, iCommon, iAmount)
    local mAmount = oPlayer.m_oActiveCtrl:GetData("npc_fight", {})
    local sNpcType = db_key(iCommon)
    mAmount[sNpcType] =iAmount
    oPlayer.m_oActiveCtrl:SetData("npc_fight", mAmount)
end

function CHuodong:GS2CNpcFightInfoList(oPlayer)
    local res = require "base.res"
    local mAmount = oPlayer.m_oActiveCtrl:GetData("npc_fight", {})
    local mNpcData = res["daobiao"]["global_npc"]
    local lNet = {}
    local mTmp = {}
    for iNpcType, m in pairs(mNpcData) do
        if m.fight and m.fight > 0 then
            local iCommon = m.fight_common_id
            if not mTmp[iCommon] then
                table.insert(lNet, {
                    npc_type = iCommon,
                    fight = self:GetNpcFightAmount(oPlayer, iCommon),
                    total = m.fight_total or 100000,
                    rewards = self:GetFightRewardIds(oPlayer, m)
                    })
                mTmp[iCommon] = 1
            end
        end
    end
    oPlayer:Send("GS2CNpcFightInfoList", {info_list = lNet})
end

function CHuodong:TestOP(oPlayer, sCmd, ...)
    if sCmd == "resetnpc" then
        oPlayer.m_oActiveCtrl:SetData("npc_fight", {})
        global.oNotifyMgr:Notify(oPlayer:GetPid(), "已重置所有npc")
    end
end