local global = require "global"

function C2GSUnlockBook(oPlayer, mData)
    local iBookID = mData["book_id"]
    if iBookID then
        oPlayer.m_oHandBookCtrl:UnlockBook(oPlayer,iBookID)
    end
end

function C2GSUnlockChapter(oPlayer, mData)
    local iChapterID = mData["chapter_id"]
    if iChapterID then
        oPlayer.m_oHandBookCtrl:UnlockChapter(oPlayer, iChapterID)
    end
end

function C2GSEnterName(oPlayer, mData)
    local iBookID = mData["book_id"]
    if iBookID then
        oPlayer.m_oHandBookCtrl:EnterBookName(oPlayer,iBookID)
    end
end

function C2GSRepairDraw(oPlayer, mData)
    local iBookID = mData["book_id"]
    if iBookID then
        oPlayer.m_oHandBookCtrl:RepairBookDraw(oPlayer, iBookID)
    end
end

function C2GSReadChapter(oPlayer, mData)
    local iChapterID = mData["chapter_id"]
    if iChapterID then
        oPlayer.m_oHandBookCtrl:ReadChapter(oPlayer, iChapterID)
    end
end

function C2GSCloseHandBookUI(oPlayer, mData)
    local iBookType = mData["book_type"]
    oPlayer.m_oHandBookCtrl:CloseHandBookUI(oPlayer, iBookType)
end

function C2GSOpenBookChapter(oPlayer, mData)
    local iBookID = mData["book_id"]
    oPlayer.m_oHandBookCtrl:OpenBookChapter(oPlayer,iBookID)
end