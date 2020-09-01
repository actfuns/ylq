module(..., package.seeall)
function main()
	local newTable = {}
	local oriTable = nil
	local task = {}
	local npc = {}
	local item = {}
	local pick = {}
	local dialog = {}

	local taskType = require("task.tasktype")

	local taskName = {"test", "story", "shimen","lilian","huodong","teach", "practice", "daily", "house", "plot", "partner","convoy"}
	for _,v in ipairs(taskName) do
		local taskMain = {}
		-- 任务主体
		oriTable = require("task." .. v .. ".task")
		task = {}
		for k, v in pairs(oriTable) do
			task[k] = {
				type = v.type,
				tips = v.tips,
				name = v.name,
				ChapterFb = v.ChapterFb or "",
				autoDoNextTask = v.autoDoNextTask,
				submitNpcId = v.submitNpcId,
				clientExtStr = v.clientExtStr,
				submitRewardStr = v.submitRewardStr,
				taskWalkingTips = v.taskWalkingTips,
				is_chapter_dialogue = v.is_chapter_dialogue,
				chapter_last_action = v.chapter_last_action,
			}
		end
		taskMain.TASK = task

		-- 任务Npc
		oriTable = require("task." .. v .. ".tasknpc")
		npc = {}
		for k, v in pairs(oriTable) do
			local mode = {}
			mode.scale =  v.scale
			mode.shape = v.modelId
			npc[k] = {
				name = v.name,
				modelId = v.modelId,
				rotateY = v.rotateY,
				model_info = mode,
				shortName = v.shortName,
			}
		end
		taskMain.NPC = npc

		-- 任务物品
		item = require("task." .. v .. ".taskitem")
		taskMain.ITEM = item

		-- 任务采集
		pick = require("task." .. v .. ".taskpick")
		taskMain.PICK = pick
		
		-- 任务对话
		local dialog_t = require("task." .. v .. ".taskdialog")
		dialog = {}
		for k, v in pairs(dialog_t) do
			dialog[v.dialog_id] = dialog[v.dialog_id] or {}
			dialog[v.dialog_id][v.subid] = v
		end
		taskMain.DIALOG = dialog
		
		--主线动画
		if v == "story" then				
			local ani = require("task." .. v .. ".animation_config")
			taskMain.ANI_CONFIG = ani
		end
		
		--伙伴任务支线任务配置
		if v == "partner" then
			local config = require("task." .. v .. ".config")
			taskMain.CONFIG = config
		end

		-- 装箱
		newTable[string.upper(v)] = taskMain
	end
	
	--成就支线
	oriTable = require("achieve" .. ".achievetask")
	local taskMain = {}
	local task = {}	
	for k, v in pairs(oriTable) do
		task[k] = {
			type = v.type,		
			submitRewardStr = v.rewarditem,
			open_id = v.open_id,
		}
	end
	taskMain.TASK = task
	newTable["ACHIEVE"] = taskMain

	local s = table.dump(taskType, "TASKTYPE") .. "\n" .. table.dump(newTable, "TASK")
	SaveToFile("task", s)
end
