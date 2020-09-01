module(..., package.seeall)
function main()
	local d1 = require("guide.powerguide")
	local d2 = require("guide.typemenu")
	local d3 = require("guide.maintypemenu")
	local d4 = require("guide.subtypemenu")
	local d5 = require("guide.fightguide")
	local d6 = require("guide.tabmenu")
	local d7 = require("guide.expectation_power")
	local d8 = require("skill.partner")
	local t8 = {}
	for k, v in pairs(d8) do
		if not t8[v.skill_id] then
			t8[v.skill_id] = v.skill_level
		else
			if t8[v.skill_id] < v.skill_level then
				t8[v.skill_id] = v.skill_level
			end
		end
	end

	local s = table.dump(d1, "DATA") .. "\n" .. table.dump(d2, "MENU") .. "\n" .. table.dump(d3, "MAIN") .. "\n" .. table.dump(d4, "SUB").."\n" .. table.dump(d5, "FIGHT_GUIDE")
	.."\n" .. table.dump(d6, "TAB_MENU").."\n" .. table.dump(d7, "EXPECTATION").."\n" .. table.dump(t8, "PARTNER_SKILL_MAX_LEVEL")
	SaveToFile("powerguide", s)
	
	
	
	local dd1 = require("guide.guide_config")
	local ss1 = table.dump(dd1, "DATA")
	SaveToFile("powerguide", ss1)
end