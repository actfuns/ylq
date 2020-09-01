local interactive = require "base.interactive"

function Push(iPid,sTitle,sText)
    local mData = {
        pid = iPid,
        title = sTitle,
        text = sText,
    }
    interactive.Send(".gamepush","common","Push",mData)
end

function PushById(iPid,id)
    local mData = {
        pid = iPid,
        id = id
    }
    interactive.Send(".gamepush","common","PushById",mData)
end