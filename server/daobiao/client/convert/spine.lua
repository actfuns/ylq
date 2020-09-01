module(..., package.seeall)
function main()
	local d1 = require("spine.config")
	local dConfig = {}
	for i, v in pairs(d1) do
		dConfig[v.id] = v
	end
	
	local s = table.dump(dConfig, "CONFIG")
	SaveAllDataToFile("spine", s)
end
