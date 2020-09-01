local login = {}
local oTaskMgr = require("common/task/taskmgr")

local function InitData(oPlayer)
    oPlayer.m_oTaskMgr = oTaskMgr:New(oPlayer)
    oPlayer.m_oTaskMgr:Init()
end

login.GS2CHello = function (self, args)
    self:run_cmd("C2GSLoginAccount", {account = self.account})
end

login.GS2CLoginAccount = function(self, args)
    local lRole = args.role_list
    InitData(self)
    if not lRole or not next(lRole) then
        local sName = string.format("DEBUG%s", args.account)
        self:run_cmd("C2GSCreateRole", {account = args.account, role_type = math.random(1,2), name = sName})
    else
        local m = lRole[1]
        self:run_cmd("C2GSLoginRole", {account = args.account, pid = m.pid})
    end
end

login.GS2CCreateRole = function(self, args)
    local m = args.role
    self:run_cmd("C2GSLoginRole", {account = args.account, pid=m.pid})
end

return login
