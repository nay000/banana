local setmetatable = setmetatable
local table = table
local loadstring1 = loadstring
local pairs = pairs
local type = type
local math = math
local tostring1 = tostring
local string = string
module "common.table"

setmetatable(_M, { __index = table })

loadstring = function(strData)
	if strData == nil or strData == "" then
		--TraceError("loadstring����Ϊnil ���߿յ��ִ�:<"..tostring1(strData)..">"..debug.traceback())
		return
	end
	local f = loadstring1(strData)
	if f then
		return f()
	end
end

tostring = function(t)
	local mark={}
	local assign={}
	local ser_table 
	if type(t) ~= "table" then
		--TraceError("tostring����Ϊnil ���߿յ��ִ�:<"..tostring1(t)..">"..debug.traceback())
		return "do local ret={} return ret end"
	end
    ser_table = function (tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local key= type(k)=="number" and "["..k.."]" or "[".. string.format("%q", k) .."]"
			if type(v)=="table" then
				local dotkey= parent.. key
				if mark[v] then
					table.insert(assign,dotkey.."='"..mark[v] .."'")
				else
					table.insert(tmp, key.."="..ser_table(v,dotkey))
				end
			elseif type(v) == "string" then
				table.insert(tmp, key.."=".. string.format('%q', v))
			elseif type(v) == "number" or type(v) == "boolean" then
				table.insert(tmp, key.."=".. tostring1(v))
			end
		end
		return "{"..table.concat(tmp,",").."}"
	end
	return "do local ret="..ser_table(t,"ret")..table.concat(assign," ").." return ret end"
end

clone = function(srctable)
	if (srctable == nil) then
		return nil
	else
		return loadstring(tostring(srctable))
	end
end

MAX_COPY_LAY = 7;
deepcopy = function(tbSrc, nMaxLay)
	nMaxLay = nMaxLay or MAX_COPY_LAY;
	if (nMaxLay <= 0) then
		error("Error: DeepCopy�����Ĳ����������㣬����Ƿ���ѭ������");
		return;
	end
	
	local tbRet = {};
	for k, v in pairs(tbSrc) do
		if (type(v) == "table") then
			tbRet[k] = deepcopy(v, nMaxLay-1);
		else
			tbRet[k] = v;
		end
	end
	
	return tbRet;
end

-- �������һ�������ģ���1��ʼTable, ע��,û�з���ֵ,ֱ�Ӷ�Ŀ��������в���
disarrange_new = function(tb)
	local nLen	= #tb;
	for n, value in pairs(tb) do
		local nRand = math.random(1, nLen);
		tb[n]		= tb[nRand];
		tb[nRand]	= value;
	end
end;

--����һ������, ע��,û�з���ֵ,ֱ�Ӷ�Ŀ��������в���
disarrange = function(ref_array)
	local ret = {}
	while #ref_array > 0 do
		local n = math.random(1, #ref_array)
		table.insert(ret, ref_array[n])
		table.remove(ref_array, n)
	end
	for k, v in pairs(ret) do
		ref_array[k] = v
	end
end

--����table�е�����key
swap = function(ref_table, key1, key2)
	local tmp = ref_table[key1]
	ref_table[key1] = ref_table[key2]
	ref_table[key2] = tmp
end

--�ж��Ƿ����ĳ��ֵ,�����򷵻�key
finditemkey = function(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return k
		end
	end
	return
end

--�ҳ�һ��table�е���ֵ
findtop = function(ref_tbl, rulefunc)
	local topitem
	if not rulefunc then
		rulefunc = function(a, b) return a < b end
	end
	for k, v in pairs(ref_tbl) do
		if not topitem then
			topitem = v
		else
			if rulefunc(v, topitem) then
				topitem = v
			end
		end
	end
	return topitem
end


--�ϲ�����
mergearray = function(...)
	local ret = {}
	for k, v in pairs({...}) do
		for k1, v1 in pairs(v) do
			table.insert(ret, v1)
		end
	end
	return ret
end

--�ϲ������table
merge_table = function(...)
	local ret = {}
	for k, v in pairs({...}) do
		for k1, v1 in pairs(v) do
            ret[k1] = v1
		end
	end
	return ret
end


-- ��ʽ�� table ������
function format(tb)
    local function fmt_key(key, var)
        local var_type = type(var)
        if (var_type == "number") then
            return "n_"..key 
        end
        if (var_type == "string") then
            return "sz_"..key 
        end
        if (var_type == "boolean") then
            return "b_"..key 
        end
        if (var_type == "table") then
            return "tb_"..key 
        end
        TraceError(string.format("\n[WARNING] Unknow type(%s) = %s in table.format(%s)", tostring(var), tostring(var_type), tostring(tb)))
        return key
    end
    local tb_res = {}
    for key, var in pairs(tb) do
        tb_res[fmt_key(key, var)] = var
    end
    return tb_res
end


-- ��ʽ�� table ������
-- �����Ѵ��ڵ� key
function mixin(tb, tb_mixin)
    for key, var in pairs(tb_mixin) do
        tb[key] = var
    end
    return tb
end

--ð������tb������˳���
function sort_bubble(tb, fun)
	for i=1, #tb  do
		for j = 1, #tb-i do
			if not fun(tb[j],tb[j+1]) then
				local temp = tb[j]
				tb[j] = tb[j+1]
				tb[j+1] = temp
			end
		end
	end
end



