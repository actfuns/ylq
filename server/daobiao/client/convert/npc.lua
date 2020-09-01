module(..., package.seeall)
function main()
	local newTable = {}
	local oriTable = nil

	local npcName = {"dialog_npc", "global_npc", "temp_npc"}
	for _,v in ipairs(npcName) do
		oriTable = require("npc." .. v)
		newTable[string.upper(v)] = oriTable
	end

	local dialog_npc_config = require("npc.dialog_npc_config")
	local school = require("npc.school")
	local npcgroup = require("npc.npcgroup")
	local dialog_animation_config = require("npc.dialog_animation_config")
	local temp_task_npc = {}
	local task_npc_1 = require("npc.task_npc_1")
	for k, v in pairs(task_npc_1) do
		temp_task_npc[k] = v
	end
	local task_npc_2 = require("npc.task_npc_2")
	for k, v in pairs(task_npc_2) do
		temp_task_npc[k] = v
	end

	local task_npc_3 = require("npc.task_npc_3")
	for k, v in pairs(task_npc_3) do
		temp_task_npc[k] = v
	end
	
	local orgWarNpc = require("huodong.orgwar.npc")
	
	local task_chapter_npc = require("npc.task_chaptertips_npc")
	
	local s = table.dump(newTable, "NPC") .. "\n" .. table.dump(dialog_npc_config, "DIALOG_NPC_CONFIG")
	.."\n" .. table.dump(school, "SCHOOL") .. "\n" .. table.dump(npcgroup, "NPCGROUP").."\n"..table.dump(dialog_animation_config, "DIALOG_ANIMATION_CONFIG")
	.."\n"..table.dump(temp_task_npc, "TASK_NPC").."\n"..table.dump(orgWarNpc, "OrgWarNpc").."\n"..table.dump(task_chapter_npc, "TASKCHAPTERNPC")
	SaveToFile("npc", s)
end
