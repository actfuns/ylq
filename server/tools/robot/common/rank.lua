local rank = {}

rank.GS2CLoginRole = function(self, args)
    local iExp = math.random(1000, 100000)
    local sCmd = 'rewardexp ' .. tostring(iExp)
    self:run_cmd("C2GSGMCmd", {cmd=sCmd})
end

return rank