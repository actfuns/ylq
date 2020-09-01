local READ_ME = [[

]]

local bit32 = require "bit32"
local ppm = require "ppm"
local epconv = require "epconv"
local lzma = require "lzma"
local pvr = require "pvr"

local filename, target, model, compress, extra_alpha = ...

local memfile = { result = {} }

function memfile:write(str)
	table.insert(self.result, str)
end

local TEXTURE4 = 0
local TEXTURE8 = 1
local DATA = 2
local PVRTC = 3
local KTX = 4
local PKM = 5
local PKMC = 6
local JPG = 7

local function wstring(f,s)
	if s == nil then
		f:write(string.char(255))
	else
		assert (#s < 255)
		f:write(string.char(#s))
		f:write(s)
	end
end

local function wchar(f,c)
	f:write(string.char(c))
end

local function wshort(f,c)
	assert(c> -0x8000 and c < 0x8000)
	f:write(string.char(bit32.extract(c,0,8),bit32.extract(c,8,8)))
end

local function wlong(f,c)
	f:write(string.char(bit32.extract(c,0,8),bit32.extract(c,8,8),bit32.extract(c,16,8),bit32.extract(c,24,8)))
end

local function load_pvr(filename)
	memfile.result = {}
	local w,h,internal_format,data_table = pvr.load(filename..".pvr")
	print("Gen pvr image",w,h,internal_format)
	wchar(memfile, PVRTC)
	assert(internal_format == 4 or internal_format == 2)
	wchar(memfile, internal_format)
	wshort(memfile, w)
	wshort(memfile, h)
	for i=1,#data_table do
		wlong(memfile, string.len(data_table[i]))
		table.insert(memfile.result, data_table[i])
	end
	return table.concat(memfile.result)
end

local function load_ktx(filename)
	local ktx = require "ktx"
	memfile.result = {}
	local w,h,size,data = ktx.read(filename..".ktx")
	print("Gen ktx image",w,h,filename)
	wchar(memfile, KTX)
	wshort(memfile, w)
	wshort(memfile, h)
	wlong(memfile, size)
	table.insert(memfile.result, data)
	return table.concat(memfile.result)
end

local function load_pkm(filename)
	local pkm = require "pkm"
	memfile.result = {}
	local w,h,rgb,alpha = pkm.read(filename)
	print("Gen pkm image",w,h,filename)
	wchar(memfile, PKM)
	wshort(memfile, w)
	wshort(memfile, h)
	table.insert(memfile.result, rgb)
	table.insert(memfile.result, alpha)
	return table.concat(memfile.result)
end

local function load_pkmc(filename)
	local pkmc = require "pkmc"
	memfile.result = {}
	local w,h,rgb,alpha = pkmc.read(filename)
	print("Gen pkm image",w,h,filename)
	wchar(memfile, PKMC)
	wshort(memfile, w)
	wshort(memfile, h)
	table.insert(memfile.result, rgb)
	table.insert(memfile.result, alpha)
	return table.concat(memfile.result)
end

local function load_dds(filename)
	memfile.result = {}
	local w,h,data = dds.read(filename..".dds")
	print("Gen dds image",w,h,filename)
	wchar(memfile, DDS)
	wshort(memfile, w)
	wshort(memfile, h)
	table.insert(memfile.result, data)
	return table.concat(memfile.result)
end

local function _load(filename, func)
	memfile.result = {}
	local w,h,depth,data = func(filename)
	print("Gen image",w,h,depth)
	if depth == 15 then
		wchar(memfile, TEXTURE4)
	elseif depth ==  255 then
		wchar(memfile, TEXTURE8)
	else
		error("Unsupport depth", depth)
	end
	wshort(memfile, w)
	wshort(memfile, h)
	table.insert(memfile.result, data)
	return table.concat(memfile.result)
end

local function load_png(filename)
	local png = require "png"
	return _load(filename..".png", function (name)
		return png.read(name, model)
		end)
end

local function load_jpg(filename)
	memfile.result = {}
	wchar(memfile, JPG)
	wchar(memfile, extra_alpha and 1 or 0)
	local f = io.open(filename..".jpg", "rb")
    local data = f:read("*all")
    f:close()

	wlong(memfile,#data)
	table.insert(memfile.result, data)
	--print('-------->>>file name',filename,#data)
	if extra_alpha then
		local png = require "png_test"
		local w,h,cmp,img = png.read_alpha(filename..'.alpha.png')
		table.insert(memfile.result,img)
		print('\t-------->>>alpha size',w,h,cmp,#img)	
	end
	return table.concat(memfile.result)
end

local function load_ppm(filename)
	return _load(filename, ppm)
end

local write_block

if compress == "0" then

function write_block(f, t)
	wlong(f, -#t)
	f:write(t)
end

else

function write_block(f, t)
	print('------>> hehhe',#t)
	local c = lzma.compress(t)
	wlong(f, #c)
	print('------------>> write block ',#c)
	f:write(c)
end

end

-- filename = string.match(filename, "(.*)%..*$")

local gm_filename, gm_load = nil, nil

if model == "-ppm" then
	gm_load = load_ppm
	gm_filename = filename.."."
elseif model =="-png8"  or model=="-png4" then
	gm_load = load_png
	gm_filename = filename
elseif model =="-pvr" then
	gm_load = load_pvr
	gm_filename = filename
elseif model == "-ktx" then
	gm_load = load_ktx
	gm_filename = filename
elseif model == "-pkm" then
	gm_load = load_pkm
	gm_filename = filename
elseif model == "-jpg8" then
	gm_load = load_jpg
	gm_filename = filename	
elseif model == "-pkmc" then
	gm_load = load_pkmc
	gm_filename = filename
-- elseif model == "-dds" then
-- 	gm_load = load_dds
-- 	gm_filename = filename
else
	print(READ_ME)
	error("not match ppm or png  model.")
end

-- gen pic data
local function gen_epp(f_epp)
	local t = gm_load(gm_filename)
	write_block(f_epp, t)
end

local f = io.open(target..".epp", "wb")
gen_epp(f)
f:close()


