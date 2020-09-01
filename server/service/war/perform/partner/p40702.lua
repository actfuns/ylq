--import module

local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))


function NewCPerform(...)
    local o = CPerform:New(...)
    return o
end

CPerform = {}
CPerform.__index = CPerform
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalculateHP(oAttack,oVictim)
    local mData = self:GetSkillData()
    local sArgs = mData["args"]
    local mEnv = {
        attack = oAttack:QueryAttr("attack"),
    }
    local mArgs = formula_string(sArgs,mEnv)
    local iAddHp = mArgs["hp"] or 500
    local iExtWid = self:GetData("ext_wid",0)
    local iHpRatio = mArgs["hp_ratio"]
    if oVictim:GetWid() == iExtWid and  iHpRatio then
        iHpRatio = iHpRatio/10000
        iAddHp = iAddHp + math.floor(oAttack:QueryAttr("attack") * iHpRatio)
    end
    return iAddHp
end

function CPerform:Perform(oAttack,lVictim)
    local mFriend = oAttack:GetFriendList()
    local mHp = {}
    for _,w in pairs(mFriend) do
        if not w:IsCallNpc() then
            table.insert(mHp,{w:GetHp(),w:GetWid()})
        end
    end
    local fSort = function (mData1,mData2)
        if mData1[1] ~= mData2[1] then
            return mData1[1] < mData2[1]
        else
            return mData2[2] < mData2[2]
        end
    end
    table.sort(mHp,fSort)
    local mData = mHp[1]
    local iHp,iWid = table.unpack(mData)
    self:SetData("ext_wid",iWid)
    super(CPerform).Perform(self,oAttack,lVictim)
    self:SetData("ext_wid",nil)
end


