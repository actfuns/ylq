local global = require "global"
local interactive = require "base.interactive"

function BKSearchPartner(mRecord,mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = mData["pid"] or 0
    local sid = mData["sid"]

    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local mResult = {online=false}
    if oPlayer then
        mResult["online"] = true
        local mInfo,mNum,mNum2 = {},{},{}
        local mList = oPlayer.m_oPartnerCtrl:GetList()
        for _, oPartner in pairs(mList) do
            local iType = oPartner:PartnerType()
            table.insert(mInfo,{
                traceno=oPartner:ID(),
                dname = oPartner:GetDefaultName(),
                name=oPartner:GetName(),
                power=oPartner:GetPower(),
                grade=oPartner:GetGrade(),
                rare=oPartner:Rare(),
                star=oPartner:GetStar(),
                exp=oPartner:GetExp(),
                awake=oPartner:GetAwake(),
                maxhp=oPartner:GetAttr("maxhp",0),
                attack = oPartner:GetAttr("attack",0),
                defense = oPartner:GetAttr("defense",0),
                speed = oPartner:GetAttr("speed",0),
                critical_ratio = oPartner:GetAttr("critical_ratio",0),
                critical_damage = oPartner:GetAttr("critical_damage",0),
                res_critical_ratio = oPartner:GetAttr("res_critical_ratio",0),
                cure_critical_ratio = oPartner:GetAttr("cure_critical_ratio",0),
                abnormal_attr_ratio = oPartner:GetAttr("abnormal_attr_ratio"),
                res_abnormal_ratio = oPartner:GetAttr("res_abnormal_ratio"),
                skill = oPartner.m_oSkillCtrl:PackNetInfo(),
                fuwen = oPartner:GetEquipTraceNoList(),
                })
            mNum[iType] = mNum[iType] or 0
            mNum[iType] = mNum[iType] + 1
        end
        for iType,iNum in pairs(mNum) do
            table.insert(mNum2,{sid=iType,num=iNum})
        end
        mResult["data"] = mInfo
        mResult["num"] = mNum2
    end
    interactive.Response(mRecord.source, mRecord.session, {
        data = mResult
    })
end