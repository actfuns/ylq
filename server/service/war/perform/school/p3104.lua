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

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    if not oVictim or oVictim:IsDead() then
        return
    end
    if oVictim:GetWid() == oAttack:GetWid() then
        return
    end
    self:Effect_Condition_For_Victim(oVictim,oAttack)
end

function CPerform:ChooseAITarget(oAttack)
    local mFriend = oAttack:GetFriendList()
    local mRatio = {}
    for _,w in pairs(mFriend) do
        local iRatio = math.floor(w:GetHp() * 100 / w:GetMaxHp())
        table.insert(mRatio,{iRatio,w:GetWid()})
    end
    local fSort = function (mData1,mData2)
        if mData1[1] ~= mData2[1] then
            return mData1[1] < mData2[1]
        else
            return mData1[2] < mData2[2]
        end
    end
    table.sort(mRatio, fSort )
    local mData = mRatio[1]
    local iRatio,iWid = table.unpack(mData)
    return iWid
end