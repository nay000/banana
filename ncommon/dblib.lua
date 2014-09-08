----------------------------------------------------------------------------------------------------------------
-------------------------------------数据库操作函数----------------------------------------------------------
--[[
	dblib.execute(sql[, onresult])	执行SQL语句并返回执行结果
		参数
			sql :			 字符串 sql语句
			onresult:	 执行成功后回调函数
		例子
			dblib.execute("select * from users limit 1", 
				funtion(dt)
					print(tostringex(dt))
				end
			)
		说明
			* dt是一个二维table, 第一维可以用#求返回记录行数; 第二维使用列名索引值. 如dt[1]["colname"]. 第二维也可以用数字索引但不推荐(如dt[1][1]).
			* 如果查询不到数据(返回0行),那么 #dt就是0; 如果SQL出错, #dt也是0; dt永不为nil
			* 查询结果根据列的类型,分别返回数字或者字符串.其中(DECIMAL, TINY, SHORT, LONG, FLOAT, DOUBLE, 
				LONGLONG, INT24)返回number类型,其余的均返回字符串类型.

	dblib.tosqlstr(s)				用于SQL拼接的字符串转义函数,生成的字符串含两侧的双引号 好比把 " 转换成 "\""
		用法: dblib.execute(string.format("update users set nick=%s where id = 1", dblib.tosqlstr(name)))
	
--------------------------------------------------------------------------------------------------------------]]
local setmetatable = setmetatable
local _G = _G
local timelib = timelib

module "common.dblib"

setmetatable(_M, {__index = _G})	--这个模块可以直接访问_G的全局变量

--把从数据库取到的数据字符串变成二维Table
function getDataTable(szData, without_index)
	assert(szData, "szData is nil")
	function splitAndTranslate(s, delim)
		local t = split(s, delim)
		if not (delim == "#" or delim == "," or delim == ";") then return t end
		local tret = {}
		local szTmp = ""
		local isSinglena = function(s)
			local ret = false
			for i = 1, string.len(s) do
				local p = string.len(s) - i + 1
				if string.sub(s, p, p) == [[\]] then
					ret = not ret
				else
					break
				end
			end
			return ret
		end
		for k, v in pairs(t) do
			if isSinglena(v) then
				szTmp = szTmp .. string.sub(v, 1, string.len(v) - 1) .. delim
			else
				szTmp = szTmp .. v
				--if szTmp ~= "" then			--这个为空字符串的时候也得占上一格.不然就会导致后面的数据下标错位
					--剥到最后一层的时候才替换掉斜杠
					if delim == "," then
						szTmp = string.gsub(szTmp, "\\\\", "\\")
					end
					table.insert(tret, szTmp)
				--end
				szTmp = ""
			end
		end
		return tret
	end

	local ret = {}
	local rows = splitAndTranslate(splitAndTranslate(szData, "#")[1] or "",";")
	for k, v in pairs(rows) do
		table.insert(ret, splitAndTranslate(v, ","))
	end
	if #ret < 2 then
		return {}
	else
		local cols = ret[1]
		local types = ret[2]

		local dt = {}
		for i = 3, #ret do
			for k, v in pairs(cols) do
				if tonumber(types[k]) <= 5 or tonumber(types[k]) == 8 or tonumber(types[k]) == 9 then
					ret[i][k] = tonumber(ret[i][k])
					ret[i][v] = ret[i][k]
				else
					ret[i][v] = ret[i][k]
				end
				if without_index then ret[i][k] = nil end
			end
			table.insert(dt, newStrongTable(ret[i]))
		end
		return dt
	end
end

--返回一个空table,和普通table不同的是, 这个table的元素会自动超时并删除 seconds传入超时时间 (删除时机是增加新元素的时候)
function newTimeoutTable(seconds, callback_timeout)
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
local dblib = {}
dblib.dbExecuteHandle = newTimeoutTable(600)		--新table,但是600秒数据会自动删除
dblib.dbExecuteHandle2 = newTimeoutTable(600, 		--刷新好友列表
	function(func_info)
		if (func_info.func ~= nil) then
			xpcall(function() func_info.func() end, throw)
		end
	end)
dblib.dbIndex = 0

function showCount()
	dblib.dbExecuteHandle.showCount()
    dblib.dbExecuteHandle2.showCount()    
end

function dourl(url, onresult)	
	if cmdHandler["DBUL"] == nil then
		cmdHandler["DBUL"] = function(buf)
				local bEnd = buf:readByte()
			    local success = buf:readByte()
				local token = buf:readString()
				local szret = buf:readString()						
				local callback_info = dblib.dbExecuteHandle2[tonumber(token)]
				if callback_info ~= nil then
					if (bEnd == 1) then
						dblib.dbExecuteHandle2.delItem(tonumber(token))
						if callback_info["func"] ~= nil and callback_info["ret"] ~= nil then
							szret = callback_info["ret"]..szret
							callback_info["func"](szret)
						end
					else
						if callback_info["ret"] ~= nil then
							callback_info["ret"] = callback_info["ret"]..szret
						end
					end
				end
			end				
	end
	if onresult then
		dblib.dbIndex = dblib.dbIndex + 1
		dblib.dbExecuteHandle2[dblib.dbIndex] = {func = onresult, ret = ""}
		tools.dourl2(url, "DBUL", tostring(dblib.dbIndex))
	else
		tools.dourl2(url, "DBUL", "")
	end
end

dblib.last_time = 0
dblib.last_index = 0
--生成一个唯一的id
function gen_sql_guid()
    local cur_time = os.time()
    local num = cur_time
    local send_token = "-1"
    if (groupinfo ~= nil) then
        send_token = groupinfo.groupid
    end
    if (dblib.last_time == num) then
        dblib.last_index = dblib.last_index + 1
        num = num + 500000 + dblib.last_index
    else
        dblib.last_index = 0
        dblib.last_time = cur_time
    end
    return send_token.."00"..num
end

--执行数据库操作, 结果传入回调函数 onresult(dataTable)  <for both gs and gc>
function execute(sql, onresult, user_id, sql_type)
    --发dbsvr包
    if (user_id == nil or string.len(user_id) == 0 or tonumber(user_id) <= 0) then
        user_id = ""
    end
    local send_token = gen_sql_guid()
    local send_count = 1
    local send_index = 1
    local pice_num = 15000
    local ret_len = string.len(sql)
    if (ret_len > pice_num) then
        if (ret_len % pice_num == 0) then
            send_count = math.floor(ret_len / pice_num)
        else
            send_count = math.floor(ret_len / pice_num) + 1
        end
    end
    --如果发送数据过长，则需要在同一个线程里面处理
    if (send_count > 1 and (user_id == nil or user_id == "")) then
        user_id = math.random(1, 1000)
    end
    cmdHandler["DBSSQL"] = function(buf)
        buf:writeString("DBSSQL")
        local start_pos = (send_index - 1)*pice_num + 1
        local end_pos = 0
        local is_end = 0
        if (send_index < send_count) then
            end_pos = send_index * pice_num
            is_end = 0
        else
            end_pos = ret_len
            is_end = 1
        end
        send_index = send_index + 1
        buf:writeString(send_token)
        buf:writeByte(is_end)
        buf:writeString(string.sub(sql, start_pos, end_pos))							
        buf:writeInt(sql_type or common_db_info.game)
    end
    if (cmdHandler["DBRSQL"] == nil) then
        cmdHandler["DBRSQL"] = function(buf)                               
            local is_end = buf:readByte()
            local success = buf:readByte()
            local token = buf:readString()
            local func = dblib.dbExecuteHandle2[tonumber(token)]
            if not func then return end
            local ret = buf:readString()
            if (is_end == 1) then
                if not func and not func["func"] then return end				
                ret = func["ret"]..ret      

                local retlen = string.len(ret)                                                                    
                if (retlen > 30000) then
                    local org_sql = func["sql"]
                    --TraceError("sql操作数据包太长，请优化 "..retlen.." "..org_sql)
                end

                local intever_time = os.time() - func["cur_time"]
                if (intever_time > 10) then
                    local org_sql = func["sql"]
                    TraceError("数据库执行时间太长，请优化 "..intever_time.." "..func["cur_time"].."  "..org_sql)
                end
                dblib.dbExecuteHandle2.delItem(tonumber(token))
                func["func"](table.loadstring(ret), token, ret)
            else
                func["ret"] = func["ret"]..ret                                    
            end
        end
    end
	if (onresult) then
		dblib.dbIndex = dblib.dbIndex + 1
		dblib.dbExecuteHandle2[dblib.dbIndex] = {func = onresult, ret = "", cur_time = os.time(), sql = sql}
        local loop_count = 0
        while(send_index <= send_count and loop_count < 1000) do
            tools.domemcache("DBSSQL", "DBRSQL", dblib.dbIndex, user_id)
            loop_count = loop_count + 1
        end
	else
        local loop_count = 0
        while(send_index <= send_count and loop_count < 1000) do
            tools.domemcache("DBSSQL", "", -1, user_id)
            loop_count = loop_count + 1
        end
	end
end

function execute_memcache(action, table_name, column_value, search_key, search_value, onresult, user_id)
    --发dbsvr包
    if (user_id == nil or string.len(user_id) == 0 or tonumber(user_id) <= 0) then
        user_id = ""
    end
    local send_token = gen_sql_guid()
    local send_content = table.tostring(column_value or {})
    local send_count = 1
    local send_index = 1
    local pice_num = 15000
    local ret_len = string.len(send_content)
    if (ret_len > pice_num) then
        if (ret_len % pice_num == 0) then
            send_count = math.floor(ret_len / pice_num)
        else
            send_count = math.floor(ret_len / pice_num) + 1
        end
    end
    --如果发送数据过长，则需要在同一个线程里面处理
    if (send_count > 1 and (user_id == nil or user_id == "")) then
        user_id = math.random(1, 1000)
    end
    cmdHandler["DBMF"] = function(buf)
        buf:writeString("DBMF")
        buf:writeString(action or "")
        buf:writeString(table_name or "")
        local start_pos = (send_index - 1)*pice_num + 1
        local end_pos = 0
        local is_end = 0
        if (send_index < send_count) then
            end_pos = send_index * pice_num
            is_end = 0
        else
            end_pos = ret_len
            is_end = 1
        end
        send_index = send_index + 1
        buf:writeString(send_token)
        buf:writeByte(is_end)
        buf:writeString(string.sub(send_content, start_pos, end_pos))
        buf:writeString(search_key or "")
        buf:writeString(search_value or "")
    end
    if (cmdHandler["DBGMF"] == nil) then
	    cmdHandler["DBGMF"] = function(buf)
            local is_end = buf:readByte()
            local success = buf:readByte()
            local token = buf:readString()
            local func = dblib.dbExecuteHandle2[tonumber(token)]
            if not func then return end
            local ret = buf:readString()
            if (is_end == 1) then
                if not func and not func["func"] then return end				
                ret = func["ret"]..ret

                local retlen = string.len(ret)                                                                        
                if (retlen > 30000) then                                        
                    local org_table_name = func["table_name"]
                    --TraceError("sql操作数据包太长，请优化 "..retlen.." "..org_table_name)
                end
                local intever_time = os.time() - func["cur_time"]
                if (intever_time > 10) then
                    local org_table_name = func["table_name"]
                    TraceError("数据库执行时间太长，请优化 "..intever_time.." "..org_table_name)
                end
                func["func"](table.loadstring(ret))
                dblib.dbExecuteHandle2.delItem(tonumber(token))
            else
                func["ret"] = func["ret"]..ret
            end   
        end
    end
	if (onresult) then
		dblib.dbIndex = dblib.dbIndex + 1
		dblib.dbExecuteHandle2[dblib.dbIndex] = {func = onresult, ret = "", cur_time=os.time(), table_name = table_name}
        local loop_count = 0
        while (send_index <= send_count and loop_count < 1000) do
            tools.domemcache("DBMF", "DBGMF", dblib.dbIndex, user_id)
            loop_count = loop_count + 1
        end
	else
        local loop_count = 0
        while (send_index <= send_count and loop_count < 1000) do
            tools.domemcache("DBMF", "", -1, user_id)
            loop_count = loop_count + 1
        end
	end
end

--执行memcache的get功能
function cache_get(table_name, column_vale, search_key, search_value, onresult, user_id)
	column_vale = split(column_vale, ",")
	execute_memcache("get", table_name, column_vale, tostring(search_key), tostring(search_value), onresult, user_id)
end

--执行memcache的set功能
function cache_set(table_name, column_vale, search_key, search_value, onresult, user_id)
	execute_memcache("set", table_name, column_vale, tostring(search_key), tostring(search_value), onresult, user_id)
end

--执行memcache的自动增长功能
function cache_inc(table_name, column_vale, search_key, search_value, onresult, user_id)
	execute_memcache("inc", table_name, column_vale, tostring(search_key), tostring(search_value), onresult, user_id)
end
--执行memcache的add功能
function cache_add(table_name, column_vale, onresult, user_id)
	execute_memcache("add", table_name, column_vale, "", "", onresult, user_id)
end

function cache_exec(action, column_vale, onresult, user_id)
	execute_memcache("custom:"..action, "", column_vale, "", "", onresult, user_id)
end
--用于SQL拼接的字符串转义函数,生成的字符串含两侧的双引号
--用法: tools.dosql(string.format("select * from user where nick=%s", dblib.tosqlstr(name)))
tosqlstr = function(s)
	return string.format('"%s"', string.gsub(string.gsub(s, "\\", "\\\\"), '"', '\\"'))
end

