local global = require "global"


Commands = {}
Helpers = {}
Opens = {}  --是否对外开放

Helpers.help = {
    "GM指令帮助",
    "help 指令名",
    "help 'clearall'",
}
function Commands.help(oMaster, sCmd)
    if sCmd then
        local o = Helpers[sCmd]
        if o then
            local sMsg = string.format("%s:\n指令说明:%s\n参数说明:%s\n示例:%s\n", sCmd, o[1], o[2], o[3])
            oMaster:Send("GS2CGMMessage", {
                msg = sMsg,
            })
        else
            oMaster:Send("GS2CGMMessage", {
                msg = "没查到这个指令"
            })
        end
    end
end

Helpers.map = {
    "跳到固定地图",
    "map {id=固定场景编号,x=X坐标,y=Y坐标,}",
    "map {id=1001,x=100,y=100,}",
}
function Commands.map(oMaster, m)
    local res = require "base.res"
    local iMapId = m.id
    local oNowScene = oMaster.m_oActiveCtrl:GetNowScene()
    if oNowScene:MapId() == iMapId then
        return
    end
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:SelectDurableScene(iMapId)
    local mNowPos = oMaster.m_oActiveCtrl:GetNowPos()
    oSceneMgr:EnterScene(oMaster, oScene:GetSceneId(), {pos = {x = m.x or mNowPos.x, y = m.y or mNowPos.y, face_x = mNowPos.face_x, face_y = mNowPos.face_y, }}, true)
end

function Commands.choosemap(oMaster)
     local oSceneMgr = global.oSceneMgr
    local iTotal = 0
    local lStat = {"\n",}
    local iChooseSceneIdx
    local iScenePlayerCnt = 100000
    local mScene = {}
    local mNoFly = {[501000] = true,[601000]=true,[204000]=true,[300000]=true,[300100]=true,[200100]=true,[261000]=true,
    [208000] = true,[666666] = true,
    }
    for id, oScene in pairs(oSceneMgr.m_mScenes) do
        local iMapId = oScene:MapId()
        --if not mNoFly[iMapId] then
        if iMapId == 101000 then
            local lPlayer = oScene:GetPlayers()
            local iCnt = table_count(lPlayer)
            mScene[id] = iCnt
        end
    end

    for id,iCnt in pairs(mScene) do
        if iCnt < iScenePlayerCnt then
            iChooseSceneIdx = id
            iScenePlayerCnt = iCnt
        end
    end
    if not iChooseSceneIdx then
        return
    end

    local mNowPos = oMaster.m_oActiveCtrl:GetNowPos()
    local oScene = oSceneMgr:GetScene(iChooseSceneIdx)
    local iX, iY = 10+math.random(5),5+math.random(5)
    local mPos = {
        x = iX,
        y = iY,
        face_x = mNowPos.face_x,
        face_y = mNowPos.face_y,
    }
    oSceneMgr:EnterScene(oMaster,iChooseSceneIdx,{pos = mPos},true)
end

Helpers.ignorewalk = {
    "忽略场景检查",
    "ignorewalk"
}


function Commands.ignorewalk(oMaster)
    local oSceneMgr = global.oSceneMgr
    local oNotifyMgr = global.oNotifyMgr
    oMaster.m_oToday:Set("gm_ignorewalk",1)
    local mNowPos = oMaster.m_oActiveCtrl:GetNowPos()
    local iScene = oMaster.m_oActiveCtrl:GetNowSceneID()
    oSceneMgr:EnterScene(oMaster, iScene, {pos = {x = mNowPos.x, y = mNowPos.y, face_x = mNowPos.face_x, face_y = mNowPos.face_y, }}, true)
    oNotifyMgr:Notify(oMaster:GetPid(),"场景设定关闭成功,今天内不会进行行走拉回")
end

Helpers.ignorewalk = {
    "场景信息",
    "sceneinfo"
}


function Commands.sceneinfo(oMaster)
     local oSceneMgr = global.oSceneMgr
    local oChatMgr = global.oChatMgr
    local sScene = {}
     for _,obj in pairs(oSceneMgr.m_mScenes) do
        local sKey = obj:GetName()
        if not sScene[sKey] then
            sScene[sKey] = 0
        end
        sScene[sKey] = sScene[sKey] + table_count(obj.m_mPlayers)
     end
     local iSum = 0
     for sKey,iCnt in pairs(sScene) do
        iSum = iSum + iCnt
        local s = string.format("%s 人数:%s",sKey,iCnt)
        oChatMgr:HandleMsgChat(oMaster,s)
     end
     oChatMgr:HandleMsgChat(oMaster,string.format("sum=%s",iSum))
end

function Commands.FlyToPos(oMaster)
    local iMap = 102000
    local mPos = {
        x = 18,
        y = 21,
        face_x = 0,
        face_y = 0,
    }
    local oScene = global.oSceneMgr:SelectDurableScene(tonumber(iMap))
    if not oScene then
        return
    end
    local iSceneId = oScene:GetSceneId()
    global.oSceneMgr:EnterScene(oMaster,iSceneId,{pos=mPos},true)
end

function Commands.choosemapline(oMaster,iMapId,iLine)
    local oTargetScene
    local lSceneobj = global.oSceneMgr:GetSceneListByMap(iMapId)
    if #lSceneobj < iLine then
        oTargetScene = lSceneobj[#lSceneobj]
    else
        oTargetScene = lSceneobj[iLine]
    end
    local mPos = {
        x = 18,
        y = 21,
        face_x = 0,
        face_y = 0,
    }
    global.oSceneMgr:EnterScene(oMaster,oTargetScene:GetSceneId(),{pos = mPos},true)
end



