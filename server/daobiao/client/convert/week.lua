module(..., package.seeall)
function main()
	local d1 = require("schedule.week")
 
 	local dNew = {}
	for k,v in pairs(d1) do
		dNew[k] = v
	end

	local s =table.dump(d1, "WEEK")
	SaveToFile("week", s)
end
