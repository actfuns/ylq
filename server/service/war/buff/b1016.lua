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
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            return oBuff:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oBuffMgr:AddFunction("OnReceivedDamage",self.m_ID,fCallback)
end

function CBuff:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
    if iDamage < 1 then
        return 0 
    end
    local oWar = oVictim:GetWar()
    local mFriendList = oVictim:GetFriendList()
    local iShareDamage = iDamage//#mFriendList
    local iMod = math.fmod(iDamage,#mFriendList)
    if iShareDamage > 0 then
        local oBuffOwner
        for _,oWarrior in ipairs(mFriendList) do
            if oWarrior:GetWid() ~= oVictim:GetWid() and  oWarrior.m_oBuffMgr:HasBuff(1016)  then
                --attack_buff证明为非BUFF类伤害
                if oWarrior:GetWid() ~= self:GetAttack() then
                    self:ModifyHp(oWarrior,-iShareDamage,{attack_wid=oAttack:GetWid(),attack_buff=1})
                else
                    oBuffOwner = oWarrior
                end
            end
        end
        if oBuffOwner then
            self:ModifyHp(oBuffOwner,-iShareDamage,{attack_wid=oAttack:GetWid(),attack_buff=1})
        end
    end
    return  - iDamage + iShareDamage + iMod
end