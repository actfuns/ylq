print('befor cpath',package.cpath)
package.cpath = '../converter/tools/lua/?.so;'..package.cpath
print('after cpath:',package.cpath)
local lfs = require "lfs"
local lzma = require "lzma"
local bit32 = require "bit32"
local ejoy_simple_enc = require "ejoy_simple_enc"

local arg, output= ...
if not output then
    output = arg
end

local STRIP_SIG = "--{STRIP}"
local STRIP_SIG_LEN = #STRIP_SIG

local function lenstr(size)
    return string.char(bit32.extract(size,24,8),bit32.extract(size,16,8),bit32.extract(size,8,8),bit32.extract(size,0,8))
end

function HexDumpString(str,spacer)
  return (
    string.gsub(str,"(.)",
      function (c)
         return string.format("%02X%s",string.byte(c), spacer or "")
        end)
     )
end

local function _error(...)
    print("!! ERROR !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    print(...)
    os.exit(false)
    assert(false)
end

local function _get_source(filename)
    local f = io.open(filename)
    local ret = f:read "*a"
    f:close()
    return ret
end

local function _get_bytecode(filename)
    local code, err = loadfile(filename)
    if not code then
        return _error(err)
    end

    local codedump, err = string.dump(code)

    if codedump == nil then
        return _error(err)
    end

    return codedump
end

local function dumpfile(filename, packname)
    if filename:sub(-4) ~= ".lua" then
        return
    end

    local f = io.open(filename)
    local firstline = f:read "*l"
    f:close()

    local codedump
    --if firstline:sub(1,STRIP_SIG_LEN) == STRIP_SIG then
        -- 打包源码 会稍微小一点点
        codedump = _get_source(filename)
    --else
        -- 打包字节码, 更安全
    --    codedump = _get_bytecode(filename)
    --end

    local size = #packname + 1 + #codedump
    print(packname, size, #codedump, HexDumpString(lenstr(size)))
    return lenstr(size) .. packname .. "\0" .. codedump
end

local function dumpdir(dirname, packname, entries)
  for name in lfs.dir(dirname) do
    if not (name == "." or name == "..") then
      local fullname = dirname .. "/" .. name
      if lfs.attributes(fullname,"mode") == "directory" then
        dumpdir(fullname, packname .. name .. "/",  entries)
      else
        table.insert(entries, {fullname, packname..name})
      end
    end
  end
end

local entries = {}
dumpdir(arg, "", entries)

table.sort(entries, function(lhs, rhs)
  return lhs[1] < rhs[1]
end)

local result = {}
for _, entry in ipairs(entries) do
  local fullname = entry[1]
  local packname = entry[2]
  local c = dumpfile(fullname, packname)
  if c then
    table.insert(result, c)
  end
end

local all = table.concat(result)

print("compressing ", #all)

local compress = lzma.compress(all)
print("lzma:", #compress)
local encoded = ejoy_simple_enc.encode(compress)

print("write to ", output , #encoded)

local f = io.open(output,"wb")
f:write( encoded )
f:close()
