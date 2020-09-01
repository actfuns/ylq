
local file, source_file, target_file = ...

local function split_string(s, rep, f, bReg)
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

local f1 = io.open(source_file, "r")
local f2 = io.open(target_file, "a")
local f3 = io.open(file, "r")
local s1 = f1:read("*a")
local s3 = f3:read("*a")

local bFlag = false
local lOutputs = {}
local lFuncs = split_string(s1, "\n\n")
for i = 2, #lFuncs do
    local s = lFuncs[i]
    local lLines = split_string(s, "\n")
    for j = 1, #lLines do
        local line = lLines[j]
        if string.find(line, "SETTABUP") and string.find(line, "_ENV") then
            bFlag = true
            table.insert(lOutputs, line)
        end
    end
end

if bFlag then
    f2:write(string.format("File: %s\n", file))
    local lFileLines = split_string(s3, "\n")
    for k, v in ipairs(lOutputs) do
        local iNo = tonumber(string.match(v, "%[(%d+)%]"))
        f2:write(string.format("warning%d(on line %d):\n", k, iNo))
        f2:write(string.format("define global in function luac code: %s\n", v))
        f2:write(string.format("define global in function lua code: %s\n", lFileLines[iNo]))
    end
end

f1:close()
f2:close()
f3:close()
