local global = require "global"

local chapterobj = import(service_path("handbook.chapterobj"))

function CreateChapter(iChapterID)
    return chapterobj.NewChapter(iChapterID)
end

function LoadChapter(iChapterID, mData)
    local oChapter = CreateChapter(iChapterID)
    oChapter:Load(mData)
    return oChapter
end