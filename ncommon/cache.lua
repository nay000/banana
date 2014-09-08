cache =
{
}
--[[
    д��cache����, ��������, ����user_id��ʾ�Ƿ���Ҫ������û���˳���ѯ�� time��ʾ���ݵĹ���ʱ��
    --д����
    local xxx_info = {aa= 1, bb = 2};
    cache.set_by_key("user_xxx_info", user_id, xxx_info, call, user_id)
    --������
    cache.get_by_key("user_xxx_info", user_id, function(dt) TraceError(dt) end, user_id)
--]]
function cache.set_by_key(key, value, callback, user_id, time)
    dblib.cache_exec("cacheset", {key, value, time}, callback, user_id);
end

--��ȡcache����
function cache.get_by_key(key, callback, user_id)
    dblib.cache_exec("cacheget", {key}, callback, user_id);
end

--ɾ��cache����
function cache.del_by_key(key, callback, user_id)
    dblib.cache_exec("cachedel", {key}, callback, user_id);
end

--������ȡcache����
function cache.mul_get_by_key(keys, callback, user_id)
    dblib.cache_exec("cachemulget", {keys}, callback, user_id);
end

--[[
    ����д��cache����, ��������, ����user_id��ʾ�Ƿ���Ҫ������û���˳���ѯ�� time��ʾ���ݵĹ���ʱ��
    --д����
    local xxx_info = {[user_id1] = {aa = 1, bb = 2}, [user_id2] = {cc = 3, dd = 4}};
    cache.mul_set_by_key("user_xxx_info", xxx_info, call, 1)
    --������
    cache.mul_get_by_key("user_xxx_info", {user_id1, user_id2}, function(dt) TraceError(dt) end, 1)
--]]
function cache.mul_set_by_key(key_values, callback, user_id, time)
    dblib.cache_exec("cachemulset", {key_values, time}, callback, user_id);
end
