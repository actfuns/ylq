--import module
local global = require "global"
local skynet = require "skynet"

arenagame = {}

function arenagame.ArenaGameResult(mRecord,mData)
    local oHuoDong = global.oHuodongMgr:GetHuodong("arenagame")
    oHuoDong:MatchResult(mData.fight,mData.info)
end

function arenagame.EqualArenaMatchResult(mRecord,mData)
    local oHuoDong = global.oHuodongMgr:GetHuodong("equalarena")
    oHuoDong:MatchResult(mData.fight,mData.info)
end

function  arenagame.TeamPVPMatchResult(mRecord,mData)
    local oHuoDong = global.oHuodongMgr:GetHuodong("teampvp")
    oHuoDong:MatchResult(mData.fight,mData.info)
end


worldboss = {}

function worldboss.HPNotify(mRecord,mData)
    local oHDMgr = global.oHuodongMgr:GetHuodong("worldboss")
    oHDMgr:HPChange(mData.damage,mData.pidlist)
end

function worldboss.AddPartner(mRecord,mData)
    local oHDMgr = global.oHuodongMgr:GetHuodong("worldboss")
    oHDMgr:AddPartner(mData.pid,mData.parlist)
end

pata = {}

function pata.RecordPtnHp(mRecord,mData)
    local oHuoDong = global.oHuodongMgr:GetHuodong("pata")
    if oHuoDong then
        oHuoDong:RecordPataPtnHp(mData.pid,mData.parid,mData.hp)
    end
end

orgfuben = {}

function orgfuben.HPNotify(mRecord,mData)
    local  oHuodongMgr = global.oHuodongMgr
    local oHuoDong = oHuodongMgr:GetHuodong("orgfuben")
    oHuoDong:OnHpChange(mData.damage,mData.org,mData.type)
end


terrawars = {}

function terrawars.RecordRomPartnerHp(mRecord,mData)
    local iPid = mData.pid
    local iParId = mData.par_id
    local bWin = mData.win
    local iHp = mData.hp
    local iWarId = mData.war_id
    local oHuoDong = global.oHuodongMgr:GetHuodong("terrawars")
    if oHuoDong then
        oHuoDong:RecordRomPartnerHp(iWarId,bWin,iPid,iParId,iHp)
    end
end

yjfuben = {}

function yjfuben.SendReward(mRecord,mData)
    local sRankName = mData.name
    local lRankData = mData.data
    local lPreRankData = mData.pre
    local oHuoDong = global.oHuodongMgr:GetHuodong("yjfuben")
    if oHuoDong then
        oHuoDong:SendReward(lRankData,lPreRankData)
    end
end

fieldboss = {}

function fieldboss.HPNotify(mRecord,mData)
    local oHDMgr = global.oHuodongMgr:GetHuodong("fieldboss")
    oHDMgr:HPChange(mData.bossid,mData.damage,mData.pidlist)
end

msattack = {}

function msattack.DamageBoss(mRecord,mData)
    local oHDObj = global.oHuodongMgr:GetHuodong("msattack")
    oHDObj:DamageBoss(mData.damage)
end


clubarena = {}

function clubarena.GiveAutoReward(mRecord,mData)
    local oHDObj = global.oHuodongMgr:GetHuodong("clubarena")
    oHDObj:GiveAutoReward(mData)
end

function clubarena.Notify(mRecord,mData)
    local oHDObj = global.oHuodongMgr:GetHuodong("clubarena")
    oHDObj:NotifyMessage(mData)
end

function clubarena.UpdateInfo(mRecord,mData)
    local iPid = mData.pid
    local oHDObj = global.oHuodongMgr:GetHuodong("clubarena")
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer and oHDObj then
        oHDObj:UpdateInfo(oPlayer)
    end
end

upcard = {}
function upcard.CloseDrawCardUI(mRecord, mData)
    local iPid = mData["pid"]
    local oHuodong = global.oHuodongMgr:GetHuodong("upcard")
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer and oHuodong then
        oHuodong:CloseDrawCardUI(oPlayer)
    end
end

dailytrain = {}

function dailytrain.SetAutoSkill(mRecord,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("dailytrain")
    if oHuodong then
        local iPid = mData["pid"]
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        local iSkill = mData["skill"]
        oHuodong:SetAutoSkill(oPlayer,iSkill)
    end
end