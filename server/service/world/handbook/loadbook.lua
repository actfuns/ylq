local global = require "global"

local bookobj = import(service_path("handbook.bookobj"))

function CreateBook(iBookID)
    return bookobj.NewBook(iBookID)
end

function LoadBook(iBookID, mData)
    local o = CreateBook(iBookID)
    o:Load(mData)
    return o
end