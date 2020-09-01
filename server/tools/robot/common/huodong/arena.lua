local CMD = {}

CMD.GS2CLoginRole = function(self, args)
    self:run_cmd("C2GSGMCmd", {cmd="supermode"})
    self:run_cmd("C2GSGMCmd", {cmd="huodong arenagame 110"})
    self:run_cmd("C2GSArenaMatch", {})
end


CMD.GS2CArenaFightResult = function(self,args)
    self:run_cmd("C2GSArenaMatch", {})
end

CMD.GS2CWarBoutStart = function (self,args)
    self:sleep(3)
    local iWarId = args.war_id
    self:run_cmd("C2GSWarAutoFight",{
        type = 2,
        war_id = iWarId,
    })
end

return CMD
