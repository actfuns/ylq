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

function CPerform:ValidUse(oAttack,oVictim)
    if oVictim and oVictim:IsDead() and not oVictim:ValidRevive({}) then
        return false
    end
    return super(CPerform).ValidUse(self,oAttack,oVictim)
end



function CPerform:CalculateHP(oAttack,oVictim)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["hp_ratio"] or 2000
    local iAddHp = math.floor(oAttack:GetMaxHp() * iRatio / 10000)
    return iAddHp
end


function CPerform:ValidCast(oAttack,oVictim)
    local mTarget = self:TargetList(oAttack)
    if oVictim then
        for _,w in pairs(mTarget) do
            if w:GetWid() == oVictim:GetWid() then
                if w:IsDead() then
                    if not oVictim:GetPerform(31102)  then
                        oAttack:SetBoutArgs("31102CD",2)
                        return w
                    end
                else
                    return w
                end
            end
        end
    end

    if #mTarget < 0 then
        return
    end
    local mDeadList = {}
    local mAlive = {}
    for _,w in pairs(mTarget) do
        if w:IsDead() and not w:GetPerform(31102)  then
            table.insert(mDeadList,w)
        else
            table.insert(mAlive,w)
        end
    end

    if #mDeadList > 0 then
        oAttack:SetBoutArgs("31102CD",2)
        return mDeadList[math.random(#mDeadList)]
    end
    table.sort(mAlive,function (a,b)
        return a:GetHpRatio() < b:GetHpRatio()
        end
        )
    return mAlive[1]

end

function CPerform:ChooseFriend(oAttack)
    local mFriend = oAttack:GetFriendList()
    table.sort(mFriend,function (a,b)
        return a:GetHpRatio() < b:GetHpRatio()
        end)
    local m = mFriend[1]
    return m:GetWid()
end

function CPerform:ChooseAITarget(oAttack)
    local mFriend = oAttack:GetFriendList(true)
    if #mFriend <= 0 then
        return
    end
    local mDead = {}
    for _,oFriend in pairs(mFriend) do
        if oFriend:IsDead() and not oFriend:GetPerform(31102) then
            table.insert(mDead,oFriend)
        end
    end
    if #mDead > 0 then
        local w = mDead[math.random(#mDead)]
        oAttack:SetBoutArgs("31102CD",2)
        return w:GetWid()
    else
        return self:ChooseFriend(oAttack)
    end
end

function CPerform:SetCD(oAttack)
    local oWar = oAttack:GetWar()
    local iCurBout = oWar.m_iBout
    local mData = self:GetPerformData()
    local iBout = oAttack:QueryBoutArgs("31102CD",mData["cd"])

    local iRatio = oAttack:Query("no_cd_ratio",0)
    if in_random(iRatio,10000) then
        self:ShowPerfrom(oAttack,{skill = 3207})
        return
    end
    iBout = iBout + 1                                      --BoutEnd减少次数,+1
    self:SetData("CD",iBout)
    self:SetData("CDBout",iBout+iCurBout)
    local mCD = {
        skill_id = self.m_ID,
        bout = iBout,
    }

    local mCD = {}
    table.insert(mCD,{skill_id=self.m_ID,bout=iBout})
     oAttack:Send("GS2CWarSkillCD",{
         war_id = oWar:GetWarId(),
         wid = oAttack:GetWid(),
         skill_cd = mCD,
     })
end

function CPerform:IsCD(oAttack)
    if oAttack:QueryBoutArgs("31102CD",0) > 0 then
        return true
    end
    local mData = self:GetPerformData()
    local iCDBout = mData["cd"]
    if iCDBout <= 0 then
        return false
    end
    return true
end

function CPerform:SetAICD(oAttack)
    if not self:IsAICD(oAttack) then
        return
    end
    if not oAttack:IsRomWarrior() then
        return
    end
    local oWar = oAttack:GetWar()
    local iCurBout = oWar.m_iBout
    local mData = self:GetSkillData()
    local iBout = oAttack:QueryBoutArgs("31102CD",mData["ai_cd"])
    iBout = iBout + 1
    self:SetData("AICD",iBout)
    self:SetData("AICDBout",iBout+iCurBout)
    local mCD = {
        skill_id = self.m_ID,
        bout = iBout,
    }
end