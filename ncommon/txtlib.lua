--��ȡ�����ļ��Ĺ�����
local setmetatable = setmetatable
local _G = _G

module "common.txtlib"
setmetatable(_M, { __index = _G })

--��ȡ��tab��Ϊ�ָ�����TXT�ļ�,
--������ͷ���ļ���ȫ���Դ�1��ʼ��������ж�ȡ
--����ͷ���ļ�����KEYΪ�����ж�ȡ
--ÿһ��ʹ�ô�1��ʼ���±�������м�¼
-- bReadTableHead == 1 ��ʾ��Ҫ��ȡ��ͷ�� = 0����Ҫ
loadTabFile = function(szFileName, bReadTableHead)
    if(szFileName == nil) then
        TraceError("------------------------------")
        TraceError("--!!ERROR:��ȡ�����ļ�û�д����ļ�·������")
        TraceError("------------------------------")
        return
    end

    --���صĽ��
    local result = {}

    --��ȡ�ļ�
    local bufsize = 2^13
    local file = io.open(szFileName, "r")
    if(file == nil) then
        TraceError("------------------------------")
        TraceError("--!!ERROR:�����ļ�û���ҵ�:"..szFileName)
        TraceError("------------------------------")
        return
    end
    bReadTableHead = bReadTableHead or 0;
	while(true) do
		--��ȡ�ļ�����
		local lines, rest = file:read(bufsize, "*line")
		if not lines then break end

	    local l = split(lines, "\n")        --ÿ�е�����
	    local tKeys = split(l[1], "\t")      --�õ���Ӧ��key
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

		--�õ���Ӧ��value
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
        TraceError("--!!ERROR:��ȡ�����ļ�û�д����ļ�·������")
        TraceError("------------------------------")
        return
    end

    --���صĽ��
    local result = {}  

    --��ȡ�ļ�
    local bufsize = 2^13
    local file = io.open(filename, "r")
    if(file == nil) then 
        TraceError("------------------------------")
        TraceError("--!!ERROR:�����ļ�û���ҵ�:"..filename)
        TraceError("------------------------------")
        return
    end

    --��ȡ�ļ�����
    while true do
        local lines, rest = file:read(bufsize, "*line")
        if not lines then break end

        local l = split(lines, "\n")        --ÿ�е�����
        local keys = split(l[1], "\t")      --�õ���Ӧ��key

        --�õ���Ӧ��value
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
                TraceError("ERROR:�����ļ�"..filename.."�з������ظ���ID����")
                TraceError("-----------------------------------")
                break
            end
        end
    end
    file:close()
    return result    
end

