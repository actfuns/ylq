local res = require "data"

local war = {}

war.GS2CLoginPartner = function (self,args)
    local mUsePartner = {301,302,308,401,402,404,410,412,503,507,508}
    self:sleep(2)
    for i=1,4 do
        local iPartner = mUsePartner[math.random(#mUsePartner)]
        local sCmd = string.format("addpartner %s",iPartner)
        self:run_cmd("C2GSGMCmd",{
            cmd = sCmd,
        })
    end
    self:sleep(5)
    self:run_cmd("C2GSGMCmd",{
        cmd = "choosemap",
    })
    self.m_iStepCount = 1
    self:run_cmd("C2GSGMCmd",{
        cmd = "taskwar 10002"
    })
end

war.GS2CWarBoutStart = function (self,args)
    local iWarId = args.war_id
    local iBout = args.bout_id
    self:run_cmd("C2GSWarAutoFight",{
        type = 2,
        war_id = iWarId,
    })
    self.m_bInWar = true
end

war.GS2CWarResult = function (self,args)
    self:sleep(3+math.random(7))
    if self.m_iStepCount % 5 == 0 then
        self:run_cmd("C2GSGMCmd",{
            cmd = "choosemap",
        })
    end
    self.m_iStepCount = self.m_iStepCount + 1
    self:run_cmd("C2GSGMCmd",{
        cmd = "taskwar 10003"
    })
end

return war