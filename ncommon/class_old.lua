----------------------------------------------------------------------------------------------------------------
-------------------------------------OOP实现----------------------------------------------------------
--[[
	class(classname[, super])
		参数
			classname :			 字符串,类名
			super:	 			 基类(可选)
		返回值
			新类
		例子1: 定义并使用类
			DClass = class("DClass")		--定义新类
			function DClass:__init(x)		--类构造函数
				self.x = x					--类成员
			end
			function DClass:foo(n)			--类方法
				assert(DClass.is(self))		--看self是不是DClass或者DClass派生类的实例
				return self.x * n
			end
			local c = DClass(2)				--声明类的实例
			print(c.x)						--访问类的成员  输出2
			print(c:foo(3))					--调用类的方法  输出6
			print(c)						--输出 [class instance of DClass : xxxxxxx]
			print(DClass.is(c))				--输出 true
			print(DClass.is(2))				--输出 false
		例子2: 继承
			DClassEx = class("DClassEx", DClass)
			local d = DClassEx(5)
			print(d.x)						--输出5
			print(DClass.is(d))				--输出 true
			print(DClassEx.is(d))			--输出 true
			print(DClassEx.is(c))			--输出 false
			print(d)						--输出 [class instance of DClassEx : xxxxxxx]
		例子3: 多态
			function DClassEx:foo(n)		--覆盖基类方法
				return self.x * n * 2
			end
			d.foo(2)	
		例子4: 封装
			DClass = class("DClass")		--定义类
			function DClass:__init(x)		--类构造函数
				local m = {}
				m.x = x						--私有成员
				function DClass:getx()		--类方法
					return m.x
				end		
			end
			local a = DClass(2)
			print(a.x)						--输出 nil
			print(a:getx())					--输出 2
		

--------------------------------------------------------------------------------------------------------------]]
local setmetatable = setmetatable
local getmetatable = getmetatable
local type = type
local assert = assert
local string = string
local tostring = tostring
module("common.class")

local _class={}
setmetatable(_class, {__mode = "k"})
function class(classname, super)
	assert(type(classname) == "string", "class name must be string")
	assert((not super) or (getmetatable(super) and getmetatable(super).__type == "class"), "super class must be class")
	local class_type = {}
	class_type.__init = false
	class_type.super = super
	class_type.__classname = classname
	local newclass = function(t, ...)
		local obj={}
		local strObj = string.match(tostring(obj), "^table: (%w*)$")
		do
			local create
			create = function(c,...)
				if c.super then
					create(c.super,...)
				end
				if c.__init then
					c.__init(obj,...)
				end
			end
			create(class_type,...)
		end
		setmetatable(obj,
			{
				__index= _class[class_type],
				__tostring = function()
					return "[class instance of " .. classname .. ": " .. strObj .. "]"
				end,
				__class = class_type,
				__classname = classname,
				__type = "instance",
			}
		)
		return obj
	end
	--判断传入的实例是不是这个类
	class_type.is = function(obj)
		local m = getmetatable(obj)
		if not m then return false end
		local currentClass = m.__class
		while currentClass.super do
			if currentClass.super.__classname == classname then
				return true
			else
				currentClass = currentClass.super
			end
		end
		return m.__classname == classname
	end
	local vtbl = {}
	_class[class_type] = vtbl
	setmetatable(class_type,
		{
			__newindex = function(t,k,v)
				vtbl[k]=v
			end,
			__tostring = function()
				return "[class define : " .. classname .. "]"
			end,
			__call = newclass,
			__classname = classname,
			__type = "class",
		}
	)
	if super then
		setmetatable(vtbl,
			{
				__index = function(t,k)
					local ret=_class[super][k]
					vtbl[k]=ret
					return ret
				end,
			}
		)
	end
	return class_type
end
