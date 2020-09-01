--import module
local global = require "global"
local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local record = require "public.record"

local httpcmd = import(service_path("httpcmd"))

function NewHttpWrapper(...)
    local o = CHttpWrapper:New(...)
    return o
end

CHttpWrapper = {}
CHttpWrapper.__index = CHttpWrapper

function CHttpWrapper:New(id)
    local o = setmetatable({}, self)
    o.m_iSocketId = id
    o.m_iResolveCode = nil
    return o
end

function CHttpWrapper:Init()
end

function CHttpWrapper:Release()
    baseobj_safe_release(self)
end

function CHttpWrapper:RecvRequest()
     socket.start(self.m_iSocketId)
     local debug = {}
     -- limit request body size to 10240 (you can pass nil to unlimit)
     local iCode, sUrl, sMethod, mHeader, sBody = httpd.read_request(sockethelper.readfunc(self.m_iSocketId), 10240,debug)
     if not iCode then
        if sUrl == sockethelper.socket_error then
            if next(debug) then
                record.error("socket closed", debug[1])
            else
                record.error("socket closed")
            end
        else
            record.error(sUrl)
        end
        self:Finish()
     else
        self.m_iResolveCode = iCode
        if iCode ~= 200 then
            self:Response()
            self:Finish()
        else
            local sPath, sQuery = urllib.parse(sUrl)
            local lPath = split_string(trim(sPath, "/"), "/")
            if #lPath >= 1 then
                local sFunc = lPath[1]
                if not httpcmd[sFunc] then
                    record.error(string.format("httpwarpper error func %s", sFunc))
                    self:Finish()
                elseif httpcmd.Method[sFunc] and not httpcmd.Method[sFunc][sMethod] then
                    record.info(string.format("httpwarpper error method %s %s", sFunc, sMethod))
                    self:Finish()
                else
                    local lAddress = {}
                    for i = 2, #lPath do
                        table.insert(lAddress, lPath[i])
                    end

                    self.m_sMethod = sMethod
                    self.m_lAddress = lAddress
                    self.m_sRouteFunc = sFunc
                    self.m_sBody = sBody
                    self.m_sQuery = sQuery
                    self.m_sRemoteIp = mHeader["x-real-ip"]

                    local br, rr = safe_call(httpcmd[sFunc], self)
                    if not br then
                        self:Finish()
                    end
                end
            else
                self:Finish()
            end
        end
     end
end

function CHttpWrapper:GetMethod()
    return self.m_sMethod
end

function CHttpWrapper:GetAddress()
    return self.m_lAddress
end

function CHttpWrapper:GetBody()
    return self.m_sBody or ""
end

function CHttpWrapper:GetQuery()
    return self.m_sQuery or ""
end

function CHttpWrapper:Response(...)
    local ok, err = httpd.write_response(sockethelper.writefunc(self.m_iSocketId), self.m_iResolveCode, ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        record.error(string.format("webhandler Response fd=%d, %s", self.m_iSocketId, err))
    end
end

function CHttpWrapper:Finish()
    socket.close(self.m_iSocketId)
end
