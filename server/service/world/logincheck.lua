local global = require "global"

function NewLoginCheckMgr(...)
    return CLoginCheck:New(...)
end

CLoginCheck = {}
CLoginCheck.__index = CLoginCheck
inherit(CLoginCheck, logic_base_cls())

function CLoginCheck:New()
    local o = super(CLoginCheck).New(self)
    o.m_sType = "login"
    o.m_iInterval = 30
    o.m_iPerDeal = 10
    o.m_mLoginCheck = {}
    o:IntervalCheck()
end

function CLoginCheck:IntervalCheck()
    local sKey = self.m_sType
    self:DelTimeCb(sKey)
    self:CheckLoginValid()
    self:AddTimeCb(sKey, self.m_iInterval * 1000, function()
        self:IntervalCheck()
    end)
end

function CLoginCheck:CheckLoginValid()
    local oWorldMgr = global.oWorldMgr
    local iNowTime = get_time()
    local mPid = {}
    local mRemove = {}
    for pid, iTime in pairs(self.m_mLoginCheck) do
        if oWorldMgr:IsOnline(pid) or not oWorldMgr:IsLogining(pid) then
            table.insert(mRemove, pid)
            goto continue
        end
        if iNowTime - iTime >= 60 then
            table.insert(mPid, pid)
        end
        ::continue::
    end
    mRemove = list_combine(mRemove, mPid)
    for _, pid in pairs(mRemove) do
        self.m_mLoginCheck[pid] = nil
    end
    local mLoginPlayer = oWorldMgr:GetLoginingPlayerList()
    for pid, _ in pairs(mLoginPlayer) do
        if self.m_mLoginCheck[pid] then
            goto continue
        end
        
        if table_in_list(mRemove, pid) then
            goto continue
        end
        self.m_mLoginCheck[pid] = iNowTime
        ::continue::
    end
    self:DealLoginFail(mPid)
end

function CLoginCheck:DealLoginFail(mLogin)
    if table_count(mLogin) <= 0 then
        return
    end
    local oWorldMgr = global.oWorldMgr
    for idx, pid in ipairs(mLogin) do
        oWorldMgr:OnLoginFail(pid)
    end
end
