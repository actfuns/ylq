module(..., package.seeall)
function main()
	local tOpenui 	= require("openui.openui")
	local s = table.dump(tOpenui, "DATA")
	SaveToFile("openui", s)
end