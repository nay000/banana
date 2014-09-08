----------------------------------------------------------------------------------------------------------------
-------------------------------------OOPʵ��----------------------------------------------------------
--[[
	class(classname[, super])
		����
			classname :			 �ַ���,����
			super:	 			 ����(��ѡ)
		����ֵ
			����
		����1: ���岢ʹ����
			DClass = class("DClass")		--��������
			function DClass:__init(x)		--�๹�캯��
				self.x = x					--���Ա
			end
			function DClass:foo(n)			--�෽��
				assert(DClass.is(self))		--��self�ǲ���DClass����DClass�������ʵ��
				return self.x * n
			end
			local c = DClass(2)				--�������ʵ��
			print(c.x)						--������ĳ�Ա  ���2
			print(c:foo(3))					--������ķ���  ���6
			print(c)						--��� [class instance of DClass : xxxxxxx]
			print(DClass.is(c))				--��� true
			print(DClass.is(2))				--��� false
		����2: �̳�
			DClassEx = class("DClassEx", DClass)
			local d = DClassEx(5)
			print(d.x)						--���5
			print(DClass.is(d))				--��� true
			print(DClassEx.is(d))			--��� true
			print(DClassEx.is(c))			--��� false
			print(d)						--��� [class instance of DClassEx : xxxxxxx]
		����3: ��̬
			function DClassEx:foo(n)		--���ǻ��෽��
				return self.x * n * 2
			end
			d.foo(2)	
		����4: ��װ
			DClass = class("DClass")		--������
			function DClass:__init(x)		--�๹�캯��
				local m = {}
				m.x = x						--˽�г�Ա
				function DClass:getx()		--�෽��
					return m.x
				end		
			end
			local a = DClass(2)
			print(a.x)						--��� nil
			print(a:getx())					--��� 2
		

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
	--�жϴ����ʵ���ǲ��������
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
