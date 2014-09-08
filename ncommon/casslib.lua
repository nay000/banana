require("luanet")
luanet.load_assembly("Thrift.dll")
CassandraLib 	= luanet.Thrift.CassandraEx.CassandraLib
Helper		 	= luanet.Thrift.CassandraEx.Helper
ArrayList		= luanet.System.Collections.ArrayList
DDataPack		= luanet.Thrift.CassandraEx.DDataPack

ColumnPath		= luanet.Apache.Cassandra.ColumnPath
ColumnParent	= luanet.Apache.Cassandra.ColumnParent
SlicePredicate	= luanet.Apache.Cassandra.SlicePredicate
SliceRange		= luanet.Apache.Cassandra.SliceRange
Column			= luanet.Apache.Cassandra.Column
SuperColumn		= luanet.Apache.Cassandra.SliceRange
ColumnOrSuperColumn	= luanet.Apache.Cassandra.SliceRange


casslib_handle = casslib_handle
casslib = _S
{
	init 				= NULL_FUNC,
	get_timestamp		= NULL_FUNC,
	-------
	get					= NULL_FUNC,
	insert				= NULL_FUNC,
	get_slice			= NULL_FUNC,
	multiget			= NULL_FUNC,
	multiget_slice		= NULL_FUNC,
	get_count			= NULL_FUNC,
	get_key_range		= NULL_FUNC,
	get_range_slice		= NULL_FUNC,
	remove				= NULL_FUNC,
	batch_insert		= NULL_FUNC,
}
local new_ListString
local new_ColumnPath
local new_ColumnParent
local new_SlicePredicate
local new_SliceRange
local new_Column
local new_SuperColumn
local new_List_col
local new_List_coc

local coc_to_table
local listcoc_to_table
local dict_to_table
local dictlistcoc_to_table
local listks_to_table
local dictcoc_to_table


--初始化数据库连接
casslib.init = function(host, port)
	local succ = xpcall(function()
		casslib_handle = CassandraLib.init(host, port)
	end, throw)
	return succ or nil
end
-----------------------------------------------------------------------------------------
casslib.get_timestamp = function()
	return Helper.GetTimestamp()
end

new_ColumnPath = function(column_path)
	local cp = ColumnPath()
	if column_path.column_family ~= nil then
		cp.Column_family = column_path.column_family 
	end
	if column_path.super_column ~= nil then
		cp.Super_column = DDataPack(column_path.super_column).PureData
	end
	if column_path.column  ~= nil then 
		cp.Column = DDataPack(column_path.column).PureData
	end
	return cp
end

new_ColumnParent = function(column_parent)
	local cp = ColumnParent()
	if column_parent.column_family ~= nil then
		cp.Column_family = column_parent.column_family 
	end
	if column_parent.super_column ~= nil then
		cp.Super_column = DDataPack(column_parent.super_column).PureData
	end
	return cp
end

new_ListString = function(tbl)
	local al = ArrayList()
	for k, v in pairs(tbl) do
		Helper.ArrayList_Add(al, v)
	end
	return al
end

new_SliceRange = function(slice_range)
	local sr = SliceRange()
	if slice_range.reversed ~= nil then sr.Reversed = slice_range.reversed end
	if slice_range.count ~= nil then sr.Count 		= slice_range.count  end
	if slice_range.start ~= nil then
		sr.Start =  DDataPack(slice_range.start).PureData
	end
	if slice_range.finish ~= nil then 
		sr.Finish = DDataPack(slice_range.finish).PureData
	end
	return sr
end

new_SlicePredicate = function(predicate)
	local sp = SlicePredicate()
	if predicate.column_names ~= nil then
		sp.Column_names = new_ListString(predicate.column_names)
	end
	if predicate.slice_range ~= nil then
		sp.Slice_range 	= new_SliceRange(predicate.slice_range)
	end
	return sp
end


new_Column = function(tbl)
	local col = Column()
	if tbl.value ~= nil then col.Value = DDataPack(tbl.value).Data end
	if tbl.name ~= nil then col.Name = DDataPack(tbl.name).PureData end
	if tbl.timestamp ~= nil then col.Timestamp = DDataPack(tbl.timestamp).PureData end
	return col
end

new_SuperColumn = function(tbl)
	local col = SuperColumn()
	if tbl.name ~= nil then col.Name = DDataPack(tbl.name).PureData end
	if tbl.columns ~= nil then col.Columns = new_List_col(columns) end
	return col
end

new_ColumnOrSuperColumn = function(tbl)
	local coc = ColumnOrSuperColumn()
	if tbl.column ~= nil then col.Column = new_Column(tbl.column) end
	if tbl.super_column ~= nil then col.Super_column = new_SuperColumn(tbl.super_column) end
	return coc
end


new_List_col = function(columns)
	local listcol = Helper.new_Listcol()
	for i = 1, #columns do
		local col = columns[i]
		Helper.Listcoc_Add(listcol, col)
	end 
	return listcol
end

new_List_coc = function(cocs)
	local listcoc = Helper.new_Listcoc()
	for i = 1, #cocs do
		local coc = new_ColumnOrSuperColumn(cocs[i])
		Helper.Listcoc_Add(listcoc, coc)
	end 
	return listcoc
end

new_Dict_list_coc = function(cfmap)
	local map = Helper.new_cfmap()
	for k, v in pairs(cfmap) do
		Helper.cfmap_Add(map, k, new_List_coc(v))
	end
	return map
end



coc_to_table = function(coc)
	local ret = {}
	if coc.Column ~= nil then
		ret = _S
		{
			name = Helper.Encoding_UTF8_GetString(coc.Column.Name),
			value = DDataPack(coc.Column.Value).Value,
			timestamp = coc.Column.Timestamp,
		}
		--ret[Helper.Encoding_UTF8_GetString(coc.Column.Name)] = DDataPack(coc.Column.Value).Value
	elseif coc.Super_column ~= nil then
		local subtbl = {}
		local _count = coc.Super_column.Columns.Count
		for j = 1, _count do
			local col = Helper.List_Column_GetIndex(coc.Super_column.Columns, j - 1)
			subtbl = _S
			{
				name = Helper.Encoding_UTF8_GetString(col.Name),
				value = DDataPack(col.Value).Value,
				timestamp = col.Timestamp,
			}
			--subtbl[Helper.Encoding_UTF8_GetString(col.Name)] = DDataPack(col.Value).Value
		end
		ret[Helper.Encoding_UTF8_GetString(coc.Super_column.Name)] = subtbl
	end
	return ret
end

listcoc_to_table = function(list_coc)
	local count = list_coc.Count
	local ret = {}
	for i = 1, count do
		local coc = Helper.List_ColumnOrSuperColumn_GetIndex(list_coc, i - 1)
		local coc_tbl = coc_to_table(coc)
		table.insert(ret, coc_tbl)
	end
	return ret
end

dict_to_table = function(dict)
	local lst = Helper.Dictionary_string_ColumnOrSuperColumn_List_String(dict)
	local count = lst.Count
	local ret = {}
	for i = 1, count do
		local key = Helper.ArrayList_GetIndex(lst, i - 1)
		ret[key] = Helper.Dictionary_string_ColumnOrSuperColumn_GetItem(key)
	end
	return ret
end

dictlistcoc_to_table = function(dictlistcoc)
	local tbl = dict_to_table(dictlistcoc)
	local ret = {}
	for k, v in pairs(tbl) do
		ret[k] = listcoc_to_table(v)
	end
	return ret
end

dictcoc_to_table = function(dictcoc)
	local tbl = dict_to_table(dictcoc)
	local ret = {}
	for k, v in pairs(tbl) do
		ret[k] = coc_to_table(v)
	end
	return ret
end

listks_to_table = function(listks)
	local ret = {}
	local count = listks.Count
	for i = 1, count do
		local ks = Helper.List_KeySlice_GetIndex(listks, i - 1)
		ret[ks.Key] = listcoc_to_table(ks.Columns)
	end
	return ret
end

-----------------------------------------------------------------------------------------------------------
casslib.get = function(keyspace, key, column_path, consistency_level)
	local ret
	local succ = xpcall(function()
		column_parent = new_ColumnPath(column_path)
		local coc = CassandraLib.get(casslib_handle, keyspace, key, column_parent, consistency_level)
		ret = coc_to_table(coc)
	end, throw)
	if not succ then TraceError(string.format("[casslib] get失败: ks:%s key:%s cpath:%s ", tostring(keyspace), tostring(key), tostringex(column_path))) end
	return succ and ret or nil
end

casslib.insert = function(keyspace, key, column_path, value, timestamp, consistency_level)
	local succ = xpcall(function()
		column_parent = new_ColumnPath(column_path)
		CassandraLib.insert(casslib_handle, keyspace, key, column_parent, DDataPack(value).Data, timestamp, consistency_level)
	end, throw)
	if not succ then TraceError(string.format("[casslib] insert失败: ks:%s key:%s cpath:%s value:%s", tostring(keyspace), tostring(key), tostringex(column_path), tostring(value))) end
	return succ or nil
end

casslib.get_slice = function(keyspace, key, column_parent, predicate, consistency_level)
	local ret
	local succ = xpcall(function()
		column_parent 	= new_ColumnParent(column_parent)
		predicate 		= new_SlicePredicate(predicate)
		local list_coc  = CassandraLib.get_slice(casslib_handle, keyspace, key, column_parent, predicate, consistency_level)
		ret = listcoc_to_table(list_coc)
	end, throw)
	if not succ then TraceError(string.format("[casslib] get_slice失败: ks:%s key:%s cp:%s pd:%s", tostring(keyspace), tostring(key), tostringex(column_parent), tostringex(predicate))) end
	return succ and ret or nil
end

casslib.multiget_slice = function(keyspace, keys, column_parent, predicate, consistency_level)
	local ret
	local succ = xpcall(function()
		keys			= new_ListString(keys)
		column_parent 	= new_ColumnParent(column_parent)
		predicate 		= new_SlicePredicate(predicate)
		local dictlist_coc  = CassandraLib.multiget_slice(casslib_handle, keyspace, keys, column_parent, predicate, consistency_level)
		ret = dictlistcoc_to_table(dictlist_coc)
	end, throw)
	return succ and ret or nil
end

casslib.multiget = function(keyspace, keys, column_path, consistency_level)
	local ret
	local succ = xpcall(function()
		keys			= new_ListString(keys)
		column_path 	= new_ColumnParent(column_path)
		local dictlist_coc  = CassandraLib.multiget_slice(casslib_handle, keyspace, keys, column_parent, predicate, consistency_level)
		ret = dictcoc_to_table(dictlist_coc)
	end, throw)
	return succ and ret or nil
end

casslib.get_count = function(keyspace, keys, column_parent, consistency_level)
	local ret
	local succ = xpcall(function()
		column_parent 	= new_ColumnParent(column_parent)
		ret = CassandraLib.get_count(casslib_handle, keyspace, keys, column_parent, consistency_level)
	end, throw)
	return succ and ret or nil
end

--过期函数，用get_range_slice代替
casslib.get_key_range = function(keyspace, column_family, start, finish, count, consistency_level)
	local ret
	local succ = xpcall(function()
		ret = CassandraLib.get_key_range(casslib_handle, keyspace, column_family, start, finish, count, consistency_level)
	end, throw)
	return succ and ret or nil
end

casslib.get_range_slice = function(keyspace, column_parent, predicate, start_key, finish_key, row_count, consistency_level)
	local ret
	local succ = xpcall(function()
		column_parent 	= new_ColumnParent(column_parent)
		predicate 		= new_SlicePredicate(predicate)
		--list<KeySlice>
		local listks = CassandraLib.get_range_slice(casslib_handle, keyspace, column_parent, predicate, start_key, finish_key, row_count, consistency_level)
		ret = listks_to_table(list_ks)
	end, throw)
	return succ and ret or nil
end

casslib.remove = function(keyspace, key, column_path, timestamp , consistency_level)
	local succ = xpcall(function()
		column_path 	= new_ColumnPath(column_path)
		CassandraLib.remove(casslib_handle, keyspace, key, column_path, timestamp , consistency_level)
	end, throw)
	return succ or nil
end

casslib.batch_insert = function(keyspace, key, cfmap, consistency_level)
	local succ = xpcall(function()
		cfmap = new_Dict_list_coc(cfmap)  --map<string, list<ColumnOrSuperColumn>> 
		CassandraLib.batch_insert(casslib_handle, keyspace, key, cfmap, consistency_level)
	end, throw)
	return succ or nil
end

xpcall(function()

casslib.init("localhost", 9160)
TraceError("连接到cassandra数据库成功")


--API测试代码
if true then	--insert/get/remove
	--普通列
	casslib.insert("Farm", "6", {column_family = "Users", column="col1"}, "test_col_value", casslib.get_timestamp(), 1)
	--casslib.remove("Farm", "6", {column_family = "Users", column="col1"}, casslib.get_timestamp(), 1)
	TraceError(casslib.get("Farm", "6", {column_family = "Users", column="col1"}, 1))	
	--超级列
	casslib.insert("Farm", "6", {column_family = "SUsers", super_column = "scol1", column="col1"}, "test_super_col_value", casslib.get_timestamp(), 1)
	TraceError(casslib.get("Farm", "6", {column_family = "SUsers", super_column = "scol1", column="col1"}, 1))	
end

if true then
	TraceError("===============普通列 get_count")
	TraceError(casslib.get("Farm", "6", {column_family = "SUsers", super_column = "scol1"}, 1))	

end

if false then	--get_slice
	TraceError("===============普通列 get_slice")
	TraceError(casslib.get_slice(
		"Farm", 
		"2", 
		{column_family = "Users"},
		{slice_range = {start = "0", finish = "z", count = 100, reversed = false}}, 
		1
	))
	TraceError("===============超级列 get_slice 读子列")
	TraceError(casslib.get_slice(
		"Farm", 
		"6", 
		{column_family = "SUsers", super_column="scol1"},
		{slice_range = {start = "0", finish = "z", count = 100, reversed = false}}, 
		1
	))
	TraceError("===============超级列 get_slice 读父列")
	TraceError(casslib.get_slice(
		"Farm", 
		"6", 
		{column_family = "SUsers"},
		{slice_range = {start = "0", finish = "z", count = 100, reversed = false}}, 
		1
	))
end


--casslib.set_col_value("Farm", "Users", "1", "nick3", "hello2")
--TraceError("Farm.Users['1']['nick'] = " .. tostringex(casslib.get_col_value("Farm", "Users", "1", "nick3")))


--casslib.mul_set_col_values("Farm", "Users", "3", {col1=123456123456789.123456789, col2="2", col3="3"})
--

--TraceError(casslib.get_slice("Farm", "Users", "6"))

--TraceError(casslib.multiget("Farm", "Users", {"2","3"}))
end, throw)
