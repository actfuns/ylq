module(..., package.seeall)
function main()
	local dOri = require("map.patrol")
    local d= {}
    for k, v in pairs(dOri) do
        if v.res_id then
            if not d[v.res_id] then
                d[v.res_id] = {}
            end
            table.insert(d[v.res_id], {x=v.x, y=v.y})
        end
    end

	local s = table.dump(d, "DATA")
	SaveToFile("patrol", s)
end