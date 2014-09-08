class = require("common.class")

----------------------------Event 事件类实现--------------------------------------------------
Event = class("Event")

function Event:__init(strEvent, data)
	self.strEvent = strEvent
	self.data = data
	self.target = false
end

----------------------------EventDispatcher 事件派发器实现--------------------------------------------
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

---------------------------EventManager实现-----------------------------------------------
eventmgr = EventDispatcher()

----------------------------Timer 定时器类实现--------------------------------------------
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

---------------------------增强版Table的定义(一个有长度的table, 还有一个强类型table)--------------------------------------------------

if not pairs_init then
	pairs_init = true
	oldpairs = pairs
	pairs = function(t)				--用于遍历 newHashTable() 和 newStrongTable() 返回的Table, 也可以遍历普通table
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
--返回一个哈希表,和{}不同的是,支持返回表的长度,
--				此表不能用table.insert插入数据; 不能用ipairs()遍历; 不能用next()
--				此表必须配合修改版的pairs遍历(另附)
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

--返回一个强类型表,和{}不同的是,成员的类型必须为初始化时定义的类型
--				此表不能用table.insert插入数据; 不能用ipairs()遍历; 不能用next()
--				此表必须配合修改版的pairs遍历(另附)
--				暂时还不支持不同class的类型检查.如果value存class的话,当table论.
--local t = newStrongTable({x=1, y=2})
--print(t.x)    输出1
--t.x = 5       成功
--t.x = nil     正常
--t.x = "haha"  抛异常     "haha"是字符串, 类型不匹配
--t.a = 123		也抛异常   a 未定义
--print(t.aaa)	更抛异常   aaa未定义
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
				ASSERT(m.data[key] or m.type[key], "读取失败. 属性[" .. tostring(key) .. "]无定义")
				return m.data[key]
			end
			meta.__newindex = setnew
			meta.__pairs = for_each
		end

		function for_each(t)
			return pairs(m.data)
		end

		function setnew(t, key, value)
			ASSERT(m.type[key], "赋值失败. 属性[" .. key .. "]无定义")
			ASSERT(m.type[key] == type(value) or value == nil, "属性[" .. key .. "]赋值失败. 类型不匹配. 定义:" .. m.type[key] .. " 新值:" .. type(value))
			rawset(m.data, key, value)
		end

		function reset()
			for k, v in pairs(m.members) do
				ASSERT(type(k) == "string" or type(k) == "number", "members 必须为一个全部字符串或者数字key的table")
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

