--import module

local global = require "global"

local gamedefines = import(lualib_path("public.gamedefines"))

local M = {}

local string = string
local string_gsub = string.gsub

--eg1: FormatColorString ("#role使用#amount个#item获得#exp经验"， {role = "玩家1", amount=1, item="#R经验道具#n",exp=1000})
--eg2: FormatColorString ("#role 打败了 #role", {role = {"张三", "李四"}})
function M.FormatColorString(sText, mReplace)
    assert(type(sText)=="string", "FormatColorString, sText must be string")

    if not mReplace then return sText end

    local res = require "base.res"
    local mAllColor = res["daobiao"]["othercolor"]

    for sKey, rReplace in pairs(mReplace) do
        local mColor = mAllColor[sKey]
        local sPatten = "#"..sKey
        local sColor = mColor and mColor.color or "%s"
        local sType = type(rReplace)

        if sType == "string" or sType == "number" then
            sText = string_gsub(sText, sPatten, {[sPatten]=string.format(sColor, rReplace)})
        elseif sType == "table" then
            local iCnt = 0
            sText = string_gsub(sText, sPatten, function()
                iCnt = iCnt+1
                return string.format(sColor, rReplace[iCnt])
            end)
        end
    end
    return sText
end

function M.GetChooseText(iText, tUrl)
    local res = require "base.res"
    local mData = res["daobiao"]
    for _,v in ipairs(tUrl) do
        mData = mData[v]
    end
    local sText = mData["choose"][iText]["content"]
    return sText
end

function M.GetTextData(iText, tUrl, args)
    -- params  tUrl: {"huodong", "fengyao"}
    -- params  iText: 1001
    args = args or {}
    local res = require "base.res"
    local mData = res["daobiao"]
    if not tUrl then
        tUrl = {}
    end
    for _,v in ipairs(tUrl) do
        mData = mData[v]
    end
    local mText = mData["text"][iText]

    if mText.type == gamedefines.TEXT_TYPE.SECOND_CONFIRM then
        local lChoose = mText["choose"] or {}
        local mCbData = {}
        local sText = mText["content"]
        for _, m in ipairs(args) do
            local pattern, value = table.unpack(m)
            sText = string_gsub(sText, pattern, value, 1)
        end
        mCbData["sContent"] = sText
        if #lChoose > 1 then
            mCbData["sConfirm"] = mData["choose"][lChoose[1]]["content"]
            mCbData["sCancle"] = mData["choose"][lChoose[2]]["content"]
            if mText.seconds > 0 then
                mCbData["time"] = mText.seconds
            end
            if mText.default_id == lChoose[2] then
                mCbData["default"] = 0
            end
        end

        return mCbData
    else
        local sText = mText["content"]
        for _, m in ipairs(args) do
            local pattern, value = table.unpack(m)
            sText = string_gsub(sText, pattern, value, 1)
        end
        if mText["choose"] then
            for _, s in ipairs(mText["choose"]) do
                  sText =  string.format("%s%s%s", sText, "&Q", M.GetChooseText(s, tUrl))
            end
        end

        return sText
    end
end

function M.FormatChuanWen(id, args)
    local res = require "base.res"
    local sMsg = ""
    local iHorse = 0
    local  mData = res["daobiao"]["chuanwen"][id]
    if mData then
        args = args or {}
        sMsg = mData.content
        iHorse = mData.horse_race
        for _, m in ipairs(args) do
            local pattern, value = table.unpack(m)
            sMsg = string_gsub(sMsg, pattern, value, 1)
        end
    end
    return sMsg, iHorse
end

return M