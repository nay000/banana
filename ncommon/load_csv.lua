
-------------------------------------------------------------------------------
-- 文件名称：load_csv.lua
-- 模块名称：load_csv
-- 作者名称：li_dongyuan
-- 创建时间：2014年1月17日 下午2:08:32
-- 文件描述：解析csv数据配置（csv文件通过excel生成） 
-------------------------------------------------------------------------------


-- TODO test regex = [^,]+ 和 regex = '([^,]*),'
-------------------------------------------------------------------------------
-- 处理 扫描空行 和 空列
-- 函数 load_csv 
-- excel 文件格式 
-- 第1行 字段注释 
-- 第2行 字段名   字段名为空则下面的变量无法被载入
-- 第3行 字段类型 string / number
-- 第N行 数据     忽略空行和 #开头的行 和第一列没有数据的行

-- @param   string  path    csv 文件路径不包含引号
--          array   arr_key     
-- @return  table   t       csv 数据数组
-------------------------------------------------------------------------------

function load_csv(path, arr_key)
    local file = io.open(path, 'r')
    if(file == nil)then return nil, "文件路径错误" end
    local regex = '[^,]+'

    -- 读取数据 注释 字段名 和 类型 
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
   
    -- 读取 注释 字段名 和 类型 
    local col_rem_ln  = file:read('*line')
    local col_name_ln = file:read('*line')
    local col_type_ln = file:read('*line')

    local arr_col_name = {}
    for name in string.gmatch(col_name_ln, regex) do
        assert(#name > 0, "列名有异常")
        table.insert(arr_col_name, name)
    end
    local arr_col_type = {}
    for type in string.gmatch(col_type_ln, regex) do
        assert(#type > 0, "列类型有异常")
        table.insert(arr_col_type, type)
    end
    
    assert(#arr_col_name == #arr_col_type, "列名与类型个数不匹配")

    local arr_csv = {}
    -- 扫描行
    for line in file:lines() do
        line = line..','
        if string.find(line, '^[^#,]') then
            local t_line = {}
            local col_num = 0
            -- 扫描列
            for value in string.gmatch(line, '([^,]*),') do
                col_num = col_num + 1
                -- 建立键值对
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
        assert(arr_key, "arr_key 必须是一个table")
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

-- 只做粗浅的检查
-- 1. 前三行 注释 字段名 和 类型  必须有
-- 2. 每行第一列无数据即该行为无效列，不做检查
-- 3. 单元格类型与第三行类型相符，无数据默认相符
-- 4. 每行列的总值<=前三行的列的总值
function check_csv_unsafe(path)
    if(path == nil or type(path) ~= "string") then return false, "文件路径错误" end
    local file = io.open(path, 'r')    
    if(file == nil)then      
        return false, "打开文件失败"
    end
    local regex = '[^,]+'
    -- 读取数据 注释 字段名 和 类型 
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
    -- 读取 注释 字段名 和 类型 
    local col_rem_ln  = file:read('*line')
    local col_name_ln = file:read('*line')
    local col_type_ln = file:read('*line')
    if(col_rem_ln == nil or col_name_ln == nil or col_type_ln == nil)then 
        io.close(file)
        return -1, "缺少:注释,字段名 或 类型"
    end
    local arr_col_name = {}
    for name in string.gmatch(col_name_ln, regex) do        
        if(#name <= 0)then io.close(file) return false, "字段名异常" end 
        table.insert(arr_col_name, name)
    end
    local arr_col_type = {}
    for type in string.gmatch(col_type_ln, regex) do        
        if(#type <= 0)then io.close(file) return false, "列类型有异常" end 
        table.insert(arr_col_type, type)
    end
    if(#arr_col_name ~= #arr_col_type)then io.close(file) return false, "列名与类型个数不匹配" end    
    local rowCount = 3;
    -- 检查行
    for line in file:lines() do	
        line = line..","
        rowCount = rowCount + 1
        if string.find(line, '^[^#,]') then
            local t_line = {}
            local col_num = 0
            -- 扫描列
            for value in string.gmatch(line, '([^,]*),') do
                col_num = col_num + 1                
                local key = arr_col_name[col_num]
                local b_key = true
                if(key == nil)then b_key = false end                                                      
                local b_type = true
                if(value ~= nil) then b_type = totype(value, arr_col_type[col_num]) ~= nil end
                if(b_key == false or b_type == false)then
                    io.close(file)
                    return false, "包含无效数据 行 = "..rowCount.." 列 = "..col_num  
                end
            end		
        end
    end   
    io.close(file)
    return true, "检测成功"
end




function csv_2_hash(path, arr_index)
    local file = io.open(path, 'r');
    local regex = '[^,]+'

    -- 读取数据 注释 字段名 和 类型 
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
   
    -- 读取 注释 字段名 和 类型 
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
    -- 扫描行
    for line in file:lines() do
        line = line..','
        if string.find(line, '^[^#,]') then
            local t_line = {}
            local col_num = 0
            -- 扫描列
            for value in string.gmatch(line, '([^,]*),') do
                col_num = col_num + 1
                -- 建立键值对
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