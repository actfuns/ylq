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
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o.m_mHuodong = {}
    o:Init()
    return o
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Load(mData)
    mData = mData or {}
    for _, m in ipairs(mData) do
        self.m_mHuodong[m.name] = m.data
    end
end

--m={starttime, endtime, plan}
function CHuodong:Save()
    local mData = {}
    for sName, m in pairs(self.m_mHuodong) do
        table.insert(mData, {
            name = sName,
            data = m,
            })
    end
    return mData
end

function CHuodong:IsOpen(sName)
    local m = self.m_mHuodong[sName]
    if not m then
        return false
    end
    local iNow = get_time()
    return iNow >= m.starttime and iNow < m.endtime
end

function CHuodong:DispatchID(sName)
    local m = self.m_mHuodong[sName] or {}
    return (m.dispatch_id or 0) + 1
end

function CHuodong:IsClose(sName)
    local m = self.m_mHuodong[sName]
    if not m then
        return true
    end
    local iNow = get_time()
    return iNow >= m.endtime
end

function CHuodong:StartTime(sName)
    local m = self.m_mHuodong[sName]
    return m and m.starttime
end

function CHuodong:EndTime(sName)
    local m = self.m_mHuodong[sName]
    return m and m.endtime
end

function CHuodong:GetOpenData(idx)
    local res =require "base.res"
    return res["daobiao"]["open_limit"][idx]
end

function CHuodong:ValidSetOpen(mArgs)
    mArgs = mArgs or {}
    local idx = mArgs.idx
    if not idx then
        return {errcode = 1004, errmsg = "导表数据不存在"}
    end
    if not mArgs.plan then
        return {errcode = 1005, errmsg = "导表数据不存在"}
    end
    local mData = self:GetOpenData(idx)
    if not mData then
        return {errcode = 1001, errmsg = "导表数据不存在"}
    end
end

function CHuodong:SetOpenInfo(mData)
    local mErr = self:ValidSetOpen(mData)
    if not mErr then
        self:Dirty()
        local oHuodongMgr = global.oHuodongMgr
        local idx =mData.idx
        local m = {}
        local mDaoBiao = self:GetOpenData(idx)
        m.dispatch_id = self:DispatchID(mDaoBiao.server_file)
        m.bchange = true
        m.starttime = mData.starttime
        m.endtime = mData.endtime
        m.plan = mData.plan
        m.idx = idx
        local sName = mDaoBiao.server_file
        self.m_mHuodong[sName] = m
        local oHuodong = oHuodongMgr:GetHuodong(sName)
        if oHuodong and oHuodong.BackendOpen then
            oHuodong:BackendOpen()
        end
        mErr = {errcode =  0}

        --idx|活动索引,name|活动名,version|版本号,plan|方案id,starttime|开启时间,endtime|结束时间
        record.user("limitopen", "setopen", {
            idx = idx,
            name = mDaoBiao.server_file,
            version = m.dispatch_id or 0,
            plan = m.plan or 0,
            starttime = get_format_time(m.starttime),
            endtime = get_format_time(m.endtime),
            })
    end
    return mErr
end

function CHuodong:CheckChange(sName)
   local m = self.m_mHuodong[sName] or {}
   return m.bchange
end

function CHuodong:ClearChange(sName)
    self:Dirty()
    local m = self.m_mHuodong[sName] or {}
    m.bchange = nil
end

function CHuodong:CheckDispatchID(sName, iDispatch)
    local m = self.m_mHuodong[sName] or {}
    return iDispatch == m.dispatch_id
end

function CHuodong:GetDispatchID(sName)
    local m = self.m_mHuodong[sName] or {}
    return m.dispatch_id or 0
end

function CHuodong:GetUsePlan(sName)
    local m = self.m_mHuodong[sName] or {}
    return m.plan or 1
end

function CHuodong:GetOpenInfo(sName)
    return self.m_mHuodong[sName]
end

function CHuodong:IsOpenGrade(sName, oPlayer)
    local m = self.m_mHuodong[sName]
    if m then
        local mDaoBiao = self:GetOpenData(m.idx)
        return mDaoBiao and mDaoBiao.grade <= oPlayer:GetGrade()
    end
    return false
end

function CHuodong:EqualOpenGrade(sName, oPlayer)
    local m = self.m_mHuodong[sName]
    if m then
        local mDaoBiao = self:GetOpenData(m.idx)
        return mDaoBiao and mDaoBiao.grade == oPlayer:GetGrade()
    end
    return false
end

function CHuodong:PackBackInfo(mData)
    mData = mData or {}
    local lNet = {}
    for sName, m in pairs(self.m_mHuodong) do
        if (not mData.idx or mData.idx == m.idx) and
            (not mData.starttime or mData.starttime <= m.starttime) and
            (not mData.endtime or mData.endtime >= m.endtime) then
            table.insert(lNet, {
                idx = m.idx,
                plan_id = m.plan,
                starttime = m.starttime,
                endtime =m.endtime,
                })
        end
    end
    return lNet
end

function CHuodong:TestOP(oPlayer, iFlag, ...)
    local iPid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    local mArgs = {...}
    if iFlag == 101 then
        local idx, plan, sStart, sEnd = table.unpack(mArgs)
        idx = tonumber(idx) or 1001
        plan = tonumber(plan) or 1
        local iStart = str2timestamp(sStart)
        local iEnd = str2timestamp(sEnd)
        if not iStart or not iEnd then
            oNotifyMgr:Notify(iPid, "时间参数有误")
            return
        end
        local mErr = self:SetOpenInfo({idx = idx, starttime = iStart, endtime = iEnd, plan =plan})
        if mErr.errmsg then
            oNotifyMgr:Notify(iPid, mErr.errmsg)
        else
            oNotifyMgr:Notify(iPid, "设置成功")
        end
    else
        oNotifyMgr:Notify(iPid, "指令不存在")
    end
end
