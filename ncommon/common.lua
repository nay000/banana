----------------------------------------------------------------------------------------------------------------
-------------------------------------公共库函数---------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
if not inited_commonlib then inited_commonlib = true   -- 最后面有个end

function tostringex(v, len)
	if len == nil then len = 0 end
	local pre = string.rep('\t', len)
	local ret = ""
	if type(v) == "table" then
		if len > 5 then return "\t{ ... }" end
		local t = ""
		local keys = {}
		for k, v1 in pairs(v) do
			table.insert(keys, k)
		end
		--table.sort(keys)
		for k, v1 in pairs(keys) do
			k = v1
			v1 = v[k]
			t = t .. "\n\t" .. pre .. tostring(k) .. ":"
			t = t .. tostringex(v1, len + 1)
		end
		if t == "" then
			ret = ret .. pre .. "{ }\t(" .. tostring(v) .. ")"
		else
			if len > 0 then
				ret = ret .. "\t(" .. tostring(v) .. ")\n"
			end
			ret = ret .. pre .. "{" .. t .. "\n" .. pre .. "}"
		end
	else
		ret = ret .. pre .. tostring(v) .. "\t(" .. type(v) .. ")"
	end
	return ret
end

-- 相比tostringex，简化class的打印结果
function tostringex2(v, n_level)
	local tb_result = {}
	local tb_printed = {[v] = '.'}
    local tb_stack = {}
    local function trace_class(s, c, sz_pre_key)
        for k, v in pairs(s) do
        	if k ~= 'class' then
				table.insert(tb_stack, k)

	            if type(v) == 'table' then
	                if not tb_printed[v] then
	                    if not n_level or n_level >= table.maxn(tb_stack) then
	                        tb_printed[v] = sz_pre_key..'.'..tostring(k)
	                        c[k] = {}

	                        trace_class(v, c[k], tb_printed[v])
	                    else
	                        c[k] = "..."
	                    end
	                else
	                    c[k] = '{'..tb_printed[v]..'}' -- 已打印的显示打印过的节点名称{.*.**...}
	                end
	            else
	                c[k] = v
	            end

	            table.remove(tb_stack)
        	end            
        end
    end

    trace_class(v, tb_result, '')

    return tostringex(tb_result)
end

ASSERT = assert

function split(s, delim)
	assert (type (delim) == "string" and string.len (delim) > 0,"bad delimiter")
	local start = 1  local t = {}
	while true do
		local pos = string.find (s, delim, start, true) -- plain find
		if not pos then
			break
		end
		table.insert (t, string.sub (s, start, pos - 1))
		start = pos + string.len (delim)
	end
	table.insert (t, string.sub (s, start))
	return t
end

function split_number(text)
    local arr = {}
    for str in string.gmatch(text, '[^,]+') do
        table.insert(arr, tonumber(str))
    end
    return arr, #arr
end

--调试函数,显示所有局部变量, more表示是否显示详细table变量
local showlocal = function(more)
	local level = 2
	local ret = ""
	--get local vars
	local i = 1
	while true do
		local name, value = debug.getlocal(level, i)
		if not name then break end
		ret = ret .. "\t" .. name .. " =\t" .. (more and tostringex(value, 3) or tostring(value)) .. "\n"
		i = i + 1
	end
	level = level + 1
	return ret
end

--四舍五入函数
math.round = function(x)
    local y = math.floor(math.mod(x * 10,10))
    if(y < 5) then
        x = math.floor(x);
    else
        x = math.ceil(x);
    end
	return x
end

--21亿
function getmaxint()
	return 2100000000
end

--2表示不报错，1表示只报一次错
tAllowVars = 
{
	--hall
	g_userinfo = 2,
	g_deskno = 2,
	g_siteno = 2,
	g_currentusernick = 2,
	g_currentuser = 2,
	g_recode = 2,
	g_realExit = 2,
	g_playerExit = 2,
	g_wuserid = 2,
	g_playingusernick = 2,
	g_userid = 2,
	g_current_userinfo = 2,
	g_nErrorCode = 2,   			--.\games\h2.lua:4720: in function 'fCommand'

	g_watchUserId = 2,
	g_watchRoomId = 2,

	--ddz
	nReady = 1,
	guideRate = 1,
	finishedCount = 1,
	user = 1,			--ddz.main.lua:5973: in function 'set_game_state'
	s = 1,				--ddz.main.lua:3592: in function 'doChuPai'
	retcontent = 1, 	--ddz.main.lua:3386: in function 'ValidatePoke'
	bvalid = 1,			--ddz.main.lua:3386: in function 'ValidatePoke'
	prevpaixin = 1, 	--ddz.main.lua:4069: in function 'doAutoAfterChupai'
	findend = 1,		--ddz.main.lua:4394: in function 'findpaixin'
	findstart = 1, 		--ddz.main.lua:4394: in function 'findpaixin'
	pokecount = 1,		--ddz.main.lua:4444: in function 'fenpokes'
	zpcount = 1,		--ddz.main.lua:4396: in function 'findpaixin'

	--zjh
	g_showbetmoney = 1, --zjh.main.lua:1340: in function <zjh.main.lua:1254>
	g_bp2Site = 1,		--zjh.main.lua:1275: in function <zjh.main.lua:1254>
	g_bpWin = 1,		--zjh.main.lua:1406: in function <zjh.main.lua:1254>

	--soha

	--mj
	gangcount = 1,		--mj.main.lua:4255: in function 'init_desk_data'	

	--tlj
	hhpokecount = 1, 	--tlj.main.lua:2142: in function 'valid_after_chupai'
}

function showErrorGlobal(szVarName, szTrace)
	if tAllowVars[szVarName] then 
		if tAllowVars[szVarName] == 1 then
			TraceError(szTrace)
			tAllowVars[szVarName] = 2
		end
	else
		TraceError(szTrace)
	end
end

--禁用全局变量读取和赋值
function disable_global()
	if _DEBUG then
		setmetatable(_G, {
			__newindex = function (_, n, v)
				rawset(_G, n, v)
				showErrorGlobal(n, "赋值失败，未定义全局变量："..tostring(n).."\r\n"..debug.traceback())
			end,
		})
	end
end

--启用全局变量
function enable_global()
	if _DEBUG then
		setmetatable(_G, {})
	end	
end

--定义全局变量的专用api（不受disable_global影响）
function global(var_name, var_value)
	if _DEBUG then
		if rawget(_G, var_name) then
			error("变量重复定义：" .. tostring(var_name))
		end
	end
	rawset(_G, var_name, var_value)
end

--检查某个全局变量是否存在（不受disable_global影响）
function check_global(var_name)
	if _DEBUG then
		assert(var_name, "var_name不能为空")
	end
	return rawget(_G, var_name)
end


_U = tools.AnsiToUtf8

cmdHandler_addons = {}

NULL_FUNC = NULL_FUNC or function() end
NULL_STATE = NULL_STATE or (function() local r = {} setmetatable(r, {__tostring = function() return "[NULL_STATE]" end}) return r end)()

common_db_info = {farm = 1, game = 2, home = 3}
----------------------------------------------------------------------------------------------------------------
-------------------------------------公共库函数-----结束-----------------------------------------------------
----------------------------------------------------------------------------------------------------------------
--静态类定义

class = require("common.class")
--类定义
dofile("common/timelib.lua")
dofile("common/cache.lua")
dofile("common/Eventlib.lua")
dofile("common/event_wrap.lua")
string = require("common.string")
table = require("common.table")
dblib = require("common.dblib")
json = require("common.json")
dofile("common/netlib.lua")
dofile("common/bit.lua")

dofile("common/buildoption.lua")
dofile("common/load_csv.lua")

-- script_engine
dofile("common/script_engine/script.lua")
dofile("common/script_engine/script_engine.lua")
dofile("common/script_engine/script_translator.lua")
dofile("common/script_engine/translate_script.lua")


if TraceError then TraceError("common lib init ok") end

end --if not inited_commonlib then inited_commonlib = true
