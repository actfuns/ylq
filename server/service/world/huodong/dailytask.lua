-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

local BARRAGE_CNT = 100

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "每日任务"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_mBarrage = {}
end

function CHuodong:NewHour(iWeekDay, iHour)
    local iCheckTime = self:GetCheckTime()
    if iCheckTime  == 0 then
        self:TriggerTask(iHour)
        return
    end
    local func = function()
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("dailytask")
        oHuodong:TriggerTask(iHour)
    end
    self:DelTimeCb("_CheckTrigger")
    self:AddTimeCb("_CheckTrigger",iCheckTime*60*1000,func)
end

function CHuodong:TriggerTask(iHour)
    local oWorldMgr = global.oWorldMgr
    local mOnlinePlayer = oWorldMgr:GetOnlinePlayerList()
    local bOpen = res["daobiao"]["global_control"]["dailytask"]["is_open"]
    local iGrade = res["daobiao"]["global_control"]["dailytask"]["open_grade"]
    if bOpen ~= "y" then
        return
    end
    local iTriggerTime = self:GetTriggerTime()
    local iCheckInterval = self:GetCheckInterval()
    for iPid,oPlayer in pairs(mOnlinePlayer) do 
        local iCurTimes = oPlayer.m_oToday:Query("dailytask",0)
        local iLastCheckHour = oPlayer.m_oToday:Query("dailytask_checkhour",0)
        if oPlayer:GetGrade() >= iGrade and not oPlayer.m_oTaskCtrl:HasDailyTask() and iCurTimes < iTriggerTime and (iCurTimes == 0 or ((iHour - iLastCheckHour) >= iCheckInterval) ) then
            local iGmRate = oPlayer:GetInfo("GMDailyTaskRate",(30 + 4*(iTriggerTime-iCurTimes)) )
            if math.random(100) > (100-iGmRate) then
                oPlayer.m_oTaskCtrl:TirggerDailyTask()
            end
        end
        oPlayer.m_oToday:Set("dailytask_checkhour",iHour)
    end
    self:DelTimeCb("_CheckTrigger")
end

function CHuodong:GMTest(oPlayer)
    local func = function()
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("dailytask")
        oHuodong:TriggerTask(oPlayer.m_oToday:Query("dailytask_checkhour",0)+3)
    end
    self:DelTimeCb("_CheckTrigger")
    self:AddTimeCb("_CheckTrigger",10*1000,func)
end

function CHuodong:Load(mData)
    self.m_mBarrage = mData.barrage or {}
end

function CHuodong:GetTriggerTime()
    local sTime = res["daobiao"]["global"]["dailytask_triggertime"]["value"]
    return tonumber(sTime)
end

function CHuodong:GetCheckTime()
    local sTime = res["daobiao"]["global"]["dailytask_checktime"]["value"]
    return tonumber(sTime)
end

function CHuodong:GetCheckInterval()
    local sTime = res["daobiao"]["global"]["dailytask_checkinterval"]["value"]
    return tonumber(sTime)
end

function CHuodong:UpdateBarrage(mData)
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.barrage = self.m_mBarrage
    return mData
end

function CHuodong:GetTaskBarrage(oPlayer,iShowId)
    local mBarrage = self.m_mBarrage[tostring(iShowId)] or {}
    local mNet = table_deep_copy(mBarrage)
    if #mNet < BARRAGE_CNT then
        local res = require "base.res"
        local mData = table_deep_copy(res["daobiao"]["task_barrage"][iShowId] or {})
        if #mData > 0 then
            for i = #mNet,BARRAGE_CNT do
                local k = math.random(#mData)
                table.insert(mNet,{from_player = 0,msg = mData[k]["msg"]})
                table.remove(mData,k)
                if #mData == 0 then
                    break
                end
            end
        end
    end
    oPlayer:Send("GS2CSendTaskBarrage",{barrage = mNet,show_id = iShowId})
end

function CHuodong:SetTaskBarrage(oPlayer,iShowId,sMsg)
    self:Dirty()
    local mBarrage = self.m_mBarrage[tostring(iShowId)]
    if not mBarrage then
        self.m_mBarrage[tostring(iShowId)] = {[1]={msg=sMsg,from_player = 1,sender = oPlayer.m_iPid}}
    else
        if #mBarrage >= 100 then
            table.remove(mBarrage,1)
        end
        table.insert(mBarrage,{msg=sMsg,from_player = 1,sender = oPlayer.m_iPid})
    end
    oPlayer:Send("GS2CSendTaskBarrage",{barrage = {[1]={msg=sMsg,from_player = 1,sender = oPlayer.m_iPid}},show_id = iShowId})
end

function CHuodong:Fixbug()
    self:Dirty()
    local iClearCount = 0
    for iShowId,barrage in pairs(self.m_mBarrage) do
        local mBarrage = {}
        for _,info in pairs(barrage) do
            if string.find(info.msg,"群") or string.find(info.msg,"裙") or string.find(info.msg,"裙") or string.find(info.msg,"公众号") then
                iClearCount = iClearCount + 1
            else
                table.insert(mBarrage,info)
            end
        end
        self.m_mBarrage[iShowId] = mBarrage
    end
    print("liuwei-debug:clear barrage - ",iClearCount)
    
end