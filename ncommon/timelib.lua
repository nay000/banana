
-- ʱ����ػ�������
timelibbk = timelib
timelib = {}

if timelibbk ~= nil then
	timelib = timelibbk
end

--- 
timelib.timeline  = {}
timelib.time = os.time()
timelib.lasttime = timelib.time

--���
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

--�����ƻ�
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

--luaʱ��ת��Ϊ���ݿ�ʱ���ʽ
timelib.lua_to_db_time = function(lua_time)
	if type(lua_time) ~= "number" then
		error("lua_to_db_time�����˴����ʱ���ʽ")
		return "1970-1-1 0:0:0"
	end
    return os.date("%Y-%m-%d %X", lua_time)
end

--���ݿ�ʱ��ת��Ϊluaʱ���ʽ
timelib.db_to_lua_time = function(db_time)
	local time = {}
	for i in string.gmatch(db_time, "%d+") do
		table.insert(time, i)
	end
	--��ֹ�����������ֵ
	if(tonumber(time[1])>2036)then
		time[1] = 2036
	end
	local lua_time = os.time{year = time[1], month = time[2], day = time[3], hour = time[4], min = time[5], sec = time[6]}
	return lua_time
end

--����һ����table,����ͨtable��ͬ����, ���table��Ԫ�ػ��Զ���ʱ��ɾ�� seconds���볬ʱʱ�� (ɾ��ʱ����������Ԫ�ص�ʱ��)
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

--�Ƿ���ĳ��0��֮ǰ
timelib.is_before_today = function(time)
    local tableTime = os.date("*t",os.time())
    local endtime = os.time{year = tableTime.year, month = tableTime.month, day = tableTime.day, hour = 0}
    if time < endtime then
        return true, endtime
    else
        return false, endtime
    end
end

--�õ�ĳ��0�������
timelib.get_today_zero_sec = function(time)
    local tableTime = os.date("*t",time)
    local endtime = os.time{year = tableTime.year, month = tableTime.month, day = tableTime.day, hour = 0}
    return endtime
end


--�ǲ�����ͬһ��
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
	
	--�ݴ������ʱ���õ��յģ���õ�1970��
	if tonumber(year1)<2012 or tonumber(year2)<2012 then 
		return 0 
	end
	if time1~=time2 then
		return 0
	end
	return 1
	
end

-------------------------------------------------------------------------------
-- ����for ö�� ʱ��� ��Խ������
-- start_time, end_time = ��ʼ����, ��ֹ����
-- timelib.enum_day ʹ�� lua time ��Ϊ���� ���� ���������� 
-- �÷���for i, eunm_day in timelib.enum_day(start_time, end_time) do
-- i, eunm_day = ��������, ��һ���0��� lua ʱ��
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
-- ʱ���ı� ת��Ϊʱ��ṹ��
-- time_txt = ʱ���ı� ʱ:��:�� ���� "02:15:30"
-- �÷�: time_struct("02:15:30") return {hour = 02; min = 15; sec = 30}
-------------------------------------------------------------------------------

function timelib.time_struct(time_txt)
    local arr = {}
    for num_str in string.gmatch(time_txt, "%d+") do
        table.insert(arr, tonumber(num_str))
    end
    return {hour = arr[1] or 0; min = arr[2] or 0; sec = arr[3] or 0}
end

-------------------------------------------------------------------------------
-- �����ı� ת��Ϊ���ڽṹ��
-- date_txt = ʱ���ı� ��-��-�� ʱ:��:�� ���� "2014-04-01 02:15:30"
-- �÷�: date_struct("2014-04-01 02:15:30") return {year = 2014; month = 04; day = 01; hour = 02; min = 15; sec = 30}
-------------------------------------------------------------------------------

function timelib.date_struct(date_txt)
    local arr = {}
    for num_str in string.gmatch(date_txt, "%d+") do
        table.insert(arr, tonumber(num_str))
    end
    return {year = arr[1] or 1970; month = arr[2] or 1; day = arr[3] or 1; hour = arr[4] or 0; min = arr[5] or 0; sec = arr[6] or 0}
end

-------------------------------------------------------------------------------
-- ���ʱ��� �Ƿ� ����ָ��ʱ��
-- start_time, end_time, time_txt = ��ʼ����, ��ֹ����, ���ʱ���
-- ʹ�� ��ʽ���� ʱ������ �ı���Ϊ����
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
-- �����ı���ʱ���ı��ϲ� ת��Ϊluaʱ��ṹ��
-- date_txt = ʱ���ı� ��-��-�� ʱ:��:�� ���� "2014-04-01 12:00:00" 
-- time_txt = ʱ���ı� ʱ:��:�� ���� "02:15:30"
-- �÷�: add_time("2014-04-01 12:00:00", "02:15:30") return {year = 2014; month = 4; day = 1hour = 02; min = 15; sec = 30}
-------------------------------------------------------------------------------
function timelib.add_time(date_txt, time_txt)
    local time1 = timelib.date_struct(date_txt)
    local time2 = timelib.time_struct(time_txt)
    time1.hour = time2.hour;
    time1.min  = time2.min;
    time1.sec  = time2.sec;
    return time1
end

