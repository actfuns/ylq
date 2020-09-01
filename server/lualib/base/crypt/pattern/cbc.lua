
local array = require("base.crypt.common.array")

local tinsert = table.insert
local tremove = table.remove

local M = {}

local CObject = {}
CObject.__index = CObject

function CObject:New(mAgol, mPadding, sKey, sV)
    	local o = setmetatable({}, self)
    	o.m_sKey = sKey
    	o.m_sV = sV or sKey
    	o.m_mAgol = mAgol
    	o.m_mPadding = mPadding
    	assert(#o.m_sKey == o.m_mAgol.BLOCK_SIZE and #o.m_sV == o.m_mAgol.BLOCK_SIZE, 
    		"CBC Object New Failed")
    	return o
end

function CObject:Encode(s)
	local lTotal = {}

	local iBlockSize = self.m_mAgol.BLOCK_SIZE
	s = self:Padding(s)
	--local lKey = array.fromString(self.m_sKey)
	local sKey = self.m_sKey
	local lInput = array.fromString(self.m_sV..s)
	local iIndex = iBlockSize
	local iLen = #lInput
	local lRecord = nil

	while (iIndex <= iLen) do
		local lBlock = {}
		for i = iIndex - iBlockSize + 1, iIndex do
			tinsert(lBlock, lInput[i])
		end

		if not lRecord then
			lRecord = lBlock
		else
			local lOut = array.xor(lRecord, lBlock)
			--lOut = self.m_mAgol.encrypt(lKey, lOut)
			lOut = array.fromString(self.m_mAgol.encrypt(sKey, array.toString(lOut)))
			for _, v in ipairs(lOut) do
				tinsert(lTotal, v)
			end
			lRecord = lOut			
		end

		iIndex = iIndex + iBlockSize
	end

	return array.toString(lTotal)
end

function CObject:Decode(s)
	local lTotal = {}

	local iBlockSize = self.m_mAgol.BLOCK_SIZE
	--local lKey = array.fromString(self.m_sKey)
	local sKey = self.m_sKey
	local lInput = array.fromString(self.m_sV..s)
	local iIndex = iBlockSize
	local iLen = #lInput
	local lRecord = nil

	while (iIndex <= iLen) do
		local lBlock = {}
		for i = iIndex - iBlockSize + 1, iIndex do
			tinsert(lBlock, lInput[i])
		end

		if not lRecord then
			lRecord = lBlock
		else
			local lOut = lBlock
			--lOut = self.m_mAgol.decrypt(lKey, lOut)		
			lOut = array.fromString(self.m_mAgol.decrypt(sKey, array.toString(lOut)))
			lOut = array.xor(lRecord, lOut)
			for _, v in ipairs(lOut) do
				tinsert(lTotal, v)
			end
			lRecord = lBlock
		end

		iIndex = iIndex + iBlockSize
	end

	return self:UnPadding(array.toString(lTotal))
end

function CObject:Padding(s)
	return self.m_mPadding.fill(s, self.m_mAgol.BLOCK_SIZE)
end

function CObject:UnPadding(s)
	return self.m_mPadding.clear(s, self.m_mAgol.BLOCK_SIZE)
end

function M.Create(...)
     	return CObject:New(...)
end

return M
