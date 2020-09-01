module(..., package.seeall)
function main()
	local dUpdate = require("chat.maskword")
	local newlist = {}
	local dict = {}
	for k, v in pairs(dUpdate) do
		if dict[v.word] then
		else
			dict[v.word] = true
			table.insert(newlist, v.word)
		end
	end
	-- table.sort(newlist)
	local s = table.dump(newlist, "DATA")
	SaveToFile("maskword", s)
end