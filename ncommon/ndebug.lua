
ndebug = ndebug or {}
local print = print

function ndebug.new_stack()
    local tb_stack = {}
    tb_stack.resource = {}
    tb_stack.push = function(v)
        table.insert(tb_stack.resource, v)
    end
    tb_stack.pop = function()
        return table.remove(tb_stack.resource)
    end
    tb_stack.top = function()
        return tb_stack.resource[#tb_stack.resource]
    end
    
    return tb_stack
end



function ndebug.trace(...)
    local dy_param = {...}
    if #dy_param == 0 then
        print("nil")
        return
    end
    
    local n_space = 1
    local sz_tab = ("    ")
    local n_tab = 0;
    local cs_stack = ndebug.new_stack();
    
    local function f_print(sz_p, is_type)
        local sz_t = type(sz_p)
        sz_p = tostring(sz_p)
        sz_p = string.rep(sz_tab, n_tab)..sz_p
        is_type = is_type ~= nil and is_type or true
        if is_type then
            sz_p = sz_p..string.rep(sz_tab, n_space).."("..sz_t..")"
        end
        print(sz_p)
    end
        
    local function f_func(tb_p)
        for k, v in pairs(tb_p) do
            local sz_t = type(v)
            if sz_t ~= 'table' then
                f_print(k, v)
            else
                f_func(v)
            end
        end     
    end
    
    for k, v in pairs(dy_param) do
        n_tab = 0
        local sz_t = type(dy_param)
        if sz_t ~= 'table' then
            f_print(k, v)
        else
            f_func(v)
        end        
    end  
    
end

function ndebug.get_time_str()
    local date = os.date("*t", os.time())
    local sz_space = '-'
    local sz_date = date.year..sz_space..date.month..sz_space..date.day..sz_space..date.hour..sz_space..date.min..sz_space..date.sec
    return sz_date
end


print(" ndebug.lua loaded ")

-- ndebug.trace(1,2,3)
-- ndebug.trace({1,2,3})
-- ndebug.trace({1,2,3,{11,22},4})













