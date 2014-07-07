--BINARY FUNCTIONS
--IEEE float conversion from http://snippets.luacode.org/snippets/IEEE_float_conversion_144

print("DATA")

module("zdata", package.seeall)


local function float2str(value)
	local s=value<0 and 1 or 0
	if math.abs(value)==1/0 then return (s==1 and "\0\0\0\255" or "\0\0\0\127") end
	if value~=value then return "\170\170\170\255" end
	local fr,exp=math.frexp(math.abs(value))
	return string.char(math.floor(fr*2^24)%256)..
	string.char(math.floor(fr*2^16)%256)..
	string.char(math.floor(fr*2^8)%256)..
	string.char(math.floor(exp+64)%128+128*s)
end

local function str2float(str)
	local fr=str:byte(1)/2^24+str:byte(2)/2^16+str:byte(3)/2^8
	local exp=str:byte(4)%128-64
	local s=math.floor(str:byte(4)/128)
	if exp==63 then return (fr==0 and (1-2*s)/0 or 0/0) end
	local n = (1-2*s)*fr*2^exp

	--fix wonky rounding
	if n - math.ceil(n) < 0.000001 then
		n = n + 0.000001
		return math.floor(n*100000)/100000
	end

	return n
end

local function int2str(value)
	return string.char(math.floor(value/2^24)%256)..
	string.char(math.floor(value/2^16)%256)..
	string.char(math.floor(value/2^8)%256)..
	string.char(math.floor(value)%256)
end

local function str2int(str)
	return str:byte(1)*2^24+str:byte(2)*2^16+str:byte(3)*2^8+str:byte(4)
end

local function short2str(value)
	return string.char(math.floor(value/2^8)%256)..
	string.char(math.floor(value)%256)
end

local function str2short(str)
	return str:byte(1)*2^8+str:byte(2)
end

--BASE64 ENCODING / DECODING
--Code from http://lua-users.org/wiki/BaseSixtyFour
--Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
--licensed under the terms of the LGPL2

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function base64encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local function base64decode(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

--LZW COMPRESSION
--Coded by Zak Blystone

local function LZWEncode(sInput)
	local stBits, dict, result, s, ch, temp = 8, {}, {}, ""
	for i=0,255 do dict[string.char(i)] = i+1 end

	for i = 1, string.len(sInput) do
		ch = string.sub(sInput, i, i)
		temp = s..ch
		if dict[temp] then
			s = temp
		else
			table.insert(result, dict[s])
			dict[temp] = #result + 256
			s = ch
		end
	end
	table.insert(result, dict[s])

	local function maxBits(v) for i=1, 32 do if v < 2^i then return i end end end
	for i=1, #result do
		stBits = math.max(maxBits(result[i]), stBits)
	end

	local ch, iBit, str = 0, 0, string.char(stBits)

	for i=1, #result do
		for b=1, stBits do
			iBit = iBit + 1
			ch = ch + math.floor(result[i]/2^(b-1)) % 2 * (2^(iBit-1))
			if iBit == 8 then
				ch, iBit, str = 0, 0, str .. string.char(ch)
			end
		end
	end

	if iBit ~= 0 then str = str .. string.char(ch) end

	return str
end

local function LZWDecode(str)
	local dict, result, entry, ch, temp, code = {}, {}
	for i=0,255 do dict[i+1] = string.char(i) end

	local data, code, iBit, stBits = {}, 0, 0, str:byte(i)

	for i=1, string.len(str)-1 do
		for b=1, 8 do
			iBit = iBit + 1
			code = code + math.floor(str:byte(i+1)/2^(b-1)) % 2 * (2^(iBit-1))

			if iBit == stBits then
				table.insert(data, code)
				code, iBit = 0, 0
			end
		end
	end

	temp = data[1]
	table.insert(result, dict[temp])

	for i = 2, #data do
		code = data[i]
		entry = dict[code]
		ch = entry and string.sub(entry, 1, 1) or string.sub(dict[temp], 1, 1)
		table.insert(result, entry or dict[temp]..ch)
		table.insert(dict, dict[temp]..ch)
		temp = code
	end

	return table.concat(result)
end

--SERIALIZATION
--Coded by Zak Blystone

local function getValueString(t)
	local ttype = type(t)

	if ttype == "table" then
		local str,keys = "T", false
		local n = 0 for k,v in pairs(t) do n = n + 1 end
		str = str .. getValueString(n)

		local mrk = {}
		for k,v in ipairs(t) do
			str = str .. getValueString(v)
			mrk[k] = true
		end
		
		for k,v in pairs(t) do
			if not mrk[k] and not keys then str = str .. 'K' keys = true end
			if not mrk[k] then str = str .. getValueString(k) .. getValueString(v) end
		end
		return str
	elseif ttype == "number" then
		local int = math.floor(t) == t
		if int then
			if t <= 127 and t >= -128 then return "B" .. string.char(t)
			elseif t <= 32767 and t >= -32768 then return "W" .. short2str(t)
			else return "I" .. int2str(t)
			end
		else
			return "F" .. float2str(t)
		end
	elseif ttype == "string" then
		return "S" .. t .. '\0'
	else
		return "N"
	end
end

local function getStringValue(str)
	local ttype = string.sub(str,1,1)
	local data = string.sub(str,2,string.len(str))

	if ttype == 'T' then
		local v,data = nil, data
		local t = {}
		v,data = getStringValue(data)

		local n = v
		local keys = false
		for i=1, n do
			if string.sub(data,1,1) == 'K' then
				data = string.sub(data,2,string.len(data))
				keys = true
			end

			if keys then
				v,data = getStringValue(data)
				local key = v

				v,data = getStringValue(data)
				t[key] = v
			else
				v,data = getStringValue(data)
				table.insert(t, v)
			end
		end
		return t, data
	elseif ttype == 'N' then return nil, data
	elseif ttype == 'B' then return string.byte(data), string.sub(data,2,string.len(data))
	elseif ttype == 'W' then return str2short(data), string.sub(data,3,string.len(data))
	elseif ttype == 'I' then return str2int(data), string.sub(data,5,string.len(data))
	elseif ttype == 'F' then return str2float(data), string.sub(data,5,string.len(data))
	elseif ttype == 'S' then
		local e = string.find(data,'\0')
		return string.sub(data,1,e-1), string.sub(data,1+e,string.len(data))
	end
end

function Serialize(t, binary)
	local vstr = getValueString(t)
	local compressed = LZWEncode(vstr)

	if not binary then
		local lzwVer = base64encode(compressed)
		local rawVer = base64encode(vstr)

		if DATA_DEBUG then
			print("COMPRESSED RAW SIZE: " .. string.len(vstr) .. " -> " .. string.len(compressed))
			print("COMPRESSED SIZE: " .. string.len(rawVer) .. " -> " .. string.len(lzwVer))
			print("COMPRESSION DELTA: " .. (string.len(rawVer) - string.len(lzwVer)))
		end

		if string.len(lzwVer) < string.len(rawVer) then
			return 'C' .. lzwVer
		else
			return 'R' .. rawVer
		end
	else
		if string.len(compressed) < string.len(vstr) then
			return 'C' .. compressed
		else
			return 'R' .. vstr
		end
	end
end

function DeSerialize(str, binary)
	local mode = string.sub(str,1,1)
	str = string.sub(str,2,string.len(str))

	if not binary then
		str = base64decode(str)
	end

	if mode == 'C' then
		local vstr = LZWDecode(str)
		return getStringValue(vstr)
	elseif mode == 'R' then
		return getStringValue(str)		
	end

end