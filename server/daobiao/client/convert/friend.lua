module(..., package.seeall)
function main()
	local d = require("friend.city")
	local citydict = {}
	local provlist = {}
	for i, v in ipairs(d) do
		if citydict[v.province] then
			table.insert(citydict[v.province], v.city)
		else
			citydict[v.province] = {v.city}
			table.insert(provlist, v.province)
		end
	end
	local s1 = table.dump(provlist, "ProvData") 
	local s2 = table.dump(citydict, "CityData")
	SaveToFile("city", s1.."\n"..s2)
	
	local d2 = require("friend.tag")
	local tagdict = {}
	local taglist = {}
	for i, v in ipairs(d2) do
		if tagdict[v.maintag] then
			table.insert(tagdict[v.maintag], v.tag)
		else
			tagdict[v.maintag] = {v.tag}
			table.insert(taglist, v.maintag)
		end
	end
	local s3 = table.dump(taglist, "MainTag") 
	local s4 = table.dump(tagdict, "Tag")
	SaveToFile("tag", s3.."\n"..s4)
	
end
