module(..., package.seeall)
function main()
	local dOri = require("map.scene")
	local dNew = {}
	for k, v in pairs(dOri) do
		dNew[k] = {
			id = v.id,
			scene_name = v.scene_name,
			map_id = v.map_id,
			anlei = v.anlei,
			width = v.width,
			height = v.height,
		}
		if v.transfers then
			dNew[k].transfers = {}
			for i,t in ipairs(v.transfers) do
				table.insert(dNew[k].transfers, t)
			end
		end
	end	
	local s = table.dump(dNew, "DATA")
	SaveToFile("scene", s)
end
