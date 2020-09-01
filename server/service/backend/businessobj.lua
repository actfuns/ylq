-- module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"
local mongo = require "mongo"
local bson = require "bson"
local cjson = require "cjson"
local router = require "base.router"
local extend = require "base.extend"

local bkdefines = import(service_path("bkdefines"))
local backendobj = import(service_path("backendobj"))


function NewBusinessObj(...)
    local o = CBusinessObj:New(...)
    return o
end

CBusinessObj = {}
CBusinessObj.__index = CBusinessObj

function CBusinessObj:New()
    local o = setmetatable({}, self)
    return o
end

function CBusinessObj:Init()
end

function CBusinessObj:CheckPreCondition(mArgs, sServer)
    if nil == mArgs or "table" ~= type(mArgs) then
        record.info("backend: OnlineCheck, mArgs is Incorrect!\n")
        return 1
    end

    local oBackendObj = global.oBackendObj
    if not oBackendObj then
        record.info("backend: OnlineCheck, backobj not exist!\n")
        return 1
    end

    return 0
end

function CBusinessObj:RankPlayer(mArgs)
    local sServer = mArgs.serverId or "1"
    local res = require "base.res"
    local mDBSchool = res["daobiao"]["school"]

    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj:GetServer(sServer)
    if not oServer then return {errcode = 1} end

    local oGameDb = oServer.m_oGameDb:GetDb()
    local mGradeRank = oGameDb:FindOne("rank", {name = "grade"}).rank_data
    mGradeRank = mGradeRank or {}

    mongoop.ChangeAfterLoad(mGradeRank)

    local mNet = {}
    local lGradeSort = mGradeRank.sort_list or {}
    for idx, sPid in ipairs(lGradeSort) do
        local iPid = tonumber(sPid)
        local mPlayer = oGameDb:FindOne("player", {pid = iPid})
        mPlayer = mPlayer or {}
        mongoop.ChangeAfterLoad(mPlayer)
        local sNickName = mPlayer.name
        local iGrade = mPlayer.base_info.grade
        local iSchool = mPlayer.base_info.school
        local iExp = mPlayer.active_info.exp
        local mSchData = mDBSchool[iSchool] or {}
        local sSchoolName = mSchData["name"] or "无"
        table.insert(mNet, {id = iPid, grade = iGrade, exp = iExp, nickName = sNickName,
            rank = idx, school = sSchoolName})
    end

    -- table.sort(mNet, function (m1, m2)
    --     if m1["grade"] ~= m2["grade"] then
    --         return m1["grade"] > m2["grade"]
    --     end
    --     if m1["exp"] ~= m2["exp"] then
    --         return m1["exp"] > m2["exp"]
    --     end

    --     return false
    -- end)

    return {errcode = 0, data = mNet}
end

function CBusinessObj:CurrencyQuery(mArgs)
    local mNet = {}

    local sServerIds = mArgs.serverIds or "0"
    local sSelectStr = mArgs.selectStr

    if type(sServerIds) ~= "string" then
        return {errcode = 1}
    end

    local oBackendObj = global.oBackendObj
    local mServer = {}
    if sServerIds == "0" then
        mServer = table_key_list(oBackendObj:GetServerList())
    else
        mServer = split_string(sServerIds, ",")
    end

    mNet = self:GetWealthInfo(mServer)

    return {errcode = 0, data = mNet}
end

function CBusinessObj:GetWealthInfo(mServer)
    local mWealthInfo = {}
    local oBackendObj = global.oBackendObj

    for _, sServer in ipairs(mServer) do
        local oServer = oBackendObj:GetServer(sServer)
        local oGameDb = oServer.m_oGameDb:GetDb()
        local mPlayer = oGameDb:Find("player")
        while mPlayer:hasNext() do
            local mData = mPlayer:next()
            local iPid = mData.pid
            local mOfflineInfo = oGameDb:FindOne("offline", {pid = iPid}, {profile_info = true})
            mOfflineInfo = mOfflineInfo or {}
            mongoop.ChangeAfterLoad(mOfflineInfo)
            local mProfileInfo = {}
            if mOfflineInfo then
                mProfileInfo = mOfflineInfo["profile_info"] or {}
            end
            table.insert(mWealthInfo, {id = pid, grade = mData.base_info.grade, nickName = mData.name, goldcoin = mProfileInfo["goldcoin"] or 0, coin = mData.active_info.coin or 0, gameServerId = sServer, accountUniqueId = mData.account})
        end
    end

    return mWealthInfo
end

function CBusinessObj:GetWealthCompare(sType, mWealth1, mWealth2)
    if sType == "gold" then
        return mWealth1.gold, mWealth2.gold
    elseif sType == "silver" then
        return mWealth1.silver, mWealth2.silver
    else
        return mWealth1.ingot, mWealth2.ingot
    end
end

function CBusinessObj:HandlePlayerDetailInfo(mInfo, sServer, mBody, sFunc)
    local iPid = mInfo["pid"]

    local mRet = {pid=iPid}

    if not mBody["online"] then
        local oBackendObj = global.oBackendObj
        local oServer =  oBackendObj:GetServer(sServer)
        if oServer then
            local res = require "base.res"
            local mDBSkill = res["daobiao"]["skill"]
            local oGameDb = oServer.m_oGameDb:GetDb()
            local m = oGameDb:FindOne("playerinfo", {["pid"] = iPid})
            mongoop.ChangeAfterLoad(m)
            mRet["base"] = m.base
            mRet["warinfo"] = m.warinfo
            mRet["money"] = m.money
            mRet["task"] = m.task
        end
    else
        mRet["base"] = mBody["base"]
        mRet["warinfo"] = mBody["warinfo"]
        mRet["money"] = mBody["money"]
        mRet["task"] = mBody["task"]
    end

    mRet["skill"] = self:HandleSkillInfo(iPid,sServer)
    mRet["equip"] = self:HandleEquipInfo(iPid,sServer)
    mRet["friend"] = self:HandleFrdInfo(iPid,sServer)
    mRet["item"] = self:HandleItemInfo(iPid,sServer)

    sFunc({errcode=0, data=mRet})
end

function CBusinessObj:HandleEquipInfo(iPid,sServer)
    local mInfo = {}
    local oBackendObj = global.oBackendObj
    local oServer =  oBackendObj:GetServer(sServer)

    if oServer then
        local res = require "base.res"
        local mDBItem = res["daobiao"]["item"]
        local mDBEquipPos = res["daobiao"]["equippos"]
        local mAttrName = res["daobiao"]["attrname"]

        local oGameDb = oServer.m_oGameDb:GetDb()

        local m = oGameDb:FindOne("player", {pid = iPid}, {active_info=true,item_info=true})
        m = m or {}
        mongoop.ChangeAfterLoad(m)
        local mActive = m.active_info or {}
        local mStrength = mActive.equip_strength or {}

        local mItem = m.item_info or {}
        local mEquip = mItem.equip or {}
        for sPos,mEquipInfo in pairs(mEquip) do
            local iPos = tonumber(sPos)
            if mDBEquipPos[iPos] then
                -- table.insert(mInfo,{})
                local mData = mEquipInfo.data or {}
                --装备名称
                local sName = mData.name or ""
                --装备唯一id
                local _,iTraceNo = table.unpack(mData.TraceNo or {iPid,0})
                --属性
                local sApply
                local mApply = mEquipInfo.apply or {}
                for sAttr,Value in pairs(mApply) do
                    sApply = sApply and (sApply..",") or ""
                    local sAttrName = mAttrName[sAttr] and mAttrName[sAttr]["name"] or sAttr
                    sApply = sApply .. sAttrName .. ":" ..Value
                end
                --宝石
                local mGem = mEquipInfo.gem or {}
                local sGem
                for _,mGemInfo in pairs(mGem) do
                    sGem = sGem and (sGem..",") or ""
                    local sGemName = mDBItem[mGemInfo.sid] and mDBItem[mGemInfo.sid]["name"]  or mGemInfo.sid
                    sGem = sGem .. sGemName
                end
                sGem = sGem or ""
                --淬灵
                local iFuWenPlan = mData.fuwen_plan or 0
                local mFuWen = mEquipInfo.fuwen_plan or {}
                local mUse = mFuWen[tostring(iFuWenPlan)] or {}
                mUse = mUse.fuwen or {}
                local sCuiLing
                for sAttr,VV in pairs(mUse) do
                    sCuiLing = sCuiLing and (sCuiLing..",") or ""
                    local sAttrName = mAttrName[sAttr] and mAttrName[sAttr]["name"] or sAttr
                    sCuiLing = sCuiLing .. sAttrName .. ":" ..VV.value
                end
                --突破等级
                local iStrength = mStrength[sPos] or 0

                table.insert(mInfo,{
                    traceno = iTraceNo,
                    name = sName,
                    pos = mDBEquipPos[iPos]["name"],
                    apply = sApply,
                    gem = sGem,
                    cuiling = sCuiLing,
                    strength = iStrength,
                })
            end
        end
    end
    return mInfo
end

function CBusinessObj:HandleFrdInfo(iPid,sServer)
    local mInfo = {}
    local oBackendObj = global.oBackendObj
    local oServer =  oBackendObj:GetServer(sServer)

    if oServer then
        local res = require "base.res"
        local mDBBranch = res["daobiao"]["rolebranch"]
        local mDBSchool = res["daobiao"]["school"]
        local oGameDb = oServer.m_oGameDb:GetDb()
        local m = oGameDb:FindOne("offline", {pid = iPid}, {friend_info=true})
        mongoop.ChangeAfterLoad(m)
        local mFrdInfo = m.friend_info or {}
        local mFrdList = mFrdInfo.friends or {}
        local mPid = {}
        for iTarget,_ in pairs(mFrdList) do
            table.insert(mPid,tonumber(iTarget) or 0)
        end
        if #mPid > 0 then
            local mSearch = {pid={["$in"]=mPid}}
            local m2 = oGameDb:Find("player", mSearch, {pid=true,name=true,base_info=true})
            while m2:hasNext() do
                local mUnit = m2:next()
                mongoop.ChangeAfterLoad(mUnit)
                local iTarget = mUnit.pid or 0
                local sName = mUnit.name or "未知"
                local mBase = mUnit.base_info or {}
                local grade = mBase.grade or 0

                local iSchool = mBase.school or 0
                local iSchoolBranch = mBase.school_branch or 0
                local mBranch = mDBBranch[iSchool] or {}
                mBranch = mBranch[iSchoolBranch] or {}
                local sBranchName = mBranch.name or "未知流派"


                local mSchool = mDBSchool[iSchool] or {}
                local sSchoolName = mSchool.name or "未知门派"

                table.insert(mInfo,{pid=iTarget,name=sName,grade=grade,school=sSchoolName,schoolbranch=sBranchName})
            end
        end
    end
    return mInfo
end

function CBusinessObj:HandleItemInfo(iPid,sServer)
    local mInfo = {}
    local oBackendObj = global.oBackendObj
    local oServer =  oBackendObj:GetServer(sServer)

    if oServer then
        local res = require "base.res"
        local mDBItem = res["daobiao"]["item"]
        local oGameDb = oServer.m_oGameDb:GetDb()
        local m = oGameDb:FindOne("player", {pid = iPid}, {item_info=true})
        m = m or {}
        mongoop.ChangeAfterLoad(m)
        local mItem = m.item_info or {}
        mItem = mItem.itemdata or {}
        for sNo,info in pairs(mItem) do
            local iNo = tonumber(sNo)
            if table_in_list({1,2,3,6},iNo) then
                for _,info2 in pairs(info) do
                    local sid = info2.sid or 0
                    local infodata = info2.data or {}
                    local _,traceno = table.unpack(infodata["TraceNo"] or {0,0})
                    local mDBData = mDBItem[sid] or {}
                    table.insert(mInfo,{
                        traceno=traceno,
                        name=mDBData["name"] or "未知物品",
                        amount=info2.amount,
                        sid = sid,
                    })
                end
            end
        end
    end
    return mInfo
end

function CBusinessObj:HandleSkillInfo(iPid,sServer)
    local mInfo = {}
    local oBackendObj = global.oBackendObj
    local oServer =  oBackendObj:GetServer(sServer)

    if oServer then
        local res = require "base.res"
        local mDBSkill = res["daobiao"]["skill"]
        local oGameDb = oServer.m_oGameDb:GetDb()
        local m = oGameDb:FindOne("player", {pid = iPid}, {skill_info=true})
        m = m or {}
        mongoop.ChangeAfterLoad(m)
        local mSkill = m.skill_info or {}
        mSkill = mSkill.skdata or {}
        for sSk,info in pairs(mSkill) do
            local iSk = tonumber(sSk)
            local mUnit = mDBSkill[iSk] or {}
            local sName = mUnit["name"] or mUnit["skill_name"]
            sName = sName or ("技能"..iSk)
            if sName then
                table.insert(mInfo,{skid=iSk,name=sName,lv=info.level or 0})
            end
        end
    end
    return mInfo
end

function CBusinessObj:RequestPlayerDetailInfo(mInfo, sFunc)
    local iPid = mInfo["pid"]
    local sServer = mInfo["serverid"]
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj:GetServer(sServer)
    if not iPid or not oServer then sFunc({errcode=2, data={}}) return end

    local mData = {cmd="SearchPlayerInfo", data={pid=iPid}}
    router.Request(get_server_tag(sServer), ".world", "backend", "gmbackend", mData, function (mRecord, mData)
        self:HandlePlayerDetailInfo(mInfo, sServer, mData, sFunc)
    end)
end

function CBusinessObj:GetPlayerDetailInfo(mArgs, sFunc)
    local iPid = mArgs["playerId"]
    if not iPid then sFunc({errcode=1, data={}}) return end

    local mInfo = self:GetPlayerServerInfo(iPid)
    self:RequestPlayerDetailInfo(mInfo, sFunc)
end

function CBusinessObj:GetPlayerServerInfo(iPid)
    local mInfo = {}
    local oBackendObj = global.oBackendObj
    for idx, oServer in pairs(oBackendObj.m_mServers) do
        if oServer then
            local oGameDb = oServer.m_oGameDb:GetDb()
            if oGameDb then
                local mPlayer = oGameDb:FindOne("player", {pid = iPid}, {pid = true, account = true})
                if mPlayer then
                    mongoop.ChangeAfterLoad(mPlayer)
                    mInfo["pid"] = iPid
                    mInfo["serverid"] = idx
                    break
                end
            end
        end
    end
    return mInfo
end

function CBusinessObj:SearchPartnerDetail(mArgs, sFunc)
    mArgs["pid"] = tonumber(mArgs["pid"])
    mArgs["sid"] = tonumber(mArgs["sid"])
    local iPid = mArgs["pid"]
    if not iPid then sFunc({errcode=1, data={}}) return end

    local mInfo = self:GetPlayerServerInfo(iPid)
    mInfo["sid"] = mArgs["sid"]
    self:RequestPartnerDetailInfo(mInfo, sFunc)
end


function CBusinessObj:RequestPartnerDetailInfo(mInfo, sFunc)
    local iPid = mInfo["pid"]
    local sServer = mInfo["serverid"]
    local sid = mInfo["sid"]
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj:GetServer(sServer)
    if not iPid or not oServer then sFunc({errcode=2, data={}}) return end

    local mData = {cmd="SearchPartnerInfo", data={pid=iPid,sid=sid}}
    router.Request(get_server_tag(sServer), ".world", "backend", "gmbackend", mData, function (mRecord, mData)
        self:HandlePartnerDetailInfo(mInfo, sServer, mData, sFunc)
    end)
end

function CBusinessObj:HandlePartnerDetailInfo(mInfo, sServer, mBody, sFunc)
    local iPid = mInfo["pid"]
    local sid = mInfo["sid"]

    local mRet = {pid=iPid}

    if not mBody["online"] then
        local res = require "base.res"
        local mDaoBiao = res["daobiao"]["partner"]["partner_info"]

        local oBackendObj = global.oBackendObj
        local oServer = oBackendObj:GetServer(sServer)
        local oGameDb = oServer.m_oGameDb:GetDb()
        local m = oGameDb:FindOne("partner", {pid = iPid}, {partner=true})
        m = m or {}
        mongoop.ChangeAfterLoad(m)
        local mFindData = m.partner or {}
        mFindData = mFindData.partner or {}
        local mPartner,mNum = {},{}
        for _,info in pairs(mFindData) do
            local iType = info.partner_type
            mNum[iType] = mNum[iType] or 0
            mNum[iType] = mNum[iType] + 1

            local _,traceno = table.unpack(info.traceno)
            local mDBContent = mDaoBiao[iType] or {}
            local mTmp ={}
            mTmp.dname = mDBContent["name"] or "无"
            mTmp.name = info.name or "无"
            mTmp.grade = info.grade
            mTmp.rare = mDaoBiao["rare"] or "无"
            mTmp.star = info.star or 1
            mTmp.exp = info.exp or 0
            mTmp.star = info.star or 1
            mTmp.awake = info.awake or 0
            local mSkill = {}
            local mTmp2 = info.skill or {}
            for iSk,info in pairs(mTmp2) do
                table.insert(mSkill,{sk=iSk,level=info.level or 0})
            end
            mTmp.skill = mSkill
            mPartner[traceno] = mTmp
        end

        local oBackendDb = oBackendObj.m_oBackendDb
        local m2 = oBackendDb:FindOne("player", {["pid"] = iPid, ["type"] = "partner"}, {["data"] = true})
        m2 = m2 or {}
        mongoop.ChangeAfterLoad(m2)
        local mPartnerList = m2.data or {}
        local mResult = {}
        for _,info in pairs(mPartnerList) do
            local traceno = info.traceno or 0
            local mUnit = mPartner[traceno]
            if mUnit then
                info.dname = mUnit.dname
                info.name = mUnit.name
                info.grade = mUnit.grade
                info.rare = mUnit.rare
                info.star = mUnit.star
                info.exp = mUnit.exp
                info.star = mUnit.star
                info.awake = mUnit.awake
                info.skill = mUnit.skill
                table.insert(mResult,info)
            end
        end
        mRet["content"] = mResult
        local mNumList = {}
        for iType,iNum in pairs(mNum) do
            table.insert(mNumList,{sid=iType,num=iNum})
        end
        mRet["num"] = mNumList
    else
        mRet["content"] = mBody["data"]
        mRet["num"] = mBody["num"]
    end

    sFunc({errcode=0, data=mRet})
end


function CBusinessObj:SearchFuWenDetail(mArgs, sFunc)
    mArgs["pid"] = tonumber(mArgs["pid"])
    mArgs["sid"] = tonumber(mArgs["sid"])
    local iPid = mArgs["pid"]
    if not iPid then sFunc({errcode=1, data={}}) return end

    local res = require "base.res"
    local mDBItem = res["daobiao"]["item"]
    local mDBEquip = res["daobiao"]["partner_item"]["equip_set"]
    local mAttrName = res["daobiao"]["partner_item"]["equip_attr_info"]

    local sid = mArgs["sid"]

    local mInfo = self:GetPlayerServerInfo(iPid)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj:GetServer(mInfo["serverid"])
    if not oServer then sFunc({errcode=2, data={}}) return end
    local oGameDb = oServer.m_oGameDb:GetDb()
    local m = oGameDb:FindOne("player", {pid = iPid},{item_info=true})
    m = m or {}
    mongoop.ChangeAfterLoad(m)
    local mItem = m.item_info or {}
    mItem = mItem.itemdata or {}
    mItem = mItem["5"] or {}
    local mRet = {}
    for iNo,info in pairs(mItem) do
        local data = info.data or {}
        local _,traceno = table.unpack(data.TraceNo)
        if (not sid or sid == traceno) and tonumber(iNo) then
            local mDBData = mDBItem[info.sid] or {}
            local iType = mDBData.equip_type or 0
            local mDBEquipData = mDBEquip[iType] or {}
            local mMainApply = {}
            for sAttr,value in pairs(info.main_apply or {}) do
                table.insert(mMainApply,{name=mAttrName[sAttr]["name"],value=value})
            end
            for sAttr,value in pairs(info.main_apply2 or {}) do
                table.insert(mMainApply,{name=mAttrName[sAttr]["name"],value=value})
            end
            local mSubApply = {}
            for sAttr,value in pairs(info.sub_apply or {}) do
                table.insert(mSubApply,{name=mAttrName[sAttr]["name"],value=value})
            end

            table.insert(mRet,{
                traceno = traceno,
                sid = info.sid,
                name = mDBEquipData.name,
                star = mDBData.equip_star,
                level = data.equip_level,
                pos = mDBData.pos,
                main_apply=mMainApply,
                sub_apply=mSubApply,
            })
        end
    end

    sFunc({errcode=0, data=mRet})
end