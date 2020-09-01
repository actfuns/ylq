module(..., package.seeall)

function main()
	local d1 = require("huodong.travel.travel_type")
	local d2 = require("huodong.travel.travel_path_config")
	local d3 = require("huodong.travel.travel_path")
	local d4 = require("huodong.travel.travel_say")
	local d5 = require("huodong.travel.travel_npcsay")
	local d6 = require("huodong.travel.model")
	local dConfig = {}
	for i, v in pairs(d6) do
		dConfig[v.id] = v
	end

	local s1 = table.dump(d1, "TRAVEL_TYPE")
	for k,v in pairs(d2) do
		if v.anim == "" then
			v.anim = "idleCity"
		end
	end
	local s2 = table.dump(d2, "TRAVEL_PATH_CONFIG")
	local s3 = table.dump(d3, "TRAVEL_PATH")
	local s4 = table.dump(d4, "TRAVEL_SAY")
	local s5 = table.dump(d5, "TRAVEL_NPCSAY")
	local s6 = table.dump(dConfig, "MODEL_CONFIG")

	local s = s1.."\n"..s2.."\n"..s3.."\n"..s4.."\n"..s5.."\n"..s6
	SaveToFile("travel", s)

end