--[[
require "io"

local file_read  = io.open("e:\\work\\gamedev\\code\\product\\win32d\\server\\ip.txt", "r")
local file_write = {}
file_write[1] = io.open("e:\\work\\gamedev\\code\\product\\win32d\\server\\ip1.lua", "w")
file_write[2] = io.open("e:\\work\\gamedev\\code\\product\\win32d\\server\\ip2.lua", "w")
file_write[3] = io.open("e:\\work\\gamedev\\code\\product\\win32d\\server\\ip3.lua", "w")
file_write[4] = io.open("e:\\work\\gamedev\\code\\product\\win32d\\server\\ip4.lua", "w")

local fff = 0
for line in file_read:lines() do
	local ipinfo = split(line, " ")
	if (fff <= 100000) then
		file_write[1]:write("{ip=")
		file_write[1]:write(ipinfo[1])
		file_write[1]:write(", city=\"")
		file_write[1]:write(ipinfo[2])
		file_write[1]:write("\"},\r\n")
	end
	if (fff >= 100000 and fff <= 200000) then
		file_write[2]:write("{ip=")
		file_write[2]:write(ipinfo[1])
		file_write[2]:write(", city=\"")
		file_write[2]:write(ipinfo[2])
		file_write[2]:write("\"},\r\n")
	end
	if (fff >= 200000 and fff <= 300000) then
		file_write[3]:write("{ip=")
		file_write[3]:write(ipinfo[1])
		file_write[3]:write(", city=\"")
		file_write[3]:write(ipinfo[2])
		file_write[3]:write("\"},\r\n")
	end
	if (fff >= 300000 and fff <= 400000) then
		file_write[4]:write("{ip=")
		file_write[4]:write(ipinfo[1])
		file_write[4]:write(", city=\"")
		file_write[4]:write(ipinfo[2])
		file_write[4]:write("\"},\r\n")
	end
	fff = fff + 1
end

file_read:close()
file_write[1]:close()
file_write[2]:close()
file_write[3]:close()
file_write[4]:close()
--]]
if(ip_info_1 == nil) then
	dofile("common/ipinfo/ip.lua")
end

iplib = {}
--通过ip查找来自哪里
function iplib.get_location_by_ip(ip)
	local  iptable=split(ip, ".")
	if (table.getn(iptable) ~= 4) then
		return 0, "未知"
	end
	local  ip_search = iptable[1]*16777216 + iptable[2]*65536 + iptable[3]*256 + iptable[4]
	local ip_info_seg=ip_info_1	
	local start_tag = 1
	local end_tag = table.getn(ip_info_seg)
	local find_tag = math.floor((start_tag + end_tag) /2)

	while(find_tag ~= start_tag and find_tag ~= end_tag) do
		if (ip_search > ip_info_seg[find_tag].ip) then
			start_tag = find_tag
		elseif (ip_search < ip_info_seg[find_tag].ip) then
			end_tag = find_tag
		else
			break
		end
		find_tag = math.floor((start_tag + end_tag) /2)
	end
	return math.floor(ip_info_seg[find_tag].ip / 4), tools.AnsiToUtf8(ip_info_seg[find_tag].city)
end
