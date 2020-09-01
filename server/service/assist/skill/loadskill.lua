

local mSkillDir = {
    ["school"] = {3001,3999},
    ["cultivate"] = {4000,4099},
    ["se"] = {0,3000},
    ["equip"] = {6001,7000}
}

local mSchoolSkill = {
    [1] = {3001,3002,3004,3005,3006,3007},
    [2] = {3101,3102,3103,3105,3106,3107},
    [3] = {3201,3202,3204,3205,3206,3207},
    [4] = {3301,3302,3303,3305,3306,3307},
    [5] = {3401,3402,3403,3405,3406,3407},
    [6] = {3501,3502,3503,3505,3506,3507},
}

local mCultivateSkill = {4000, 4001,4002,4003,4004,4005,4006,4007,4008}

function GetDir(iSk)
    for sDir,mPos in pairs(mSkillDir) do
        local iStart,iEnd = table.unpack(mPos)
        if iStart <= iSk and iSk <= iEnd then
            return sDir
        end
    end
end

function NewSkill(iSk)
    local sDir = GetDir(iSk)
    assert(sDir,string.format("NewSkill err:%s",iSk))
    local sPath = string.format("skill/%s/%sbase",sDir,sDir)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("NewSkill err:%d",iSk))
    local oSk = oModule.NewSkill(iSk)
    return oSk
end

function GetSkill(iSk)
    local oSk = mSkillList[iSk]
    if oSk then
        return oSk
    end
    local oSk = NewSkill(iSk)
    mSkillList[iSk] = oSk
    return oSk
end

function LoadSkill(iSk,mData)
    local oSk = NewSkill(iSk)
    oSk:Load(mData)
    return oSk
end

function GetSkillData()
    local res = require "base.res"
    local mData = res["daobiao"]["skill"]
    return mData
end

function GetSchoolSkill(iSchool,iSchoolBranch)
    local iType = (iSchool - 1) * 2 + iSchoolBranch
    return mSchoolSkill[iType]
end

function GetCultivateSkill()
    return mCultivateSkill
end