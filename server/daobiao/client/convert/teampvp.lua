module(..., package.seeall)
function main()
	local d1 = require("huodong.teampvp.reward_top")

	local s = table.dump(d1, "Reward")
	SaveToFile("teampvp", s)
end
