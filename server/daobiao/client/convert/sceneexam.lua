module(..., package.seeall)
function main()
	local t = {}
	local d = require("huodong.question.scene")
	table.insert(t, table.dump(d, "SceneData"))

	local d = require("huodong.question.scene_exam_chat")
	table.insert(t, table.dump(d, "SceneChat"))

	local d = require("huodong.question.ui_award")
	table.insert(t, table.dump(d, "UIAward"))
	SaveToFile("sceneexam", table.concat(t, "\n"))
end