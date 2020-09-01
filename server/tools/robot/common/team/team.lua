local team = {}

team.GS2CConfirmUI = function(self,mArgs)
	local iSessionIdx = mArgs.sessionidx
	self:run_cmd("C2GSCallback", {sessionidx =iSessionIdx,answer =1})
end

team.GS2CWarConfig = function(self,mArgs)
	local iWarId = mArgs.war_id
	self:run_cmd("C2GSWarAutoFight",{type = 1,war_id = iWarId})
end

team.GS2CWarBoutStart = function(self,mArgs)
	local iWarId = mArgs.war_id
	self:run_cmd("C2GSWarAutoFight",{type = 1,war_id = iWarId})
end

return team