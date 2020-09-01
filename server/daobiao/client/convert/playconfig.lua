module(..., package.seeall)
function main()
	local newTable = nil
	local oriTable = nil
	local configList = {"worldboss", "clubarena"}
	for _,name in ipairs(configList) do
		oriTable = require("playconfig." .. name)
	
		newTable = (newTable or "") .. "\n" .. table.dump(oriTable, string.upper(name))
	end
	SaveToFile("playconfig", newTable)
end