local global = require "global"
local extend = require "base/extend"

local datactrl = import(lualib_path("public.datactrl"))

CToday = {}
CToday.__index = CToday
inherit(CToday, datactrl.CDataCtrl)

function CToday:New(pid)
    local o = super(CToday).New(self, {pid = pid})
    o.m_ID = pid
    o.m_mData = {}
    o.m_mKeepList = {}
    return o
end

function CToday:Load(data)
    data = data or {}
    self.m_mData = data["data"] or {}
    self.m_mKeepList = data["keeplist"] or {}
end

function CToday:Save()
    local data = {}
    data["data"] = self.m_mData
    data["keeplist"]  = self.m_mKeepList
    return data
end

function CToday:Add(key,value)
    self:Validate(key)
    local iValue = self:GetData(key,0)
    iValue = iValue + value
    self:SetData(key,iValue)
    self.m_mKeepList[key] = self:GetTimeNo()
end

function CToday:Set(key,value)
    self:Validate(key)
    self:SetData(key,value)
    self.m_mKeepList[key] = self:GetTimeNo()
end

function CToday:Query(key,rDefault)
    self:Validate(key)
    return self:GetData(key,rDefault)
end

function CToday:Delete(key)
    if not self:GetData(key) then
        return
    end
    self:Dirty()
    self:SetData(key,nil)
    self.m_mKeepList[key] =nil
end

function CToday:Validate(key)
    local iDayNo = self.m_mKeepList[key]
    if not iDayNo then
        return
    end
    if iDayNo >= self:GetTimeNo() then
        return
    end
    self:SetData(key,nil)
    self.m_mKeepList[key] = nil
end

function CToday:ClearData()
    self:Dirty()
    self.m_mKeepList = {}
    self.m_mData = {}
end

function CToday:GetTimeNo()
    return get_dayno()
end

CTodayMorning = {}
CTodayMorning.__index = CTodayMorning
inherit(CTodayMorning,CToday)

function CTodayMorning:New(pid)
    local o = super(CTodayMorning).New(self,{pid=pid})
    return o
end

function CTodayMorning:GetTimeNo()
    return get_morningdayno()
end

CThisWeek = {}
CThisWeek.__index = CThisWeek
inherit(CThisWeek,CToday)

function CThisWeek:New(pid)
    local o = super(CThisWeek).New(self,{pid=pid})
    return o
end

function CThisWeek:GetTimeNo()
    return get_weekno()
end

CThisWeekMorning = {}
CThisWeekMorning.__index = CThisWeekMorning
inherit(CThisWeekMorning,CToday)

function CThisWeekMorning:New(pid)
    local o = super(CThisWeekMorning).New(self,{pid=pid})
    return o
end

function CThisWeekMorning:GetTimeNo()
    return get_morningweekno()
end

CThisTemp = {}
CThisTemp.__index = CThisTemp
inherit(CThisTemp,datactrl.CDataCtrl)

function CThisTemp:New(pid)
    local o = super(CThisTemp).New(self,{pid=pid})
    o.m_ID = pid
    o.m_mData = {}
    o.m_mKeepList = {}
    return o
end

function CThisTemp:Load(data)
    data = data or {}
    self.m_mData = data["Data"] or self.m_mData
    self.m_mKeepList = data["KeepList"] or self.m_mKeepList

end

function CThisTemp:Save()
    local data = {}
    data["Data"] =self.m_mData
    data["KeepList"] = self.m_mKeepList
    return data
end

function CThisTemp:Add(key,value,iSecs)
    self:Validate(key)
    iSecs = iSecs or 30
    local iValue = self:GetData(key)
    if not iValue then
        self:SetData(key,value)
        self.m_mKeepList[key] = iSecs + self:GetTimeNo()
    else
        iValue = iValue + value
        self:SetData(key,iValue)
    end
end

function CThisTemp:Set(key,value,iSecs)
    self:Validate(key)
    iSecs = iSecs or 30
    local iValue = self:GetData(key)
    if not iValue then
        self:SetData(key,value)
        self.m_mKeepList[key] = iSecs + self:GetTimeNo()
    else
        self:SetData(key,value)
    end
end

function CThisTemp:Delete(key)
    if not self:GetData(key) then
        return
    end
    self:Dirty()
    self:SetData(key,nil)
    self.m_mKeepList[key] =nil
end

function CThisTemp:Delay(key,iSecs)
    self:Validate()
    local iEndTime = self.m_mKeepList[key]
    if not iEndTime then
        return
    end
    self:Dirty()
    iEndTime = iEndTime + iSecs
     self.m_mKeepList[key] = iEndTime
end

function CThisTemp:Query(key,rDefault)
    self:Validate(key)
    return self:GetData(key,rDefault)
end

function CThisTemp:Validate(key)
    local iSecs = self.m_mKeepList[key]
    if not iSecs then
        return
    end
    if iSecs >= self:GetTimeNo() then
        return
    end
    self:SetData(key,nil)
    self.m_mKeepList[key] = nil
end

function CThisTemp:QueryLeftTime(key)
    self:Validate(key)
    local iSecs = self.m_mKeepList[key]
    if not iSecs  then return 0 end
    return iSecs - self:GetTimeNo()
end

function CThisTemp:GetTimeNo()
    return get_time()
end

CSeveralDay = {}
CSeveralDay.__index = CSeveralDay
inherit(CSeveralDay,datactrl.CDataCtrl)

function CSeveralDay:New(pid)
    local o = super(CSeveralDay).New(self,{pid=pid})
    o.m_ID = pid
    o.m_mData = {}
    o.m_mDayList = {}
    return o
end

function CSeveralDay:Save()
    local data = {}
    data["Data"] = self.m_mData
    data["DayList"] = self.m_mDayList
    return data
end

function CSeveralDay:Load(data)
    data = data or {}
    self.m_mData = data["Data"] or self.m_mData
    self.m_mDayList = data["DayList"] or self.m_mDayList

end

function CSeveralDay:Add(key,value,iKeepDay)
    self:Validate()
    iKeepDay = iKeepDay or 7
    local iDayNo = self:GetTimeNo()
    local mData = self:GetData(key)
    if not mData then
        mData = {}
        mData[iDayNo] = value
        self.m_mDayList[key] = iKeepDay
    else
        local iValue = mData[iDayNo] or 0
        iValue = iValue + value
        mData[iDayNo] = iValue
    end
    self:SetData(key,mData)
end

function CSeveralDay:Set(key,value,iKeepDay)
    self:Validate()
    iKeepDay = iKeepDay or 7
    local iDayNo = self:GetTimeNo()
    local mData = self:GetData(key)
    if not mData then
        mData = {}
        mData[iDayNo] =value
        self.m_mDayList[key] = iKeepDay
    else
        mData[iDayNo] = value
    end
    self:SetData(key,mData)
end

function CSeveralDay:Delete(key)
    if not self:GetData(key) then
        return
    end
    self:Dirty()
    self:SetData(key,nil)
    self.m_mDayList[key] = nil
end

function CSeveralDay:GetDataList(key)
    self:Validate()
    return self:GetData(key,{})
end

function CSeveralDay:QueryRecent(key,iDay)
    self:Validate(key)
    local mDataList = self:GetData(key,{})
    local iNowDay = self:GetTimeNo()
    local iSum = 0
    for iDayNo,value in pairs(mDataList) do
        if iNowDay - iDayNo < iDay then
            iSum = iSum + value
        end
    end
    return iSum
end

function CSeveralDay:Delay(key,iDay)
    self:Validate(key)
    local mData = self:GetData(key)
    if not mData or not iDay then
        return
    end
    local iKeepDay = self.m_mDayList[key]
    if not iKeepDay then
        return
    end
    self:Dirty()
    self.m_mDayList[key] = self.m_mDayList[key] + iDay
end

function CSeveralDay:Validate(key)
    local mData = self:GetData(key)
    if not mData then
        return
    end
    local iKeepDay = self.m_mDayList[key] or 7
    local iNowDay = self:GetTimeNo()
    local bUpdate = false
    for iDayNo,iValue in pairs(mData) do
        if iNowDay - iDayNo >= iKeepDay then
            mData[iDayNo] = nil
            bUpdate = true
        end
    end
    if extend.Table.size(mData) == 0 then
        self:SetData(key,nil)
        self.m_mDayList[key] = nil
    else
        if bUpdate then
          self:SetData(key,mData)
        end
    end
end

function CSeveralDay:GetTimeNo()
    return get_dayno()
end

CTimeCtrl = {}
CTimeCtrl.__index = CTimeCtrl
inherit(CTimeCtrl,datactrl.CDataCtrl)

function CTimeCtrl:New(pid,mCtrlList)
    local o = super(CTimeCtrl).New(self,{pid=pid})
    o.m_ID = pid
    o.m_mList = mCtrlList
    return o
end

function CTimeCtrl:Save()
    local mData = {}
    local data = {}
    for sKey,oSaveObj in pairs(self.m_mList) do
        data[sKey] = oSaveObj:Save()
    end
    mData["Data"]  = data
    return mData
end

function CTimeCtrl:Load(mData)
   mData = mData or {}
    local data = mData["Data"] or {}
    for sKey,mSaveData in pairs(data) do
        local oTimeObj = self.m_mList[sKey]
        if oTimeObj then
            oTimeObj:Load(mSaveData)
        end
    end
end

function CTimeCtrl:GetTimeObj(sName)
    return self.m_mList[sName]
end

function CTimeCtrl:Release()
    for _,oSaveObj in pairs(self.m_mList) do
        baseobj_safe_release(oSaveObj)
    end
    self.m_mList = {}
    super(CTimeCtrl).Release(self)
end

function CTimeCtrl:IsDirty()
    for _,oObj in pairs(self.m_mList) do
        if oObj:IsDirty() then
            return true
        end
    end
    return false
end

function CTimeCtrl:UnDirty()
    for _,oObj in pairs(self.m_mList) do
        if oObj:IsDirty() then
            oObj:UnDirty()
        end
    end
end

CThisMonth = {}
CThisMonth.__index = CThisMonth
inherit(CThisMonth,CToday)

function CThisMonth:GetTimeNo()
    return get_monthno()
end



