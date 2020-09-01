module(..., package.seeall)
function main()
	local d2 = require("huodong.worldboss.reward")
	local d3 = require("huodong.worldboss.buff")
	local d4 = require("huodong.worldboss.statusdesc")
	local d5 = require("huodong.worldboss.airpos")
	local s2 = table.dump(d2, "REWARD")
	local s3 = table.dump(d3, "BUFF")
	local s4 = table.dump(d4, "STATUSDESC")
	local temp = {}
	for i,v in ipairs(d5) do
		if v.shape then
			temp[v.shape] = {}
			temp[v.shape].pos = {
				x = v.posx,
				y = v.posy,
				z = 0,
			}
		end
	end
	local s5 = table.dump(temp, "AIRPOS")
	SaveToFile("worldboss", s2.."\n"..s3.."\n"..s4.."\n"..s5)
end
