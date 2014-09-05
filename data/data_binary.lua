--BINARY FUNCTIONS
--IEEE float conversion adapted from http://snippets.luacode.org/snippets/IEEE_float_conversion_144

print("DATA BINARY")

module("zdata", package.seeall, package.inherit(bit))

MIN_SIGNED_BYTE = -128
MAX_SIGNED_BYTE = 127
MAX_UNSIGNED_BYTE = 255

MIN_SIGNED_SHORT = -32768
MAX_SIGNED_SHORT = 32767
MAX_UNSIGNED_SHORT = 65535

MIN_SIGNED_LONG = -2147483648
MAX_SIGNED_LONG = 2147483647
MAX_UNSIGNED_LONG = 4294967295

local function sbrsh(v, b) return string.char(band(rshift(v, b), 0xFF)) end
local function sblsh(s, e, b) return lshift(s:byte(e), b) end

function float2str(value)
	local s=value<0 and 1 or 0
	if math.abs(value)==1/0 then return (s==1 and "\0\0\0\255" or "\0\0\0\127") end
	if value~=value then return "\170\170\170\255" end
	local fr,exp=math.frexp(math.abs(value))
	return string.char(math.floor(fr*2^24)%256)..
	string.char(math.floor(fr*2^16)%256)..
	string.char(math.floor(fr*2^8)%256)..
	string.char(math.floor(exp+64)%128+128*s)
end

function str2float(str)
	local fr, b = str:byte(1)/2^24+str:byte(2)/2^16+str:byte(3)/2^8, sblsh(str, 4, 0)
	local exp, s = band(b, 0x7F) - 0x40, math.floor(b/128)
	if exp==63 then return (fr==0 and (1-2*s)/0 or 0/0) end
	local n = (1-2*s)*fr*2^exp

	--fix wonky rounding
	if n - math.ceil(n) < 0.000001 then
		n = n + 0.000001
		return math.floor(n*100000)/100000
	end

	return n
end

function int2str(value, signed)
	if not signed then value = value + MAX_SIGNED_LONG + 1 end
	return sbrsh(value,24) .. sbrsh(value,16) .. sbrsh(value,8) .. sbrsh(value, 0)
end

function str2int(str, signed)
	local v = sblsh(str, 1, 24) + sblsh(str, 2, 16) + sblsh(str, 3, 8) + sblsh(str, 4, 0)
	return signed and v or (MAX_SIGNED_LONG + v + 1)
end

function short2str(value, signed)
	if signed then value = value - MIN_SIGNED_SHORT end
	return sbrsh(value, 8) .. sbrsh(value, 0)
end

function str2short(str, signed)
	local v = sblsh(str, 1, 8) + sblsh(str, 2, 0)
	return signed and (MIN_SIGNED_SHORT + v) or v
end

function byte2str(value, signed)
	if signed then value = value - MIN_SIGNED_BYTE end
	return sbrsh(value, 0)
end

function str2byte(str, signed)
	local v = sblsh(str, 1, 0)
	return signed and (MIN_SIGNED_BYTE + v) or v
end

print(MAX_UNSIGNED_LONG)
print(str2int( int2str(MAX_UNSIGNED_LONG, false), false ) )