--import module

local global = require "global"
local skynet = require "skynet"
local playersend = require "base.playersend"
local interactive = require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"
local router = require "base.router"

local bigpacket = import(lualib_path("public.bigpacket"))
local tinsert = table.insert

function NewReportProxy(...)
    local o = CReportProxy:New(...)
    return o
end

local tCheckAttr = {"account","pid","target","t_account","reason","other","ptime"}

CReportProxy = {}
CReportProxy.__index = CReportProxy
inherit(CReportProxy, logic_base_cls())

function CReportProxy:New()
    local o = super(CReportProxy).New(self)
    o.m_mCaCheList = {}
    return o
end

function CReportProxy:Init()
    local f1
    f1 = function ()
        self:DelTimeCb("DoPromote")
        self:AddTimeCb("DoPromote", 5 * 60 * 1000, f1)
        self:DoPromote()
    end
    f1()
end

function CReportProxy:DoAddNew(mData)
    for _,sAttr in pairs(tCheckAttr) do
        if not mData[sAttr] then
            record.warning("report no attr "..sAttr)
            record.warning(ConvertTblToStr(mData))
            return
        end
    end
    mData.serverkey = MY_SERVER_KEY
    table.insert(self.m_mCaCheList,mData)
end

function CReportProxy:DoPromote()
    local mCaChe = self.m_mCaCheList
    local sCaChe = extend.Table.serialize(mCaChe)
    self.m_mCaCheList = {}
    router.Send("bs", ".backend", "common", "AddReportList", sCaChe)
end