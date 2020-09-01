module(..., package.seeall)

function main()
	local d1 = require("huodong.terrawars.terraconfig")
	local d2 = require("huodong.terrawars.npc")
	local d3 = require("huodong.terrawars.serverreward")
	local d4 = require("huodong.terrawars.orgreward")
	local d5 = require("huodong.terrawars.rule")
	local s1 = table.dump(d1, "TERRACONFIG")
	local s2 = table.dump(d2, "NPC")
	local s3 = table.dump(d3, "SERVERREWARD")
	local s4 = table.dump(d4, "ORGREWARD")
	local s5 = "RULE=".."\""..d5[1].rule.."\""

	local s = s1.."\n"..s2..s3.."\n"..s4.."\n"..s5
	SaveToFile("terrawar", s)

end