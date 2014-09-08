-------------------------------------------------
---      *** BitLibEmu for Lua ***            ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------

local mod   = math.fmod
local floor = math.floor
bit = {}

----------------------------------------

local function cap(x)
	return mod(x,4294967296)
end

----------------------------------------

function bit.bnot(x)
	return 4294967295-cap(x)
end

----------------------------------------

function bit.lshift(x,n)
	return cap(cap(x)*2^n)
end

----------------------------------------

function bit.rshift(x,n)
	return floor(cap(x)/2^n)
end

----------------------------------------

function bit.band(x,y)
	local z,i,j = 0,1
	for j = 0,31 do
		if (mod(x,2)==1 and mod(y,2)==1) then
			z = z + i
		end
		x = bit.rshift(x,1)
		y = bit.rshift(y,1)
		i = i*2
	end
	return z
end

----------------------------------------

function bit.bor(x,y)
	local z,i,j = 0,1
	for j = 0,31 do
		if (mod(x,2)==1 or mod(y,2)==1) then
			z = z + i
		end
		x = bit.rshift(x,1)
		y = bit.rshift(y,1)
		i = i*2
	end
	return z
end

----------------------------------------

function bit.bxor(x,y)
	local z,i,j = 0,1
	for j = 0,31 do
		if (mod(x,2)~=mod(y,2)) then
			z = z + i
		end
		x = bit.rshift(x,1)
		y = bit.rshift(y,1)
		i = i*2
	end
	return z
end



-------------------------------------------------
---      *** SHA-1 algorithm for Lua ***      ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------

local strlen  = string.len
local strchar = string.char
local strbyte = string.byte
local strsub  = string.sub
local floor   = math.floor
local bnot    = bit.bnot
local band    = bit.band
local bor     = bit.bor
local bxor    = bit.bxor
local shl     = bit.lshift
local shr     = bit.rshift
local h0, h1, h2, h3, h4

-------------------------------------------------

local function LeftRotate(val, nr)
	return shl(val, nr) + shr(val, 32 - nr)
end

-------------------------------------------------

local function ToHex(num)
	local i, d
	local str = ""
	for i = 1, 8 do
		d = band(num, 15)
		if (d < 10) then
			str = strchar(d + 48) .. str
		else
			str = strchar(d + 87) .. str
		end
		num = floor(num / 16)
	end
	return str
end

-------------------------------------------------

local function PreProcess(str)
	local bitlen, i
	local str2 = ""
	bitlen = strlen(str) * 8
	str = str .. strchar(128)
	i = 56 - band(strlen(str), 63)
	if (i < 0) then
		i = i + 64
	end
	for i = 1, i do
		str = str .. strchar(0)
	end
	for i = 1, 8 do
		str2 = strchar(band(bitlen, 255)) .. str2
		bitlen = floor(bitlen / 256)
	end
	return str .. str2
end

-------------------------------------------------

local function MainLoop(str)
	local a, b, c, d, e, f, k, t
	local i, j
	local w = {}
	while (str ~= "") do
		for i = 0, 15 do
			w[i] = 0
			for j = 1, 4 do
				w[i] = w[i] * 256 + strbyte(str, i * 4 + j)
			end
		end
		for i = 16, 79 do
			w[i] = LeftRotate(bxor(bxor(w[i - 3], w[i - 8]), bxor(w[i - 14], w[i - 16])), 1)
		end
		a = h0
		b = h1
		c = h2
		d = h3
		e = h4
		for i = 0, 79 do
			if (i < 20) then
				f = bor(band(b, c), band(bnot(b), d))
				k = 1518500249
			elseif (i < 40) then
				f = bxor(bxor(b, c), d)
				k = 1859775393
			elseif (i < 60) then
				f = bor(bor(band(b, c), band(b, d)), band(c, d))
				k = 2400959708
			else
				f = bxor(bxor(b, c), d)
				k = 3395469782
			end
			t = LeftRotate(a, 5) + f + e + k + w[i]	
			e = d
			d = c
			c = LeftRotate(b, 30)
			b = a
			a = t
		end
		h0 = band(h0 + a, 4294967295)
		h1 = band(h1 + b, 4294967295)
		h2 = band(h2 + c, 4294967295)
		h3 = band(h3 + d, 4294967295)
		h4 = band(h4 + e, 4294967295)
		str = strsub(str, 65)
	end
end

-------------------------------------------------

function Sha1(str)
	str = PreProcess(str)
	h0  = 1732584193
	h1  = 4023233417
	h2  = 2562383102
	h3  = 0271733878
	h4  = 3285377520
	MainLoop(str)
	return  ToHex(h0) ..
		ToHex(h1) ..
		ToHex(h2) ..
		ToHex(h3) ..
		ToHex(h4)
end

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------


-------------------------------------------------
---      *** SHA-1 algorithm for Lua ***      ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
--- License: You may use this code in your    ---
---          projects as long as this header  ---
---          stays intact.                    ---
-------------------------------------------------

local strlen  = string.len
local strchar = string.char
local strbyte = string.byte
local strsub  = string.sub
local floor   = math.floor
local bnot    = bit.bnot
local band    = bit.band
local bor     = bit.bor
local bxor    = bit.bxor
local shl     = bit.lshift
local shr     = bit.rshift
local h0, h1, h2, h3, h4

-------------------------------------------------

local function LeftRotate(val, nr)
	return shl(val, nr) + shr(val, 32 - nr)
end

-------------------------------------------------

local function ToHex(num)
	local i, d
	local str = ""
	for i = 1, 8 do
		d = band(num, 15)
		if (d < 10) then
			str = strchar(d + 48) .. str
		else
			str = strchar(d + 87) .. str
		end
		num = floor(num / 16)
	end
	return str
end

-------------------------------------------------

local function PreProcess(str)
	local bitlen, i
	local str2 = ""
	bitlen = strlen(str) * 8
	str = str .. strchar(128)
	i = 56 - band(strlen(str), 63)
	if (i < 0) then
		i = i + 64
	end
	for i = 1, i do
		str = str .. strchar(0)
	end
	for i = 1, 8 do
		str2 = strchar(band(bitlen, 255)) .. str2
		bitlen = floor(bitlen / 256)
	end
	return str .. str2
end

-------------------------------------------------

local function MainLoop(str)
	local a, b, c, d, e, f, k, t
	local i, j
	local w = {}
	while (str ~= "") do
		for i = 0, 15 do
			w[i] = 0
			for j = 1, 4 do
				w[i] = w[i] * 256 + strbyte(str, i * 4 + j)
			end
		end
		for i = 16, 79 do
			w[i] = LeftRotate(bxor(bxor(w[i - 3], w[i - 8]), bxor(w[i - 14], w[i - 16])), 1)
		end
		a = h0
		b = h1
		c = h2
		d = h3
		e = h4
		for i = 0, 79 do
			if (i < 20) then
				f = bor(band(b, c), band(bnot(b), d))
				k = 1518500249
			elseif (i < 40) then
				f = bxor(bxor(b, c), d)
				k = 1859775393
			elseif (i < 60) then
				f = bor(bor(band(b, c), band(b, d)), band(c, d))
				k = 2400959708
			else
				f = bxor(bxor(b, c), d)
				k = 3395469782
			end
			t = LeftRotate(a, 5) + f + e + k + w[i]	
			e = d
			d = c
			c = LeftRotate(b, 30)
			b = a
			a = t
		end
		h0 = band(h0 + a, 4294967295)
		h1 = band(h1 + b, 4294967295)
		h2 = band(h2 + c, 4294967295)
		h3 = band(h3 + d, 4294967295)
		h4 = band(h4 + e, 4294967295)
		str = strsub(str, 65)
	end
end

-------------------------------------------------

function Sha1(str)
	str = PreProcess(str)
	h0  = 1732584193
	h1  = 4023233417
	h2  = 2562383102
	h3  = 0271733878
	h4  = 3285377520
	MainLoop(str)
	return  ToHex(h0) ..
		ToHex(h1) ..
		ToHex(h2) ..
		ToHex(h3) ..
		ToHex(h4)
end

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------


function lsh(value,shift)
	return (value*(2^shift)) % 256
end

-- shift right
 function rsh(value,shift)
	return math.floor(value/2^shift) % 256
end

-- return single bit (for OR)
function bit2(x,b)
	return (x % 2^b - x % 2^(b-1) > 0)
end

-- logic OR for number values
 function lor(x,y)
	result = 0
	for p=1,8 do result = result + (((bit2(x,p) or bit2(y,p)) == true) and 2^(p-1) or 0) end
	return result
end

-- encryption table
base64chars = {[0]='A',[1]='B',[2]='C',[3]='D',[4]='E',[5]='F',[6]='G',[7]='H',[8]='I',[9]='J',[10]='K',[11]='L',[12]='M',[13]='N',[14]='O',[15]='P',[16]='Q',[17]='R',[18]='S',[19]='T',[20]='U',[21]='V',[22]='W',[23]='X',[24]='Y',[25]='Z',[26]='a',[27]='b',[28]='c',[29]='d',[30]='e',[31]='f',[32]='g',[33]='h',[34]='i',[35]='j',[36]='k',[37]='l',[38]='m',[39]='n',[40]='o',[41]='p',[42]='q',[43]='r',[44]='s',[45]='t',[46]='u',[47]='v',[48]='w',[49]='x',[50]='y',[51]='z',[52]='0',[53]='1',[54]='2',[55]='3',[56]='4',[57]='5',[58]='6',[59]='7',[60]='8',[61]='9',[62]='-',[63]='_'}

-- function encode
-- encodes input string to base64.
function enc(data)
	local bytes = {}
	local result = ""
	for spos=0,string.len(data)-1,3 do
		for byte=1,3 do bytes[byte] = string.byte(string.sub(data,(spos+byte))) or 0 end
		result = string.format('%s%s%s%s%s',result,base64chars[rsh(bytes[1],2)],base64chars[lor(lsh((bytes[1] % 4),4), rsh(bytes[2],4))] or "=",((#data-spos) > 1) and base64chars[lor(lsh(bytes[2] % 16,2), rsh(bytes[3],6))] or "=",((#data-spos) > 2) and base64chars[(bytes[3] % 64)] or "=")
	end
	return result
end

-- decryption table
base64bytes = {['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,['l']=37,['m']=38,['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['-']=62,['_']=63,['=']=nil}

-- function decode
-- decode base64 input to string
function dec(data)
	local chars = {}
	local result=""
	for dpos=0,string.len(data)-1,4 do
		for char=1,4 do chars[char] = base64bytes[(string.sub(data,(dpos+char),(dpos+char)) or "=")] end
		result = string.format('%s%s%s%s',result,string.char(lor(lsh(chars[1],2), rsh(chars[2],4))),(chars[3] ~= nil) and string.char(lor(lsh(chars[2],4), rsh(chars[3],2))) or "",(chars[4] ~= nil) and string.char(lor(lsh(chars[3],6) % 192, (chars[4]))) or "")
	end
	return result
end
