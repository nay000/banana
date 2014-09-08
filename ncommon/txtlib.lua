--读取配置文件的公共类
local setmetatable = setmetatable
local _G = _G

module "common.txtlib"
setmetatable(_M, { __index = _G })

--读取以tab作为分隔符的TXT文件,
--不带表头的文件，全部以从1开始的数组进行读取
--带表头的文件，以KEY为名进行读取
--每一行使用从1开始的下标数组进行记录
-- bReadTableHead == 1 表示需要读取表头， = 0则不需要
loadTabFile = function(szFileName, bReadTableHead)
    if(szFileName == nil) then
        TraceError("------------------------------")
        TraceError("--!!ERROR:获取配置文件没有传入文件路径名称")
        TraceError("------------------------------")
        return
    end

    --返回的结果
    local result = {}

    --读取文件
    local bufsize = 2^13
    local file = io.open(szFileName, "r")
    if(file == nil) then
        TraceError("------------------------------")
        TraceError("--!!ERROR:配置文件没有找到:"..szFileName)
        TraceError("------------------------------")
        return
    end
    bReadTableHead = bReadTableHead or 0;
	while(true) do
		--读取文件内容
		local lines, rest = file:read(bufsize, "*line")
		if not lines then break end

	    local l = split(lines, "\n")        --每行的内容
	    local tKeys = split(l[1], "\t")      --拿到对应的key
	    local nStartLine = 1;
	
	    local nKeyCount = #tKeys;
	    if (string.len(tKeys[nKeyCount]) == 0) then
	        tKeys[nKeyCount] = nil;
	        nKeyCount = nKeyCount - 1;
	    end
		
		if (bReadTableHead == 1) then
			nStartLine = 2;
		else
			tKeys = {};
			for i = 1, nKeyCount do
				tKeys[i] = i;
			end
		end

		--拿到对应的value
		local nCount = 0;
		for k = nStartLine, #l do
			if (string.len(l[k]) > 0) then
				nCount = nCount + 1;
				result[nCount] = {};
				local values = split(l[k], "\t")
				for i = 1, #tKeys do
					 result[nCount][tKeys[i]] = values[i] and tonumber(values[i]) or values[i];
				end
			end
		end
		break;
    end
	file:close()
    return result
end


loadtxt = function(filename)
    if(filename == nil) then
        TraceError("------------------------------")
        TraceError("--!!ERROR:获取配置文件没有传入文件路径名称")
        TraceError("------------------------------")
        return
    end

    --返回的结果
    local result = {}  

    --读取文件
    local bufsize = 2^13
    local file = io.open(filename, "r")
    if(file == nil) then 
        TraceError("------------------------------")
        TraceError("--!!ERROR:配置文件没有找到:"..filename)
        TraceError("------------------------------")
        return
    end

    --读取文件内容
    while true do
        local lines, rest = file:read(bufsize, "*line")
        if not lines then break end

        local l = split(lines, "\n")        --每行的内容
        local keys = split(l[1], "\t")      --拿到对应的key

        --拿到对应的value
        local ids = {}
        for k = 2, #l do
            local values = split(l[k], "\t")
            if(values[1] and values[1] ~= "") then
                values[1] = values[1] and tonumber(values[1]) or values[1]
                result[values[1]] = {}
                table.insert(ids, values[1])
                for i = 1, #keys do
                     result[values[1]][keys[i]] = values[i] and tonumber(values[i]) or values[i]
                end     
            end
        end

        table.sort(ids, function(a, b) return a < b end)
        for i = 1, #ids - 1 do
            if(ids[i] == ids[i+1]) then
                TraceError("-----------------------------------")
                TraceError("ERROR:配置文件"..filename.."中发现了重复的ID配置")
                TraceError("-----------------------------------")
                break
            end
        end
    end
    file:close()
    return result    
end

