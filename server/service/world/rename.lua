local global = require "global"
local interactive = require "base.interactive"
local colorstring = require "public.colorstring"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local gamedefines = import(lualib_path("public/gamedefines"))
local loaditem = import(service_path("item/loaditem"))


function NewRenameMgr()
    local o = CRenameMgr:New()
    return o
end


CRenameMgr = {}
CRenameMgr.__index = CRenameMgr
inherit(CRenameMgr, logic_base_cls())

function CRenameMgr:New()
    local o = super(CRenameMgr).New(self)
    o:Init()
    return o
end

function CRenameMgr:Init()
    self.m_sDBName = "namecounter"
end

function CRenameMgr:Request(mCond, sFunc, callback)
    local mData = {
        module = self.m_sDBName,
        cmd = sFunc,
        data = mCond
    }
    gamedb.LoadDb(self.m_sDBName,"common", "LoadDb",mData, callback)
end

function CRenameMgr:Notify(iPid, sMsg)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(iPid, sMsg)
end

function CRenameMgr:GetPlayer(iPid)
    local oWorldMgr = global.oWorldMgr
    return oWorldMgr:GetOnlinePlayerByPid(iPid)
end

function CRenameMgr:DoRename(oPlayer, sNewName)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iOpenGrade = oWorldMgr:QueryControl("rename", "open_grade")
    local iPid = oPlayer:GetPid()
    if oPlayer:GetGrade() < iOpenGrade then
        self:Notify(iPid, string.format("你的等级＜%s级无法改名", iOpenGrade))
        return
    end
    sNewName = trim(sNewName)
    if not sNewName or sNewName == "" then
        oNotifyMgr:Notify(iPid, "请输入名字")
        return
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("virtualchat")
    if oHuodong then
        if not oHuodong:ValidRename(sNewName) then
            oNotifyMgr:Notify(iPid, "名字已重复")
            return
        end
    end
    local mCond = {name = sNewName}
    self:Request(mCond, "FindName", function(mRecord, mData)
        if not is_release(self) then
            self:DoRename1(iPid, sNewName, mData)
        end
    end)
end

function CRenameMgr:DoRename1(iPid, sNewName, mData)
    local oPlayer = self:GetPlayer(iPid)
    if not oPlayer then return end

    if mData.success then
        self:Notify(iPid, "名字已重复")
        return
    end

    local sMsg = string.format("[896055]你确定要将名字修改为：[-][1d8e00]%s[-][896055]？[-]", sNewName)
    self:SetCallBack(iPid, sNewName, sMsg)
end

function CRenameMgr:SetCallBack(iPid, sNewName, sMsg)
    local oPlayer = self:GetPlayer(iPid)
    if not oPlayer then return end

    local oCbMgr = global.oCbMgr
    local mData = oCbMgr:PackConfirmData(nil, {sContent=sMsg})
    oCbMgr:SetCallBack(iPid, "GS2CConfirmUI", mData, nil, function(oPlayer, mData)
        self:DoRename2(oPlayer, sNewName, mData.answer)
    end)
end

function CRenameMgr:DoRename2(oPlayer, sNewName, iAnswer)
    if iAnswer ~= 1 then return end

    local iItemSid = self:GetRenameItemSid()
    local iAmount = oPlayer:GetItemAmount(iItemSid)
    local iFrozen
    if iAmount <= 0 then
        local oItem = loaditem.GetItem(iItemSid)
        local iCost = oItem:BuyPrice()
        if not oPlayer:ValidGoldCoin(iCost) then
            return
        end
        iFrozen = oPlayer:FrozenMoney("goldcoin",iCost, "改名")
    end
    local iPid = oPlayer:GetPid()
    local mCond = {name = sNewName}
    local mArgs = {
        module = self.m_sDBName,
        cmd = "InsertNewNameCounter",
        data = mCond,
    }
    gamedb.LoadDb(self.m_sDBName,"common", "SaveDb",mArgs,function (mRecord,mData)
        self:DoRename3(iPid, sNewName, iFrozen, mData)
    end)
end

function CRenameMgr:DoRename3(iPid, sNewName, iFrozen, mData)
    local oPlayer = self:GetPlayer(iPid)
    if not oPlayer then
        self:DoRenameFail(iPid, iFrozen)
        return
    end
    if mData.success then
        self:DoRenameSuccess(oPlayer, sNewName, iFrozen)
    else
        self:DoRenameFail(iPid, iFrozen)
    end
end

function CRenameMgr:DoRenameSuccess(oPlayer, sNewName, iFrozen)
    local sReason = "改名"
    local iItemSid = self:GetRenameItemSid()
    local oItem = loaditem.GetItem(iItemSid)
    local oProfile = oPlayer:GetProfile()
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    if iFrozen then
        oProfile:UnFrozenMoney(iFrozen)
        oPlayer:ResumeGoldCoin(oItem:BuyPrice(), "rename", {from_id = 20001})
        self:_TrueDoRenameSuccess(iPid,sNewName,{success=true})
    else
        if oPlayer:GetItemAmount(iItemSid) < 1 then
            return
        end
        local fCallback = function (mRecord,mData)
            self:_TrueDoRenameSuccess(iPid,sNewName,mData)
        end
        oPlayer.m_oItemCtrl:RemoveItemAmount(iItemSid,1,sReason,{},fCallback)
    end

end

function CRenameMgr:_TrueDoRenameSuccess(iPid,sNewName,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local sOldName = oPlayer:GetName()
    oPlayer:SetName(sNewName)

    oPlayer:SyncSceneInfo({name = sNewName})

    self:OnRenameSuccess(oPlayer, sOldName, sNewName)
    oPlayer:SyncRoleData2DataCenter()
    oPlayer:SyncAssistPlayerData({name = oPlayer:GetName()})

    local oNotifyMgr = global.oNotifyMgr
    local sMsg = "改名成功，你的名字已修改为#role"
    local mNotifyArgs = {
        role = sNewName
    }
    oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),{"GS2CNotify"},sMsg,mNotifyArgs)
end

function CRenameMgr:DoRenameFail(iPid, iFrozen)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iPid, function(o)
        self:DoRenameFail1(o, iFrozen)
    end)
end

function CRenameMgr:DoRenameFail1(oProfile, iFrozen)
    if not oProfile or not iFrozen then return end
    oProfile:UnFrozenMoney(iFrozen)

    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oProfile:GetPid(), "抱歉，该角色名已存在！")
end

function CRenameMgr:OnRenameSuccess(oPlayer, sOldName, sNewName)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        local oMember = oTeam:GetMember(pid)
        if oMember then
            oMember:Update({name=sNewName})
        end
    end
    self:RefreshDbName(oPlayer:GetPid(),sOldName,sNewName)
    oPlayer:SyncTosOrg({name=true})

    local oMailMgr = global.oMailMgr
    local mInfo, sMail = oMailMgr:GetMailInfo(13)
    mInfo.context = string.format(mInfo.context, sOldName, sNewName)
    local oFriendCtrl = oPlayer:GetFriend()
    oFriendCtrl:SendMailByDegree(0, sMail, mInfo)

    self:OnRenameTitle(oPlayer,sNewName)

    record.user("player", "rename", {
        pid = oPlayer:GetPid(),
        old_name = sOldName,
        new_name = sNewName,
    })
end

function CRenameMgr:OnRenameTitle(oPlayer,sNewName)
    local oFriend = oPlayer:GetFriend()
    local iMarryID = oFriend:GetMarryID()
    if iMarryID == 0 then
        return
    end
    global.oTitleMgr:CheckAdjust(iMarryID,1082,sNewName)
end

function CRenameMgr:RefreshDbName(iPid,sOldName,sNewName)
    local oRankMgr = global.oRankMgr
    oRankMgr:OnUpdateName(iPid,sNewName)

    local mData = {
        name = sOldName,
    }
    gamedb.SaveDb(self.m_sDBName,"common", "SaveDb", {module = "namecounter",cmd="DeleteName",data = mData})
end

function CRenameMgr:GetRenameItemSid()
    local res = require "base.res"
    local mGlobal = res["daobiao"]["global"]["rename_role_item"]
    return tonumber(mGlobal.value)
end


function CRenameMgr:InitRoleName(oPlayer,sName)
    local mCond = {name = sName}
    local iPid = oPlayer:GetPid()
    self:Request(mCond, "FindName", function(mRecord, mData)
        if not is_release(self) then
            self:InitRoleName1(iPid, sName, mData)
        end
    end)
end

function CRenameMgr:InitRoleName1(iPid,sNewName,mData)
    if mData.success then
        self:Notify(iPid, "名字已重复")
        local oPlayer = self:GetPlayer(iPid)
        oPlayer:Send("GS2CInitRoleNameResult",{})
        return
    end
    local mCond = {name = sNewName}
    self:Request(mCond, "InsertNewNameCounter", function (mRecord, mData)
        self:InitRoleName2(iPid, sNewName, mData)
    end)
end

function CRenameMgr:InitRoleName2(iPid,sNewName,mData)
    local oPlayer = self:GetPlayer(iPid)
    if not oPlayer then
        self:DoRenameFail(iPid, iFrozen)
        return
    end
    if mData.success then
        self:InitRoleNameSuccess(oPlayer, sNewName)
    else
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(iPid, "抱歉，该角色名已存在！")
        oPlayer:Send("GS2CInitRoleNameResult",{result = 0})
    end
end

function CRenameMgr:InitRoleNameSuccess(oPlayer,sNewName)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oPlayer:GetPid(),"起名成功")
    self:ChangeRoleName(oPlayer,sNewName)
    oPlayer.m_oActiveCtrl:SetData("initrolename",1)
end

function CRenameMgr:ChangeRoleName(oPlayer,sNewName)
    oPlayer:SetName(sNewName)

    oPlayer:SyncSceneInfo({name = sNewName})

    oPlayer:SyncRoleData2DataCenter()
    oPlayer:Send("GS2CInitRoleNameResult",{result = 1})

    oPlayer:SyncTosOrg({name=true})
    local oRankMgr = global.oRankMgr
    oRankMgr:OnUpdateName(oPlayer:GetPid(),sNewName)
    oPlayer:SyncAssistPlayerData({name = oPlayer:GetName()})
end