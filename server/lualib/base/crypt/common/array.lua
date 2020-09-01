
local string = require("string");
local bit = require("base.crypt.common.bit")

local XOR = bit.bxor;

local Array = {};

Array.size = function(array)
	return #array;
end

Array.fromString = function(str)
	local bytes = {};

	local i=1;
	local byte = string.byte(str,i);
	while byte ~= nil do
		bytes[i] = byte;
		i = i + 1;
		byte = string.byte(str,i);
	end

	return bytes;

end

Array.toString = function(bytes)
	local chars = {};
	local i=1;

	local byte = bytes[i];
	while byte ~= nil do
		chars[i] = string.char(byte);
		i = i+1;
		byte = bytes[i];
	end

	return table.concat(chars,"");
end

local fromHexTable = {};
for i=0, 255 do
	fromHexTable[string.format("%02X",i)]=i;
	fromHexTable[string.format("%02x",i)]=i;
end

Array.fromHex = function(hex)
	local array = {};

	for i=1, string.len(hex)/2 do
		local h = string.sub(hex,i*2-1,i*2);
		array[i] = fromHexTable[h];
	end

	return array;
end


local toHexTable = {};
for i=0,255 do
	toHexTable[i]=string.format("%02X",i);
end

Array.toHex = function(array)
	local hex = {};
	local i = 1;

	local byte = array[i];
	while byte ~= nil do
		hex[i] = toHexTable[byte];
		i=i+1;
		byte = array[i];
	end

	return table.concat(hex,"");

end

Array.concat = function(a,b)
	local concat = {};
	local out=1;

	local i=1;
	local byte = a[i];
	while byte ~= nil do
		concat[out] = byte;
		i = i + 1;
		out = out + 1;
		byte = a[i];
	end

	local i=1;
	local byte = b[i];
	while byte ~= nil do
		concat[out] = byte;
		i = i + 1;
		out = out + 1;
		byte = b[i];
	end

	return concat;
end

Array.truncate = function(a,newSize)
	local x = {};

	for i=1,newSize do
		x[i]=a[i];
	end

	return x;
end

Array.xor = function(a,b)
	local x = {};

	for k,v in pairs(a) do
		x[k] = XOR(v,b[k]);
	end

	return x;
end

Array.substitute = function(input,sbox)
	local out = {};

	for k,v in pairs(input) do
		out[k] = sbox[v];
	end

	return out;
end

Array.permute = function(input,pbox)
	local out = {};

	for k,v in pairs(pbox) do
		out[k] = input[v];
	end

	return out;
end

Array.copy = function(input)
	local out = {};

	for k,v in pairs(input) do
		out[k] = v;
	end
	return out;
end

Array.slice = function(input,start,stop)
	local out = {};

	for i=start,stop do
		out[i-start+1] = input[i];
	end
	return out;
end

return Array;
