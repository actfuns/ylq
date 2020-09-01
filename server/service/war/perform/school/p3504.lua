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
    if true then return end
    if not oVictim or oVictim:IsDead() then
        return
    end
    local mData = self:GetSkillData()
    local mArgs = {}
    local sArgs = mData["args"]
    local mEnv = {
        attack = oAttack:QueryAttr("attack")
    }
    mArgs = formula_string(sArgs,mEnv)
    local iAddHp = mArgs["on_perform_hp"]
    local oWar = oVictim:GetWar()
    local mData = self:GetSkillData()
    local mBuff = mData["victimBuff"] or {}
    for _,mData in pairs(mBuff) do
        local iBuffID = mData["buffid"]
        local iBout = mData["bout"]
        local oBuffMgr = oVictim.m_oBuffMgr
        oBuffMgr:AddBuff(iBuffID,iBout,{
            level = self:Level(),
            attack = oAttack:GetWid(),
            buff_bout = oWar.m_iBout,
            hp = iAddHp,
        })
    end
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