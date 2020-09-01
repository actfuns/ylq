local global = require "global"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local loadbook = import(service_path("handbook.loadbook"))

function NewBookCtrl()
    local o = CBookCtrl:New()
    return o
end

CBookCtrl = {}
CBookCtrl.__index = CBookCtrl
inherit(CBookCtrl, datactrl.CDataCtrl)

function CBookCtrl:New()
    local o = super(CBookCtrl).New(self)
    o.m_mList = {}
    return o
end

function CBookCtrl:Release()
    for _, oBook in pairs(self.m_mList) do
        baseobj_safe_release(oBook)
    end
    self.m_mList = nil
    super(CBookCtrl).Release(self)
end

function CBookCtrl:Load(mData)
    local mBookData = mData or {}
    for sBookID, data in pairs(mBookData) do
        local iBookID = tonumber(sBookID)
        local oBook = loadbook.LoadBook(iBookID, data)
        self.m_mList[iBookID] = oBook
    end
end

function CBookCtrl:Save()
    local mBookData = {}
    for iBookID, oBook in pairs(self.m_mList) do
        mBookData[db_key(iBookID)] = oBook:Save()
    end
    return mBookData
end

function CBookCtrl:OnLogin(oPlayer, bReEnter)
    for _, oBook in pairs(self.m_mList) do
        oBook:PreCheck()
    end
end

function CBookCtrl:UnDirty()
    super(CBookCtrl).UnDirty(self)
    for _, oBook in pairs(self.m_mList) do
        oBook:UnDirty()
    end
end

function CBookCtrl:IsDirty()
    if super(CBookCtrl).IsDirty(self) then
        return true
    end
    for _, oBook in pairs(self.m_mList) do
        if oBook:IsDirty() then
            return true
        end
    end
    return false
end

function CBookCtrl:GetList()
    return self.m_mList
end

function CBookCtrl:GetBook(iBookID)
    return self.m_mList[iBookID]
end

function CBookCtrl:AddBook(iBookID)
    self:Dirty()
    local oBook = loadbook.CreateBook(iBookID)
    assert(oBook, string.format("handbook err, book id:%s not exsit!", iBookID))
    self.m_mList[iBookID] = oBook
    oBook:PreCheck()
    return oBook
end

function CBookCtrl:AddCondition(iBookID, iConditionID)
    local oBook = self:GetBook(iBookID)
    if not oBook then
        oBook = self:AddBook(iBookID)
    end
    assert(oBook, string.format("handbook err, book id:%s not exsit!", iBookID))
    oBook:AddCondition(iConditionID)
end

function CBookCtrl:AddChapter(iBookID, iChapterID)
    local oBook = self:GetBook(iBookID)
    if not oBook then
        oBook = self:AddBook(iBookID)
    end
    oBook:AddChapter(iChapterID)
    return oBook
end

function CBookCtrl:HasBook(iBookID)
    return self.m_mList[iBookID]
end

function CBookCtrl:HasCondition(iBookID, iConditionID)
    local oBook = self:GetBook(iBookID)
    if not oBook then
        oBook = self:AddBook(iBookID)
    end
    return oBook:HasCondition(iConditionID)
end

function CBookCtrl:HasChapter(iBookID, iChapterID)
    local oBook = self:GetBook(iBookID)
    if not oBook then
        oBook = self:AddBook(iBookID)
    end
    return oBook:HasChapter(iChapterID)
end

function CBookCtrl:IsShow(iBookID)
    local oBook = self:GetBook(iBookID)
    if not oBook then
        oBook = self:AddBook(iBookID)
    end
    assert(oBook, string.format("handbook err, book id:%s not exsit!", iBookID))
    return oBook:IsShow()
end

function CBookCtrl:SetShow(iBookID)
    local oBook = self:GetBook(iBookID)
    if not oBook then
        oBook = self:AddBook(iBookID)
    end
    assert(oBook, string.format("handbook err, book id:%s not exsit!", iBookID))
    oBook:SetShow()
end

function CBookCtrl:CheckRedPoint(iBookType)
    for _, oBook in pairs(self.m_mList) do
        if oBook:Type() == iBookType and oBook:IsRedPoint(1) then
            return true
        end
    end
    return false
end

function CBookCtrl:UnSetRedPoint(iBookType, iRed)
    iRed = iRed or 1
    local lUnSetID = {}
    for _, oBook in pairs(self.m_mList) do
        if oBook:Type() == iBookType and oBook:IsRedPoint(iRed) then
            oBook:UnSetRedPoint(iRed)
            table.insert(lUnSetID, oBook:ID())
        end
    end
    return lUnSetID
end

function CBookCtrl:PackBookInfo(iBookID)
    local oBook = self:GetBook(iBookID)
    if not oBook then
        oBook = self:AddBook(iBookID)
    end
    assert(oBook, string.format("handbook err, book id:%s not exsit!", iBookID))
    return oBook:PackNetInfo()
end

function CBookCtrl:TestCmd(oPlayer, sCmd, mData, sReason)
    -- body
end

