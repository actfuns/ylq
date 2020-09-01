
local dumpapi = require "utils.datadump"

local sRootPath, sOutPath = ...

local function Require(sPath)
	local sFile = string.format("%s/%s.lua", sRootPath, sPath)
	local f, s = loadfile(sFile, "bt")
	assert(f, s)
	return f()
end

local function OutPath(sFile)
	print(string.format("%s/%s.lua", sOutPath, sFile))
	return string.format("%s/%s.lua", sOutPath, sFile)
end

local M = {}

--daobiao begin

M.example = Require("example")

--daobiao end

for k, v in pairs(M) do
	local s = dumpapi(v)
	local f = io.open(OutPath(k), "wb")
	f:write(s)
	f:close()
end
