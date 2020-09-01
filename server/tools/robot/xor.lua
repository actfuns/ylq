

XOR_KEY = "e07aea3911363aa9"

local MOD_KEY = function (k)
    local j = k*2+1
    local f = load(string.format("return 0x%s",string.sub(XOR_KEY,j,j+1)))
    return f()
end

local ORX_KEY_MAP={
MOD_KEY(7),MOD_KEY(6),MOD_KEY(5),MOD_KEY(4),
MOD_KEY(3),MOD_KEY(2),MOD_KEY(1),MOD_KEY(0),
}

M = {}

function M.code(s)
    local len = s:len()
    local t = {}
    local mark = len%10+1
    local sp_mark
    if len%2 ~= 0 then
        sp_mark = len%20
    else
        sp_mark = len//7
    end
    for i=0,len-1 do
        local asi
        if  i%mark ~=0 then
            if i == sp_mark then
               asi = s:byte(i+1) ~ 0xa3
           else
                asi = s:byte(i+1) ~ ORX_KEY_MAP[i%8+1]
           end
        else
            asi = tonumber(s:byte(i+1))
        end
        
        table.insert(t,string.char(asi))
    end
    local sCode = table.concat(t,"")
    return sCode
end

return M