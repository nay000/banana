
ndebug = {}
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

function ndebug.get_time_str()
    local date = os.date("*t", os.time())
    local sz_space = '-'
    local sz_date = date.year..sz_space..date.month..sz_space..date.day..sz_space..date.hour..sz_space..date.min..sz_space..date.sec
    return sz_date
end

function ndebug.trace(...)
    local dy_param = {...}
    if #dy_param == 0 then
        print("nil")
        return
    end
    
    local n_space = 1
    local sz_tab = ("    ")
    local sz_wrap = '\n'
    local n_tab = 0;    
    
    local function f_print(sz_idx, sz_v, is_type)
        local sz_t = type(sz_v)        
        is_type = (is_type ~= nil and type(is_type) == 'number') and is_type or (sz_t == 'table' and 1 or 0)
        local sz_s = string.rep(sz_tab, n_tab)
        if type(sz_idx) == 'number' then
        	sz_idx = '['..tostring(sz_idx)..']'
        else
            sz_idx = tostring(sz_idx)
        end
        local sz_rv = tostring(sz_v)
        sz_s = sz_s..sz_idx..string.rep(sz_tab, n_space)	   	             
        sz_s = sz_s..sz_rv..string.rep(sz_tab, n_space)        
        if is_type == 0 then
            local sz_k = sz_t == 'table' and "" or sz_t
	        sz_s = sz_s..sz_k
        else
        	sz_s = sz_s..sz_wrap..string.rep(sz_tab, n_tab)..'{';
        end      
		             
        print(sz_s)
    end
        
    local tb_printed = {}
    local function f_func(tb_p)  
    	tb_printed[tb_p] = 1      	
        for k, v in pairs(tb_p) do
            local sz_t = type(v)
            if sz_t ~= 'table' then
                f_print(k, v)
            else
            	if tb_printed[v] == 1 then
            		f_print(k, v, 0)
            	else       
            		tb_printed[v] = 1     	            
	            	f_print(k, v)
					n_tab = n_tab + 1
	                f_func(v, n_tab) 
	                n_tab = n_tab - 1                   	               
	                print(string.rep(sz_tab, n_tab)..'}')
                end                               
            end
        end     
    end
    
	f_func(dy_param)    
end

function ndebug.get_time_str()
    local date = os.date("*t", os.time())
    local sz_space = '-'
    local sz_date = date.year..sz_space..date.month..sz_space..date.day..sz_space..date.hour..sz_space..date.min..sz_space..date.sec
    return sz_date
end


-- print(" ndebug.lua loaded ")

-- ndebug.trace(1,2,3)
-- ndebug.trace({1,2,3})
-- ndebug.trace({1,2,3,{11,22},4})













