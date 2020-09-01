--执行所有客户端导表
OTHER_PATH = ...
require("client.convert._common")

local list ={
	"global",
	"globalcontrol",
	"item",
	"map",
	"chat",
	"patrol",
	"scene",
	"upgrade",
	"audio",
	"task",
	"reward",
	"roletype",
	"randomname",
	"npcshop",
	"pay",
	"school",
	"schedule",
	"autoteam",
	"team",
	"charge",
	"skill",
	"buff",
	"maskword",
	"worldboss",
	"treasure",
	"loginreward",
	"magic",
	"npc",
	"model",
	"partner",
	"partnerequip",
	"house",
	"arena",
	"equalarena",
	"rank",
	"org",
	"tollgate",
	"monster",
	"endlesspve",
	"help",
	"title",
	"equipfuben",
	"pefuben",
	"teach",
	"openui",
	"playconfig",
	"trapmine",
	"friend",
	"pata",
	"huodong_block",
	"achieve",
	"mapbook",
	"guide",
	"terrawar",
	"foretell",
	"yjfuben",
	"travel",
	"forge",
	"lilian",
	"spine",
	"minglei",
	"sociality",
	"fieldboss",
	"welfare",
	"onlinegift",
	"convoy",
	"chapterfuben",
	"teampvp",
	"sceneexam",
	"msattack",
	"roleskin",
	"hunt",
	"clubarena",
	"marry",
	"servergrade",
}


for i, name in ipairs(list) do
	local m = require("client.convert."..name)
	if m.main then
		local r1, r2 = pcall(function ()
			m.main()
		end)
		if not r1 then
			print(r2)
		end
	end
end
