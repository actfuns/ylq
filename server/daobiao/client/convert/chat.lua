module(..., package.seeall)
function main()
	local d1 = require("chat.helpchat")
	local list = {}
	for k, v in pairs(d1) do
		table.insert(list, v.content)
	end
	
	local d2 = require("chat.chatconfig")
	local chatconfig = {}
	for k, v in pairs(d2) do
		chatconfig[v.id] = {
			name = v.name,
			sort = v.sort,
			talkable = v.talkable,
			talk_gap = v.talk_gap,
			voiceable = v.voiceable,
			energy_cost = v.energy_cost,
			grade_limit = v.grade_limit,
		}
	end
	
	local s = table.dump(list, "HELP") .. "\n" .. table.dump(chatconfig, "CHATCONFIG")
	
	local d2 = require("chat.horsespeed")
	local s2 = table.dump(d2, "HORSESPEED") 
	local d3 = require("chat.normalmsg")
	local s3 = table.dump(d3, "NormalMsg")

	local d4 = require("chat.adword")
	local s4 = table.dump(d4, "ADWords")

	SaveToFile("chat", s.."\n"..s2.."\n"..s3.."\n"..s4)
end