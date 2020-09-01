local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))

function NewAchieveFix()
    return CAchieveFix:New()
end

-- 历史修复切勿删除，调整顺序
local mVersion2Func={
    "CheckGrade",
    "CheckSevDayGem",
    "CheckSevDayPEquip",
    "FixCountParEquipWield",
}

CAchieveFix = {}
CAchieveFix.__index = CAchieveFix
inherit(CAchieveFix, logic_base_cls())

function CAchieveFix:New()
    local o = super(CAchieveFix).New(self)
    return o
end

function CAchieveFix:OnLogin(oPlayer, bReEnter)
    local iVersion = oPlayer.m_oActiveCtrl:GetData("achieve_fix",0)
    local iMaxVersion = iVersion
    for iCheck,sFunName in ipairs(mVersion2Func) do
        if iVersion < iCheck then
            local func = self[sFunName]
            safe_call(func, self, oPlayer)
            iMaxVersion = math.max(iMaxVersion,iCheck)
        end
    end
    oPlayer.m_oActiveCtrl:SetData("achieve_fix",iMaxVersion)
end

function CAchieveFix:CheckGrade(oPlayer)
    global.oAchieveMgr:PushAchieve(oPlayer:GetPid(),"主角等级",{value=oPlayer:GetGrade()})
end

--七日目标宝石总等级
function CAchieveFix:CheckSevDayGem(oPlayer)
    local oAssistMgr = global.oAssistMgr
    local oAchieveMgr = global.oAchieveMgr
    local iPid = oPlayer:GetPid()
    local iRemoteAddr = oAssistMgr:SelectRemoteAssist(iPid)
    interactive.Request(iRemoteAddr,"item","GetTotalGemLevel",{pid = iPid,},function(mRecord,mData)
        oAchieveMgr.m_AchieveFix:_CheckSevDayGem(mData)
    end)
end

function CAchieveFix:_CheckSevDayGem(mData)
    mData = mData or {}
    mData.cmd = "FixGemLevel"
    interactive.Send(".achieve", "common", "FixSevDay", mData)
end

--修复七日目标五星符文套装条件
function CAchieveFix:CheckSevDayPEquip(oPlayer)
    local oAssistMgr = global.oAssistMgr
    local oAchieveMgr = global.oAchieveMgr
    local iPid = oPlayer:GetPid()
    local iRemoteAddr = oAssistMgr:SelectRemoteAssist(iPid)
    interactive.Send(iRemoteAddr,"partner","FixSevDayParEquip",{pid = iPid,})
end

function CAchieveFix:FixCountParEquipWield(oPlayer)
    local oAssistMgr = global.oAssistMgr
    local oAchieveMgr = global.oAchieveMgr
    local iPid = oPlayer:GetPid()
    local iRemoteAddr = oAssistMgr:SelectRemoteAssist(iPid)
    interactive.Send(iRemoteAddr,"partner","FixCountParEquipWield",{pid = iPid,})
end