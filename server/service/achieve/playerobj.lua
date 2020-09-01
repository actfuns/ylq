--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"
local extend = require "base/extend"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))
local achievectrl = import(service_path("achievectrl"))
local picturectrl = import(service_path("picturectrl"))
local sevendayctrl = import(service_path("sevendayctrl"))
local taskctrl = import(service_path("taskctrl"))

function NewPlayer(...)
    local o = CPlayer:New(...)
    return o
end

local function SaveDbFunc(self)
    local iPid = self:GetPid()
    if self.m_oAchieveCtrl:IsDirty() then
        local mData = {
            pid = iPid,
            data = self.m_oAchieveCtrl:Save()
        }
        gamedb.SaveDb(iPid,"common", "SaveDb", {module = "achievedb", cmd = "SaveAchieve",data=mData})
    end
    if self.m_oPictureCtrl:IsDirty() then
        local mData = {
            pid = iPid,
            data = self.m_oPictureCtrl:Save(),
        }
        gamedb.SaveDb(iPid,"common", "SaveDb", {module ="achievedb", cmd="SavePicture",data=mData})
    end
    if self.m_oSevenDayCtrl:IsDirty() then
        local mData = {
            pid = iPid,
            data = self.m_oSevenDayCtrl:Save(),
        }
        gamedb.SaveDb(iPid,"common", "SaveDb", {module ="achievedb", cmd="SaveSevenDay",data=mData})
    end
    if self.m_oTaskCtrl:IsDirty() then
        local mData = {
            pid = iPid,
            data = self.m_oTaskCtrl:Save(),
        }
        gamedb.SaveDb(iPid,"common", "SaveDb", {module ="achievedb", cmd="SaveTask",data=mData})
    end
end

CPlayer = {}
CPlayer.__index = CPlayer
inherit(CPlayer, datactrl.CDataCtrl)

function CPlayer:New(iPid,mInfo)
    local o = super(CPlayer).New(self)
    o.m_iPid = iPid
    o.m_oAchieveCtrl = achievectrl.NewAchieveCtrl()
    o.m_oPictureCtrl = picturectrl.NewPictureCtrl()
    o.m_oSevenDayCtrl = sevendayctrl.NewSevenDayCtrl()
    o.m_oTaskCtrl = taskctrl.NewTaskCtrl(iPid)
    o.m_Power = mInfo.power or 0
    o.m_PartnerPower = mInfo.ppower or 0
    o.m_iCreateTime = mInfo.create_time or get_time() --创角时间
    return o
end

function CPlayer:Release()
    baseobj_delay_release(self.m_oAchieveCtrl)
    baseobj_delay_release(self.m_oPictureCtrl)
    baseobj_delay_release(self.m_oSevenDayCtrl)
    baseobj_delay_release(self.m_oTaskCtrl)
    self.m_iPid = nil
    self.m_Power = nil
    self.m_PartnerPower = nil
    super(CPlayer).Release(self)
end

function CPlayer:NewDay()
    if not self:IsSevAchieveClose() then
        self:OpenSevdayMainUI()
    end
    self:CheckSevenDayEnd()
end

function CPlayer:GetPid()
    return self.m_iPid
end

function CPlayer:UpdatePower(iVal)
    self.m_Power = iVal
end

function CPlayer:UpdatePartnerPower(iVal)
    self.m_PartnerPower = iVal
end

function CPlayer:GetWarPower()
    return self.m_Power + self.m_PartnerPower
end

function CPlayer:OnLogin(bReEnter)
    self:CheckAchieveRedDot()
    self:CheckPictureRedDot()
    self:CheckSevenDayRedDot()
    self:CheckSevenDayEnd()
    self:SyncTotalAchPoint()
    self:OpenSevdayMainUI()
    self.m_oTaskCtrl:OnLogin(self)
end

function CPlayer:OnLogout()
    self:MarkCloseUI()
    self:DoSave()
end

function CPlayer:Disconnected()
    self:MarkCloseUI()
end

function CPlayer:Send(sMessage, mData)
    playersend.Send(self:GetPid(),sMessage,mData)
end

function CPlayer:LoadAchieve(mData)
    self.m_oAchieveCtrl:Load(mData)
end

function CPlayer:LoadPicture(mData)
    self.m_oPictureCtrl:Load(mData)
end

function CPlayer:LoadSevenDay(mData)
    self.m_oSevenDayCtrl:Load(mData)
end

function CPlayer:LoadTask(mData)
    self.m_oTaskCtrl:Load(mData)
end

function CPlayer:LoadFinish(mData)
    local iPid = self:GetPid()
    self:ApplySave(function ()
        local oAchieveMgr = global.oAchieveMgr
        local obj = oAchieveMgr:GetPlayer(iPid)
        if not obj then
            record.warning(string.format("achieve service , not have player　id: %d",iPid))
            return
        end
        SaveDbFunc(obj)
    end)
    self:OnLogin(false)
end

function CPlayer:GetCreateDay()
    local iCday = get_dayno(self.m_iCreateTime)
    local iNday = get_dayno(get_time())
    return iNday - iCday
end

function CPlayer:IsDone(iID,sType)
    local oObj
    if not sType then
        oObj = self.m_oAchieveCtrl:GetAchieve(iID)
    elseif sType == "picture" then
        oObj = self.m_oPictureCtrl:GetPicture(iID)
    elseif sType == "sevenday" then
        oObj = self.m_oSevenDayCtrl:GetAchieve(iID)
    else
        record.warning(string.format("error call,not identify of sType: %s ,ID:%d",sType,iID))
    end
    if oObj then
        return oObj:IsDone()
    end
    return false
end

function CPlayer:OpenAchieveMainUI()
    local oAchieveMgr = global.oAchieveMgr
    local mAchieve = self.m_oAchieveCtrl:GetList()
    local mDirection = oAchieveMgr:GetDirectionList()
    local directions,cur_point = {},0
    for _,id in pairs(mDirection) do
        table.insert(directions,{id=id,cur=0})
    end
    for _,oAchieve in pairs(mAchieve) do
        local direction = oAchieve:Direction()
        if oAchieve:GetDone() == 2 then
            local iPoint = oAchieve:Point()
            directions[direction].cur = directions[direction].cur + iPoint
            cur_point = cur_point + iPoint
        end
    end
    self:MarkOpenUI()
    self:Send("GS2CAchieveMain",{directions=directions,cur_point=cur_point,already_get=self.m_oAchieveCtrl:GetAlready()})
end

function CPlayer:OpenPictureMainUI()
    local oAchieveMgr = global.oAchieveMgr
    local mPicture = self.m_oPictureCtrl:GetList()
    local mNet = {}
    for iPictureID,oPicture in pairs(mPicture) do
        table.insert(mNet,{id=iPictureID,cur = oPicture:PackDegreeInfo(),done=oPicture:GetDone()})
    end
    self:Send("GS2CPictureInfo",{ui_opened = self.m_oPictureCtrl:GetUIStatus(),info=mNet})
    self.m_oPictureCtrl:OpenUI()
end

function CPlayer:OpenAchieveDirectionUI(id,belong)
    local mAchieve = self.m_oAchieveCtrl:GetList()
    local achlist = {}
    for iAchieveID,oAchieve in pairs(mAchieve) do
        if id == oAchieve:Direction() and belong == oAchieve:GetBelong() then
            table.insert(achlist,{id=iAchieveID,cur=oAchieve:GetDeGree(),done=oAchieve:GetDone()})
        end
    end
    self:Send("GS2CAchieveDirection",{id=id,belong=belong,achlist=achlist})
end

function CPlayer:OpenSevdayMainUI()
    local oAchieveMgr = global.oAchieveMgr
    local mAchieve = self.m_oSevenDayCtrl:GetList()
    local cur_point = 0
    for _,oAchieve in pairs(mAchieve) do
        if oAchieve:GetDone() == 2 then
            local iPoint = oAchieve:Point()
            cur_point = cur_point + iPoint
        end
    end
    self:Send("GS2CSevenDayMain",{
        cur_point = self:GetSevTotalAchievePoint(),
        already_get = self.m_oSevenDayCtrl:GetAlready(),
        server_day = self:GetCreateDay(),
        -- end_time = oAchieveMgr:GetSevDayEndTime(),
        })
end

function CPlayer:OpenSevDayUI(iDay)
    local oAchieveMgr = global.oAchieveMgr
    local mAchieve = self.m_oSevenDayCtrl:GetList()
    local lAch = {}
    for iAchieveID,oAchieve in pairs(mAchieve) do
        if oAchieve:Day() == iDay then
            table.insert(lAch, {id=iAchieveID,cur=oAchieve:GetDeGree(),done=oAchieve:GetDone()})
        end
    end
    self:Send("GS2CSevenDayInfo",{
        day = iDay,
        achlist =lAch,
        })
end

function CPlayer:CheckAchieveRedDot()
    local mDirection = {}
    local oAchieveMgr = global.oAchieveMgr
    local mAchieve = self.m_oAchieveCtrl:GetList()
    for _,oAchieve in pairs(mAchieve) do
        local id = oAchieve:Direction()
        local belong = oAchieve:GetBelong()
        if oAchieve:GetDone() == 1 then
            mDirection[id] = mDirection[id] or {}
            mDirection[id][belong] = true
        end
    end
    local infolist = {}
    for id,mBelong in pairs(mDirection) do
        table.insert(infolist,{id=id,blist=table_key_list(mBelong)})
    end
    self:Send("GS2CAchieveRedDot",{infolist=infolist})
end

function CPlayer:CheckPictureRedDot()
    local mPicture = self.m_oPictureCtrl:GetList()
    for _,oPicture in pairs(mPicture) do
        if oPicture:GetDone() == 1 then
            self:Send("GS2CPictureRedDot",{})
            break
        end
    end
end

function CPlayer:CheckSevenDayRedDot()
    local oAchieveMgr = global.oAchieveMgr
    if self:IsSevAchieveClose() then
        return
    end
    local lDirection = {}
    local mAchieve = self.m_oSevenDayCtrl:GetList()
    for _,oAchieve in pairs(mAchieve) do
        local id = oAchieve:Direction()
        local belong = oAchieve:GetBelong()
        if oAchieve:GetDone() == 1 then
            table.insert(lDirection, id)
        end
    end
    self:Send("GS2CSevenDayRedDot",{days=lDirection})
end

function CPlayer:PushAchieveUI(iAchieveID)
    local oAchieve = self.m_oAchieveCtrl:GetAchieve(iAchieveID)
    if not oAchieve then
        return
    end
    local pop = true
    local direction,sub_direction = oAchieve:Direction(),oAchieve:SubDirection()
    local mAchieve = self.m_oAchieveCtrl:GetList()
    for id,mUnit in pairs(mAchieve) do
        if mUnit:Direction() == direction and
            mUnit:SubDirection() == sub_direction and
            id < iAchieveID and mUnit:GetDone() == 1 then
            pop = false
        end
    end
    self:Send("GS2CAchieveDone",{id=iAchieveID,pop=pop})
    self:CheckAchieveRedDot()
    record.log_db("achieve", "ach_done",{pid=self:GetPid(),aid=iAchieveID})
end

function CPlayer:PushSevenDayUI(iAchieveID)
    local oAchieve = self.m_oSevenDayCtrl:GetAchieve(iAchieveID)
    if not oAchieve then
        return
    end
    -- self:Send("GS2CSevenDayDone",{id=iAchieveID})
    self:CheckSevenDayRedDot()
    record.log_db("achieve", "sevday_done",{pid=self:GetPid(),aid=iAchieveID})
end

function CPlayer:GetTotalAchievePoint()
    local mAchieve = self.m_oAchieveCtrl:GetList()
    local cur_point = 0
    for _,oAchieve in pairs(mAchieve) do
        if oAchieve:GetDone() == 2 then
            cur_point = cur_point + oAchieve:Point()
        end
    end
    return cur_point
end

function CPlayer:GetSevTotalAchievePoint()
    local mAchieve = self.m_oSevenDayCtrl:GetList()
    local cur_point = 0
    for _,oAchieve in pairs(mAchieve) do
        if oAchieve:GetDone() == 2 then
            cur_point = cur_point + oAchieve:Point()
        end
    end
    return cur_point
end

function CPlayer:RewardAchItem(iAchieveID)
    if self.m_oAchieveCtrl:SignReward(iAchieveID) then
        local oAchieveMgr = global.oAchieveMgr
        oAchieveMgr:Forward(self:GetPid(),"RewardAchItem",{achieveid=iAchieveID})
        local id = oAchieveMgr:GetAchieveDirection(iAchieveID)
        local belong = oAchieveMgr:GetAchieveBelong(iAchieveID)
        self:OpenAchieveDirectionUI(id,belong)
        self:CheckAchieveRedDot()
        self:OpenAchieveMainUI()
        self:SyncTotalAchPoint()
    end
end

function CPlayer:RewardPicItem(iPictureID)
    if self.m_oPictureCtrl:SignReward(iPictureID) then
        local oAchieveMgr = global.oAchieveMgr
        oAchieveMgr:Forward(self:GetPid(),"RewardPicItem",{pictureid=iPictureID})
        local oPicture = self.m_oPictureCtrl:GetPicture(iPictureID)
        record.user("picture","reward",{pid = self:GetPid(),id=oPicture:ID(),degree=ConvertTblToStr(oPicture:GetDeGree())})
        self:SyncPictureDegree(iPictureID)
        self:CheckPictureRedDot()
    end
end

function CPlayer:RewardSevItem(iAchieveID)
    local oAchieveMgr = global.oAchieveMgr
    local mInfo = oAchieveMgr:GetSevenDayInfo(iAchieveID)
    if mInfo["day"] > (self:GetCreateDay() + 1) then
        return
    end
    if self.m_oSevenDayCtrl:SignReward(iAchieveID) then
        local oAchieveMgr = global.oAchieveMgr
        oAchieveMgr:Forward(self:GetPid(),"RewardSevItem",{achieveid=iAchieveID})
        local iDay = oAchieveMgr:GetSevAchieveDay(iAchieveID)
        self:OpenSevDayUI(iDay)
        self:CheckSevenDayRedDot()
        self:OpenSevdayMainUI()
        -- self:SyncTotalAchPoint()
    end
end

function CPlayer:RewardPointItem(id)
    local oAchieveMgr = global.oAchieveMgr
    local info = oAchieveMgr:GetTotalAchieveInfo(id)
    if not info then
        return
    end
    if self:GetTotalAchievePoint() < info["point"] then
        return
    end
    if self.m_oAchieveCtrl:SignAlready(id) then
        local oAchieveMgr = global.oAchieveMgr
        oAchieveMgr:Forward(self:GetPid(),"RewardPointItem",{id=id})
        self:OpenAchieveMainUI()
    end
end

function CPlayer:RewardSevPointItem(id)
    local oAchieveMgr = global.oAchieveMgr
    local info = oAchieveMgr:GetSevTotalAchieveInfo(id)
    if not info then
        return
    end
    if self:GetSevTotalAchievePoint() < info["point"] then
        return
    end
    if self.m_oSevenDayCtrl:SignAlready(id) then
        local oAchieveMgr = global.oAchieveMgr
        oAchieveMgr:Forward(self:GetPid(),"RewardSevPointItem",{id=id})
        self:OpenSevdayMainUI()
    end
end

function CPlayer:RewardSevGiftItem(iDay)
    -- local oAchieveMgr = global.oAchieveMgr
    -- local mInfo = oAchieveMgr:GetSevGiftInfo(iDay)
    -- if not mInfo then
    --     return
    -- end
    -- if table_in_list(self.m_oSevenDayCtrl:GetAlreadyBuy(), iDay) then
    --     return
    -- end
    -- if self.m_oSevenDayCtrl:SignBuy(iDay) then
    --     local oAchieveMgr = global.oAchieveMgr
    --     oAchieveMgr:Forward(self:GetPid(),"RewardSevGiftItem",{day=iDay})
    --     self:OpenSevdayMainUI()
    -- end
end

function CPlayer:SyncAchieveDegree(iAchieveID)
    local oAchieve = self.m_oAchieveCtrl:GetAchieve(iAchieveID)
    if not oAchieve or not self:IsOpenUI() then
        return
    end
    global.oAchieveMgr:SetDegreeNet(self:GetPid(),iAchieveID,{
        info={id=iAchieveID,cur=oAchieve:GetDeGree(),done=oAchieve:GetDone()}
    })
    record.log_db("achieve", "ach_change",{pid=self:GetPid(),aid=iAchieveID,degree=oAchieve:GetDeGree()})
end

function CPlayer:SyncPictureDegree(iPictureID)
    local oPicture = self.m_oPictureCtrl:GetPicture(iPictureID)
    if not oPicture then
        return
    end
    self:Send("GS2CPictureDegree",{info={id=iPictureID,cur = oPicture:PackDegreeInfo(),done=oPicture:GetDone()}})
end

function CPlayer:SyncSevenDayDegree(iAchieveID)
    local oAchieve = self.m_oSevenDayCtrl:GetAchieve(iAchieveID)
    if not oAchieve then
        return
    end
    self:Send("GS2CSevenDayDegree", {
        info = {id = iAchieveID, cur = oAchieve:GetDeGree(), done = oAchieve:GetDone()}
        })
    record.log_db("achieve", "sevday_change",{pid=self:GetPid(),aid=iAchieveID,degree=oAchieve:GetDeGree()})
end

function CPlayer:ClearAchieveDegree(sKey)
    local mAchieve = self.m_oAchieveCtrl:GetList()
    for iAchieveID,oAchieve in pairs(mAchieve) do
        if oAchieve:GetKey() == sKey then
            oAchieve:ClearDegree()
            global.oAchieveMgr:SetDegreeNet(self:GetPid(),iAchieveID,{
                info={id=iAchieveID,cur=oAchieve:GetDeGree(),done=oAchieve:GetDone()}
            })
        end
    end
end

function CPlayer:SyncTotalAchPoint()
    interactive.Send(".world", "achieve", "SyncTotalAchPoint", {pid = self:GetPid(),point=self:GetTotalAchievePoint()})
end

function CPlayer:MarkOpenUI()
    self.m_bMarkOpenUI = true
end

function CPlayer:MarkCloseUI()
    self.m_bMarkOpenUI = false
end

function CPlayer:IsOpenUI()
    return self.m_bMarkOpenUI
end

function CPlayer:GetAchieveTaskReward(iTaskId)
    if self.m_oTaskCtrl:GetAchieveTaskReward(iTaskId) then
        local oAchieveMgr = global.oAchieveMgr
        oAchieveMgr:Forward(self:GetPid(),"RewardAchieveTaskItem",{taskid=iTaskId})
    end
end

function CPlayer:CheckSevenDayEnd()
    local oAchieveMgr = global.oAchieveMgr
    if self.m_oSevenDayCtrl:IsSend() then
        return
    end
    if not self:IsSevAchieveClose() then
        return
    end
    self.m_oSevenDayCtrl:SetSend()
    local lSev = {}
    local mSev = oAchieveMgr:GetSevenDayList()
    for iAchieveID, m in pairs(mSev) do
        if self.m_oSevenDayCtrl:SignReward(iAchieveID) then
            table.insert(lSev, iAchieveID)
        end
    end
    local lDeg = {}
    local mDeg = oAchieveMgr:GetSevTotalAchieveList()
    local iCur = self:GetSevTotalAchievePoint()
    for id, m in pairs(mDeg) do
        if m.point <= iCur and self.m_oSevenDayCtrl:SignAlready(id) then
            table.insert(lDeg, id)
        end
    end
    local mData = {}
    if #lSev > 0 then
        mData.unget_achieve = lSev
    end
    if #lDeg > 0 then
        mData.unget_degress = lDeg
    end
    if next(mData) then
        oAchieveMgr:Forward(self:GetPid(),"SendSevMail", mData)
    end
end

function CPlayer:IsSevAchieveClose()
    local res = require "base.res"
    local val = res['daobiao']["global"]["sevenday_close"]["value"] or 7
    val = tonumber(val)
    if self:GetCreateDay() > val then
        return true
    end
    return false
end