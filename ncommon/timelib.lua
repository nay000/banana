
-- 时间相关基本操作
timelibbk = timelib
timelib = {}

if timelibbk ~= nil then
	timelib = timelibbk
end

--- 
timelib.timeline  = {}
timelib.time = os.time()
timelib.lasttime = timelib.time

--入口
timelib.ontimecheck = function()
	timelib.time = os.time()
	if timelib.lasttime < timelib.time then
		for i = timelib.lasttime, timelib.time do
			if timelib.timeline[i] then
				for j = 1, #timelib.timeline[i] do
					xpcall(function() timelib.timeline[i][j](); end, throw) 
				end
				timelib.timeline[i] = nil
			end
		end --for i
		for i = timelib.lasttime + 1, timelib.time do
			--TraceError("dispatch " .. os.time() .. debug.traceback())
			eventmgr:dispatchEvent(Event("timer_second", {time = i}));
		end
	end --if
	timelib.lasttime = timelib.time
end

--创建计划
timelib.createplan = function(callback, delay)
	assert(type(callback) == "function")
	assert(type(delay) == "number" and delay > 0)
	local raise_time = timelib.time + delay
	if not timelib.timeline[raise_time] then
		timelib.timeline[raise_time] = {}
	end
	table.insert(timelib.timeline[raise_time], callback)
	local inx = #timelib.timeline[raise_time]

	local cancel = function()
		if timelib.timeline[raise_time] then
			timelib.timeline[raise_time][inx] = NULL_FUNC
		end
	end
  local run = function()
    callback()
		cancel()
  end
  local getlefttime = function()
    return raise_time - timelib.time
  end
  
	return
	{
		cancel = cancel,
		run = run,
		getlefttime = getlefttime,
	}
end

--lua时间转换为数据库时间格式
timelib.lua_to_db_time = function(lua_time)
	if type(lua_time) ~= "number" then
		error("lua_to_db_time传递了错误的时间格式")
		return "1970-1-1 0:0:0"
	end
    return os.date("%Y-%m-%d %X", lua_time)
end

--数据库时间转换为lua时间格式
timelib.db_to_lua_time = function(db_time)
	local time = {}
	for i in string.gmatch(db_time, "%d+") do
		table.insert(time, i)
	end
	--防止超过整型最大值
	if(tonumber(time[1])>2036)then
		time[1] = 2036
	end
	local lua_time = os.time{year = time[1], month = time[2], day = time[3], hour = time[4], min = time[5], sec = time[6]}
	return lua_time
end

--返回一个空table,和普通table不同的是, 这个table的元素会自动超时并删除 seconds传入超时时间 (删除时机是增加新元素的时候)
timelib.newTimeoutTable = function(seconds, callback_timeout)
	local nseconds = seconds
	local ret = {}
	local data = {}
	local m = {}
	m.__index = function(tbl, key)
		local v = data[key]
		if not v then return end
		return v.value;
	end
	m.__newindex = function(tbl, key, value)
		data[key] =
		{
			["value"] = value,
			["del_plan"] = timelib.createplan(function()
				if callback_timeout ~= nil then
					xpcall(function() callback_timeout(value) end, throw)
				end
				data[key] = nil
			end, nseconds),
		}
	end
	ret.delItem = function(key)
		if data[key] then
			data[key].del_plan.cancel()
			data[key] = nil
		end
	end
	ret.showCount = function()
		local c = 0
		for k, v in pairs(data) do
			c = c + 1
		end
		TraceError(c)
	end
	setmetatable(ret, m)
	return ret
end

--是否在某天0点之前
timelib.is_before_today = function(time)
    local tableTime = os.date("*t",os.time())
    local endtime = os.time{year = tableTime.year, month = tableTime.month, day = tableTime.day, hour = 0}
    if time < endtime then
        return true, endtime
    else
        return false, endtime
    end
end

--得到某天0点的秒数
timelib.get_today_zero_sec = function(time)
    local tableTime = os.date("*t",time)
    local endtime = os.time{year = tableTime.year, month = tableTime.month, day = tableTime.day, hour = 0}
    return endtime
end


--是不是在同一天
function timelib.is_today(time1,time2)
    if time1==nil or time2==nil or time1=="" or time2=="" then return 0 end
	local table_time1 = os.date("*t",time1);
	local year1  = table_time1.year;
	local month1 = table_time1.month;
	local day1 = table_time1.day;
	local time1 = year1.."-"..month1.."-"..day1.." 00:00:00"
	
	local table_time2 = os.date("*t",time2);
	local year2  = tonumber(table_time2.year);
	local month2 = tonumber(table_time2.month);
	local day2 = tonumber(table_time2.day);
	local time2 = year2.."-"..month2.."-"..day2.." 00:00:00"
	
	--容错处理，如果时间拿到空的，会得到1970年
	if tonumber(year1)<2012 or tonumber(year2)<2012 then 
		return 0 
	end
	if time1~=time2 then
		return 0
	end
	return 1
	
end

-------------------------------------------------------------------------------
-- 泛型for 枚举 时间段 跨越的天数
-- start_time, end_time = 起始日期, 终止日期
-- timelib.enum_day 使用 lua time 作为参数 遍历 经过的天数 
-- 用法：for i, eunm_day in timelib.enum_day(start_time, end_time) do
-- i, eunm_day = 天数计数, 那一天的0点的 lua 时间
-------------------------------------------------------------------------------

function timelib.enum_day(start_time, end_time)
    local date = function (lua_time)
        local t = os.date("*t", lua_time)  
        return os.time{year = t.year; month = t.month; day = t.day; hour = 0; min = 0; sec = 0;}
    end
    local start_date = date(start_time)
    local itor = function (x, i)
        local eunm_day = start_date + i * 86400    
        i = i + 1
        if (eunm_day <= end_time) then
            return i, eunm_day
        end
        return nil
    end
    return itor, nil, 0
end

-------------------------------------------------------------------------------
-- 时间文本 转换为时间结构体
-- time_txt = 时间文本 时:分:秒 形如 "02:15:30"
-- 用法: time_struct("02:15:30") return {hour = 02; min = 15; sec = 30}
-------------------------------------------------------------------------------

function timelib.time_struct(time_txt)
    local arr = {}
    for num_str in string.gmatch(time_txt, "%d+") do
        table.insert(arr, tonumber(num_str))
    end
    return {hour = arr[1] or 0; min = arr[2] or 0; sec = arr[3] or 0}
end

-------------------------------------------------------------------------------
-- 日期文本 转换为日期结构体
-- date_txt = 时间文本 年-月-日 时:分:秒 形如 "2014-04-01 02:15:30"
-- 用法: date_struct("2014-04-01 02:15:30") return {year = 2014; month = 04; day = 01; hour = 02; min = 15; sec = 30}
-------------------------------------------------------------------------------

function timelib.date_struct(date_txt)
    local arr = {}
    for num_str in string.gmatch(date_txt, "%d+") do
        table.insert(arr, tonumber(num_str))
    end
    return {year = arr[1] or 1970; month = arr[2] or 1; day = arr[3] or 1; hour = arr[4] or 0; min = arr[5] or 0; sec = arr[6] or 0}
end

-------------------------------------------------------------------------------
-- 检查时间段 是否 包含指定时间
-- start_time, end_time, time_txt = 起始日期, 终止日期, 检查时间点
-- 使用 格式化的 时间日期 文本作为参数
-- ps: f("2014-04-01 14:00:01", "2014-04-01 16:00:00", "14:00:00")
-------------------------------------------------------------------------------

function timelib.check_period_on_time(start_time, end_time, time_txt)
--    timelib.lua_to_db_time(123)
--    timelib.db_to_lua_time("2014-04-01 02:00:00")
    local st = timelib.db_to_lua_time(start_time)
    local et = timelib.db_to_lua_time(end_time)
    local tm = timelib.time_struct(time_txt)

    for i, eunm_day in timelib.enum_day(st, et) do
        local the_time = os.date("*t", eunm_day)
        the_time.hour = tm.hour;
        the_time.min  = tm.min;
        the_time.sec  = tm.sec;
        local lua_time = os.time(the_time)
        if (lua_time >= st and lua_time <= et) then
            return 1
        end
    end
    return 0
end

-------------------------------------------------------------------------------
-- 日期文本和时间文本合并 转换为lua时间结构体
-- date_txt = 时间文本 年-月-日 时:分:秒 形如 "2014-04-01 12:00:00" 
-- time_txt = 时间文本 时:分:秒 形如 "02:15:30"
-- 用法: add_time("2014-04-01 12:00:00", "02:15:30") return {year = 2014; month = 4; day = 1hour = 02; min = 15; sec = 30}
-------------------------------------------------------------------------------
function timelib.add_time(date_txt, time_txt)
    local time1 = timelib.date_struct(date_txt)
    local time2 = timelib.time_struct(time_txt)
    time1.hour = time2.hour;
    time1.min  = time2.min;
    time1.sec  = time2.sec;
    return time1
end

