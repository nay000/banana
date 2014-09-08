
-------------------------------------------------------------------------------
-- �ļ����ƣ�load_csv.lua
-- ģ�����ƣ�load_csv
-- �������ƣ�li_dongyuan
-- ����ʱ�䣺2014��1��17�� ����2:08:32
-- �ļ�����������csv�������ã�csv�ļ�ͨ��excel���ɣ� 
-------------------------------------------------------------------------------


-- TODO test regex = [^,]+ �� regex = '([^,]*),'
-------------------------------------------------------------------------------
-- ���� ɨ����� �� ����
-- ���� load_csv 
-- excel �ļ���ʽ 
-- ��1�� �ֶ�ע�� 
-- ��2�� �ֶ���   �ֶ���Ϊ��������ı����޷�������
-- ��3�� �ֶ����� string / number
-- ��N�� ����     ���Կ��к� #��ͷ���� �͵�һ��û�����ݵ���

-- @param   string  path    csv �ļ�·������������
--          array   arr_key     
-- @return  table   t       csv ��������
-------------------------------------------------------------------------------

function load_csv(path, arr_key)
    local file = io.open(path, 'r')
    if(file == nil)then return nil, "�ļ�·������" end
    local regex = '[^,]+'

    -- ��ȡ���� ע�� �ֶ��� �� ���� 
    local function totype(value, val_type) 
        if value == nil then
            return nil
        end
        if (type(value) ~= "string") then
            return nil
        end
        if (#value == 0) then
            return nil
        end
        if (val_type == "number") then
            return tonumber(value) 
        end
        if (val_type == "boolean") then
            return (tonumber(value) ~= 0 and true or false) 
        end
        if (val_type == "string") then
            return tostring(value) 
        end
    end
   
    -- ��ȡ ע�� �ֶ��� �� ���� 
    local col_rem_ln  = file:read('*line')
    local col_name_ln = file:read('*line')
    local col_type_ln = file:read('*line')

    local arr_col_name = {}
    for name in string.gmatch(col_name_ln, regex) do
        assert(#name > 0, "�������쳣")
        table.insert(arr_col_name, name)
    end
    local arr_col_type = {}
    for type in string.gmatch(col_type_ln, regex) do
        assert(#type > 0, "���������쳣")
        table.insert(arr_col_type, type)
    end
    
    assert(#arr_col_name == #arr_col_type, "���������͸�����ƥ��")

    local arr_csv = {}
    -- ɨ����
    for line in file:lines() do
        line = line..','
        if string.find(line, '^[^#,]') then
            local t_line = {}
            local col_num = 0
            -- ɨ����
            for value in string.gmatch(line, '([^,]*),') do
                col_num = col_num + 1
                -- ������ֵ��
                local key = arr_col_name[col_num]
                value = totype(value, arr_col_type[col_num])
                if (key) then
                    t_line[key] = value
                end
            end
            table.insert(arr_csv, t_line)
        end
    end
    io.close(file)
        
    if arr_key then
        assert(arr_key, "arr_key ������һ��table")
        if (#arr_key == 0) then
            return arr_csv
        end
        local ht_csv = {}
        for _, line in ipairs(arr_csv) do
            local cur_root = ht_csv
            for _, key in ipairs(arr_key) do
                local value = line[key]
                cur_root[value] = cur_root[value] or {}
                cur_root = cur_root[value]
            end
            table.insert(cur_root, line)
        end
        return ht_csv
    end
    return arr_csv
end

-- ֻ����ǳ�ļ��
-- 1. ǰ���� ע�� �ֶ��� �� ����  ������
-- 2. ÿ�е�һ�������ݼ�����Ϊ��Ч�У��������
-- 3. ��Ԫ����������������������������Ĭ�����
-- 4. ÿ���е���ֵ<=ǰ���е��е���ֵ
function check_csv_unsafe(path)
    if(path == nil or type(path) ~= "string") then return false, "�ļ�·������" end
    local file = io.open(path, 'r')    
    if(file == nil)then      
        return false, "���ļ�ʧ��"
    end
    local regex = '[^,]+'
    -- ��ȡ���� ע�� �ֶ��� �� ���� 
    local function totype(value, val_type)         
        if (type(value) ~= "string") then
            return nil
        end
        if (#value == 0) then
            return ""
        end        
        if (val_type == "number") then
            local n_t = tonumber(value) 
            if(n_t ~= nil) then return type(n_t) end 
        end
        if (val_type == "boolean") then
            return (tonumber(value) ~= 0 and true or false) 
        end
        if (val_type == "string") then
            return tostring(value) 
        end
    end   
    -- ��ȡ ע�� �ֶ��� �� ���� 
    local col_rem_ln  = file:read('*line')
    local col_name_ln = file:read('*line')
    local col_type_ln = file:read('*line')
    if(col_rem_ln == nil or col_name_ln == nil or col_type_ln == nil)then 
        io.close(file)
        return -1, "ȱ��:ע��,�ֶ��� �� ����"
    end
    local arr_col_name = {}
    for name in string.gmatch(col_name_ln, regex) do        
        if(#name <= 0)then io.close(file) return false, "�ֶ����쳣" end 
        table.insert(arr_col_name, name)
    end
    local arr_col_type = {}
    for type in string.gmatch(col_type_ln, regex) do        
        if(#type <= 0)then io.close(file) return false, "���������쳣" end 
        table.insert(arr_col_type, type)
    end
    if(#arr_col_name ~= #arr_col_type)then io.close(file) return false, "���������͸�����ƥ��" end    
    local rowCount = 3;
    -- �����
    for line in file:lines() do	
        line = line..","
        rowCount = rowCount + 1
        if string.find(line, '^[^#,]') then
            local t_line = {}
            local col_num = 0
            -- ɨ����
            for value in string.gmatch(line, '([^,]*),') do
                col_num = col_num + 1                
                local key = arr_col_name[col_num]
                local b_key = true
                if(key == nil)then b_key = false end                                                      
                local b_type = true
                if(value ~= nil) then b_type = totype(value, arr_col_type[col_num]) ~= nil end
                if(b_key == false or b_type == false)then
                    io.close(file)
                    return false, "������Ч���� �� = "..rowCount.." �� = "..col_num  
                end
            end		
        end
    end   
    io.close(file)
    return true, "���ɹ�"
end




function csv_2_hash(path, arr_index)
    local file = io.open(path, 'r');
    local regex = '[^,]+'

    -- ��ȡ���� ע�� �ֶ��� �� ���� 
    local function totype(value, val_type) 
        if value == nil then
            return nil
        end
        if (type(value) ~= "string") then
            return nil
        end
        if (#value == 0) then
            return nil
        end
        if (val_type == "number") then
            return tonumber(value) 
        end
        if (val_type == "boolean") then
            return (tonumber(value) ~= 0 and true or false) 
        end
        if (val_type == "string") then
            return tostring(value) 
        end
    end
   
    -- ��ȡ ע�� �ֶ��� �� ���� 
    local col_rem_ln  = file:read('*line')
    local col_name_ln = file:read('*line')
    local col_type_ln = file:read('*line')

    local arr_col_name = {}
    for name in string.gmatch(col_name_ln, regex) do
        table.insert(arr_col_name, name)
    end
    local arr_col_type = {}
    for type in string.gmatch(col_type_ln, regex) do
        table.insert(arr_col_type, type)
    end

    local arr_csv = {}
    -- ɨ����
    for line in file:lines() do
        line = line..','
        if string.find(line, '^[^#,]') then
            local t_line = {}
            local col_num = 0
            -- ɨ����
            for value in string.gmatch(line, '([^,]*),') do
                col_num = col_num + 1
                -- ������ֵ��
                local key = arr_col_name[col_num]
                value = totype(value, arr_col_type[col_num])
                if (key) then
                    t_line[key] = value
                end
            end
            table.insert(arr_csv, t_line)
        end

    end

    local t_multi = {}
    if (arr_index) then
        for _, line in ipairs(arr_csv) do
            
            local hash_root = t_multi  
            local last_root = nil
            local last_index= nil
            for _, index in ipairs(arr_index) do
                hash_root[line[index]] = hash_root[line[index]] or {}
                last_root = hash_root
                last_index= index
                hash_root = hash_root[line[index]]

            end
            --table.insert(hash_root, line)
            last_root[line[last_index]] = line
        end
    end
    return t_multi
end