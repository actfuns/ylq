local login = {}

login.GS2CHello = function (self, args)
    self:run_cmd("C2GSQueryLogin",{res_file_version={{file_name="achievedata",version=1508884413},{file_name="arenadata",version=1508884413},}})
end

login.GS2CQueryLogin = function (self,args)
    self:run_cmd("C2GSLoginAccount", {account = self.account,device="huawei",platform=2,mac="asdfasdfdf",client_version="1.0.2",client_svn_version=999999,os="ios10",udid="fasdfasdfasdf111111"})
end

login.GS2CLoginAccount = function(self, args)
    local lRole = args.role_list
    if not lRole or not next(lRole) then
        local sName = string.format("DEBUG%s", args.account)
        self:run_cmd("C2GSCreateRole", {account = args.account, role_type = math.random(1,6), name = sName})
    else
        local m = lRole[1]
        self:run_cmd("C2GSLoginRole", {account = args.account, pid = m.pid})
    end
end

login.GS2CCreateRole = function(self, args)
    local m = args.role
    self:run_cmd("C2GSLoginRole", {account = args.account, pid=m.pid})
end

login.GS2CLoginRole = function(self, args)
    self.m_mRoleInfo = args.role or {}
    self.m_iPid = args.pid
    self.m_sAccount = args.account
    self.m_iChannel = 0
    self:run_cmd("C2GSGMCmd", {cmd="choosemap"})
end

return login
