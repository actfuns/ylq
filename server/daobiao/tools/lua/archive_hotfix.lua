print('befor cpath',package.cpath)
package.cpath = 'tools/bin/mingw/?.dll;'..package.cpath
print('after cpath:',package.cpath)
local lfs = require "lfs"
local lzma = require "lzma"
local bit32 = require "bit32"
local ejoy_simple_enc = require "ejoy_simple_enc"

local arg, output, revision= ...
if not output then
    output = arg
end

if not revision then
  revision = 0
end

print("......................................")
print("........", revision)
print("......................................")

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

local totalsize = 0
local function dumpfile(filename)
    if filename:sub(-4) ~= ".lua" then
        return
    end

    -- local f = io.open(filename)
    -- local firstline = f:read "*l"
    -- f:close()

    local codedump
    --if firstline:sub(1,STRIP_SIG_LEN) == STRIP_SIG then
        -- 打包源码 会稍微小一点点
        codedump = _get_source(filename)
    --else
        -- 打包字节码, 更安全
    --    codedump = _get_bytecode(filename)
    --end

    local size = lfs.attributes(filename, "size")
    totalsize = totalsize + size
    codedump = codedump.."\n".."return "..revision
    return codedump
end

local result = dumpfile(arg)

print(totalsize)
print("compressing ", #result)

local compress = lzma.compress(result)
print("lzma:", #compress)
local encoded = ejoy_simple_enc.encode(compress)

print("write to ", output , #encoded)

local f = io.open(output,"wb")
f:write( encoded )
f:close()
