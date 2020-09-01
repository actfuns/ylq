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

function CPerform:PerformTarget(oAttack,oVictim)
    local iCnt = self:Range()
    local mTarget = {oVictim.m_iWid,}
    if iCnt <= 1 then
        return mTarget
    end
    local m = oAttack:GetFriendList()
    local mRatio = {}
    for _,w in pairs(m) do
        if w ~= oVictim then
            local iRatio = math.floor(w:GetHp() * 100 / w:GetMaxHp())
            table.insert(mRatio,{iRatio,w:GetWid()})
        end
    end
    local func = function (tbl1,tbl2)
        if tbl1[1] ~= tbl2[1] then
            return tbl1[1] < tbl2[1]
        else
            return tbl1[2] < tbl2[2]
        end
    end
    table.sort(mRatio,func)
    for _,mData in pairs(mRatio) do
        if #mTarget >= iCnt then
            break
        end
        local iWid = mData[2]
        table.insert(mTarget,iWid)
    end
    self:SetData("PerformTarget",mTarget)
    return mTarget
end

function CPerform:CalculateHP(oAttack,oVictim)
    local mData = self:GetSkillData()
    local mArgs = {}
    local sArgs = mData["args"]
    local mEnv = {
        attack = oAttack:QueryAttr("attack"),
    }
    local mArgs = formula_string(sArgs,mEnv)
    return mArgs["hp"]
end

function CPerform:ChooseAITarget(oAttack)
     local mFriend = oAttack:GetFriendList()
     if #mFriend <= 0 then
        return
    end
     local mOther = {}
    local mRatio = {}
    for _,w in pairs(mFriend) do
        if not w:IsNpc() then
            local iRatio = math.floor(w:GetHp() * 100 / w:GetMaxHp())
            table.insert(mRatio,{iRatio,w:GetWid()})
        else
            table.insert(mOther,w)
        end
    end
    if #mRatio <= 0 then
        local w = mOther[math.random(#mOther)]
        return w:GetWid()
    end
    local fSort = function (tbl1,tbl2)
        if tbl1[1] ~= tbl2[1] then
            return tbl1[1] < tbl2[1]
        else
            return tbl1[2] < tbl2[2]
        end
    end
    table.sort(mRatio,fSort)
    local mData = mRatio[1]
    local iRatio,iWid = table.unpack(mData)
    return iWid
end