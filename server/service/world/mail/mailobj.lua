--import module
local global = require "global"
local extend = require "base.extend"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local loaditem = import(service_path("item.loaditem"))
local loadpartner = import(service_path("partner.loadpartner"))
local gamedefines = import(lualib_path("public.gamedefines"))

ATTACH_ITEM = 1
ATTACH_MONEY = 2
ATTACH_SUMMON = 3
ATTACH_PARTNER = 4

function NewMail(...)
    return CMail:New(...)
end

CMail = {}
CMail.__index = CMail
inherit(CMail,datactrl.CDataCtrl)

function CMail:New(iMailID)
    local o = super(CMail).New(self)
    o.m_iID = iMailID
    o.m_lAttachs = {}
    return o
end

function CMail:Create(senderinfo, recieverid, mData)
    self:SetData("senderinfo", senderinfo)
    self:SetData("recieverid", recieverid)
    self:SetData("createtime", mData.createtime or get_time())
    self:SetData("title", mData.title)
    self:SetData("subject",mData.subject)
    self:SetData("context", mData.context)
    self:SetData("keeptime", mData.keeptime or 15*24*3600)
    self:SetData("readtodel", mData.readtodel or 0)
    self:SetData("autoextract", mData.autoextract or 1)
    self:SetData("opened", 0)
    self:SetData("recieved", 0)
    return self:GetData("keeptime",15*24*3600)+self:GetData("createtime",get_time())
end

function CMail:Load(mData)
    mData = mData or {}
    self:SetData("senderinfo", mData.senderinfo)
    self:SetData("recieverid", mData.recieverid)
    self:SetData("createtime", mData.createtime)
    self:SetData("keeptime", mData.keeptime)
    self:SetData("title", mData.title)
    self:SetData("subject",mData.subject)
    self:SetData("context", mData.context)
    self:SetData("readtodel", mData.readtodel)
    self:SetData("autoextract", mData.autoextract)
    self:SetData("opened",  mData.opened)
    self:SetData("recieved",  mData.recieved)
    for _, info in ipairs(mData.attachs) do
        local oAttach = NewAttach()
        oAttach:Load(info)
        table.insert(self.m_lAttachs, oAttach)
    end
    return mData.keeptime + mData.createtime
end

function CMail:MailTimeOut()
    local iReceverId = self:GetData("recieverid")
    local oWorldMgr = global.oWorldMgr
    local oMailBox = oWorldMgr:GetMailBox(iReceverId)
    local pid, name = table.unpack(self:GetData("senderinfo"))
    oMailBox:DelMail(self.m_iID,"TimeOut")
end

function CMail:Save()
    local mData = {}
    mData.senderinfo = self:GetData("senderinfo")
    mData.recieverid = self:GetData("recieverid")
    mData.createtime = self:GetData("createtime")
    mData.keeptime = self:GetData("keeptime")
    mData.title = self:GetData("title")
    mData.subject = self:GetData("subject")
    mData.context = self:GetData("context")
    mData.readtodel = self:GetData("readtodel")
    mData.autoextract = self:GetData("autoextract")
    mData.opened = self:GetData("opened")
    mData.recieved = self:GetData("recieved")

    local lAttachs = {}
    for _, oAttach in ipairs(self.m_lAttachs) do
        table.insert(lAttachs, oAttach:Save())
    end
    mData.attachs = lAttachs
    return mData
end

function CMail:Release()
    for _,oAttach in pairs(self.m_lAttachs) do
        baseobj_safe_release(oAttach)
    end
    self.m_lAttachs = {}
    super(CMail).Release(self)
end

function CMail:UnDirty()
    super(CMail).UnDirty(self)
    for _, oAttach in ipairs(self.m_lAttachs) do
        if oAttach:IsDirty() then
            oAttach:UnDirty()
        end
    end
end

function CMail:IsDirty()
    local bDirty = super(CMail).IsDirty(self)
    if bDirty then
        return true
    end
    for _, oAttach in ipairs(self.m_lAttachs) do
        if oAttach:IsDirty() then
            return true
        end
    end
    return false
end

function CMail:ValidTime()
    return self:GetData("createtime") + self:GetData("keeptime")
end

function CMail:Validate()
    return self:ValidTime() >= get_time()
end

function CMail:ReadToDel()
    return self:GetData("readtodel") == 1
end

function CMail:AutoExtract()
    return self:GetData("autoextract") == 1
end

function CMail:Open()
    self:SetData("opened", 1)
end

function CMail:Opened()
    return self:GetData("opened", 0) == 1
end

function CMail:AddAttach(oAttach)
    self:Dirty()
    table.insert(self.m_lAttachs, oAttach)
end

function CMail:HasAttach()
    return next(self.m_lAttachs)
end

function CMail:HasReceived()
    return self:GetData("recieved",0) == 1
end

function CMail:NeedBagSpace()
    local iSpace = 0
    for _, oAttach in ipairs(self.m_lAttachs) do
        iSpace = iSpace + oAttach:NeedBagSpace()
    end
    return iSpace
end

function CMail:GetAttachListByType(iType)
    local mList = {}
    for _,oAttach in ipairs(self.m_lAttachs) do
        if oAttach:GetData("type") == iType  then
            table.insert(mList,oAttach:GetData("attach"))
        end
    end
    return mList
end

function CMail:GetAttachItemList()
    local mItem = {}
    for _,oAttach in ipairs(self.m_lAttachs) do
        if oAttach:GetData("type") == ATTACH_ITEM  then
            local rAttach = oAttach:GetData("attach")
            local oItem = loaditem.LoadItem(rAttach["sid"],rAttach)
            table.insert(mItem,{oItem["m_SID"],oItem["m_iAmount"]})
        end
    end
    return mItem
end


function CMail:GetAttachPartneList()
    local mItem = {}
    for _,oAttach in ipairs(self.m_lAttachs) do
        if oAttach:GetData("type") == ATTACH_PARTNER  then
            local attach = oAttach:GetData("attach")
            local oPartner = loadpartner.LoadPartner(attach["partner_type"],attach)
            table.insert(mItem,{oPartner["partner_type"],1})
        end
    end
    return mItem
end

function CMail:NeedSummonSpace()
    local iSpace = 0
    for _, oAttach in ipairs(self.m_lAttachs) do
        iSpace = iSpace + oAttach:NeedSummonSpace()
    end
    return iSpace
end

function CMail:RecieveAttach(oPlayer)
    if not self:Validate() then
        return false
    end
    self:Dirty()
    local attachs = self.m_lAttachs
    for _, oAttach in ipairs(attachs) do
        oAttach:Recieve(oPlayer)
    end
    self:SetData("recieved",1)
    self:Open()
    local  mLogData = self:PackLogInfo()
    record.user("mail","rec_mail",mLogData)
    return true
end

function CMail:PackSimpleInfo()
    local hasattach = 0
    if self:GetData("recieved", 0) == 1 then
        hasattach = 2
    elseif self:HasAttach() then
        hasattach = 1
    end
    local mNet = {
        mailid = self.m_iID,
        title = self:GetData("title"),
        subject = self:GetData("subject"),
        keeptime = self:GetData("keeptime"),
        hasattach = hasattach,
        opened = self:GetData("opened"),
        readtodel = self:GetData("readtodel"),
        createtime = self:GetData("createtime"),
    }
    return mNet
end

function CMail:PackInfo()
    local pid, name = table.unpack(self:GetData("senderinfo"))
    local hasattach = 0
    if self:GetData("recieved", 0) == 1 then
        hasattach = 2
    elseif self:HasAttach() then
        hasattach = 1
    end
    local lAttachs = {}
    for _, oAttach in ipairs(self.m_lAttachs) do
        table.insert(lAttachs, oAttach:PackInfo())
    end
    local mNet = {
        mailid = self.m_iID,
        title = self:GetData("title"),
        subject = self:GetData("subject"),
        context = self:GetData("context"),
        keeptime = self:GetData("keeptime"),
        validtime = self:ValidTime(),
        pid = pid,
        name = name,
        opened = self:GetData("opened"),
        hasattach = hasattach,
        attachs = lAttachs,
    }
    return mNet
end

function CMail:PackLogInfo()
    local mLogData = {}
    local iSenderId,sSenderName = table.unpack(self:GetData("senderinfo"))
    local sTitle = self:GetData("title")
    local iReceverId = self:GetData("recieverid")
    local iCreateTime = self:GetData("createtime")
    mLogData = {sender_id = iSenderId,receiver_id = iReceverId,mail_title = sTitle,mail_time = iCreateTime,mailid=self.m_iID,keep_time = self:GetData("keeptime",15*24*3600)}
    local lAttachs = {}
    for _, oAttach in ipairs(self.m_lAttachs) do
        table.insert(lAttachs, oAttach:PackInfo())
    end
    mLogData.attach = "no attach"
    if #lAttachs > 0 then
        mLogData.attach = ConvertTblToStr(lAttachs)
    end
    return mLogData
end

function NewAttach(...)
    return CAttach:New(...)
end

CAttach = {}
CAttach.__index = CAttach
inherit(CAttach,datactrl.CDataCtrl)

function CAttach:New(iType, ...)
    local o = super(CAttach).New(self)
    o:Init(iType, ...)
    return o
end

function CAttach:Init(iType, rAttach)
    self:SetData("type", iType)
    self:SetData("attach", rAttach)
    if iType == ATTACH_ITEM then
        self:SetData("value",rAttach["amount"] or 0)
    end
end

function CAttach:Load(mData)
    mData = mData or {}
    self:SetData("type", mData.type)
    if self:GetData("type") == ATTACH_ITEM then
        local attach = mData.attach
        local oItem = loaditem.LoadItem(attach["sid"],attach)
        self:SetData("attach", attach)
        self:SetData("value",self:GetData("value",oItem:GetAmount()))
    elseif self:GetData("type") == ATTACH_PARTNER then
        local attach = mData.attach
        local oPartner = loadpartner.LoadPartner(attach["partner_type"],attach)
        self:SetData("attach", attach)
    else
        self:SetData("attach", mData.attach)
    end
end

function CAttach:Save()
    local mData = {}
    mData.type = self:GetData("type")
    mData.attach = self:GetData("attach")
    return mData
end

function CAttach:NeedBagSpace()
    local iSpace = 0
    if self:GetData("type") == ATTACH_ITEM then
        local mAttach = self:GetData("attach")
        local oItem = loaditem.LoadItem(mAttach["sid"],mAttach)
        if oItem.m_ItemType ~= "virtual" then
            iSpace = iSpace + math.floor(oItem:GetAmount() / math.max(1, oItem:GetMaxAmount()))
            if oItem:GetAmount() % oItem:GetMaxAmount() ~= 0 then
                iSpace = iSpace + 1
            end
        end
    end
    return iSpace
end

function CAttach:NeedSummonSpace()
    if self:GetData("type") == ATTACH_SUMMON then
        return 1
    else
        return 0
    end
end

function CAttach:Recieve(who)
    local iType = self:GetData("type")
    local mArgs = {cancel_tip = 1,}
    if iType == ATTACH_ITEM then
        local mAttach = self:GetData("attach")
        local oItem = loaditem.LoadItem(mAttach["sid"],mAttach)
        --self:SetData("attach", nil)
        who:RewardItem(oItem, "mail attach", mArgs)
    elseif iType == ATTACH_PARTNER then
        local attach = self:GetData("attach")
        mArgs.star = attach["star"]
        who:GivePartner({{attach["partner_type"],1,mArgs}},"mail attach", {cancel_tip = 1})
    elseif iType == ATTACH_MONEY then
        local mMoney = self:GetData("attach")
        local sid = mMoney.sid
        local iValue = mMoney.value
        if iValue > 0 then
            if sid == gamedefines.COIN_FLAG.COIN_GOLD then
                who:RewardGoldCoin(iValue, "mail attach", mArgs)
            elseif sid == gamedefines.COIN_FLAG.COIN_COIN then
                who:RewardCoin(iValue, "mail attach", mArgs)
            elseif sid == gamedefines.COIN_FLAG.COIN_ARENA then
                who:RewardArenaMedal(iValue,"mail attach", mArgs)
            elseif sid == gamedefines.COIN_FLAG.COIN_COLOR then
                who:RewardColorCoin(iValue, "mail attach", mArgs)
            else
                assert(true, string.format("Recieve mail err, pid:%s, mail:%s", who:GetPid(), self.m_iID))
            end
        end
    end
end

function CAttach:PackInfo()
    local sid = 0
    local val = 0
    local iType = self:GetData("type")
    if iType == ATTACH_ITEM then
        local mAttach = self:GetData("attach")
        local oItem = loaditem.LoadItem(mAttach["sid"],mAttach)
        if oItem then
            sid = oItem:SID()
            val = self:GetData("value",oItem:GetAmount())
            if oItem:SID() < 10000 then
                val = oItem:GetData("value",1)*oItem:GetAmount()
            end
        end
    elseif iType == ATTACH_PARTNER then
        local attach = self:GetData("attach")
        local oPartner = loadpartner.LoadPartner(attach["partner_type"],attach)
        if oPartner then
            sid = oPartner:PartnerType()
            val = 1
        end
    elseif iType == ATTACH_MONEY then
        local mMoney = self:GetData("attach")
        sid = mMoney.sid
        val = mMoney.value
    end
    local mNet = {
        type = self:GetData("type"),
        sid = sid,
        val = val,
    }
    return mNet
end