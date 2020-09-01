local login = {}

login.GS2CHello = function (self, args)
    self:run_cmd("C2GSLoginAccount", {account = self.account})
end

login.GS2CLoginAccount = function(self, args)
    local lRole = args.role_list
    if not lRole or not next(lRole) then
        local sName = string.format("%s-%s", self.clientType,args.account)
        self:run_cmd("C2GSCreateRole", {account = args.account, role_type = math.random(1,2), name = sName})
    else
        local m = lRole[1]
        self:run_cmd("C2GSLoginRole", {account = args.account, pid = m.pid})
    end
end

login.GS2CCreateRole = function(self, args)
    local m = args.role
    self:run_cmd("C2GSLoginRole", {account = args.account, pid=m.pid})
    self:run_cmd("C2GSGMCmd",{cmd = "rewardexp 1000000"})
    self:run_cmd("C2GSGMCmd",{cmd = " addpartner 301 1"})
end

login.GS2CAddPartner = function(self,args)
    local iParId = args.partner_info.parid
    self:run_cmd("C2GSGMCmd",{cmd = string.format("addpartnerexp %d 1000000",iParId)})
    self:run_cmd("C2GSGMCmd",{cmd = string.format("awakepartner %d",iParId)})
end

return login