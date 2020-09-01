local global = require "global"

local loaditem = import(service_path("item.loaditem"))
local loadpartner = import(service_path("partner.loadpartner"))


function NewHandBookMgr(...)
    return CHandBookMgr:New(...)
end

function NewCheckHuoDong()
    return CCheckCondition:New()
end

CHandBookMgr = {}
CHandBookMgr.__index = CHandBookMgr
inherit(CHandBookMgr, logic_base_cls())

function CHandBookMgr:New()
    local o = super(CHandBookMgr).New(self)
    o.m_oCheck = CCheckCondition:New()
    o.m_mKey2Condition = {}
    return o
end

function CHandBookMgr:InitData()
    self:InitKeyCondition()
end

function CHandBookMgr:InitKeyCondition()
    local res = require "base.res"
    local mCondition = res["daobiao"]["handbook"]["condition"]
    for iCondition, mInfo in pairs(mCondition) do
        local sCondition = mInfo or res["daobiao"]["handbook"]["condition"][iConditionID]["condition"]
        local sKey = split_string(mInfo["condition"], "=")[1]
        local m = self.m_mKey2Condition[sKey] or {}
        table.insert(m, iCondition)
        self.m_mKey2Condition[sKey] = m
    end
end

function CHandBookMgr:GetConditionByKey(sKey)
    return self.m_mKey2Condition[sKey] or {}
end

function CHandBookMgr:PushCondition(iPid, sKey, mData)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:PushBookCondition(sKey, mData)
    end
end

function CHandBookMgr:CheckCondition(sType, iPid, mWarArgs)
    self.m_oCheck:CheckCondition(sType, iPid, mWarArgs)
end



CCheckCondition = {}
CCheckCondition.__index = CCheckCondition
inherit(CCheckCondition, logic_base_cls())

function CCheckCondition:New()
    local o = super(CCheckCondition).New(self)

    return o
end

function CCheckCondition:CheckCondition(sType, iPid, mWarArgs)
    if sType == "arena" then
        self:CheckPVPCondition(mWarArgs)
    else
        self:CheckPVECondition(sType, iPid, mWarArgs)
    end
end

function CCheckCondition:CheckPVPCondition(mWarArgs)
    local oPubMgr = global.oPubMgr
    local oHandBookMgr = global.oHandBookMgr
    local lWinPlayer = mWarArgs.win_list or {}
    local mWinParName = {}
    for _, iPid in ipairs(lWinPlayer) do
        local mPartner = self:GetFightPartner(iPid, mWarArgs)
        for iParId,mInfo in pairs(mPartner) do
            local m = loadpartner.GetPartnerData(tonumber(mInfo.type))
            mWinParName[m.name] = true
        end
    end
    local lFailPlayer = mWarArgs.fail_list or {}
    local mFailParName = {}
    for _, iPid in ipairs(lFailPlayer) do
        local mPartner = self:GetFightPartner(iPid, mWarArgs)
        for iParId,mInfo in pairs(mPartner) do
            local m = loadpartner.GetPartnerData(tonumber(mInfo.type))
            mFailParName[m.name] = true
        end
    end

    for _, iPid in ipairs(lWinPlayer) do
        if mWinParName["朵屠"] and mFailParName["重华"] then
            oHandBookMgr:PushCondition(iPid, "竞技场朵屠战胜重华", {value = 1})
        end
        if mWinParName["执阳"] and mFailParName["青竹"] then
            oHandBookMgr:PushCondition(iPid, "竞技场执阳战胜青竹", {value = 1})
        end
        if mWinParName["白殊"] and mFailParName["奉主夜鹤"] then
            oHandBookMgr:PushCondition(iPid, "竞技场白殊战胜奉主夜鹤", {value = 1})
        end
        if mWinParName["稻荷"] and mFailParName["莲"] then
            oHandBookMgr:PushCondition(iPid, "竞技场稻荷战胜莲", {value = 1})
        end
        if mWinParName["蛇姬"] and mFailParName["犬妖"] then
            oHandBookMgr:PushCondition(iPid, "竞技场蛇姬战胜犬妖", {value = 1})
        end
        if mWinParName["青竹"] and mFailParName["执夷"] then
            oHandBookMgr:PushCondition(iPid, "竞技场青竹战胜执夷", {value = 1})
        end
        if mWinParName["琥非"] and mFailParName["古娄"] then
            oHandBookMgr:PushCondition(iPid, "竞技场琥非战胜古娄", {value = 1})
        end
        if mWinParName["琥非"] and mFailParName["古娄"] then
            oHandBookMgr:PushCondition(iPid, "竞技场琥非战胜古娄", {value = 1})
        end
        if mWinParName["黑"] and mFailParName["白殊"] then
            oHandBookMgr:PushCondition(iPid, "竞技场黑战胜白殊", {value = 1})
        end
        if mWinParName["黑"] and mFailParName["白"] then
            oHandBookMgr:PushCondition(iPid, "竞技场黑战胜白", {value = 1})
        end

        if mWinParName["阿坊"] and mWinParName["马面面"] then
            oHandBookMgr:PushCondition(iPid, "竞技场阿坊马面面获胜", {value = 1})
        end
        if mWinParName["伊露"] and mWinParName["白"] then
            oHandBookMgr:PushCondition(iPid, "竞技场伊露白获胜", {value = 1})
        end
    end
end

function CCheckCondition:CheckPVECondition(sType, iPid, mWarArgs)
    if sType == "pata" then
        self:CheckPVEPata(iPid, mWarArgs)
    elseif sType == "endlesspve" then
        self:CheckEndlessPVE(iPid, mWarArgs)
    end
end

function CCheckCondition:CheckPVEPata(iPid, mWarArgs)
    local oPubMgr = global.oPubMgr
    local oHandBookMgr = global.oHandBookMgr
    local lWinPlayer = mWarArgs.win_list or {}
    for _, iPid in ipairs(lWinPlayer) do
        local mPartner = self:GetFightPartner(iPid, mWarArgs)
        local mParName = {}
        local mEquip = {}
        for iParId,mInfo in pairs(mPartner) do
            local m = loadpartner.GetPartnerData(tonumber(mInfo.type))
            mParName[m.name] = true
        end
        local l = {"黑烈", "莲", "古娄", "琥非", "嘟嘟噜"}
        for _, sName in ipairs(l) do
            if mParName[sName] then
                -- local m = oPubMgr:GetPartnerData(sName)
                oHandBookMgr:PushCondition(iPid, string.format("地牢%s获胜", sName), {value = 1})
            end
        end
        if mParName["檀"] and mParName["重华"] then
            oHandBookMgr:PushCondition(iPid,"地牢檀重华获胜",{value = 1})
        end
        if mParName["绿狸"] and mParName["莹月"] then
            oHandBookMgr:PushCondition(iPid,"地牢绿狸莹月获胜",{value = 1})
        end
        if mParName["阿坊"] and mParName["马面面"] then
            oHandBookMgr:PushCondition(iPid,"地牢阿坊马面面获胜",{value = 1})
        end
        if mParName["吞天"] and mParName["噬地"] then
            oHandBookMgr:PushCondition(iPid,"地牢吞天噬地获胜",{value = 1})
        end
    end
end

function CCheckCondition:GetFightPartner(iPid, mWarArgs)
    mWarArgs = mWarArgs or {}
    return mWarArgs.fight_partner[iPid] or {}
end

function CCheckCondition:CheckEndlessPVE(iPid, mWarArgs)
    local oPubMgr = global.oPubMgr
    local oHandBookMgr = global.oHandBookMgr
    local lWinPlayer = mWarArgs.win_list or {}
    local iWinRing = mWarArgs.ring or 0
    for _, iPid in ipairs(lWinPlayer) do
        local mPartner = self:GetFightPartner(iPid, mWarArgs)
        local mParName = {}
        local mEquip = {}
        for iParId,mInfo in pairs(mPartner) do
            local m = loadpartner.GetPartnerData(tonumber(mInfo.type))
            mParName[m.name] = true
        end
        local l = {"黑"}
        for _, sName in ipairs(l) do
            if mParName[sName] then
                -- local m = oPubMgr:GetPartnerData(sName)
                -- oHandBookMgr:PushCondition(iPid,string.format("月见幻境%s获胜",sName), {value = 1})
            end
        end
        if mParName["执阳"] and mParName["执夷"] then
            oHandBookMgr:PushCondition(iPid,"月见幻境执阳执夷获胜",{value = 1})
        end
        if mParName["莹月"] and mParName["绿狸"] then
            oHandBookMgr:PushCondition(iPid,"月见幻境莹月绿狸获胜",{value = 1})
        end
        if mParName["莲"] and mParName["北溟"] then
            oHandBookMgr:PushCondition(iPid,"月见幻境莲北溟获胜",{value = 1})
        end
        if mParName["黑"] and mParName["白"] then
            oHandBookMgr:PushCondition(iPid,"月见幻境黑和白获胜",{value = 1})
        end
        if mParName["魃女"] and mParName["判官"] then
            oHandBookMgr:PushCondition(iPid,"月见幻境魃女判官获胜",{value = 1})
        end
        if mParName["判官"] and mParName["奉主夜鹤"] then
            oHandBookMgr:PushCondition(iPid,"月见幻境判官奉主夜鹤获胜",{value = 1})
        end
    end
end

function CHandBookMgr:UpdateKey()
    self:InitKeyCondition()
end