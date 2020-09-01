--import module

local global = require "global"
local taskobj = import(service_path("task/taskobj"))
local loadpartner = import(service_path("partner/loadpartner"))

CTask = {}
CTask.__index = CTask
CTask.m_sName = "story"
CTask.m_sTempName = "主线任务"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self,taskid)
    return o
end

function CTask:CheckGrade(iGrade)
    local iDoneGrade = self:GetData("grade")
    if not iDoneGrade then
        return
    end
    local oWorldMgr = global.oWorldMgr
    if iGrade < iDoneGrade then
        return
    end
    local iPid = self.m_Owner
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    oPlayer.m_oTaskCtrl:MissionDone(self,iPid)
end

function CTask:ConfigWar(oWar,pid,npcobj,iFight)
    local iWarid = oWar:GetWarId()
    --[[if self.m_ID == 10004 then
        local oFightPartner = loadpartner.CreatePartner(404)
        oFightPartner:SetData("traceno",{pid,102})
        local mFightPartner = {}
        mFightPartner[2] = oFightPartner
        oWar:SetData("fight_partner",mFightPartner)
    end--]]
    oWar:SetData("task_id",self.m_ID)
end

function CTask:WarFightEnd(oWar,iPid,oNpc,mArgs)
    if self.m_ID == 10001 or self.m_ID == 10004 then
        if mArgs and mArgs and mArgs.fight_partner then
            local mPartnerInfo = mArgs.fight_partner[iPid] or {}
            if self.m_ID == 10001 then
                if mPartnerInfo[100] then
                    mPartnerInfo[100] = nil
                end
            elseif self.m_ID == 10004 then
                if mPartnerInfo[102] then
                    mPartnerInfo[102] = nil
                end
            end
        end
    end
    super(CTask).WarFightEnd(self,oWar,iPid,oNpc,mArgs)
    
end

function CTask:GetCreateWarArg(mArg)
    local mArg2 = table_copy(mArg)
    if self.m_ID == 10001 or self.m_ID == 10004 then
        mArg2.war_type = self.m_ID
        mArg2.remote_war_type = "guidance"
    end
    return mArg2
end

function CTask:GetAcceptCallPlot()
    local mData = self:GetTaskData()
    return mData["AcceptCallPlot"]
end

function CTask:GetSubmitCallPlot()
    local mData = self:GetTaskData()
    return mData["submitCallPlot"]
end

function CTask:PackTaskInfo()
    local mNet = super(CTask).PackTaskInfo(self)
    mNet.acceptcallplot = self:GetAcceptCallPlot()
    mNet.submitcallplot = self:GetSubmitCallPlot()
    return mNet
end

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end