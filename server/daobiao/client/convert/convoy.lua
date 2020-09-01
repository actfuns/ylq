module(..., package.seeall)
function main()
	local d1 = require("huodong.convoy.config")
	local d2 = require("huodong.convoy.random_talk")
	local d3 = require("huodong.convoy.follow_talk")
	local d4 = require("huodong.convoy.talk_content")
	local d5 = require("huodong.convoy.convoy_pool")

	local s = table.dump(d1, "DATA").."\n"..table.dump(d2, "RandomTalk").."\n"..table.dump(d3, "FollowTalk")
	.."\n"..table.dump(d4, "TalkContent").."\n"..table.dump(d5, "ConvoyPool")
	SaveToFile("convoy", s)
end
