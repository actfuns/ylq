
local ldes = require "ldes"

local DES = {};

DES.BLOCK_SIZE = 8;

DES.encrypt = function(sKey, sInput)
	return ldes.desencode(sKey, sInput)
end

DES.decrypt = function(sKey, sInput)
	return ldes.desdecode(sKey, sInput)
end

return DES;
