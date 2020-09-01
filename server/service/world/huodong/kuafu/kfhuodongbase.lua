--import module
local global  = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

local huodongbase = import(service_path("huodong.huodongbase"))

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "kfhuodong"
CHuodong.m_sTempName = "神秘跨服活动"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    return o
end

function CHuodong:NeedSave()
    return false
end

function CHuodong:GetKFService()
    return self.m_KFService or ".world1"
end