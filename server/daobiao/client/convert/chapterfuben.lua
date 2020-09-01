module(..., package.seeall)
function main()
	local d1 = require("huodong.chapterfb.chapterfb")
	local d3 = require("huodong.chapterfb.chapterinfo")
	local d4 = require("huodong.chapterfb.starreward")
	local d5 = require("huodong.chapterfb.dialogue")
	local d6 = require("huodong.chapterfb.task_dialogue")
	local chapters = {}
	for k,v in pairs(d1) do
		local extra_reward = {}
		if v.extra_reward then
			for i,r in ipairs(v.extra_reward) do
				table.insert(extra_reward, {amount=r.amount, sid=r.sid})
			end
		end
		local pass_reward = {}
		if v.pass_reward then
			for i,r in ipairs(v.pass_reward) do
				table.insert(pass_reward, {num=r.num, sid=r.sid})
			end
		end
		local first_reward = {}
		if v.first_reward then
			for i,r in ipairs(v.first_reward) do
				table.insert(first_reward, {num=r.num, sid=r.sid})
			end
		end
		local ui_reward = {}
		if v.ui_reward then
			for i,r in ipairs(v.ui_reward) do
				table.insert(ui_reward, {num=r.num, sid=r.sid})
			end
		end

		if not chapters[v.type] then
			chapters[v.type] = {}
		end
		if not chapters[v.type][v.chapterid] then
			chapters[v.type][v.chapterid] = {}
		end
		chapters[v.type][v.chapterid][v.level] = {
			chapterid = v.chapterid,
			level = v.level,
			name = v.name,
			issweep = v.issweep,
			open_condition = v.open_condition,
			sweep_condition = v.sweep_condition,
			star_condition = v.star_condition,
			energy_cost = v.energy_cost,
			fightid = v.fightid,
			fight_time = v.fight_time,
			ui_pos = v.ui_pos,
			hero_pos = v.hero_pos,
			ui_scale = v.ui_scale,
			extra_reward = extra_reward,
			pass_reward = pass_reward,
			first_reward = first_reward,
			yuanicon = v.yuanicon,
			ui_reward = ui_reward,
			taskPassDes = v.taskPassDes,
			isrotate = v.isrotate,
			task_dialogue = v.task_dialogue,
			power = v.power,
			pass_dialogueani_id = v.pass_dialogueani_id,
			type = v.type,
			sweep_cost = v.sweep_cost,
			partnerclip = v.partnerclip
		}
	end


	local chapterinfo = {}
	for k,v in pairs(d3) do
		if not chapterinfo[v.type] then
			chapterinfo[v.type] = {}
		end
		chapterinfo[v.type][v.chapterid] = v
	end

	local starrewards = {}
	for k,v in pairs(d4) do
		if not starrewards[v.type] then
			starrewards[v.type] = {}
		end
		if not starrewards[v.type][v.chapterid] then
			starrewards[v.type][v.chapterid] = {}
		end
		table.insert(starrewards[v.type][v.chapterid], {star = v.star,star_reward = v.star_reward,})
		local function sortfun(a, b)
			return a.star < b.star
		end
		table.sort(starrewards[v.type][v.chapterid], sortfun)
	end

	local dialogue = {}
	for k,v in pairs(d5) do
		if not dialogue[v.id] then
			dialogue[v.id] = {}
		end
		local tmp = {
			level = v.level,
			sort = v.sort,
			content = v.content,
			emoji = v.emoji,
			start_time = v.start_time,
			end_time = v.end_time,
		}
		table.insert(dialogue[v.id], tmp)
	end
	local function sort(a, b)
		return a.sort < b.sort
	end
	for k,v in pairs(dialogue) do
		table.sort(v, sort)
	end

	local task_dialogue = {}
	for k,v in pairs(d6) do
		if not task_dialogue[v.id] then
			task_dialogue[v.id] = {}
		end
		local tmp = {
			sort = v.sort,
			content = v.content,
			emoji = v.emoji,
			start_time = v.start_time,
			end_time = v.end_time,
			speeker = v.speeker,
		}
		table.insert(task_dialogue[v.id], tmp)
	end
	local function sort(a, b)
		return a.sort < b.sort
	end
	for k,v in pairs(task_dialogue) do
		table.sort(v, sort)
	end
	local s1 = table.dump(chapters, "Config")
	local s3 = table.dump(chapterinfo, "ChapterInfo")
	local s4 = table.dump(starrewards, "StarReward")
	local s5 = table.dump(dialogue, "Dialogue")
	local s6 = table.dump(task_dialogue, "TaskDialogue")
	SaveToFile("chapterfuben", s1.."\n"..s3.."\n"..s4.."\n"..s5.."\n"..s6)
end
