
function split_string(s, rep, f, bReg)
    assert(rep ~= '')
    local lst = {}
    if #s > 0 then
        local bPlain
        if bReg then
            bPlain = false
        else
            bPlain = true
        end

        local iField, iStart = 1, 1
        local iFirst, iLast = string.find(s, rep, iStart, bPlain)
        while iFirst do
            lst[iField] = string.sub(s, iStart, iFirst - 1)
            iField = iField + 1
            iStart = iLast + 1
            iFirst, iLast = string.find(s, rep, iStart, bPlain)
        end
        lst[iField] = string.sub(s, iStart)

        if f then
            for k, v in ipairs(lst) do
                lst[k] = f(v)
            end
        end
    end
    return lst
end

function index_string(s, i)
    local iLen = #s
    if i > iLen or i < 1 then
        return
    end
    return string.char(s:byte(i))
end

local fm = {}
function formula_string(s, m)
    local f = fm[s]
    if f then
        return f(m)
    else
        f = load(string.format([[
            return function (m)
                for k, v in pairs(m) do
                    _ENV[k] = v
                end

                local __r = (%s)

                for k, v in pairs(m) do
                    _ENV[k] = nil
                end

                return __r
            end]], s), s, "bt", {pairs = pairs,math=math})()
        fm[s] = f
        return f(m)
    end
end

function trim(s, p)
    p = p or " "
    local pl = string.format("^[%s]*(.-)[%s]*$", p, p)
    return string.gsub(s, pl, "%1")
end

--将年-月-日 时：分：秒 格式的日期转化为毫秒数
function getTimeByDate(sDate)
    local a = split_string(sDate," ")
    local b = split_string(a[1],"-")
    local c = split_string(a[2],":")
    local t = os.time({year=b[1],month=b[2],day=b[3],hour=c[1],min=c[2],sec=c[3]})
    return t
end

function clientstrlen(str)
    local count = 0
    local len = 0
    local limit = string.len(str)
    while count < limit do
        local utf8 = string.byte(str, count + 1)
        if utf8 == nil then
            break
        end
        len = len + 1
        --utf8字符1byte,中文3byte
        if utf8 > 127 then
            count = count + 3
        else
            count = count + 1
        end
    end
    return len
end