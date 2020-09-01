--import module
--与客户端回调管理
local interactive = require "base.interactive"

CCBMgr = {}
CCBMgr.__index = CCBMgr
inherit(CCBMgr,logic_base_cls())

function CCBMgr:New()
    local o = super(CCBMgr).New(self)
    o.m_iSessionIdx = 0
    o.m_mCallBack = {}
    o:Schedule()
    return o
end

function CCBMgr:Schedule()
    local f1
    f1 = function ()
        self:DelTimeCb("_CheckClean")
        self:AddTimeCb("_CheckClean", 3*60*1000, f1)
        self:_CheckClean()
    end
    f1()
end

function CCBMgr:GetSession()
    self.m_iSessionIdx = self.m_iSessionIdx + 1
    if self.m_iSessionIdx >= 1000000000 then
        self.m_iSessionIdx = 1
    end
    return self.m_iSessionIdx
end

function CCBMgr:GetSendObj(key)
end

function CCBMgr:SetCallBack(key,sCmd,mData,fResCallBack,fCallback)
    local iSessionIdx = self:GetSession()
    local iClientSession = tostring(iSessionIdx*1000+MY_ADDR)
    mData["sessionidx"] = iClientSession
    local func = self[sCmd]
    assert(func,string.format("Callback err:%s %s",key,sCmd))
    func(self,key,mData)
    if not fCallback then
        return
    end
    self.m_mCallBack[iSessionIdx] = {key,fResCallBack,fCallback,get_time(),MY_ADDR}
    return iSessionIdx
end

function CCBMgr:GetCallBack(iSessionIdx)
    return self.m_mCallBack[iSessionIdx]
end

function CCBMgr:RemoveCallBack(iSessionIdx)
    self.m_mCallBack[iSessionIdx] = nil
end


function CCBMgr:TrueCallback(oPlayer,iSessionIdx,mData)
    local iPid = oPlayer:GetPid()
    local mCallBack = self:GetCallBack(iSessionIdx)
    if not mCallBack then
        return
    end
    self:RemoveCallBack(iSessionIdx)
    local key,fResCallBack,fCallback = table.unpack(mCallBack)
    --assert(iOwner==iPid,string.format("Callback err %d %d %d",iSessionIdx,iPid,iOwner))
    if fResCallBack then
        if not fResCallBack(oPlayer,mData) then
            return
        end
    end
    if not fCallback then
        return
    end
    fCallback(oPlayer,mData)
end

function CCBMgr:GS2CConfirmUI(key,mNet)
    local oSend = self:GetSendObj(key)
    if oSend then
        oSend:Send("GS2CConfirmUI",mNet)
    end
end

function CCBMgr:_CheckClean()
    local iNowTime = get_time()
    for key,value in pairs(self.m_mCallBack) do
        if iNowTime - value[4]  > (3*60) then
            self.m_mCallBack[key] = nil
        end
    end
end