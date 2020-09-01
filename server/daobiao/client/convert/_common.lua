package.path = package.path..";./luadata/?.lua"

LINE_WIDTH = 60
function table_tostring(t, maxlayer, name)
	local tableList = {}
	local layer = 0
	maxlayer = maxlayer or 100
	local function cmp(t1, t2)
		return tostring(t1) < tostring(t2)
	end
	local function table_r (t, name, indent, full, layer)
		local id = not full and name or type(name)~="number" and tostring(name) or '['..name..']'
		local tag = indent .. id .. ' = '
		local out = {}  -- result
		if type(t) == "table" and layer < maxlayer then
			if tableList[t] ~= nil then
				table.insert(out, tag .. '{} -- ' .. tableList[t] .. ' (self reference)')
			else
				tableList[t]= full and (full .. '.' .. id) or id
				if next(t) then -- Table not empty
					table.insert(out, tag .. '{')
					local keys = {}
					for key,value in pairs(t) do
						table.insert(keys, key)
					end
					table.sort(keys, cmp)
					for i, key in ipairs(keys) do
						local value = t[key]
						table.insert(out,table_r(value,key,indent .. '|  ',tableList[t], layer + 1))
					end
					table.insert(out,indent .. '}')
				else table.insert(out,tag .. '{}') end
			end
		else
			local val = type(t)~="number" and type(t)~="boolean" and '"'..tostring(t)..'"' or tostring(t)
			table.insert(out, tag .. val)
		end
		return table.concat(out, '\n')
	end
	return table_r(t,name or 'Table', '', '', layer)
end

function table.print(t, name, maxlayer)
	print(table_tostring(t, maxlayer, name))
end

function table.dump(t, name)
	local function p(o, name, indent, send)
		local s = ""
		s = s .. string.rep("\t", indent)
		if name ~= nil then
			if type(name) == "number" then
				name = string.format("[%d]", name)
			else
				name = tostring(name)
				if indent ~= 0 then
					if not string.match(name, "^[A-Za-z_][A-Za-z0-9_]*$") then
						name = string.format("[\"%s\"]", name)
					end
				end
			end
			s = s .. name .. "="
		end
		if type(o) == "table" then
			s = s.."{"
			local temp = ""
			local keys = {}
			for k, v in pairs(o) do
				table.insert(keys, k)
			end
			pcall(function() table.sort(keys) end)
			for i, k in ipairs(keys) do
				local v = o[k]
				temp = temp .. p(v, k, indent+1, ",")
			end

			local temp2 = string.gsub(temp, "[\n\t]", "")
			if #temp2 < LINE_WIDTH then
				temp = temp2
			else
				s = s .. "\n"
				temp = temp .. string.rep("\t", indent)
			end
			s = s .. temp .. "}" .. send .. "\n"
		else
			if type(o) == "string" then
				if string.sub(o, -1) ~= "]" then
					o = "[[" .. o .. "]]"
				--中括号结尾，则末尾加空格
				else
					o = "[[" .. o .. " ]]"
				end
			elseif o == nil then
				o = "nil"
			end
			s = s .. tostring(o) .. send .. "\n"
		end
		return s
	end
	return p(t, name, 0, "")
end

function table.listdump(list, name)
	local s = name.." = { \n"
	for i, v in ipairs(list) do
		if type(v) == "string" then
			v = "" .. v .. "\n"
			s = s..v
		end
	end
	s = s.."}"
	return s
end

function SaveToFile(filename, s)
	s = "module(...)\n--auto generate data\n"..s
	pcall(function ()
		local path = string.format("client/data/%sdata.lua", filename)
		if IsSameFile(path, s) then
			return
		end
		local f, errmsg = io.open(path, "wb")
		if f then
			f:write(s)
			f:close()
			print("client change->"..path)
		else
			error(errmsg)
		end
	end)
	if OTHER_PATH then
		local path = string.format("%s/%sdata.lua", OTHER_PATH, filename)
		local f, errmsg = io.open(path, "wb")
		if f then
			f:write(s)
			f:close()
		end
	end
end


function IsSameFile(path, s)
	local f, errmsg = io.open(path, "rb")
	if f then
		local oldStr = f:read("*a")
		f:close()
		return s == oldStr
	else
		return false
	end
end

function SaveAllDataToFile(filename, s)
	local oldStr = GetOldStr(filename)
	if oldStr then
		s = oldStr.."--auto generate data\n"..s
	else
		s = "module(...)\n--auto generate data\n"..s
	end

	pcall(function ()
		local path = string.format("client/data/%sdata.lua", filename)
		if IsSameFile(path, s) then
			return
		end
		local f, errmsg = io.open(path, "wb")
		if f then
			f:write(s)
			f:close()
			print("client有改变"..path)
		else
			error(errmsg)
		end
	end)
	if OTHER_PATH then
		local path = string.format("%s/%sdata.lua", OTHER_PATH, filename)
		local f, errmsg = io.open(path, "wb")
		if f then
			f:write(s)
			f:close()
		end
	end
end

function GetOldStr(filename)
	local path = string.format("client/data/%sdata.lua", filename)
	local f, errmsg = io.open(path, "rb")
	if f then
		local oldStr = f:read("*a")
		f:close()
		local index, _ = string.find(oldStr, "--auto generate data")
		return string.sub(oldStr, 1, index)
	else
		return ""
	end
end
