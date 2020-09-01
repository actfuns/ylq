
local tinsert = table.insert
local tconcat = table.concat
local schar = string.char
local sbyte = string.byte
local ssub = string.sub

local M = {}

function M.fill(s, ib)
	local iLen = #s
	local iLeft = ib - iLen%ib
	local l = {s,}
	local sm = schar(iLeft)
	for i = 1, iLeft do
		tinsert(l, sm)
	end
	return tconcat(l)
end

function M.clear(s, ib)
	local iLen = #s
	local iLeft = sbyte(s, iLen)
	assert(iLen>iLeft, "pkcs5 clear failed1")
	for i = 1, iLeft do
		assert(sbyte(s, iLen - i + 1) == iLeft, "pkcs5 clear failed2")
	end
	return ssub(s, 1, iLen - iLeft)
end

return M
