local print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local sformat = string.format
local sfind = string.find
local type = type
local pairs = pairs
local tostring = tostring
local next = next
local unpack = unpack

local extend = {
    Table = {},
    Io = {},
    String = {},
    Array = {},
    Protobuf = {},
    Random = {},
    Queue = {},
    Misc = {},
}

----------------------------------------
-- Table
function extend.Table.size(T)
    local i = 0
    for _, _ in pairs(T) do
        i = i + 1
    end
    return i
end

function extend.Table.keys(T)
    local out = {}
    for k, _ in pairs(T) do
        out[#out + 1] = k
    end
    return out
end

function extend.Table.values(T)
    local out = {}
    for _, v in pairs(T) do
        out[#out + 1] = v
    end
    return out
end

function extend.Table.list2map(T)
    local out = {}
    for _, v in ipairs(T) do
        out[v] = v
    end
    return out
end

function extend.Table.foreach(T, F)
    local out = {}
    for k, v in pairs(T) do
        out[#out + 1] = F(v, k)
    end
    return out
end

function extend.Table.get_default(T, key, default)
    local t = T[key]
    if not t then
        t = default
        T[key] = t
    end
    return t
end

function extend.Table.clone(T)
    local out = {}
    for k, v in pairs(T) do
        out[k] = v
    end
    return out
end

function extend.Table.deep_clone(T)
    local mark={}
    local function copy_table(t)
        if type(t) ~= 'table' then return t end
        local mt = getmetatable(t)
        local res = {}
        for k,v in pairs(t) do
            if type(v) == 'table' then
                if not mark[v] then
                    mark[v] = copy_table(v)
                end
                res[k] = mark[v]
            else
                res[k] = v
            end
        end
        setmetatable(res,mt)
        return res
    end
    return copy_table(T)
end

function extend.Table.serialize(T)
	local mark={}
	local assign={}

	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local key= type(k)=="number" and "["..k.."]" or "['" .. k .. "']"
			if type(v)=="table" then
				local dotkey= parent..(type(k)=="number" and key or "."..key)
				if mark[v] then
					tinsert(assign,dotkey.."="..mark[v])
				else
					tinsert(tmp, key.."="..ser_table(v,dotkey))
				end
			elseif type(v) == "string" then
				tinsert(tmp, key.."=".. sformat("%q", v))
            else
				tinsert(tmp, key.."=".. tostring(v))
            end
		end
		return "{"..tconcat(tmp,",").."}"
	end
	return ser_table(T,"ret")..tconcat(assign," ")
end

function extend.Table.filter(T, func)
   local t = {}
   for i,v in ipairs(T) do
      if func(v) then
         table.insert(t,v)
      end
   end
   return t
end

function extend.Table.deserialize(data)
    if data == nil or data == "" then
        return nil
    end

	local load_source = coroutine.wrap(function()
		coroutine.yield "do local ret="
		coroutine.yield (data)
		coroutine.yield " return ret end"
	end)

	local routine, err = load( load_source ,  "@deserialize", "t", {})
	return assert(routine, tostring(err) .. data)()
end

function extend.Table.print(T, CR)
    assert(type(T) == "table")

	CR = CR or '\r\n'
	local cache = {  [T] = "." }
	local function _dump(t,space,name)
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
			elseif type(v) == "table" then
				local new_key = name .. "." .. key
				cache[v] = new_key
				tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
			else
				tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
			end
		end
		return tconcat(temp,CR..space)
	end
	print(_dump(T, "",""))
end

local function toprintable(value)
    local t = type(value)
    if t == 'number' then
        return tostring(value)
    elseif t == 'string' then
        return sformat('%q', value)
    elseif t == 'boolean' then
        return value and 'true' or 'false'
    end
    return
end

function extend.Table.pretty_serialize(T, CR)
    local function error_type(v)
        error(('不能打印的类型 %s'):format(tostring(v)))
    end

	local function ser_table(tbl, index)
        local space = string.rep(' ', index)
		local tmp={}
        tinsert(tmp, '{\n')
		for k,v in pairs(tbl) do
            local key = toprintable(k)
            local value = toprintable(v)

            tinsert(tmp, space)
            tinsert(tmp, '[')
            tinsert(tmp, key)
            tinsert(tmp, '] = ')
            if value then
                tinsert(tmp, value)
            elseif type(v) == 'table' then
                tinsert(tmp, ser_table(v, index + 4))
            else
                error()
            end
            tinsert(tmp, ',\n')
        end
        tinsert(tmp, space)
        tinsert(tmp, '}')
		return tconcat(tmp)
	end
	return ser_table(T, 0)
end
----------------------------------------
-- Io
function extend.Io.readfile(file)
	local fh = io.open(file , "rb")
	if not fh then return end
	local data = fh:read("*a")
	fh:close()
	return data
end

function extend.Io.writefile(file, data)
	local fh = io.open(file , "w+b")
	if not fh then return end
	fh:write(data)
	fh:close()
	return
end

function extend.Io.hasfile(file)
	local fh = io.open(file , "w+b")
    if fh then
        fh:close()
        return true
    end
    return
end

function extend.eprint(...)
    local arg = {...}
    tinsert(arg, '\r')
    print(unpack(arg))
end

function extend.String.tohex(uid)
    local out = {}
    local len = uid:len()
    for i = 1, len do
        tinsert(out, sformat("%.2X", uid:byte(i)))
    end
    return tconcat(out)
end

function extend.String.to_camel_case(name)
	local camel_case = ""
	for section in name:gmatch( "[^_]+" ) do
		camel_case = camel_case..section:sub( 1, 1 ):upper()..section:sub( 2 )
    end
    name = camel_case
    camel_case = ''
	for section in name:gmatch( "[^.]+" ) do
		camel_case = camel_case..'.'..section:sub( 1, 1 ):upper()..section:sub( 2 )
	end
	return camel_case:sub(2)
end


--去除hex前面所有的0, 并加前缀0x
function extend.String.tozhex(uid)
    local hex = extend.String.tohex(uid)
    local zhex = hex:gsub("^0*","")
    if #zhex == 0 then
        zhex="0"
    end
    return "0x"..zhex
end

function extend.String.start_with(str, start_pattern)
    local s, e = sfind(str, start_pattern)
    return (s == 1)
end
----------------------------------------
-- Array
function extend.Array.member(L,key)
   -- 判断key是否在链表L中
   for k,v in ipairs(L) do
      if key == v then
         return k,v
      end
   end
   return false
end

function extend.Array.append (L1,L2)
   -- 将两个链表合成一个链表
   for _,v in ipairs(L2) do
      L1[#L1+1] = v
   end
   return L1
end

function extend.Array.foreach(T, F)
    local out = {}
    for k, v in ipairs(T) do
        out[#out + 1] = F(v, k)
    end
    return out
end

function extend.Array.min(T)
    if #T == 0 then return nil end
    local i = 1
    for k,v in ipairs(T) do
        if v < T[i] then i = k end
    end
    return T[i] ,i
end


----------------------------------------
-- Protobuf
local function dump(dest, src)
    for k, v in pairs(dest) do
        if type(v) == "table" then
            dest[k] = dump(v, src[k])
        else
            dest[k] = src[k]
        end
    end
    return dest
end

function extend.Protobuf.table_is_empty(tbl)
    return (next(tbl) == nil)
end

extend.Protobuf.dump = dump
--------------------------------
-- Random
function extend.Random.random_choice(t)
    return t[math.random(#t)]
end

--  根据一个随机值列表随机其中一个值
function extend.Random.random_list(rate_list)
    local sum_rate  =   0

    for _, rate in ipairs(rate_list) do
        sum_rate = sum_rate + rate
    end

    if (sum_rate <= 0) then
        return nil
    end

    local roll  = math.random() * sum_rate
    for _, rate in ipairs(rate_list) do
        if (rate >= roll) then
            return _
        else
            roll = roll - rate
        end
    end

    assert(nil)
end

function extend.Random.random_struct_list(rate_struct_list, cb)
    local rate_list = {}

    for _, s in ipairs(rate_struct_list) do
        local rate  = cb(s)
        if (rate ~= nil) then
            table.insert(rate_list, rate)
        else
            table.insert(rate_list, 0)
        end
    end

    return extend.Random.random_list(rate_list)
end

function extend.Random.random_float(min, max)
    if (max == nil) then
        return (math.random() * min)
    end

    local k = max - min
    return min + math.random() * k
end

function extend.Random.toss(ratio)
    return math.random() < ratio
end

--------------------------------
-- Misc
function extend.Misc.assert(v,message,level)
   if not v then
      message = message or "Assertion failed!"
      level = level or 1
      error(message,level+1)
   end
end

-- Queue
function extend.Queue.create()
    return {queue={},head=0,tail=-1}
end

function extend.Queue.enqueue(Q,v)
    Q.tail = Q.tail + 1
    Q.queue[Q.tail] = v
end

function extend.Queue.dequeue(Q)
    if Q.tail < Q.head then
        return nil
    end

    local v = Q.queue[Q.head]
    Q.head = Q.head + 1
    if Q.tail < Q.head then
        Q.tail = -1
        Q.head = 0
    end
    return v
end 

return extend
