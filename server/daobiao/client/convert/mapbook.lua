module(..., package.seeall)
function main()
	local d1 = require("handbook.chapter")
	local d2 = require("handbook.condition")
	local d3 = require("handbook.partner")
	local d4 = require("handbook.partner_equip")
	local d5 = require("achieve.picture")
	local d6 = require("handbook.person")
	local d7 = require("handbook.npcchat")
	local list = {
		table.dump(d1, "CHAPTER"),
		table.dump(d2, "CONDITION"),
		table.dump(d3, "PARTNER"),
		table.dump(d4, "PARTNEREQUIP"),
		table.dump(d5, "WORLDMAP"),
		table.dump(d6, "PERSON"),
		table.dump(d7, "NPCCHAT"),
	}
	local s = table.concat(list, "\n")
	SaveToFile("mapbook", s)
end
