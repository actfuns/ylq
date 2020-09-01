local READ_ME = [[

]]

local output_dir,file_list = ...

local tbl_dumper = require('table_dumper')
local infos = assert(loadfile(file_list, 't'))()

local rlt = {}
local tex_cnt = #infos
for k,v in ipairs(infos) do
	local ppm = io.open(output_dir..'/'..v..'.ppm','rb')
	local l = ppm:read("*l")
	l = ppm:read("*l")
	local w_str,h_str = l:match("(%d+) (%d+)")
	local w, h = assert(tonumber(w_str)), assert(tonumber(h_str))
	local ii  = {}
	ii[1] = w
	ii[2] = h
	rlt[v] = ii 
end

local desc_str = tbl_dumper(rlt)
local desc_file = io.open(output_dir..'/tex_info.txt','wb')
desc_file:write(desc_str)
desc_file:close()

desc_file = io.open(output_dir..'_bin/tex_info.txt','wb')
desc_file:write(desc_str)
desc_file:close()