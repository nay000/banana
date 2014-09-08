class = require("common.class")

----------------------------Event �¼���ʵ��--------------------------------------------------
Event = class("Event")

function Event:__init(strEvent, data)
	self.strEvent = strEvent
	self.data = data
	self.target = false
end

----------------------------EventDispatcher �¼��ɷ���ʵ��--------------------------------------------
EventDispatcher = class("EventDispatcher")

function EventDispatcher:__init()
	self.eventList = {}
end

function EventDispatcher:addEventListener(strEvent, func)
	if _DEBUG then
		ASSERT(EventDispatcher.is(self), "you must use ':' instead of '.' to call method")
		ASSERT(strEvent and type(strEvent) == "string", "event name is nil or not string")
		ASSERT(func and type(func) == "function", "function is nil")
	end
	if not self.eventList[strEvent] then self.eventList[strEvent] = {} end
	self.eventList[strEvent][func] = 1
end

function EventDispatcher:removeEventListener(strEvent, func)
	if _DEBUG then
		ASSERT(EventDispatcher.is(self), "you must use ':' instead of '.' to call method")
		ASSERT(strEvent and type(strEvent) == "string", "event name is nil")
		ASSERT(func and type(func) == "function", "function is nil")
	end
	if self.eventList[strEvent] then
		self.eventList[strEvent][func] = nil
	end
end

function EventDispatcher:removeAllEventListener(strEvent)
	if _DEBUG then
		ASSERT(EventDispatcher.is(self), "you must use ':' instead of '.' to call method")
		ASSERT(strEvent and type(strEvent) == "string", "event name is nil")
	end
	if self.eventList[strEvent] then
		self.eventList[strEvent] = {}
	end
end

function EventDispatcher:hasEventListener(strEvent)
	if _DEBUG then
		ASSERT(EventDispatcher.is(self), "you must use ':' instead of '.' to call method")
		ASSERT(strEvent and type(strEvent) == "string", "event name is nil or not string")
	end
	if self.eventList[strEvent] then
		return self.eventList[strEvent][func]
	end
end

function EventDispatcher:dispatchEvent(eventNew)
	if _DEBUG then
		ASSERT(EventDispatcher.is(self), "you must use ':' instead of '.' to call method")
		ASSERT(Event.is(eventNew), "eventNew is not Event")
	end
	eventNew.target = self
	if self.eventList[eventNew.strEvent] then
		for k, v in pairs(self.eventList[eventNew.strEvent]) do
			xpcall(function()
				k(eventNew)
			end, throw)
		end
	end
end

---------------------------EventManagerʵ��-----------------------------------------------
eventmgr = EventDispatcher()

----------------------------Timer ��ʱ����ʵ��--------------------------------------------
g_timerchecklist = {}
Timer = class("Timer", EventDispatcher)

function Timer:__init(seconds)
    self.seconds = seconds or 0
    self.lastraise = 0
    function Timer:start()
        ASSERT(Timer.is(self), "you must use ':' instead of '.' to call method")
        self.lastraise = os.time()
        g_timerchecklist[self] = 1
    end
    
    function Timer:stop()
        ASSERT(Timer.is(self), "you must use ':' instead of '.' to call method")
        g_timerchecklist[self] = nil
    end
end

---------------------------��ǿ��Table�Ķ���(һ���г��ȵ�table, ����һ��ǿ����table)--------------------------------------------------

if not pairs_init then
	pairs_init = true
	oldpairs = pairs
	pairs = function(t)				--���ڱ��� newHashTable() �� newStrongTable() ���ص�Table, Ҳ���Ա�����ͨtable
		if _DEBUG then
			local meta = getmetatable(t)
			if meta and meta.__pairs then
				return meta.__pairs(t)
			else
				return oldpairs(t)
			end
		else
			if (t == nil) then
				TraceError(debug.traceback())
			end
			return oldpairs(t)
		end
	end
end
--����һ����ϣ��,��{}��ͬ����,֧�ַ��ر�ĳ���,
--				�˱�����table.insert��������; ������ipairs()����; ������next()
--				�˱��������޸İ��pairs����(��)
--local t = newHashTable()
--print(t:getlength())
function newHashTable()
	local DHashTable = class("DHashTable")
	function DHashTable:__init()
		local m = {}
		m.data = {}
		m.length = 0
		local setnew
		local for_each

		function DHashTable:init()
			local meta = getmetatable(self)
			setmetatable(m.data, { __index = meta.__index})
			meta.__index = m.data
			meta.__newindex = setnew
			meta.__pairs = for_each
		end

		function for_each(t)
			return pairs(m.data)
		end

		function setnew(t, key, value)
			if rawget(m.data, key) then
				if value == nil then
					m.length = m.length - 1
				end
			else
				if value ~= nil then
					m.length = m.length + 1
				end
			end
			rawset(m.data, key, value)
		end

		function DHashTable:getlength()
			ASSERT(DHashTable.is(self), "you must use ':' instead of '.' to call method")
			return m.length
		end
	end
	local t = DHashTable()
	t:init()
	return t
end

--����һ��ǿ���ͱ�,��{}��ͬ����,��Ա�����ͱ���Ϊ��ʼ��ʱ���������
--				�˱�����table.insert��������; ������ipairs()����; ������next()
--				�˱��������޸İ��pairs����(��)
--				��ʱ����֧�ֲ�ͬclass�����ͼ��.���value��class�Ļ�,��table��.
--local t = newStrongTable({x=1, y=2})
--print(t.x)    ���1
--t.x = 5       �ɹ�
--t.x = nil     ����
--t.x = "haha"  ���쳣     "haha"���ַ���, ���Ͳ�ƥ��
--t.a = 123		Ҳ���쳣   a δ����
--print(t.aaa)	�����쳣   aaaδ����
function newStrongTable(members)
	if not _DEBUG then
		return members
	end
	local DStrongTable = class("DStrongTable")
	function DStrongTable:__init()
		local m = {}
		m.data = {}
		m.members = {}
		m.type = {}
		local setnew
		local for_each
		local reset

		function DStrongTable:init(members)
			ASSERT(type(members) == "table")
			m.members = members
			reset()
			local meta = getmetatable(self)
			setmetatable(m.data, { __index = meta.__index})
			meta.__index = function(t, key)
				ASSERT(m.data[key] or m.type[key], "��ȡʧ��. ����[" .. tostring(key) .. "]�޶���")
				return m.data[key]
			end
			meta.__newindex = setnew
			meta.__pairs = for_each
		end

		function for_each(t)
			return pairs(m.data)
		end

		function setnew(t, key, value)
			ASSERT(m.type[key], "��ֵʧ��. ����[" .. key .. "]�޶���")
			ASSERT(m.type[key] == type(value) or value == nil, "����[" .. key .. "]��ֵʧ��. ���Ͳ�ƥ��. ����:" .. m.type[key] .. " ��ֵ:" .. type(value))
			rawset(m.data, key, value)
		end

		function reset()
			for k, v in pairs(m.members) do
				ASSERT(type(k) == "string" or type(k) == "number", "members ����Ϊһ��ȫ���ַ�����������key��table")
				m.type[k] = type(v)
				rawset(m.data, k, v)
			end
		end
	end
	local t = DStrongTable()
	t:init(members)
	return t
end

_S = newStrongTable

