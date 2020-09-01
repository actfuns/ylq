-- import module
local res = require "base.res"
local global = require "global"

local xgpush = import(lualib_path("public.xgpush"))
local huodongbase = import(service_path("huodong.huodongbase"))
local colorstring = require "public.colorstring"
local net = require "base.net"
local interactive = require "base.interactive"

local CHANNEL_CHUANWEN = 1

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "virtualchat"
CHuodong.m_sTempName = "虚拟聊天"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_mRobot = {}
    self.m_mTimeCb = {}
end

function CHuodong:GetConfigData(iChannel)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName]["config"]
    assert(mData[iChannel],"miss virtualchat config:"..iChannel)
    return mData[iChannel]
end

function CHuodong:IsOpen(iChannel)
    local mConfig = self:GetConfigData(iChannel)
    return mConfig["open"] == 1
end

function CHuodong:GetChatPool(iChannel)
    local mConfig = self:GetConfigData(iChannel)
    local sPoolName = mConfig["pool_name"]
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"][self.m_sName][sPoolName]
    assert(mData,"miss chatpool:"..iChannel.."   sPoolName:"..sPoolName)
    return mData
end

function CHuodong:RandomPlayerCnt(iChannel)
    local mConfig = self:GetConfigData(iChannel)
    local iLowerLimit = mConfig["lower_limit"]
    local iOnlineCnt = global.oWorldMgr:GetOnlinePlayerCnt()
    if iOnlineCnt < iLowerLimit then
        return 0
    end
    local sRule = mConfig["rule"]
    local mEnv = {OL=iOnlineCnt}
    local iCnt = formula_string(sRule,mEnv)
    return math.min(iCnt,mConfig["max_cnt"] or 20)
end

function CHuodong:RandomName(iSex)
    for i=1,10000 do
        local sName = global.oWorldMgr:RandomVirtualName(iSex)
        if not self.m_mRobot[sName] then
            return sName
        end
    end
    return
end

function CHuodong:RandomRole()
    local mInfo = res["daobiao"]["roletype"]
    local iType = table_random_key(mInfo)
    return mInfo[iType]
end

function CHuodong:RandomGrade()
    local iSerGrade = global.oWorldMgr:GetServerGrade()
    return math.random(10,iSerGrade)
end

function CHuodong:RandomChat(iChannel)
    local mChatPool = self:GetChatPool(iChannel)
    local iTotalWeight = 0
    for _,info in pairs(mChatPool) do
        iTotalWeight = iTotalWeight + info["weight"]
    end
    local iRan = math.random(iTotalWeight)
    local iCur = 0
    for _,info in pairs(mChatPool) do
        iCur = iCur + info["weight"]
        if iCur >= iRan then
            return info["content"]
        end
    end
end

function CHuodong:NewHour(iWeekDay, iHour)
    self:DelTimeCb("SendVirtualMsg1")
    self:ProduceChuanwenMsg()
end

function CHuodong:NewDay(iWeekDay)
    self.m_mRobot = {}
end

function CHuodong:ProduceChuanwenMsg()
    if not self:IsOpen(CHANNEL_CHUANWEN) then
        return
    end
    local iNum = self:RandomPlayerCnt(CHANNEL_CHUANWEN)
    if iNum <= 0 then
        return
    end
    self.m_mTimeCb[CHANNEL_CHUANWEN] = {}
    for i=1,iNum do
        table.insert(self.m_mTimeCb[CHANNEL_CHUANWEN],math.random(2) == 1 and math.random(60,1740) or math.random(1860,3540))
    end
    local func = function(num1,num2)
        return num1<num2
    end
    table.sort(self.m_mTimeCb[CHANNEL_CHUANWEN],func)
    self:CheckTimeCb(CHANNEL_CHUANWEN,0)
end

function CHuodong:CheckTimeCb(iChannel,iLastTime)
    local iNextTime = self.m_mTimeCb[iChannel][1]
    if (iNextTime-iLastTime) > 0 then
        self:AddTimeCb("SendVirtualMsg"..iChannel,(iNextTime-iLastTime)*1000,function()
                local oHuodong = global.oHuodongMgr:GetHuodong("virtualchat")
                if oHuodong then
                    oHuodong:SendVirtualMsg(iChannel,iNextTime)
                end
            end)
    else
        self:SendVirtualMsg(iChannel,iNextTime)
    end
end

function CHuodong:TranString(sMsg,mArgs)
    return colorstring.FormatColorString(sMsg,mArgs)
end

function CHuodong:SendVirtualMsg(iChannel,iLastTime)
    self:DelTimeCb("SendVirtualMsg"..iChannel)
    if not self:IsOpen(iChannel) then
        return
    end
    table.remove(self.m_mTimeCb[iChannel],1)
    local mRoleInfo = self:RandomRole()
    local sVirtualName = self:RandomName(mRoleInfo["sex"])
    if not sVirtualName then
        return
    end
    local sMsg = self:RandomChat(iChannel)
    if not sMsg then
        return
    end
    sMsg = self:TranString(sMsg,{role = sVirtualName})
    local iGrade = self:RandomGrade()
    self.m_mRobot[sVirtualName] = {
        grade = iGrade,
        name = sVirtualName,
        pid = 0,
        school = mRoleInfo["school"],
        shape = mRoleInfo["shape"],
    }
    self:AddUnvalidName(sVirtualName)
    global.oNotifyMgr:SendSysChat(sMsg, 1, 1)
    if table_count(self.m_mTimeCb[iChannel]) > 0 then
        self:CheckTimeCb(CHANNEL_CHUANWEN,iLastTime)
    end
end

function CHuodong:PackVirtualPlayerInfo(sName)
    if self.m_mRobot[sName] then
        local m = table_copy(self.m_mRobot[sName])
        return net.Mask("base.FriendProfile", m)
    else
        return nil
    end
end

function CHuodong:ValidRename(sNewName)
    if self.m_mRobot[sNewName] then
        return false
    end
    return true
end

function CHuodong:AddUnvalidName(sVirtualName)
    interactive.Send(".login", "login", "AddUnvalidName", {name = sVirtualName})
end

function CHuodong:CleanUnValidName()
    interactive.Send(".login", "login", "CleanUnValidName", {})
end