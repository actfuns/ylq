local global = require "global"
local extend = require "base.extend"
local playersend = require "base.playersend"
local router = require "base.router"
local record = require "public.record"
local res = require "base.res"

local gamedefines = import(lualib_path("public.gamedefines"))
local kfobj = import(service_path("kuafu.kfobj"))


function NewKuaFuMgr()
    return CKuaFuMgr:New()
end

CKuaFuMgr = {}
CKuaFuMgr.__index = CKuaFuMgr
inherit(CKuaFuMgr, logic_base_cls())

function CKuaFuMgr:New()
    local o = super(CKuaFuMgr).New(self)
    o.m_ObjectList = {}
    return o
end

function CKuaFuMgr:GetPlayManager(sPlay)
    return global.oHuodongMgr:GetHuodong(sPlay)
end

function CKuaFuMgr:GetObject(pid)
    return self.m_ObjectList[pid]
end

function CKuaFuMgr:RemoveObject(pid)
    local obj = self:GetObject(pid)
    if obj then
        self.m_ObjectList[pid] = nil
        baseobj_safe_release(obj)
    end
end

function CKuaFuMgr:Send2GSHuoDong(server,sFunc,sName,mData,fRespond)
    local mArgs = {func =sFunc, name = sName,data=mData}
    local mPack = {
        func = "KS2GSHuoDong",
        args = mArgs
    }
    if fRespond then
        router.Request(get_server_tag(server), ".world", "kuafu", "KS2GSForward", mPack,fRespond)
    else
        router.Send(get_server_tag(server), ".world", "kuafu", "KS2GSForward", mPack)
    end
end

function CKuaFuMgr:Send2GSProxyEvent(server,iPid,sCmd,mData)
    local mArgs = { pid=iPid , cmd = sCmd, data = mData}
    local mPack = {
        func = "KS2GSProxyEvent",
        args = mArgs
        }
    router.Send(get_server_tag(server), ".world", "kuafu", "KS2GSForward", mPack)
end


function CKuaFuMgr:Send2GSWorld(iPid,sFunName,mArgs)
    local obj = self:GetObject(iPid)
    assert(obj, "ks has not player serverkey "..iPid)
    router.Send(get_server_tag(obj.m_Where), ".world", "kuafu", "KS2GSForward", {func=sFunName,args=mArgs})
end


function CKuaFuMgr:JoinGame(mRecord,mData)
    local sPlay = mData["play"]
    local mBase = mData["basedata"]
    local mExtra = mData["extra"]
    local pid = mBase["pid"]
    local oPlay = self:GetPlayManager(sPlay)
    if not oPlay then
        return {code=1,reason=string.format("null play %s",sPlay),data={play=sPlay}}
    end
    if self:GetObject(pid) then
        return {code=1,reason=string.format("exit kfobj %s %d",sPlay,pid),data={play=sPlay}}
    end
    local obj = kfobj.NewKuafuObject(pid,sPlay,mData)
    obj.m_Where = mData["serverkey"]
    self.m_ObjectList[pid] = obj
    local mRe = oPlay:KFJoinGame(obj)
    return {code=0,data=mRe,play = sPlay}
end

function  CKuaFuMgr:DeleteGameObject(mArgs)
    local pid = mArgs["pid"]
    local sPlay = mArgs["play"]
    local obj = self:GetObject(pid)
    if obj then
        if obj.m_sPlay ~= sPlay then
            record.error(string.format(" remove kfobj %d %s %s",pid,error,sPlay))
        end
        self:KuafuCmd({cmd="Delete"})
        self:RemoveObject(pid)
    end
end

function CKuaFuMgr:KuafuCmd(mData)
    local iPid = mData["pid"]
    local obj = self:GetObject(iPid)
    if not obj then
        return
    end
    local oPlayMgr = obj:GetPlayMgr()
    if not oPlayMgr then
    end
    local mRet = oPlayMgr:KFCmd(obj,mData)
    if mRet then
        mRet["play"] = obj.m_sPlay
    end
    return mRet
end

function CKuaFuMgr:OnLogin(mData)
    local iPid = mData["pid"]
    local mArg = mData["arg"]
    local obj = self:GetObject(iPid)
    if not obj then
        return
    end
    local oPlayMgr = obj:GetPlayMgr()
    if oPlayMgr and oPlayMgr.OnLogin then
        oPlayMgr:OnLogin(obj,mArg["reenter"])
    end
end

function CKuaFuMgr:OnDisconnected(mData)
    local iPid = mData["pid"]
    local obj = self:GetObject(iPid)
    if not obj then
        return
    end
    local oPlayMgr = obj:GetPlayMgr()
    if oPlayMgr and oPlayMgr.OnDisconnected then
        oPlayMgr:OnDisconnected(obj)
    end
end


function CKuaFuMgr:RandomName(iSex)
    local mData  = res["daobiao"]["randomname"]
    iSex = iSex or 1
    local f = function ()
        local mName,idx = extend.Random.random_choice(mData)
        local sFirst = mName["firstName"]
        local sMale
        if iSex == 1 then
            sMale = mName["maleName"]
        else
            sMale = mName["femaleName"]
        end
        local sMid = ""
        if #mName["midName"] > 0 and math.random(2) > 1 then
            sMid = extend.Random.random_choice(mName["midName"])
        end
        return sFirst..sMid..sMale
    end
    local sName = "MisakaMikoto"
    for i=1,1000 do
        local sNew = f()

        if string.len(sNew) > 0 and string.len(sNew) < 18 then
            sName = sNew
            break
        end
    end
    return sName
end




