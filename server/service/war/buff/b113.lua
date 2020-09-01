--import module

local global = require "global"
local skynet = require "skynet"

local buffbase = import(service_path("buff/buffbase"))

function NewBuff(...)
    local o = CBuff:New(...)
    return o
end

CBuff = {}
CBuff.__index = CBuff
inherit(CBuff, buffbase.CBuff)

function CBuff:CalInit(oWarrior,oBuffMgr)
    local iBuffID = self.m_ID
    local func = function (oVictim,oAttack,iDamage)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oBuff:OnKilled(oVictim,oAttack,iDamage)
        end
    end
    oWarrior:AddFunction("OnKilled",self.m_ID,func)
end

function CBuff:OnKilled(oVictim,oAttack,iDamage)
    local iMaxHp = oVictim:GetMaxHp()
    local mFriend = oAttack:GetFriendList()
    local iCnt = 0
    for _,w in pairs(mFriend) do
        if w and not w:IsDead() then
            iCnt = iCnt + 1
        end
    end
    if iCnt <= 0 then
        return
    end
    local iAddHp = math.floor(iMaxHp / iCnt)
    local mArgs = {
        attack_wid = oAttack:GetWid()
    }
    for _,w in pairs(mFriend) do
        if w and not w:IsDead() then
            self:ModifyHp(w,iAddHp,mArgs)
        end
    end
end