print("NET RPC " .. (SERVER and "SERVER" or "CLIENT"))

module("znet", package.seeall)

local RPC = {}

local function dummyCall(self, func, args)
	if args[1] == self then table.remove(args, 1) end

	if type(func) ~= "string" then return end

	local mcall = self:__lookup( func )
	if not mcall then
		ErrorNoHalt("RPC CALL: INVALID: " .. tostring(func))
		return
	end

	if #args > 15 then
		ErrorNoHalt("RPC CALL: TOO MANY ARGUMENTS (max 15)\n")
	end

	if RPC_DEBUG then print("RPC CALL: " .. tostring(self) .. " : " .. tostring(func) .. "[" .. mcall .. "] : " .. #args .. " args.") end
	for k,v in pairs(args) do
		if RPC_DEBUG then print("\targs[" .. k .. "] = " .. tostring(v)) end
	end

	table.insert( self.pending_calls, { mcall = mcall, args = args } )

	if self.onCall then
		self.onCall()
	end
end

RPC.__index = function(self, k)
	local v = rawget(self, k)
	if v then return v end
	if RPC[k] then return RPC[k] end

	return function(...)

		if self.role then
			return dummyCall(self, k, {...})
		end

	end
end

function RPC:__init( tab, role, onCall )
	self.role = role
	self.calltable = tab
	self.pending_calls = {}
	self.rpc_lookup0 = {}
	self.rpc_lookup1 = {}
	self.onCall = onCall

	local i = 1
	for k,v in pairs(getmetatable(self.calltable)) do
		--print("\t" .. i .. "] " .. k .. " : " .. tostring(v))
		self.rpc_lookup0[k] = i - 1
		self.rpc_lookup1[i] = k
		i = i + 1
	end
	return self
end

function RPC:__lookup( v )
	if type(v) == "number" then
		return self.rpc_lookup1[v+1]
	elseif type(v) == "string" then
		return self.rpc_lookup0[v]
	end
end

function RPC:Post()
	local n_calls = #self.pending_calls
	if n_calls > 15 then n_calls = 15 end
	net.WriteUInt(n_calls, 4)

	if RPC_DEBUG then print("RPC POST: " .. n_calls .. " calls") end

	for i=1, 15 do
		local t = self.pending_calls[1]
		if not t then return end

		net.WriteUInt(t.mcall, 8) --TODO optimize

		net.WriteUInt(#t.args, 4)
		for k,v in pairs(t.args) do
			local vtype = znet.TypeOf(v)
			if RPC_DEBUG then print("DEFER TYPE: " .. tostring(v) .. " = " .. vtype) end
			net.WriteUInt(vtype, 4)
			znet.DefWriteValue(vtype, v)
		end

		table.remove(self.pending_calls, 1)
	end
end

function RPC:Receive(...)
	local n_calls = net.ReadUInt(4)
	local args = {}

	if RPC_DEBUG then print("RPC GOT: " .. n_calls .. " calls") end

	for i=1, n_calls do
		local mcall = net.ReadUInt(8) --TODO optimize
		local n_args = net.ReadUInt(4)

		for k,v in pairs({...}) do
			table.insert(args, v)
		end

		for j=1, n_args do
			local vtype = net.ReadUInt(4)
			table.insert(args, znet.DefReadValue(vtype))
		end

		local fname = self:__lookup(mcall)
		if RPC_DEBUG then print("CALL: " .. fname) end
		local b,e = pcall(self.calltable[fname], self.calltable, unpack(args))
		if not b then
			ErrorNoHalt("RPC_ERROR: " .. e)
		end
		args = {}
	end
end

function CreateRPCTable( tab, role, onCall )
	return setmetatable( {}, RPC ):__init( tab, role, onCall )
end