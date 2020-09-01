
function list_generate(t, func, bIsMap)
    local r = {}
    if not bIsMap then
        for _, v in ipairs(t) do
            if func then
                v = func(v)
            end
            table.insert(r, v)
        end
    else
        for _, v in pairs(t) do
            if func then
                v = func(v)
            end
            table.insert(r, v)
        end
    end
    return r
end

function list_clear(t)
    for i = #t, 1, -1 do
        t[i] = nil
    end
end

function table_count(t)
    local iLen = 0
    for k, v in pairs(t) do
        iLen = iLen + 1
    end
    return iLen
end

function table_to_int_key(t)
    local mNew = {}
    for k, v in pairs(t) do
        mNew[tonumber(k)] = v
    end
    return mNew
end

function table_to_db_key(t)
    local mNew = {}
    for k, v in pairs(t) do
        mNew[db_key(k)] = v
    end
    return mNew
end

function list_key_table(l, v)
    local t = {}
    for idx, k in pairs(l) do
        t[k] = v or idx
    end
    return t
end

function table_key_list(t)
    local l = {}
    for k, v in pairs(t) do
        table.insert(l, k)
    end
    return l
end

function table_value_list(t)
    local l = {}
    for k, v in pairs(t) do
        table.insert(l, v)
    end
    return l
end

function table_copy(t)
    local m = {}
    for k, v in pairs(t) do
        m[k] = v
    end
    return m
end

function table_deep_copy(t)
    local r = {}
    local f
    f = function (ot)
        if r[ot] then
            return r[ot]
        end
        local m = {}
        r[ot] = m
        for k, v in pairs(ot) do
            local ok, ov = k, v
            if type(k) == "table" then
                ok = f(k)
            end
            if type(v) == "table" then
                ov = f(v)
            end
            m[ok] = ov
        end
        return m
    end

    return f(t)
end

function table_choose_key(tbl)
    if table_count(tbl) <= 0 then
        return
    end
    local iSumPa = 0
    for key,value in pairs(tbl) do
        iSumPa = iSumPa + value
    end
    if iSumPa <= 0 then return end

    local iRnd = math.random(iSumPa)
    for key,value in pairs(tbl) do
        if value >= iRnd then
            return key
        end
        iRnd = iRnd - value
    end
end

function list_split(l, iStart, iEnd)
    local lRes = {}
    for idx = iStart, iEnd do
        local value = l[idx]
        if value == nil then
            break
        elseif type(value) == "table" then
            value = table_deep_copy(value)
        end
        table.insert(lRes, value)
    end
    return lRes
end

function table_in_list(l, r)
    for _, v in ipairs(l) do
        if v == r then
            return true
        end
    end
    return false
end

function table_get_depth(t, keylist)
    assert(type(t) == "table")
    local v = t
    for _, k in ipairs(keylist) do
        if type(k) ~= "number" and type(k) ~= "string" then
            return nil
        end
        if type(v) ~= "table" then
            return nil
        end
        v = v[k]
    end
    return v
end

function table_get_set_depth(t, keylist)
    local v = t
    for _, k in ipairs(keylist) do
        if type(k) ~= "number" and type(k) ~= "string" then
            return nil
        end
        if type(v) ~= "table" then
            return nil
        end
        if not v[k] then
            v[k] = {}
        end
        v = v[k]
    end
    return v
end

function table_set_depth(t, keylist, lastkey, value)
    local mTable = table_get_set_depth(t, keylist)
    if not mTable then
        return false
    end
    mTable[lastkey] = value
    return true
end

function table_combine(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

function list_combine(l1, l2)
    for _,v in ipairs(l2) do
      l1[#l1+1] = v
   end
   return l1
end

function table_all_true(t, f)
    for k, v in pairs(t) do
        if not f(k, v) then
            return false
        end
    end
    return true
end

function table_count_value(t)
    t = t or {}

    local c = 0
    for k, v in pairs(t) do
        c = c + v
    end
    return c
end

function table_random_key(tbl)
    tbl = tbl or {}
    local l = table_key_list(tbl)
    return l[math.random(#l)]
end

function ConvertTblToStr(tbl)
    local str = "{"
    local Head = true
    if type(tbl) == "table" then
        for key,value in pairs(tbl) do
            if not Head then
                str = str .. ","
            else
                Head = false
            end
            if type(key) == "number" then
                    str = str .. "["..key .."]="
            else
                    str = str.. "['"..key .."']="
            end
            if  value == nil then
                str = str .."nil,"
            elseif type(value) == "boolean" then
                str = str ..tostring(value)
            elseif type(value) == "number" then
                str = str .. value
            elseif type(value) == "table" then
                str = str ..ConvertTblToStr(value)
            elseif type(value) == "string" then
                str = str .."\""..value.."\""
            else
                str = str .. type(value)
            end
        end
    else
        print("ConvertTblToStr failed,param is not a table,it is a "..type(tbl))
    end
    str = str.."}"
    return str
end

function list_join(tbl,slink)
    local s = ""
    slink = slink or ""
    for k,v in pairs(tbl) do
        if s == "" then
            s = s .. v
        else
            s = s .. slink .. v
        end
    end
    return s
end