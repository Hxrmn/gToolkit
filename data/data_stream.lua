
print("DATA STREAM")

module("zdata", package.seeall, package.inherit(bit))

local OUT = {} OUT.__index = OUT
local IN = {} IN.__index = IN

function OUT:Init(bitstream)
	if bitstream then
		self.bit = 0
		self.buffer = {}
	else
		self.buffer = ""
	end
	self.bitstream = bitstream
	return self
end

function OUT:GetString()
	if self.bitstream then
		local str = ""
		for i=1, #self.buffer do
			str = str .. string.char(self.buffer[i])
		end
		return str
	else
		return self.buffer
	end
end

function OUT:WriteToFile(name)
	file.Write(name, self:GetString())
end

function OUT:WriteBit(v)
	if not self.bitstream then error("buffer is not a bitstream") end
	local byte = rshift(self.bit, 3) + 1
	local bcmp = band(self.bit, 7)
	if bcmp == 0 then self.buffer[byte] = 0 end
	self.buffer[byte] = bor(self.buffer[byte], bit.lshift(v, bcmp))
	self.bit = self.bit + 1
end

function OUT:WriteBits(v, bits)
	if not self.bitstream then
		if bits > 0 then self.buffer = self.buffer .. string.char(band(v, 0xFF)) end
		if bits > 8 then self.buffer = self.buffer .. string.char(band(rshift(v,8), 0xFF)) end
		if bits > 16 then self.buffer = self.buffer .. string.char(band(rshift(v,16), 0xFF)) end
		if bits > 24 then self.buffer = self.buffer .. string.char(band(rshift(v,24), 0xFF)) end
		return
	end
	if bits > 32 or bits <= 0 then return end
	while bits > 0 do
		self:WriteBit(band(v, 1))
		v = rshift(v, 1)
		bits = bits - 1
	end
end

function OUT:WriteStr(str) 
	if self.bitstream then
		for i=1, string.len(str) do self:WriteBits(str:byte(i), 8) end
	else
		self.buffer = self.buffer .. str
	end
end
function OUT:WriteByte(v, signed) self:WriteStr(byte2str(v, signed)) end
function OUT:WriteShort(v, signed) self:WriteStr(short2str(v, signed)) end
function OUT:WriteInt(v, signed) self:WriteStr(int2str(v, signed)) end
function OUT:WriteFloat(v) self:WriteStr(float2str(v)) end

function IN:Init(bitstream)
	if bitstream then
		self.bit = 0
		self.buffer = {}
	else
		self.buffer = ""
	end
	self.bitstream = bitstream
	return self
end

function IN:LoadString(str)
	if self.bitstream then
		self.buffer = {}
		self.bit = 0
		for i=1, string.len(str) do self.buffer[i] = str:byte(i) end
	else
		self.buffer = str
	end
end

function IN:LoadFile(name)
	self:LoadString(file.Read(name,true))
end

function IN:ReadBit()
	if not self.bitstream then error("buffer is not a bitstream") end
	local byte = rshift(self.bit, 3) + 1
	local bcmp = band(self.bit, 7)
	local v = self.buffer[byte] or 0
	v = band(rshift(v, bcmp), 1)
	self.bit = self.bit + 1
	return v
end

function IN:ReadBits(bits)
	if not self.bitstream then 
		local v = 0
		if bits > 0 then v = v + self:ReadStr(1):byte(1) end
		if bits > 8 then v = v + lshift(self:ReadStr(1):byte(1),8) end
		if bits > 16 then v = v + lshift(self:ReadStr(1):byte(1),16) end
		if bits > 24 then v = v + lshift(self:ReadStr(1):byte(1),24) end
		return v
	end
	if bits > 32 or bits <= 0 then return 0 end

	local m = bits
	local value = 0
	while bits > 0 do
		value = bor(value, lshift(self:ReadBit(), m-bits))
		bits = bits - 1
	end

	return value
end

function IN:ReadStr(n)
	if self.bitstream then
		local s = ""
		for i=1, n do s = s .. string.char(self:ReadBits(8)) end
		return s
	else
		local r = string.sub(self.buffer, 1, n)
		self.buffer = string.sub(self.buffer, n+1)
		return r
	end
end
function IN:ReadByte(signed) return str2byte(self:ReadStr(1), signed) end
function IN:ReadShort(signed) return str2short(self:ReadStr(2), signed) end
function IN:ReadInt(signed) return str2int(self:ReadStr(4), signed) end
function IN:ReadFloat() return str2float(self:ReadStr(4)) end

function in_stream(bitstream) return setmetatable({}, IN):Init(bitstream) end
function out_stream(bitstream) return setmetatable({}, OUT):Init(bitstream) end