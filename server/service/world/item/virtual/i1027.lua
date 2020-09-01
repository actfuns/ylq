local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

local virtualbase = import(service_path("item/virtual/virtualbase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,virtualbase.CItem)

function CItem:Reward(oPlayer, sReason, mArgs)
   local iWay = self:GetData("gain_way")
   if not iWay then
        return
   end

   local iShape = self:FilterShape(oPlayer)
   if iShape then
        oPlayer:AddShape(iShape, sReason,mArgs)
        global.oUIMgr:AddKeepItem(oPlayer:GetPid(), self:GetShowInfo())
    else
        record.warning("roleskin err, pid:%s, reason:%s", oPlayer:GetPid(), sReason)
    end
end

function CItem:FilterShape(oPlayer)
    local iSex = oPlayer:GetSex()
    local iSchool = oPlayer:GetSchool()
   local iWay = self:GetData("gain_way")
   local res = require "base.res"
   local mShape = res["daobiao"]["roleskin"]
   for iShape, m in pairs(mShape) do
        if m.gain_way == iWay and m.school == iSchool and m.sex == iSex then
            return iShape
        end
   end
end

function CItem:GetShowInfo()
    return {
        id = self:ID(),
        sid = self:GetData("gain_way"),
        virtual = self:SID(),
        amount = self:GetData("value", 1),
    }
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end