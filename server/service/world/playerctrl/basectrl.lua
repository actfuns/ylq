--import module
local skynet = require "skynet"
local global = require "global"
local res = require "base.res"

local datactrl = import(lualib_path("public.datactrl"))
local playernet = import(service_path("netcmd/player"))

CPlayerBaseCtrl = {}
CPlayerBaseCtrl.__index = CPlayerBaseCtrl
inherit(CPlayerBaseCtrl, datactrl.CDataCtrl)

function CPlayerBaseCtrl:New(pid)
    local o = super(CPlayerBaseCtrl).New(self, {pid = pid})
    return o
end

function CPlayerBaseCtrl:Load(mData)
    local mData = mData or {}
    local mRoleInitProp = res["daobiao"]["roleprop"][1]

    self:SetData("grade", mData.grade or mRoleInitProp.grade)
    self:SetData("sex", mData.sex or 1)
    self:SetData("model_info", mData.model_info)
    self:SetData("school", mData.school)
    self:SetData("init_newrole",mData.init_newrole)
    self:SetData("cure_power", mData.cure_power or mRoleInitProp.cure_power)
    self:SetData("school_branch",mData.school_branch or 1)
    self:SetData("systemsetting",mData.systemsetting or {})
    self:SetData("ArenaData",mData.arena or {})
    self:SetData("ArenaScore",mData.score or 1000)
    self:SetData("orgname",mData.orgname or "")
    self:SetData("create_time",mData.create_time or 0)
    self:SetData("platform",mData.platform or "")
    self:SetData("channel",mData.channel or 0)
    self:SetData("other_info",mData.other_info or {})
    self:SetData("fuli_info",mData.fuli_info or {})
    local mBC = mData.blcmd
    if not mBC then
        local res = require "base.res"
        local mBattle = res["daobiao"]["battle_command"]
        mBC = {}
        for k,v in pairs(mBattle) do
            mBC[v.id] =v.desc
        end
    end
    self:SetData("BattleCommand",mBC)
    self:SetData("first_charge",mData.first_charge or 0)
end

function CPlayerBaseCtrl:Save()
    local mData = {}

    mData.grade = self:GetData("grade")
    mData.sex = self:GetData("sex")
    mData.model_info = self:GetData("model_info")
    mData.school = self:GetData("school")
    mData.init_newrole = self:GetData("init_newrole")
    mData.school_branch = self:GetData("school_branch")
    mData.systemsetting = self:GetData("systemsetting")
    mData.arena = self:GetData("ArenaData",{})
    mData.score = self:GetData("ArenaScore",1000)

    mData.create_time = self:GetData("create_time",0)
    mData.platform = self:GetData("platform","")
    mData.channel = self:GetData("channel",0)
    mData.other_info = self:GetData("other_info",{})
    mData.orgname = self:GetOrgName()
    mData.fuli_info = self:GetData("fuli_info",{})
    mData.blcmd = self:GetData("BattleCommand")
    mData.first_charge = self:GetData("first_charge",0)
    return mData
end

function CPlayerBaseCtrl:OnLogin(oPlayer,bReEnter)
end

function CPlayerBaseCtrl:OnLogout(oPlayer)
end

function CPlayerBaseCtrl:OnDisconnected(oPlayer)
end

function CPlayerBaseCtrl:ChangeShape(iShape)
    local m = self:GetData("model_info")
    m.shape = iShape
    self:SetData("model_info", m)

    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    oPlayer:PropChange("model_info")
end

function CPlayerBaseCtrl:OnUpGrade(iGrade)
    --
end

function CPlayerBaseCtrl:SchoolBranch()
    return self:GetData("school_branch")
end

function CPlayerBaseCtrl:SetSchoolBranch(iBranch)
    local oWorldMgr = global.oWorldMgr
    self:SetData("school_branch",iBranch)
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        local mChange = {
            ["school_branch"] = true,
            ["skill_point"] = true,
        }
        oPlayer:ClientPropChange(mChange)
        oPlayer:PropChange("school_branch","skill_point")
        oPlayer:SyncTosOrg({school_branch=true})
        oPlayer:SyncAssistPlayerData({school_branch=self:SchoolBranch()})
    end
end

function CPlayerBaseCtrl:SetSystemSetting(mNewSetting)
    local mSetting = self:GetData("systemsetting")

    for key,value in pairs(mNewSetting) do
        if not mSetting[key] then
            mSetting[key] = value
        else
            for option,choice in pairs(value) do
                mSetting[key][option] = choice
            end
        end
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        local mChange = {
            ["systemsetting"] = true,
        }
        oPlayer:ClientPropChange(mChange)
        oPlayer:PropChange("systemsetting")
    end
end

function CPlayerBaseCtrl:GetSystemSetting(sKey)
    local mSetting = self:GetData("systemsetting")
    if not sKey then
        return mSetting
    else
        return mSetting[sKey] or {}
    end
end

function CPlayerBaseCtrl:GetOrgName()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        return oPlayer:GetOrgName()
    end
    return ""
end

function CPlayerBaseCtrl:SetFirstCharge( ... )
    self:SetData('first_charge',1)
end

function CPlayerBaseCtrl:IsFirstCharge()
    if self:GetData("first_charge",0) == 1 then
        return true
    end
    return false
end