module(..., package.seeall)
function main()
	local d1 = require("map.map")
	local d2 = require("map.scenefly")	
	local d3 = require("map.scenegroup")
	
	local s = table.dump(d1, "DATA") .. "\n"..table.dump(d2, "MAP_SCENEFLY").."\n"..table.dump(d3, "SCENE_GROUP")
	SaveToFile("map", s)
end


