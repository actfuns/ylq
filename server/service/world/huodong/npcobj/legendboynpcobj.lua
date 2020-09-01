--import module

local global = require "global"
local extend = require "base.extend"
local npcobj = import(service_path("npc/npcobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
local geometry = require "base.geometry"
local record = require "public.record"

CLegendBoyNpc = {}
CLegendBoyNpc.__index = CLegendBoyNpc
inherit(CLegendBoyNpc, npcobj.CNpc)

function NewClientNpc(mArgs)
    local o = CLegendBoyNpc:New(mArgs)
    return o
end

function CLegendBoyNpc:New(mArgs)
    local o = super(CLegendBoyNpc).New(self)
    o:Init(mArgs)
    return o
end

function CLegendBoyNpc:Init(mArgs)
    local mArgs = mArgs or {}
    self.m_iType = mArgs["type"]
    self.m_iMapid = mArgs["map_id"] or 0
    self.m_mModel = mArgs["model_info"] or {}
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iEvent = mArgs["event"] or 0
    self.m_iReUse = mArgs["reuse"]
    self.m_sSysName = mArgs.sys_name
    self.m_iOwner = mArgs.owner
    self.m_iCreateTime = mArgs.createtime or get_time()
    self.m_iDoneTime = mArgs.donetime or 0
    self:CountDown()
end

function CLegendBoyNpc:Save()
    local data = {}
    data["type"] = self.m_iType
    data["map_id"] = self.m_iMapid
    data["model_info"] = self.m_mModel
    data["pos_info"] = self.m_mPosInfo

    data["reuse"]  = self.m_iReUse
    data["event"] = self.m_iEvent
    data.owner = self.m_iOwner
    data.createtime = self.m_iCreateTime
    data.sys_name = self.m_sSysName
    return data
end

function CLegendBoyNpc:SetEvent(iEvent)
    self.m_iEvent = iEvent
end

function CLegendBoyNpc:CheckTimeOut()
    local iCurTime = get_time()
    if (iCurTime - self.m_iCreateTime) >= (30*60*1000) then
        return true
    end
    return false
end

function CLegendBoyNpc:CountDown()
    local iTime = self:Timer()
    if iTime <= 0 then
        self:TimeOut()
        return
    end
    self:DelTimeCb("timeout")
    self:AddTimeCb("timeout",iTime, function()  self:TimeOut()  end)
end

function CLegendBoyNpc:Timer()
    local iCurTime = get_time()
    return ((30*60) - (iCurTime - self.m_iCreateTime))*1000
end

function CLegendBoyNpc:TimeOut()
    self:DelTimeCb("timeout")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    if oPlayer then
        oPlayer.m_oHuodongCtrl:RemoveClientNpc("legendboynpc",self.m_ID,"timeout")
    end
end

function CLegendBoyNpc:PackInfo()
    local mData = {
            npctype = self.m_iType,
            npcid      = self.m_ID,
            name = self:Name(),
            title = self:Title(),
            map_id = self.m_iMapid,
            pos_info = self:GetPos(),
            model_info = self.m_mModel,
            createtime = self.m_iCreateTime,
            sceneid = self.m_iScene,
    }
    return mData
end

function CLegendBoyNpc:GetPos()
    local mPos = self.m_mPosInfo
    local pos_info = {
            x = math.floor(geometry.Cover(mPos.x)),
            y = math.floor(geometry.Cover(mPos.y)),
            z = math.floor(geometry.Cover(mPos.z)),
            face_x = math.floor(geometry.Cover(mPos.face_x)),
            face_y = math.floor(geometry.Cover(mPos.face_y)),
            face_z = math.floor(geometry.Cover(mPos.face_z)),
        }
     return pos_info
end

function CLegendBoyNpc:DoScript(pid,s,mArgs)
    if type(s) ~= "table" then
        return
    end
    for _,ss in pairs(s) do
        self:DoScript2(pid,ss,mArgs)
    end
end

function CLegendBoyNpc:DoScript2(pid,s,mArgs)
    if string.sub(s,1,2) == "DI" then
        local iDialog = string.sub(s,3,-1)
        iDialog = tonumber(iDialog)
        self:GS2CDialog(pid,iDialog)
    elseif string.sub(s,1,5) == "ENTER" then
        self:EnterLegendFb()
    elseif string.sub(s,1,2) == "CP" then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
        oPlayer:Send("GS2CGetLegendTeam",{})
    elseif string.sub(s,1,7) == "CONFIRM" then
        self:_TrueEnterLegendFB(pid)
    end
end

function CLegendBoyNpc:EnterLegendFb()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    local oTeam = oPlayer:HasTeam()
    if not oTeam or (oTeam and oTeam:MemberSize() < 4 )then
        self:DoScript(pid,{"DI102"})
    else
        self:_TrueEnterLegendFB(self.m_iOwner)
    end
end

function CLegendBoyNpc:GetRewardData()
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("treasure")
    return oHuodong:GetLegendReward()
end

function CLegendBoyNpc:_TrueEnterLegendFB(iPid)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("game")
    local mArgs = {}
    mArgs.owner = iPid
    mArgs.sys_name = "treasure"
    mArgs.exit_gate = self:GetPos()
    mArgs.reward = self:GetRewardData()
    local oGame = oHuodong:NewGame("caiquan",mArgs)
    local oTeam = oPlayer:HasTeam()
    local sEnterPlayer = ""
    if oTeam then
        if not oTeam:IsLeader(iPid) then
            oNotifyMgr:Notify(iPid,"你必须以队长的身份进入幻境")
            baseobj_delay_release(oGame)
            return
        end
        local mMem = oTeam:GetTeamMember()
        local sInvalidName = ""
        local bAllValid = true
        for i = 1,#mMem do
            local iMID = mMem[i]
            local oMem = oWorldMgr:GetOnlinePlayerByPid(iMID)
            if oMem and oMem:GetGrade() < 13 then
                bAllValid = false
                sInvalidName = sInvalidName..oMem:GetName()..((i==#mMem) and " " or "、")
            else
                if iPid == iMID then
                    oGame:AddPlayer(iMID,1)
                else
                    oGame:AddPlayer(iMID,2)
                end
                sEnterPlayer=sEnterPlayer..iMID.."、"
            end
            
        end
        if not bAllValid then
            oNotifyMgr:Notify(iPid,string.format("队伍中 %s 等级低于13级，无法进入幻境",sInvalidName))
            baseobj_delay_release(oGame)
            return
        end
    else
        if oPlayer:GetGrade() < 13 then
            oNotifyMgr:Notify(iPid,"你的等级低于13级，不可进入该副本")
            baseobj_delay_release(oGame)
            return
        end
        oGame:AddPlayer(iPid,1)
    end
    oGame:OnGameStart()
    record.user("treasure","legendboy_enter",{npcid=self.m_ID,enterplayer=sEnterPlayer,gameid=oGame.m_ID})
    oPlayer.m_oHuodongCtrl:RemoveClientNpc("legendboynpc",self.m_ID,"进入副本移除npc")
end

function CLegendBoyNpc:GetEventData(iEvent)
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"]["treasure"]["event"][iEvent]
    assert(mData,string.format("Not Event Config:%s",self.m_sName))
    return mData
end

function CLegendBoyNpc:GetCostBaseData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"]["treasure"]["playboy_cost"]
    assert(mData,string.format("Not PlayBoyCost Config:%s",self.m_sName))
    return mData
end

function CLegendBoyNpc:GetDialogBaseData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"]["treasure"]["dialog"]
    assert(mData,string.format("Not PlayBoyDialog Config:%s",self.m_sName))
    return mData
end

function CLegendBoyNpc:GetDialogInfo(iDialog)
    local mData = self:GetDialogBaseData()
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CLegendBoyNpc:do_look(oPlayer)
    local mEvent = self:GetEventData(self.m_iEvent)
    self:DoScript(self.m_iOwner,mEvent["look"])
end

function CLegendBoyNpc:GetCostInfo()
    local mCostData = self:GetCostBaseData()
    for _,info in pairs(mCostData) do
        if info.times == (self.m_iDoneTime + 1) then
            return table_deep_copy(info)
        end
    end
end

function CLegendBoyNpc:GS2CDialog(iPid,iDialog)
    local mDialogInfo = self:GetDialogInfo(iDialog)
    if not mDialogInfo then
        return
    end
    local m = {}
    m["dialog"] = {{
        ["type"] = mDialogInfo["type"],
        ["pre_id_list"] = mDialogInfo["pre_id_list"],
        ["content"] = mDialogInfo["content"],
        ["voice"] = mDialogInfo["voice"],
        ["last_action"] = mDialogInfo["last_action"],
        ["next"] = mDialogInfo["next"],
        ["ui_mode"] = mDialogInfo["ui_mode"],
        ["status"] = mDialogInfo["status"],
    }}
    m["dialog_id"] = iDialog
    m["npc_id"] = self.m_ID
    m["npc_name"] = self:Name()
    m["shape"] = self:Shape()
    m["playboyinfo"] = {endtime = self:Timer()/1000}
    local iNpcId = self.m_ID
    local iOwner = self.m_iOwner
    local func = function(oPlayer,mArgs)
        if mArgs.answer and mArgs.answer ~= 0 then
            local event = mDialogInfo["last_action"][mArgs.answer]["event"]
            if event then
                local oWorldMgr = global.oWorldMgr
                local oP = oWorldMgr:GetOnlinePlayerByPid(iOwner)
                if not oP then
                    return
                end
                local oNpc = oP.m_oHuodongCtrl:GetNpcByID("legendboynpc",iNpcId)
                if not oNpc then
                    return
                end
                oNpc:DoScript(iOwner,{event})
            end
        end
    end
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    local iSessionidx = oCbMgr:SetCallBack(self.m_iOwner,"GS2CDialog",m,nil,func)
    oPlayer.m_oHuodongCtrl:AddNpcSessionId(self.m_ID,iSessionidx)
end

function CLegendBoyNpc:Release()
    self:DelTimeCb("timeout")
    super(CLegendBoyNpc).Release(self)
end

function CLegendBoyNpc:GetData()
    local res = require"base.res"
    local mData = res["daobiao"]["huodong"][self.m_sSysName] or {}
    assert(mData["npc"],string.format("miss %s npc config :%s",self.m_sSysName,self.m_iType))
    return mData["npc"][self.m_iType]
end

function CLegendBoyNpc:Name()
    local mNpcInfo = self:GetData()
    return mNpcInfo["name"]
end

function CLegendBoyNpc:Title()
    local mNpcInfo=self:GetData()
    return mNpcInfo["title"]
end