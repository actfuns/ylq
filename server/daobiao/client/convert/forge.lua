module(..., package.seeall)
function main()
	local t1 = require("item.compound")
	local d1 = {}
	local t4 = {}
	for k, v in pairs(t1) do
		v.equip_level = v.grade
		d1[v.sid] = v
		t4[v.equip_level] = true
	end
	local d2 = require("item.decompose")
	local d3 = require("item.compose_define")
	
	local d4 = require("item.compose_equip")
	local t4 = {}
	for k, v in ipairs(d4) do
		t4[v.pos] = t4[v.pos] or {}
		table.insert(t4[v.pos], v)
	end
	
	local d5 = require("item.exchange_equip")
	
	local s = table.dump(d1, "COMPOSITE").."\n"..table.dump(d2, "DE_COMPOSITE").."\n"..table.dump(d3, "COMPOSITE_DEFINE").."\n"..table.dump(t4, "COMPOSITE_EQUIP")
	.."\n"..table.dump(d5, "COMPOSITE_EXCHANGE")
	SaveToFile("forge", s)
end
