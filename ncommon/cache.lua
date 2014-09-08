cache =
{
}
--[[
    写入cache数据, 例子如下, 参数user_id表示是否需要和这个用户按顺序查询， time表示数据的过期时间
    --写数据
    local xxx_info = {aa= 1, bb = 2};
    cache.set_by_key("user_xxx_info", user_id, xxx_info, call, user_id)
    --读数据
    cache.get_by_key("user_xxx_info", user_id, function(dt) TraceError(dt) end, user_id)
--]]
function cache.set_by_key(key, value, callback, user_id, time)
    dblib.cache_exec("cacheset", {key, value, time}, callback, user_id);
end

--读取cache数据
function cache.get_by_key(key, callback, user_id)
    dblib.cache_exec("cacheget", {key}, callback, user_id);
end

--删除cache数据
function cache.del_by_key(key, callback, user_id)
    dblib.cache_exec("cachedel", {key}, callback, user_id);
end

--批量读取cache数据
function cache.mul_get_by_key(keys, callback, user_id)
    dblib.cache_exec("cachemulget", {keys}, callback, user_id);
end

--[[
    批量写入cache数据, 例子如下, 参数user_id表示是否需要和这个用户按顺序查询， time表示数据的过期时间
    --写数据
    local xxx_info = {[user_id1] = {aa = 1, bb = 2}, [user_id2] = {cc = 3, dd = 4}};
    cache.mul_set_by_key("user_xxx_info", xxx_info, call, 1)
    --读数据
    cache.mul_get_by_key("user_xxx_info", {user_id1, user_id2}, function(dt) TraceError(dt) end, 1)
--]]
function cache.mul_set_by_key(key_values, callback, user_id, time)
    dblib.cache_exec("cachemulset", {key_values, time}, callback, user_id);
end
