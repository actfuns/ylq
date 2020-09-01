
local  fProto, fOut= ...

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

local function checkProto(rFile, wFile)
    -- body
    local rf = io.open(rFile, "r")
    local outPuts = {} 
    -- print(string.format("check warning:%s\n", rFile))
    for line in rf:lines() do
        local sMessage = split_string(line, " ")
        -- if #sMessage <= 2 then return end
        for _,s in pairs(sMessage) do
            local sNew = string.upper(s)
            if s ~= string.lower(s)  and string.sub(sNew, 1, 1) ~= string.sub(s, 1, 1) and "base." ~= string.sub(s, 1, 5) then
                table.insert(outPuts, line)
                break
            end
        end
    end
    rf:close()
    if #outPuts  > 0 then
        local wf = io.open(wFile, "a")
        wf:write(string.format("check warning:%s\n", rFile))
        print(string.format("check warning:%s\n", rFile))
        for _,v in pairs(outPuts) do
            wf:write(string.format("%s\n", v))
            print(string.format("%s", v))
        end
        wf:close()
    end
end

checkProto(fProto, fOut)
