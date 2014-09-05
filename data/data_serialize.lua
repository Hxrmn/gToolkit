print("DATA")

module("zdata", package.seeall)

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
			if t <= MAX_SIGNED_BYTE and t >= MIN_SIGNED_BYTE then return "B" .. byte2str(t, true)
			elseif t <= MAX_SIGNED_SHORT and t >= MIN_SIGNED_SHORT then return "W" .. short2str(t, true)
			elseif t <= MAX_SIGNED_LONG and t >= MIN_SIGNED_LONG then return "I" .. int2str(t, true)
			elseif t >= 0 and t <= MAX_UNSIGNED_LONG then return "U" .. int2str(t, false)
			else return "F" .. str2float(t)
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
	elseif ttype == 'B' then return str2byte(data, true), string.sub(data,2,string.len(data))
	elseif ttype == 'W' then return str2short(data, true), string.sub(data,3,string.len(data))
	elseif ttype == 'I' then return str2int(data, true), string.sub(data,5,string.len(data))
	elseif ttype == 'U' then return str2int(data, false), string.sub(data,5,string.len(data))
	elseif ttype == 'F' then return str2float(data), string.sub(data,5,string.len(data))
	elseif ttype == 'S' then
		local e = string.find(data,'\0')
		return string.sub(data,1,e-1), string.sub(data,1+e,string.len(data))
	end
end

function serialize(t, binary)
	local vstr = getValueString(t)
	local compressed = lzw_encode(vstr)

	if not binary then
		local lzwVer = base64_encode(compressed)
		local rawVer = base64_encode(vstr)

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

function deserialize(str, binary)
	local mode = string.sub(str,1,1)
	str = string.sub(str,2,string.len(str))

	if not binary then
		str = base64_decode(str)
	end

	if mode == 'C' then
		local vstr = lzw_decode(str)
		return getStringValue(vstr)
	elseif mode == 'R' then
		return getStringValue(str)		
	end

end

local t = deserialize( serialize({"Hello", "world", 12, 6500}) )

PrintTable( t )