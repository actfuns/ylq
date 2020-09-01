module(..., package.seeall)
function main()
	local d1 = require("system.title.title")
	local d2 = require("system.title.show_type")
	local d1_out = {}
	local d1_out1 = {}

	local function d1_sortFunc(v1, v2)
		return d1[v1].sort_id < d1[v2].sort_id
	end

	local function d1_out1sortFunc(v1, v2)
		return d1[v1].lv < d1[v2].lv
	end

	for k,v in pairs(d1) do
		table.insert(d1_out, v.id)
		if d1_out1[v.group] == nil then
			d1_out1[v.group] = {}
		end
		table.insert(d1_out1[v.group], v.id)
	end
	table.sort(d1_out, d1_sortFunc)

	for i,v in ipairs(d1_out1) do
		table.sort(v, d1_out1sortFunc)
	end

	local s = table.dump(d1, "DATA") .. "\n" .. table.dump(d1_out, "ShowSort") .. "\n" .. table.dump(d1_out1, "LvSort")
	 .. "\n" .. table.dump(d2, "ShowType")
	SaveToFile("title", s)
end
