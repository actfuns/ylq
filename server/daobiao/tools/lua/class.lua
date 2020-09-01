-- [[
--  为热更新提供支持的类，尽量兼容penlight的class
-- ]]


local M = {}

function M.super(cls)
	return getmetatable(cls).__index
end

--判断一个class或者对象是否
function M.is_a(cls_or_obj, other_cls)
	local tmp = cls_or_obj
	while true do
		local mt = getmetatable(tmp)
		if mt then
			tmp = mt.__index
			if tmp == other_cls then
				return true
			end
		else
			return false
		end
	end
end

--没有一个比较好的方法来防止将Class的table当成一个实例来使用
--命名一个Class的时候一定要和其产生的实例区别开来。
local Class = {
		--用于区别是否是一个对象 or Class or 普通table
		__ClassType__ = "<base class>"
}
Class.__index = Class
M.Class = Class

function Class:Inherit()	
	local o = {}
    o.__index = o
    o.__ClassType__ = '<base class>'
    
    if self.__tostring then
        o.__tostring = self.__tostring
    end
	return setmetatable(o, self)
end

function Class:New(...)
	local o = {}

	--子类，应该在自己的init函数中调用父类的init函数
	setmetatable(o, self)
    o._class = self -- TODO 多消耗点内存，考虑要不要

    if o._init then
		o:_init(...)
	end
	return o
end

function Class:is_a(other_cls)
	return M.is_a(self, other_cls)
end

-- 没事还是用 Pattern.XXX 代替 self:super().XXX 吧
function Class:super()
    return M.super(getmetatable(self))
end

function Class:__tostring()
    local mt = getmetatable(self)
    local tbl_str = tostring(setmetatable(self, {}))
    setmetatable(self, mt)
    if self._class then
        return self._class.__ClassType__ .. '实例: ' .. tbl_str
    else
        return self.__ClassType__ .. '类:' .. tbl_str
    end
end

return M

