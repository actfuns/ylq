local memory = {}

memory.GS2CLoginPartner = function(self, args)
    self:sleep(5)
    local iClientIdx = self.client_idx
    if iClientIdx then
        local iTime = math.floor(iClientIdx / 2)
        if iTime > 0 then
            self:sleep(iTime)
        end
    end
    self:run_cmd("C2GSGMCmd", {cmd="fullpartner"})
end

memory.GS2CLoginItem = function(self, args)
    --self:sleep(10+math.random(20))
    --self:run_cmd("C2GSGMCmd", {cmd="fullitem"})
end

return memory