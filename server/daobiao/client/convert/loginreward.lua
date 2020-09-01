module(..., package.seeall)
function main()
	local d1 = require("huodong.loginreward.reward")
	local s = table.dump(d1, "Reward")
	SaveToFile("loginreward", s)
end
