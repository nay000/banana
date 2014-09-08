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
local type = type
local assert = assert
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
module("common.class")

local middleclass = {
  _VERSION = 'middleclass v3.0.1',
  _DESCRIPTION = 'Object Orientation for Lua',
  _URL = 'https://github.com/kikito/middleclass',
  _LICENSE = [[
MIT LICENSE

Copyright (c) 2011 Enrique García Cota

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
}

local function _setClassDictionariesMetatables(aClass)
  local dict = aClass.__instanceDict
  dict.__index = dict

  local super = aClass.super
  if super then
    local superStatic = super.static
    setmetatable(dict, super.__instanceDict)
    setmetatable(aClass.static, { __index = function(_,k) return dict[k] or superStatic[k] end })
  else
    setmetatable(aClass.static, { __index = function(_,k) return dict[k] end })
  end
end

local function _setClassMetatable(aClass)
  setmetatable(aClass, {
    __tostring = function() return "class " .. aClass.name end,
    __index = aClass.static,
    __newindex = aClass.__instanceDict,
    __call = function(self, ...) return self:new(...) end
  })
end

local function _createClass(name, super)
  local aClass = { name = name, super = super, static = {}, __mixins = {}, __instanceDict={} }
  aClass.subclasses = setmetatable({}, {__mode = "k"})

  _setClassDictionariesMetatables(aClass)
  _setClassMetatable(aClass)

  return aClass
end

local function _createLookupMetamethod(aClass, name)
  return function(...)
    local method = aClass.super[name]
    assert( type(method)=='function', tostring(aClass) .. " doesn't implement metamethod '" .. name .. "'" )
    return method(...)
  end
end

local function _setClassMetamethods(aClass)
  for _,m in ipairs(aClass.__metamethods) do
    aClass[m]= _createLookupMetamethod(aClass, m)
  end
end

local function _setDefaultInitializeMethod(aClass, super)
  aClass.__init = function(instance, ...)
    --return super.__init(instance, ...)
  end
end

local function _includeMixin(aClass, mixin)
  assert(type(mixin)=='table', "mixin must be a table")
  for name,method in pairs(mixin) do
    if name ~= "included" and name ~= "static" then aClass[name] = method end
  end
  if mixin.static then
    for name,method in pairs(mixin.static) do
      aClass.static[name] = method
    end
  end
  if type(mixin.included)=="function" then mixin:included(aClass) end
  aClass.__mixins[mixin] = true
end

local Object = _createClass("Object", nil)

Object.static.__metamethods = { '__add', '__call', '__concat', '__div', '__ipairs', '__le',
                                '__len', '__lt', '__mod', '__mul', '__pairs', '__pow', '__sub',
                                '__tostring', '__unm'}

function Object.static:allocate()
  assert(type(self) == 'table', "Make sure that you are using 'Class:allocate' instead of 'Class.allocate'")
  return setmetatable({ class = self }, self.__instanceDict)
end


function Object.static:new(...)
    local instance = self:allocate()
    local function _initInstance(class, instance, ...)
        if (class.super) then
            _initInstance(class.super, instance, ...)
        end
        if (class.__init) then
            class.__init(instance, ...)
        end
    end
    _initInstance(self, instance, ...)
    return instance
end



function Object.static:subclass(name)
  assert(type(self) == 'table', "Make sure that you are using 'Class:subclass' instead of 'Class.subclass'")
  assert(type(name) == "string", "You must provide a name(string) for your class")

  local subclass = _createClass(name, self)
  _setClassMetamethods(subclass)
  _setDefaultInitializeMethod(subclass, self)
  self.subclasses[subclass] = true
  self:subclassed(subclass)

  return subclass
end

function Object.static:subclassed(other) end

function Object.static:isSubclassOf(other)
  return type(other) == 'table' and
         type(self) == 'table' and
         type(self.super) == 'table' and
         ( self.super == other or
           type(self.super.isSubclassOf) == 'function' and
           self.super:isSubclassOf(other)
         )
end

function Object.static:include( ... )
  assert(type(self) == 'table', "Make sure you that you are using 'Class:include' instead of 'Class.include'")
  for _,mixin in ipairs({...}) do _includeMixin(self, mixin) end
  return self
end

function Object.static:includes(mixin)
  return type(mixin) == 'table' and
         type(self) == 'table' and
         type(self.__mixins) == 'table' and
         ( self.__mixins[mixin] or
           type(self.super) == 'table' and
           type(self.super.includes) == 'function' and
           self.super:includes(mixin)
         )
end

function Object:__init() end

function Object:__tostring() return "instance of " .. tostring(self.class) end

function Object:isInstanceOf(aClass)
  return type(self) == 'table' and
         type(self.class) == 'table' and
         type(aClass) == 'table' and
         ( aClass == self.class or
           type(aClass.isSubclassOf) == 'function' and
           self.class:isSubclassOf(aClass)
         )
end



function middleclass.class(name, super, ...)
  super = super or Object
  return super:subclass(name, ...)
end

middleclass.Object = Object

setmetatable(middleclass, { __call = function(_, ...) return middleclass.class(...) end })

return middleclass
