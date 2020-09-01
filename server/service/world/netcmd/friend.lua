--import module

local global = require "global"
local skynet = require "skynet"



function C2GSApplyAddFriend(oPlayer, mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:AddApply(oPlayer, mData.pid)
end

function  C2GSAgreeApply(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    local iCnt=0
    for k,v in ipairs(mData.pidlist) do 
        iCnt=iCnt+1
        if iCnt>=100 then
            break
        end
        oFriendMgr:AddFriend(oPlayer,v)
    end
end



function C2GSDelApply(oPlayer, mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:RemoveApply(oPlayer, mData.pidlist)
end


function C2GSDeleteFriend(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:DelFriend(oPlayer,mData.pid)
end

function C2GSChatTo(oPlayer, mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:ChatToFriend(oPlayer, mData.pid, mData.message_id, mData.msg)    
end

function C2GSAckChatFrom(oPlayer, mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:AckChatFrom(oPlayer, mData.pid, mData.message_id)   
end

function C2GSFindFriend(oPlayer, mData)
    local oFriendMgr = global.oFriendMgr
    local iPid = mData.pid
    local sName = mData.name
    if iPid and iPid ~= 0 then
        oFriendMgr:FindFriendByPid(oPlayer, iPid)
    else
        oFriendMgr:FindFriendByName(oPlayer, sName)
    end
end

function C2GSQueryFriendProfile(oPlayer, mData)
    local oFriendMgr = global.oFriendMgr
    local lPidList = mData.pid_list or {}
    if #lPidList > 0 then
        oFriendMgr:QueryFriendProfile(oPlayer, lPidList)
    end
end

function C2GSQueryFriendApply(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    local lPidList = mData.pid_list or {}

    if #lPidList>0  and #lPidList < 60  then
        oFriendMgr:QueryFriendApply(oPlayer,lPidList)
    end
end

function C2GSSimpleFriendList(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    local pidlist = mData.pidlist
    if #pidlist > 0 then
        oFriendMgr:QuerySimpleFriendList(oPlayer,pidlist)
    end
end



function C2GSFriendShield(oPlayer, mData)
    local oFriendMgr = global.oFriendMgr
    local iPid = mData.pid
    if iPid and iPid ~= 0 then
        oFriendMgr:Shield(oPlayer, iPid)
    end
end

function C2GSFriendUnshield(oPlayer, mData)
    local oFriendMgr = global.oFriendMgr
    local iPid = mData.pid
    if iPid and iPid ~= 0 then
        oFriendMgr:Unshield(oPlayer, iPid)
    end
end

function C2GSEditDocument(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    local mDoc = mData.doc
    oFriendMgr:EditDocument(oPlayer,mDoc)
end

function C2GSTakeDocunment(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:TakeDocunment(oPlayer,mData.pid)
end

function C2GSFriendSetting(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:FriendSetting(oPlayer,mData.setting or {})
end


function C2GSRecommendFriends(oPlayer,mData)
    --local oFriendMgr = global.oFriendMgr
    --oFriendMgr:Recommend(oPlayer)
end

function C2GSBroadcastList(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    
    oFriendMgr:FocusStranger(oPlayer,mData.plist)
end

function C2GSNearByFriend(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:SendNearbyList(oPlayer)
end

function C2GSSetPhoto(oPlayer,mData)
    if oPlayer.m_oThisTemp:Query("set_photo") then
        return
    end
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:SetPhoto(oPlayer,mData.url)
end

function C2GSSetShowPartner(oPlayer,mData)
    if oPlayer.m_oThisTemp:Query("ShowPartnerLimit")  then
        return
    end
    oPlayer.m_oPartnerCtrl:Forward("C2GSSetShowPartner",oPlayer:GetPid(),mData)
    oPlayer.m_oThisTemp:Set("ShowPartnerLimit",1,10)
end

function C2GSGetShowPartnerInfo(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:ShowPartnerInfo(oPlayer,mData.target,mData.parid)
end

function C2GSSetShowEquip(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:SetShowEquip(oPlayer,mData.show)
end

function C2GSGetEquipDesc(oPlayer,mData)
    local oFriendMgr = global.oFriendMgr
    oFriendMgr:ShowEquipInfo(oPlayer,mData.pid,mData.pos)
end


