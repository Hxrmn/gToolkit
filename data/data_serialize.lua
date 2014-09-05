print("DATA SERIALIZE")

module("zdata", package.seeall)

--SERIALIZATION
--Coded by Zak Blystone

local ENTITY_BITS = 12
local USE_BITSTREAM = true

DT_NULL = 0
DT_BYTE = 1
DT_UBYTE = 2
DT_SHORT = 3
DT_USHORT = 4
DT_INT = 5
DT_UINT = 6
DT_FLOAT = 7
DT_VECTOR = 8
DT_CVECTOR = 9
DT_ENTITY = 10
DT_STRING = 11
DT_KEYS = 12
DT_TABLE = 13

local typenames = {
	"DT_NULL",
	"DT_BYTE",
	"DT_UBYTE",
	"DT_SHORT",
	"DT_USHORT",
	"DT_INT",
	"DT_UINT",
	"DT_FLOAT",
	"DT_VECTOR",
	"DT_CVECTOR",
	"DT_ENTITY",
	"DT_STRING",
	"DT_KEYS",
	"DT_TABLE",
}

local function DTName(d)
	return typenames[d+1] or "DT_UNKNOWN"
end

DT_STATUSBITS = 4

local stringMap = {}

local function initStringMap()
	stringMap.strings = {}
	stringMap.hash = {}
end

local function getValueString(t, buf)
	local ttype = type(t)

	local function numtype(t, v)
		buf:WriteBits(t, DT_STATUSBITS)
		if t == DT_BYTE then buf:WriteByte(v, true)
		elseif t == DT_UBYTE then buf:WriteByte(v, false)
		elseif t == DT_SHORT then buf:WriteShort(v, true)
		elseif t == DT_USHORT then buf:WriteShort(v, false)
		elseif t == DT_INT then buf:WriteInt(v, true)
		elseif t == DT_UINT then buf:WriteInt(v, false)
		elseif t == DT_FLOAT then buf:WriteFloat(v)
		else print("UNKNOWN TYPE: " .. tostring(t) .. " [" .. v .. "]") end
	end

	if ttype == "table" then
		buf:WriteBits(DT_TABLE, DT_STATUSBITS)
		local keys = false
		local n = 0 for k,v in pairs(t) do n = n + 1 end
		getValueString(n, buf)

		local mrk = {}
		for k,v in ipairs(t) do
			getValueString(v, buf)
			mrk[k] = true
		end
		
		for k,v in pairs(t) do
			if not mrk[k] and not keys then buf:WriteBits(DT_KEYS, DT_STATUSBITS) keys = true end
			if not mrk[k] then getValueString(k, buf) getValueString(v, buf) end
		end
	elseif ttype == "number" then
		local int = math.floor(t) == t
		if int then
			if t <= MAX_SIGNED_BYTE and t >= MIN_SIGNED_BYTE then numtype(DT_BYTE, t)
			elseif t >= 0 and t <= MAX_UNSIGNED_BYTE then numtype(DT_UBYTE, t)
			elseif t <= MAX_SIGNED_SHORT and t >= MIN_SIGNED_SHORT then numtype(DT_SHORT, t)
			elseif t >= 0 and t <= MAX_UNSIGNED_SHORT then numtype(DT_USHORT, t)
			elseif t <= MAX_SIGNED_LONG and t >= MIN_SIGNED_LONG then numtype(DT_INT, t)
			elseif t >= 0 and t <= MAX_UNSIGNED_LONG then numtype(DT_UINT, t)
			else numtype(DT_FLOAT, t)
			end
		else
			return numtype(DT_FLOAT, t)
		end
	elseif ttype == "Vector" then
		--if true or math.floor(t.x) == t.x or math.floor(t.y) == t.y or math.floor(t.z) == t.z then
			buf:WriteBits(DT_CVECTOR, DT_STATUSBITS)
			getValueString(t.x, buf)
			getValueString(t.y, buf)
			getValueString(t.z, buf)
		--[[else
			buf:WriteBits(DT_VECTOR, DT_STATUSBITS)
			buf:WriteFloat(t.x)
			buf:WriteFloat(t.y)
			buf:WriteFloat(t.z)
		end]]
	elseif ttype == "Entity" then
		if IsValid(t) and t:EntIndex() >= 0 then
			buf:WriteBits(DT_ENTITY, DT_STATUSBITS)
			buf:WriteBits(t:EntIndex(), ENTITY_BITS)
		else
			buf:WriteBits(DT_NULL, DT_STATUSBITS)
		end
	elseif ttype == "string" then
		buf:WriteBits(DT_STRING, DT_STATUSBITS)
		if stringMap.hash[t] then
			getValueString(stringMap.hash[t], buf)
		else
			table.insert(stringMap.strings, t)
			local id = #stringMap.strings
			stringMap.hash[t] = id
			getValueString(id-1, buf)
		end
	else
		buf:WriteBits(DT_NULL, DT_STATUSBITS)
	end
end

local function getStringValue(buf)
	local ttype = buf:ReadBits(DT_STATUSBITS)

	--print("TYPE: " .. DTName(ttype))

	local function numtype(t)
		if t == DT_BYTE then return buf:ReadByte(true) end
		if t == DT_UBYTE then return buf:ReadByte(false) end
		if t == DT_SHORT then return buf:ReadShort(true) end
		if t == DT_USHORT then return buf:ReadShort(false) end
		if t == DT_INT then return buf:ReadInt(true) end
		if t == DT_UINT then return buf:ReadInt(false) end
		if t == DT_FLOAT then return buf:ReadFloat() end
	end

	if ttype == DT_TABLE then
		local t = {}
		local n = getStringValue(buf)
		local keys = false
		for i=1, n do
			local v,f = getStringValue(buf)
			if f == 'K' then keys = true end

			if keys then
				local key = getStringValue(buf)
				t[key] = getStringValue(buf)
			else
				table.insert(t, v)
			end
		end
		return t, data
	elseif ttype == DT_KEYS then return nil, 'K'
	elseif ttype == DT_NULL then return nil
	elseif ttype >= DT_BYTE and ttype <= DT_FLOAT then return numtype(ttype)
	elseif ttype == DT_CVECTOR then
		local x = getStringValue(buf)
		local y = getStringValue(buf)
		local z = getStringValue(buf)
		return Vector(x,y,z)
	--[[elseif ttype == DT_VECTOR then
		return Vector(buf:ReadFloat(), buf:ReadFloat(), buf:ReadFloat())]]
	elseif ttype == DT_ENTITY then
		local index = buf:ReadBits(ENTITY_BITS)
		return ents.GetByIndex(index)
	elseif ttype == DT_STRING then
		local id = getStringValue(buf) + 1
		return stringMap.strings[id]
	end
end

function serialize(t, binary)
	local vout = out_stream(USE_BITSTREAM)
	initStringMap()
	getValueString(t, out_stream(USE_BITSTREAM))

	local map = ""
	for k,v in pairs(stringMap.strings) do map = map .. v .. "\0" end

	local lzwmap = lzw_encode(map)
	if string.len(lzwmap) < string.len(map) then
		getValueString(string.len(lzwmap), vout)
		vout:WriteStr('C' .. lzwmap)
	else
		getValueString(string.len(map), vout)
		vout:WriteStr('R' .. map)
	end

	getValueString(t, vout)

	local vstr = vout:GetString()
	local compressed = lzw_encode(vstr)

	print("COMPRESSED SIZE: " .. string.len(vstr) .. " -> " .. string.len(compressed))

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

	if not binary then str = base64_decode(str) end
	local vin = in_stream(USE_BITSTREAM)
	if mode == 'C' then
		vin:LoadString(lzw_decode(str))
	elseif mode == 'R' then
		vin:LoadString(str)	
	end

	local mapsize = getStringValue(vin)
	local map = ""
	local mapmode = vin:ReadStr(1)
	if mapmode == 'C' then
		map = lzw_decode(vin:ReadStr(mapsize))
	elseif mapmode == 'R' then
		map = vin:ReadStr(mapsize)
	end

	local term = 0

	initStringMap()
	local index = 1
	while index do
		index = string.find(map,'\0')
		if index then
			local s = string.sub(map, 1, index-1)
			map = string.sub(map, index+1)
			table.insert(stringMap.strings, s)
		end
	end

	return getStringValue(vin)	

end