local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"
local playersend = require "base.playersend"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))
local playerobj = import(service_path("playerobj"))
local achievecheck = import(service_path("achievecheck"))

local sTableName = "achieve"

function NewAchieveMgr(...)
    local o = CAchieveMgr:New(...)
    return o
end

CAchieveMgr = {}
CAchieveMgr.__index = CAchieveMgr
inherit(CAchieveMgr, datactrl.CDataCtrl)

function CAchieveMgr:New()
    local o = super(CAchieveMgr).New(self)
    o.m_mPlayers = {}
    o.m_AchCnt = {}
    o.m_AchCheck = achievecheck.NewAchieveCheck()
    o.m_mPlayerNet = {}
    o.m_KeyToSys = {}           ---记录关键字对应的玩法
    return o
end

function CAchieveMgr:InitData()
    local mData = {
        name = sTableName,
    }
    local mArgs = {
        module = "global",
        cmd = "LoadGlobal",
        data = mData
    }
    gamedb.LoadDb("achieve","common", "LoadDb", mArgs, function (mRecord, mData)
        if not is_release(self) then
            local m = mData.data
            self:Load(m)
            self:ConfigSaveFunc()
            self:Schedule()
        end
    end)
    self:InitAchieveTaskData()
    self:InitAchieveKey()
end

function CAchieveMgr:ConfigSaveFunc()
    self:ApplySave(function ()
        local oWorldMgr = global.oWorldMgr
        local oAchieveMgr = global.oAchieveMgr
        oAchieveMgr:CheckSaveDb()
    end)
end

function CAchieveMgr:Schedule()
    local f1
    f1 = function ()
        self:DelTimeCb("SendDegreeNet")
        self:AddTimeCb("SendDegreeNet", 1000, f1)
        self:SendDegreeNet()
    end
    f1()
end

function CAchieveMgr:CheckSaveDb()
    if self:IsDirty() then
        local mData = {
            name = sTableName,
            data = self:Save()
        }
        gamedb.SaveDb("achieve","common","SaveDb",{
            module = "global",
            cmd = "SaveGlobal",
            data = mData
        })
        self:UnDirty()
    end
end

function CAchieveMgr:Save()
    local mData = {}
    local mAchCnt = {}
    for iAchieveID,iCnt in pairs(self.m_AchCnt) do
        mAchCnt[db_key(iAchieveID)] = iCnt
    end
    mData["achcnt"] = mAchCnt
    return mData
end

function CAchieveMgr:Load(mData)
    mData = mData or {}
    local mAchCnt = mData["achcnt"] or {}
    local tTmp = {}
    for sAchieveID,iCnt in pairs(mAchCnt) do
        tTmp[tonumber(sAchieveID)] = iCnt
    end
    self.m_AchCnt = tTmp
end

function CAchieveMgr:MergeFrom(mFromData)
    local mData = mFromData["achcnt"] or {}
    local mAchCnt = self.m_AchCnt
    for sAchieveID,iCnt in pairs(mData) do
        local iAchieveID = tonumber(sAchieveID)
        mAchCnt[iAchieveID] = mAchCnt[iAchieveID] or 0
        mAchCnt[iAchieveID] = mAchCnt[iAchieveID] + iCnt
    end
    return true
end

function CAchieveMgr:NewDay(mData)
    if mData.open_day then
        self:SetServerDay(mData.open_day + 1)
        for _, oPlayer in pairs(self.m_mPlayers) do
            -- oPlayer:CheckSevenDayEnd()
            oPlayer:NewDay()
        end
    end
end

function CAchieveMgr:UpdateOpenDay(iOpenDay)
    self:SetServerDay(iOpenDay + 1)
    for _, oPlayer in pairs(self.m_mPlayers) do
        oPlayer:CheckSevenDayEnd()
    end
end

function CAchieveMgr:AddAchCnt(iAchieveID)
    self:Dirty()
    local iCnt = self.m_AchCnt[iAchieveID] or 0
    iCnt = iCnt + 1
    self.m_AchCnt[iAchieveID] = iCnt
end

function CAchieveMgr:CloseGS()
    save_all()
    local lPids = table_key_list(self.m_mPlayers)
    for _, iPid in ipairs(lPids) do
        self:OnLogout(iPid)
    end
end

function CAchieveMgr:Disconnected(iPid)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:Disconnected()
    end
end

function CAchieveMgr:OnLogout(iPid)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:OnLogout()
        self.m_mPlayers[iPid] = nil
        baseobj_delay_release(oPlayer)
    end
end

function CAchieveMgr:OnLogin(iPid, mInfo)
    local o = self:GetPlayer(iPid)
    if o then
        o:OnLogin(true)
    else
        self.m_mPlayers[iPid] = playerobj.NewPlayer(iPid, mInfo)
        local mFunc = {"LoadAchieveDB","LoadPictureDB","LoadTaskDB", "LoadSevenDayDB"}
        local mLoad = {}
        for _,sFunc in pairs(mFunc) do
            if self[sFunc] then
                self[sFunc](self,iPid,function(o)
                    mLoad[sFunc] = 1
                    if table_count(mLoad) >= #mFunc then
                        if not is_release(o) then
                            o:LoadFinish()
                        end
                    end
                end)
            end
        end
    end
end

function CAchieveMgr:LoadAchieveDB(iPid,fCallback)
    local mData = {
        pid = iPid
    }
    local mArgs = {
        module = "achievedb",
        cmd = "LoadAchieve",
        data = mData
    }
    gamedb.LoadDb(iPid,"common", "LoadDb", mArgs, function (mRecord, mData)
        if not is_release(self) then
            self:_LoadAchieve(mRecord, mData)
            local o = self:GetPlayer(iPid)
            if o then
                fCallback(o)
            end
        end
    end)
end

function CAchieveMgr:LoadPictureDB(iPid,fCallback)
    local mData = {
        pid = iPid
    }
    local mArgs = {
        module = "achievedb",
        cmd = "LoadPicture",
        data = mData
    }
    gamedb.LoadDb(iPid,"common", "LoadDb", mArgs, function (mRecord, mData)
        if not is_release(self) then
            self:_LoadPicture(mRecord, mData)
            local o = self:GetPlayer(iPid)
            if o then
                fCallback(o)
            end
        end
    end)
end

function CAchieveMgr:LoadSevenDayDB(iPid, fCallback)
    local mData = {
        pid = iPid
    }
    local mArgs = {
        module = "achievedb",
        cmd = "LoadSevenDay",
        data = mData
    }
    gamedb.LoadDb(iPid,"common", "LoadDb", mArgs, function (mRecord, mData)
        if not is_release(self) then
            self:_LoadSevenDay(mRecord, mData)
            local o = self:GetPlayer(iPid)
            if o then
                fCallback(o)
            end
        end
    end)
end

function CAchieveMgr:_LoadAchieve(mRecord, mData)
    local iPid = mData.pid
    local m = mData.data
    local o = self:GetPlayer(iPid)
    if o then
        o:LoadAchieve(m)
    end
end

function CAchieveMgr:_LoadPicture(mRecord, mData)
    local iPid = mData.pid
    local m = mData.data
    local o = self:GetPlayer(iPid)
    if o then
        o:LoadPicture(m)
    end
end

function CAchieveMgr:_LoadSevenDay(mRecord, mData)
    local iPid = mData.pid
    local m = mData.data
    local o = self:GetPlayer(iPid)
    if o then
        o:LoadSevenDay(m)
    end
end

function CAchieveMgr:LoadTaskDB(iPid,fCallback)
    local mData = {
        pid = iPid
    }
    local mArgs = {
        module = "achievedb",
        cmd = "LoadTask",
        data = mData
    }
    gamedb.LoadDb(iPid,"common", "LoadDb", mArgs, function (mRecord, mData)
        if not is_release(self) then
            self:_LoadTask(mRecord, mData)
            local o = self:GetPlayer(iPid)
            if o then
                fCallback(o)
            end
        end
    end)
end

function CAchieveMgr:_LoadTask(mRecord, mData)
    local iPid = mData.pid
    local m = mData.data
    local o = self:GetPlayer(iPid)
    if o then
        o:LoadTask(m)
    end
end

function CAchieveMgr:GetPlayer(iPid)
    return self.m_mPlayers[iPid]
end

function CAchieveMgr:Notify(iPid, sMsg)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:Send("GS2CNotify", {cmd = sMsg})
    end
end

function CAchieveMgr:HasAchieve(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][iAchieveID] ~= nil
end

function CAchieveMgr:HasPicture(iPictureID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["picture"][iPictureID] ~= nil
end

function CAchieveMgr:HasSevenDay(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][iAchieveID] ~= nil
end

function CAchieveMgr:AddDegree(iPid,iAchieveID,iAdd)
    if not self:HasAchieve(iAchieveID) then
        record.warning(string.format("not have achieve %d from iPid:%d",iAchieveID,iPid))
        return
    end
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        if not oPlayer.m_oAchieveCtrl:IsLoadFinish() then
            return
        end
        if oPlayer:IsDone(iAchieveID) then
            return
        end
        oPlayer.m_oAchieveCtrl:AddAchDegree(iAchieveID,iAdd)
        if oPlayer:IsDone(iAchieveID)  then
            self:AddAchCnt(iAchieveID)
            self:Forward(iPid,"ReachAchieve",{achieveid=iAchieveID})
            oPlayer:PushAchieveUI(iAchieveID)
        else
            oPlayer:SyncAchieveDegree(iAchieveID)
        end
    end
end

function CAchieveMgr:SetDegree(iPid,iAchieveID,iDegree)
    if not self:HasAchieve(iAchieveID) then
        record.warning(string.format("not have achieve %d from iPid:%d",iAchieveID,iPid))
        return
    end
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        if not oPlayer.m_oAchieveCtrl:IsLoadFinish() then
            return
        end
        if oPlayer:IsDone(iAchieveID) then
            return
        end
        oPlayer.m_oAchieveCtrl:SetAchDegree(iAchieveID,iDegree)
        if oPlayer:IsDone(iAchieveID) then
            self:AddAchCnt(iAchieveID)
            self:Forward(iPid,"ReachAchieve",{achieveid=iAchieveID})
            oPlayer:PushAchieveUI(iAchieveID)
        else
            oPlayer:SyncAchieveDegree(iAchieveID)
        end
    end
end

function CAchieveMgr:GetAchieveList()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"]
end

function CAchieveMgr:GetPictureList()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["picture"]
end

function CAchieveMgr:GetSevenDayList()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"]
end

function CAchieveMgr:GetDirectionList()
    local res = require "base.res"
    return table_key_list(res["daobiao"]["achieve"]["direction"])
end

function CAchieveMgr:GetDirectionCnt()
    local res = require "base.res"
    return table_count(res["daobiao"]["achieve"]["direction"])
end

function CAchieveMgr:GetAchieveKey(iAchieveID,info)
    local res = require "base.res"
    local sCondition = info or res["daobiao"]["achieve"]["configure"][iAchieveID]["condition"]
    local value = split_string(sCondition,"=")
    return value[1]
end

function CAchieveMgr:PushAchieve(iPid,sKey,data)
    if not self.m_KeyToSys[sKey] or not self.m_KeyToSys[sKey]["achieve"] then
        return
    end
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        local mAchieve = self.m_KeyToSys[sKey]["achieve"]
        local mCheckAchieve = {}
        local mDegreetype = {}
        for _,iAchieveID in pairs(mAchieve) do
            table.insert(mCheckAchieve,iAchieveID)
            mDegreetype[iAchieveID] = self:GetAchieveDegreeType(iAchieveID)
        end
        table.sort(mCheckAchieve)
        for _,iAchieveID in pairs(mCheckAchieve) do
            self.m_AchCheck:CheckCondition(iPid,iAchieveID,sKey,data,mDegreetype[iAchieveID])
        end
    end
end

function CAchieveMgr:ClearAchieveDegree(iPid,sKey)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:ClearAchieveDegree(sKey)
    end
end

function CAchieveMgr:GetTotalAchieveInfo(id)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["reward"][id]
end

function CAchieveMgr:Forward(iPid,sCmd,mData)
    interactive.Send(".world", "achieve", "Forward", {
        pid = iPid, cmd = sCmd, data = mData,
    })
end

function CAchieveMgr:GetAchieveDirection(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][iAchieveID]["direction"]
end

function CAchieveMgr:GetAchieveDegreeType(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][iAchieveID]["degreetype"]
end

function CAchieveMgr:GetAchieveBelong(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["configure"][iAchieveID]["belong"]
end

function CAchieveMgr:PushPicture(iPid,sKey,data)
    local iTarget = data.target
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        if not self.m_KeyToSys[sKey] or not self.m_KeyToSys[sKey]["picture"] or not self.m_KeyToSys[sKey]["picture"][iTarget] then
            return
        end
        local mPictureList = self.m_KeyToSys[sKey]["picture"][iTarget]
        local value = data["value"]
        if value > 0  then
            for _,iPictureID in pairs(mPictureList) do
                self:SetPictureDegree(iPid,iPictureID,sKey,iTarget,value)
            end
        end
    end
end

function CAchieveMgr:SetPictureDegree(iPid,iPictureID,sKey,iTarget,iValue)
    if not self:HasPicture(iPictureID) then
        record.warning(string.format("not have picture %d from iPid:%d",iPictureID,iPid))
        return
    end
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        if oPlayer:IsDone(iPictureID,"picture") then
            return
        end
        oPlayer.m_oPictureCtrl:SetPicDegree(iPid,iPictureID,sKey,iTarget,iValue)
        if oPlayer:IsDone(iPictureID,"picture")  then
            self:Forward(iPid,"ReachPicture",{pictureid=iPictureID})
            oPlayer:CheckPictureRedDot()
        end
        oPlayer:SyncPictureDegree(iPictureID)
    end
end

--seven day
function CAchieveMgr:PushSevenDay(iPid,sKey,data)
    local oPlayer = self:GetPlayer(iPid)
    if not oPlayer then
        return
    end
    if oPlayer:IsSevAchieveClose() then
        return
    end
    if not self.m_KeyToSys[sKey] or not self.m_KeyToSys[sKey]["sevenday"] then
        return
    end
    if oPlayer then
        local mAchieve = self.m_KeyToSys[sKey]["sevenday"]
        for _,iAchieveID in pairs(mAchieve) do
            local mInfo = self:GetSevenDayInfo(iAchieveID)
            -- if mInfo["day"] <= (self:GetServerDay() + 1) then
                self.m_AchCheck:CheckSevenDayCondition(iPid,iAchieveID,sKey,data,mInfo["degreetype"])
            -- end
        end
    end
end

function CAchieveMgr:GetSevenDayKey(iAchieveID, info)
    local res = require "base.res"
    local sCondition = info or res["daobiao"]["achieve"]["sevenday"][iAchieveID]["condition"]
    local value = split_string(sCondition,"=")
    return value[1]
end

function CAchieveMgr:GetSevenDayInfo(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][iAchieveID]
end

function CAchieveMgr:AddSevenDayDegress(iPid, iAchieveID, iAdd)
    if not self:HasSevenDay(iAchieveID) then
        record.warning(string.format("not have achieve %d from iPid:%d",iAchieveID,iPid))
        return
    end
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        if not oPlayer.m_oSevenDayCtrl:IsLoadFinish() then
            return
        end
        if oPlayer:IsDone(iAchieveID, "sevenday") then
            return
        end
        oPlayer.m_oSevenDayCtrl:AddAchDegree(iAchieveID,iAdd)
        if oPlayer:IsDone(iAchieveID, "sevenday") then
            -- self:AddSevenDayAchCnt(iAchieveID)
            -- self:Forward(iPid,"ReachAchieve",{achieveid=iAchieveID})
            oPlayer:PushSevenDayUI(iAchieveID)
        else
            oPlayer:SyncSevenDayDegree(iAchieveID)
        end
    end
end

function CAchieveMgr:SetSevenDayDegree(iPid,iAchieveID,iDegree)
    if not self:HasSevenDay(iAchieveID) then
        record.warning(string.format("not have achieve %d from iPid:%d",iAchieveID,iPid))
        return
    end
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        if not oPlayer.m_oSevenDayCtrl:IsLoadFinish() then
            return
        end
        if oPlayer:IsDone(iAchieveID, "sevenday") then
            return
        end
        oPlayer.m_oSevenDayCtrl:SetAchDegree(iAchieveID,iDegree)
        if oPlayer:IsDone(iAchieveID, "sevenday") then
            -- self:AddSevenDayAchCnt(iAchieveID)
            -- self:Forward(iPid,"ReachAchieve",{achieveid=iAchieveID})
            oPlayer:PushSevenDayUI(iAchieveID)
        else
            oPlayer:SyncSevenDayDegree(iAchieveID)
        end
    end
end

function CAchieveMgr:GetServerDay()
    return self.m_iServerDay or 1
end

function CAchieveMgr:SetServerDay(iServer)
    self.m_iServerDay = iServer or 1
end

function CAchieveMgr:SetDegreeNet(iPid,iAchieveID,mData)
    self.m_mPlayerNet[iPid] = self.m_mPlayerNet[iPid] or {}
    self.m_mPlayerNet[iPid][iAchieveID] = {message="GS2CAchieveDegree",data=mData}
end

function CAchieveMgr:GetSevAchieveDay(iAchieveID)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday"][iAchieveID]["day"]
end

function CAchieveMgr:GetSevTotalAchieveInfo(id)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday_point"][id]
end

function CAchieveMgr:GetSevGiftInfo(iDay)
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday_gift"][iDay]
end

function CAchieveMgr:GetSevDayCloseDay()
    local res = require "base.res"
    local val = res['daobiao']["global"]["sevenday_close"]["value"] or 8
    return tonumber(val)
end

function CAchieveMgr:GetSevTotalAchieveList()
    local res = require "base.res"
    return res["daobiao"]["achieve"]["sevenday_point"]
end

function CAchieveMgr:GetSevDayEndTime()
    local iCloseDay = self:GetSevDayCloseDay()
    return get_starttime() + iCloseDay * 24 * 60 * 60
end

function CAchieveMgr:SendDegreeNet()
    local m = self.m_mPlayerNet or {}
    for iPid,lData in pairs(m) do
        playersend.SendList(iPid,lData)
    end
    self.m_mPlayerNet = {}
end

function CAchieveMgr:InitAchieveTaskData()
    self.m_mAchieveTask = {}
    local res = require "base.res"
    local mData = res["daobiao"]["achieve"]["achievetask"]
    local mPreCondition = {}
    local mCondition = {}
    for iTaskId,info in pairs(mData) do
        local mTrigger = info["pre_condition"]
        for _,sTrigger in pairs(mTrigger) do
            local mValue = split_string(sTrigger,"=")
            if not mValue[1] then
                record.warning("InitAchieveTaskData fail,please check excel config")
                break
            end
            if not mPreCondition[mValue[1]] then
                mPreCondition[mValue[1]] = {}
            end
            table.insert(mPreCondition[mValue[1]],iTaskId)
        end
        local sCondition = info["condition"]
        local mValue = split_string(sCondition,"=")
        mCondition[mValue[1]] = mCondition[mValue[1]] or {}
        table.insert(mCondition[mValue[1]],iTaskId)
    end
    self.m_mAchieveTask["pre_condition"] = mPreCondition
    self.m_mAchieveTask["condition"] = mCondition
end

function CAchieveMgr:PushAchieveTask(iPid,sKey,mData)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        if self.m_mAchieveTask["pre_condition"][sKey] then
            for _,iTaskId in pairs(self.m_mAchieveTask["pre_condition"][sKey]) do
                oPlayer.m_oTaskCtrl:PushPreCondition(iTaskId,sKey,mData)
            end
        end
        if self.m_mAchieveTask["condition"][sKey] then
            for _,iTaskId in pairs(self.m_mAchieveTask["condition"][sKey]) do
                oPlayer.m_oTaskCtrl:PushCondition(iTaskId,sKey,mData)
            end
        end
    end
end

function CAchieveMgr:InitAchieveKey()
    local res = require "base.res"
    local sKey
    local mData = res["daobiao"]["achieve"]["configure"]
    for iAchieveID,info in pairs(mData) do
        local sCondition = info["condition"]
        local mArgs = split_string(sCondition,"=")
        sKey = mArgs[1]
        self.m_KeyToSys[sKey] = self.m_KeyToSys[sKey] or {}
        self.m_KeyToSys[sKey]["achieve"] = self.m_KeyToSys[sKey]["achieve"] or {}
        table.insert(self.m_KeyToSys[sKey]["achieve"],iAchieveID)
    end

    mData = res["daobiao"]["achieve"]["achievetask"]
    for iTaskId,info in pairs(mData) do
        local mTrigger = info["pre_condition"]
        for _,sTrigger in pairs(mTrigger) do
            local mArgs = split_string(sTrigger,"=")
            sKey = mArgs[1]
            if not sKey then
                record.warning("InitAchieveTaskData fail,please check excel config")
                break
            end
            self.m_KeyToSys[sKey] = self.m_KeyToSys[sKey] or {}
            self.m_KeyToSys[sKey]["achievetask"] = self.m_KeyToSys[sKey]["achievetask"] or {}
            table.insert(self.m_KeyToSys[sKey]["achievetask"],iTaskId)
        end
        local sCondition = info["condition"]
        local mArgs = split_string(sCondition,"=")
        sKey = mArgs[1]
        self.m_KeyToSys[sKey] = self.m_KeyToSys[sKey] or {}
        self.m_KeyToSys[sKey]["achievetask"] = self.m_KeyToSys[sKey]["achievetask"] or {}
        table.insert(self.m_KeyToSys[sKey]["achievetask"],iTaskId)
    end

    mData = res["daobiao"]["achieve"]["picture"]
    for iAchieveID,info in pairs(mData) do
        local mCondition = info["condition"]
        for _,sCondition in pairs(mCondition) do
            local mArgs = split_string(sCondition,":")
            sKey = mArgs[1]
            local iTarget = tonumber(mArgs[2])
            self.m_KeyToSys[sKey] = self.m_KeyToSys[sKey] or {}
            self.m_KeyToSys[sKey]["picture"] = self.m_KeyToSys[sKey]["picture"] or {}
            self.m_KeyToSys[sKey]["picture"][iTarget] = self.m_KeyToSys[sKey]["picture"][iTarget] or {}
            table.insert(self.m_KeyToSys[sKey]["picture"][iTarget],iAchieveID)
        end
    end

    mData = res["daobiao"]["achieve"]["sevenday"]
    for iAchieveID,info in pairs(mData) do
        local sCondition = info["condition"]
        local mArgs = split_string(sCondition,"=")
        sKey = mArgs[1]
        self.m_KeyToSys[sKey] = self.m_KeyToSys[sKey] or {}
        self.m_KeyToSys[sKey]["sevenday"] = self.m_KeyToSys[sKey]["sevenday"] or {}
        table.insert(self.m_KeyToSys[sKey]["sevenday"],iAchieveID)
    end
end

function CAchieveMgr:Push(sKey,mData)
    if not self.m_KeyToSys[sKey] then
        return
    end
    local iPid = mData.pid
    local data = mData.data
    for sSys,info in pairs(self.m_KeyToSys[sKey]) do
        if sSys == "achieve" then
            self:PushAchieve(iPid,sKey,data)
        elseif sSys == "achievetask" then
            self:PushAchieveTask(iPid,sKey,data)
        elseif sSys == "sevenday" then
            self:PushSevenDay(iPid,sKey,data)
        elseif sSys == "picture" then
            self:PushPicture(iPid,sKey,data)
        end
    end
end

function CAchieveMgr:UpdateAchieveKey()
    self.m_KeyToSys = {}
    self:InitAchieveKey()
end