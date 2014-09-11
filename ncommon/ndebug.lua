
ndebug = {}
ndebug.record_dir = ""
ndebug.platform = ""	-- linux, windows
local print = print

function ndebug.check_platform()	
	local sz_time = ndebug.get_time_str()
	local sz_cmd = ndebug.concat_idx("mkdir ", "~tmp", sz_time, '\\', sz_time)
	local sz_remove = ndebug.concat_idx("rd /q /s ", "~tmp", sz_time)
	local n_re = os.execute(sz_cmd)
	if n_re == 0 then
		ndebug.platform = 'windows'
		os.execute(sz_remove)
		return
	end
	sz_cmd = ndebug.concat_idx("mkdir -p ", "~tmp", sz_time, '/', sz_time)
	sz_remove = ndebug.concat_idx("rm -rf ", "~tmp", sz_time)
	n_re = os.execute(sz_cmd)
	if n_re == 0 then
		ndebug.platform = 'linux'
		os.execute(sz_remove)
		return 
	end
	ndebug.trace(" error when judging platform ")
end

function ndebug.concat_idx(...)
	local p = {...}
	if #p == 1 then return p[1] end
	local res = {}
	for i = 1, #p do
		res[i] = ndebug.concat_idx(p[i])
	end
	return table.concat(res)
end

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

function ndebug.record(...)
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

function ndebug.env_dir()	
	--os.execute("echo %cd%")	
	local obj=io.popen("cd")  
	local path=obj:read("*all"):sub(1,-2) 
	obj:close()  
	return path
end

-- dir1/dir2/dir3/
function ndebug.mkdir(path)
	local sz_path = path	
	local sz_ori = "/"
	local sz_tar = "/"
	if ndebug.platform == "windows" then
		sz_tar = "\\"
	end	
	sz_path = string.gsub(sz_path, sz_ori, sz_tar) 
	local command = ndebug.concat_idx("mkdir ", sz_path)
	local re = os.execute(command)
	return re
end

--1 覆盖cover	2 追加 add	 path = t1/t2/tt.txt
function ndebug.mktext(path, mode)
	local n_mode = mode ~= nil and mode or 1
	local sz_path = path 
	local sz_cmd = ""
	local tb_mode = {">",">>"} 
	if ndebug.flatform == 'linux' then		
		
	elseif ndebug.flatform == 'windows' then
		sz_cmd = "cd.>>"
	end
end

ndebug.check_platform()
------------------------------------------------------------------------


--ndebug.trace(ndebug.mkdir("t1/t2/t3"))

--ndebug.trace(ndebug.env_dir())

--ndebug.trace(os.execute("mkdir tt\\ttt"))
--ndebug.trace(os.execute("mkdir -p ooxx/ooxx/ooxx"))

--local file = ndebug.record_dir.."record"..ndebug.get_time_str()
--file = ndebug.env_dir().."/src/test1.lua"
--ndebug.trace(ndebug.openfile(file, "r"))

-- print(" ndebug.lua loaded ")

-- ndebug.trace(1,2,3)
-- ndebug.trace({1,2,3})
-- ndebug.trace({1,2,3,{11,22},4})



--local sz_cmd = ndebug.concat_idx("mkdir -p ", "~tmp~", ndebug.get_time_str(), '/', ndebug.get_time_str())
--ndebug.trace(sz_cmd)
--ndebug.trace(os.execute(sz_cmd))






