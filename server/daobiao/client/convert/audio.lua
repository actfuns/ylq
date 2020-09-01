module(..., package.seeall)
function main()
	local d1 = require("audio")
	local d2 = require("war")
	local dWar = {}
	for k,v in pairs(d2) do
		dWar[k] = {
			wartype = v.wartype,
			filename = v.filename,
		}
	end
	local d3 = require("normal")


	local s = table.dump(d1, "DATA").."\n"..table.dump(dWar, "WAR").."\n"..table.dump(d3, "NORMAL")
	SaveToFile("audio", s)
end
