module(..., package.seeall)
function main()

	local tPublic 	= require("schedule.public")
	local tSchedule = require("schedule.schedule")
	local tReward 	= require("schedule.activereward")
	local tTag 		= require("schedule.scheduleTag")
	local tWeek 	= require("schedule.week")
	local tRegionshow = require("schedule.regionshow")
	local data
	for k,v in pairs(tPublic) do
		data = tSchedule[k]
		if data then
			data.maxtimes = v.maxfinish
			data.active = v.active
			data.maxactive = v.maxactive
			data.gotoway  = v.gotoway
			data.open_view = v.open_view
			data.grade = v.grade
			data.addlimit = v.addlimit
		end
	end
	for k,v in pairs(tSchedule) do
		if #v.times <= 0 then
			v.times = nil
		end
	end
	for k,v in pairs(tReward) do
		if v.reward then
			v.reward = nil
		end
	end
	local s = table.dump(tTag, "SCHEDULETAG").."\n"..
			table.dump(tSchedule, "SCHEDULE").."\n"..
			table.dump(tReward, "ACTIVEREWARD").."\n"..
			table.dump(tWeek, "WEEK").."\n"..
			table.dump(tRegionshow, "REGIONSHOW")
	SaveToFile("schedule", s)
end