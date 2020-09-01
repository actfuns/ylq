module(..., package.seeall)
function main()
	local d1 = require("skill.cultivate")
	local t1 = {}
	local iType = 0
	local sKey = ""
	for k, v in pairs(d1) do
		if sKey ~= v.name then
			iType = iType + 1
			sKey = v.name
		end
		t1[iType] = t1[iType] or {}
		table.insert(t1[iType],v)
	end

	local s = table.dump(t1, "CULTIVATTE")
	local d2 = require("skill.partner")
	local t2 = {}
	for k, v in pairs(d2) do
		if t2[v["skill_id"]] then
			t2[v["skill_id"]][v["skill_level"]] = v
		else
			t2[v["skill_id"]] = {}
			t2[v["skill_id"]][v["skill_level"]] = v
		end
	end
	local s2 = table.dump(t2, "PARTNER")
	
	
	local d3 = require("skill.school")
	local t3 = {}
	local skill_id = nil
	for k, v in pairs(d3) do
		if v.skill_id ~= skill_id then
			skill_id = v.skill_id
			t3[skill_id] =  t3[skill_id] or {}
		end		
		table.insert(t3[skill_id], v)
	end
	local s3 = table.dump(t3, "SCHOOL")
	
	local d4 = require("skill.init_skill")
	local t4 = {}
	for k, v in pairs(d4) do
		t4[k] = t4[k] or {}
		t4[k] = v
	end
	local s4 = table.dump(t4, "INIT_SKILL")

	
	local d5 = require("skill.partner_skill_info")
	local s5 = table.dump(d5, "PARTNERSKILL")
	
	local d6 = require("skill.desc")
	local s6 = table.dump(d6, "DESC")

	local d7 = require("perform.equip")
	local s7 = table.dump(d7, "EQUIP_SKILL")
	
	local d8 = require("skill.se")
	local t8 = {}
	for k, v in ipairs(d8) do
		t8[v.skill_id] = v
	end
	local s8 = table.dump(t8, "SE")
	
	local d10 = require("skill.equip")
	local s10 = table.dump(d10, "EQUIP_SET_SKILL")
	
	SaveToFile("skill", s.."\n"..s2.."\n"..s3.."\n"..s4.."\n"..s5.."\n"..s6.."\n"..s7.."\n"..s8.."\n"..s10)

	local d9 = require("skill.passiveskill")
	local s9 = table.dump(d9, "DATA")
	SaveToFile("passiveskill", s9)
end