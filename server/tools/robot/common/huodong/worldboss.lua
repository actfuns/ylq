local boss = {}

boss.GS2CLoginRole = function(self, args)
    local sCmd = "huodong worldboss 111 1000"
    self:run_cmd("C2GSGMCmd", {cmd=sCmd})
end

return boss
