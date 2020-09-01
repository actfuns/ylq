--import module
local global = require "global"

local npcnet = import(service_path("netcmd/npc"))
local datactrl = import(lualib_path("public.datactrl"))

CNpc = {}
CNpc.__index = CNpc
inherit(CNpc,datactrl.CDataCtrl)

function CNpc:New(iNpcType)
    local o = super(CNpc).New(self)
    o.m_iType = iNpcType
    o:InitObject()
    o:Init()
    return o
end

function CNpc:Init()
    local mArgs = self:GetData(self.m_iType)

    self.m_iMapid = mArgs["sceneId"]

    local mModel = {
        shape = mArgs["modelId"],
        adorn = mArgs["ornamentId"],
        weapon = mArgs["wpmodel"],
        color = mArgs["mutateColor"],
        mutate_texture = mArgs["mutateTexture"],
        scale = mArgs["scale"]
    }
    self.m_mModel = mModel

    self.m_iDialog = mArgs["dialogId"]
    local mPosInfo = {
            x = mArgs["x"],
            y = mArgs["y"],
            z = mArgs["z"],
            face_x = mArgs["face_x"] or 0,
            face_y = mArgs["face_y"] or 0,
            face_z = mArgs["face_z"] or 0
    }
    self.m_mPosInfo = mPosInfo
end

function CNpc:InitObject()
    local oNpcMgr = global.oNpcMgr
    local iDispatchId = oNpcMgr:DispatchId()
    self.m_ID = iDispatchId
    oNpcMgr:AddObject(self)
end

function CNpc:Release()
    super(CNpc).Release(self)
end

function CNpc:GetData(iNpcType)
    local res = require "base.res"
    return res["daobiao"]["global_npc"][iNpcType]
end

function CNpc:Name()
    local mNpcInfo = self:GetData(self.m_iType)
    return mNpcInfo["name"]
end

function CNpc:SetScene(iScene)
    self.m_iScene = iScene
end

function CNpc:GetScene()
    return self.m_iScene
end

function CNpc:do_look(oPlayer)
    if self.m_CustomLook and self.m_CustomLook(oPlayer) then
        return
    end
    local sText = self:GetText()
    self:Say(oPlayer.m_iPid,sText)
end

function CNpc:Type()
    return self.m_iType
end

function CNpc:Fight(oPlayer)
    local oHuodong = global.oHuodongMgr:GetHuodong("npcfight")
    if oHuodong then
        oHuodong:Fight(oPlayer, self)
    else
        local record = require "public.record"
        record.error("npc fight error, huodong:npcfight not exist!")
    end
end

function CNpc:GetTotalFight()
    local mData = self:GetData(self.m_iType)
    if not mData then
        return 0
    end
    return mData.fight_total or 0
end

function CNpc:CommonFightID()
    local mData  = self:GetData(self.m_iType)
    if not mData then
        return 0
    end
    return mData.fight_common_id or 0
end

function CNpc:Shape()
    return self.m_mModel["shape"]
end

function CNpc:ModelInfo()
    return self.m_mModel
end

function CNpc:PosInfo()
    return self.m_mPosInfo
end

function CNpc:MapId()
    return self.m_iMapid
end

function CNpc:Title()
    return nil
end


function CNpc:Say(pid,sText)
    local mNet = {}
    mNet["npcid"] = self.m_ID
    mNet["shape"] = self:Shape()
    mNet["name"] = self:Name()
    mNet["text"] = sText
    mNet["fight"] = self:CanFight(pid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        oPlayer:Send("GS2CNpcSay",mNet)
    end
end

--需要客户端回应
function CNpc:SayRespond(pid,sText,fResCb,fCallBack)
    local mNet = {}
    mNet["npcid"] = self.m_ID
    mNet["shape"] = self:Shape()
    mNet["name"] = self:Name()
    mNet["text"] = sText
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(pid,"GS2CNpcSay",mNet,fResCb,fCallBack)
end

function CNpc:CanFight(pid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        local mFight = oPlayer.m_oActiveCtrl:GetData("npc_fight", {})
        local iHaveFight = mFight[db_key(self.m_iType)] or 0
        local iTotal = self:GetTotalFight()
        return iHaveFight < iTotal
    end
    return false
end

function CNpc:GetText()
    local res = require "base.res"
    local iDialog = self.m_iDialog
    local mDialog = res["daobiao"]["dialog_npc"][iDialog]
    local iNo = math.random(3)
    local sKey = string.format("dialogContent%d",iNo)
    if not mDialog then
        return ""
    end
    local sDialog = mDialog[sKey]
    return sDialog
end

function CNpc:InWar()
    if not self.m_iWarID then
        return
    end
    local oWarMgr = global.oWarMgr
    return oWarMgr:GetWar(self.m_iWarID)
end

function CNpc:SetNowWar(iWarID)
    self.m_iWarID = iWarID
end

function CNpc:ClearNowWar()
    self.m_iWarID = nil
end

function CNpc:GetMonsterFlag()
    return false
end

function CNpc:PackSceneInfo()
    local mInfo = {
        npctype  = self.m_iType,
        npcid = self.m_ID,
        name = self:Name(),
        model_info = self:ModelInfo(),
        mode = self.m_ShowMode or 0,
        title = self:Title(),
        monster_flag = self:GetMonsterFlag(),
    }
    return mInfo
end

--同步信息去场景
function CNpc:SyncSceneInfo(mInfo)
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(self.m_iScene)
    if oScene then
        oScene:SyncNpcInfo(self,mInfo)
    end
end

function CNpc:ID()
    return self.m_ID
end

function CNpc:CountDown()
    -- body
end

function NewNpc(npctype)
    local o = CNpc:New(npctype)
    return o
end
