module(..., package.seeall)
function main()
	local d1 = require("huodong.minglei.guide_dialog")
	local d2 = require("huodong.minglei.guide_npc")
	local d3 = require("huodong.minglei.config_ui_reward")
	local d4 = require("huodong.minglei.npc")
	SaveToFile("minglei", table.dump(d1, "GUIDE_DIALOG") .. "\n"..table.dump(d2, "GUIDE_NPC").. "\n"..table.dump(d3, "CONFIG_UI_REWARD").. "\n"..table.dump(d4, "NPC"))
end
