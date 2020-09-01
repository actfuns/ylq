--import module
local global = require "global"

function  C2GSClickLink(oPlayer,mData)
    local idx = mData.idx
    global.oLinkMgr:ClickLink(oPlayer,idx)

end

function C2GSLinkName(oPlayer,mData)
    LinkObjectHandle(oPlayer,mData,"name")
end

function C2GSLinkItem(oPlayer,mData)
    LinkObjectHandle(oPlayer,mData,"item")
end

function C2GSLinkPartner(oPlayer,mData)
    LinkObjectHandle(oPlayer,mData,"partner")
end

function C2GSLinkPlayer(oPlayer, mData)
    LinkObjectHandle(oPlayer,mData,"player")
end

function LinkObjectHandle(oPlayer,mData,sName)
    local oLink = global.oLinkMgr:GetLink(sName)
    if oLink then
        oLink:SetLink(oPlayer,mData)
    end
end


function C2GSEditCommonChat(oPlayer,mData)
    local mChatList = mData.chat_list
    for _,sChat in pairs(mChatList) do
        if string.len(sChat) > 100 then
            return
        end
    end
    oPlayer.m_oHuodongCtrl:SetData("ComChat",mChatList)
    oPlayer:Send("GS2CSendCommonChat",{chat_list =mChatList })
end

function C2GSGetCommonChat(oPlayer,mData)
    local mChatList = oPlayer.m_oHuodongCtrl:GetData("ComChat",{})
    oPlayer:Send("GS2CSendCommonChat",{chat_list =mChatList })
end


