print("NET UTIL " .. (SERVER and "SERVER" or "CLIENT"))

module("znet", package.seeall)

local NMETA = {}
NMETA.__index = NMETA

function NMETA:Init(baseclass, networkString)
	self.nextIndex = 1
	self.spawn = baseclass
	self.netstring = networkString
	self.instances = {}
end

function NMETA:Create(index, ...)
	local out = setmetatable({}, self.spawn)

	out.__instanceIndex = index
	out.__factory = self

	if out.Init then out:Init(unpack({...})) end

	self.instances[index] = out

	return out
end

function NMETA:Send(instance, players)
	if instance.__instanceIndex then
		--print("NET_FACTORYSEND: " .. instance.__instanceIndex)

		net.Start(self.netstring)
		net.WriteUInt(instance.__instanceIndex, 32)

		if instance.Send then instance:Send() end

		if SERVER then
			if isvector(players) then
				--print("SEND IN PVS")
				net.SendPVS(players)
			else
				if not players then
					--print("SEND BROADCAST")
					net.Broadcast()
				else 
					--print("SEND TO PLAYERS")
					net.Send(players)
				end
			end
		else
			net.SendToServer()
		end
	end
end

function NMETA:Recv(pl)
	local index = net.ReadUInt(32)
	local tab = self.instances[index]
	if tab and tab.Recv then
		--print("NET_FACTORYRECV: " .. index)
		tab:Recv(pl)
	end
end

function NetworkedTableFactory( networkString, base )
	if SERVER then util.AddNetworkString( networkString ) end

	local netObject = setmetatable({}, NMETA)
	netObject:Init(base, networkString)

	if SERVER then
		net.Receive( networkString, function(len, pl)
			netObject:Recv(pl)
		end)
	else
		net.Receive( networkString, function(len)
			netObject:Recv()
		end)
	end

	return netObject
end

function NetworkedRPCFactory( networkString, rpcFunctions )

	local CL_Selector = {}
	local RPC_Table = {}

	table.Inherit(RPC_Table, rpcFunctions)

	CL_Selector.__index = function(self, k)
		local parent = rawget(self, "parent")
		local client = rawget(parent, "__client")
		if type(k) == "string" then return client[k] end 
		if type(k) == "number" then rawset(parent, "__selectorTarget", player.GetAll()[k]) end
		if IsEntity(k) and k:IsPlayer() then rawset(parent, "__selectorTarget", k) end
		if isvector(k) then rawset(parent, "__selectorTarget", k) end
		if type(k) == "table" then rawset(parent, "__selectorTarget", k) end
		return client
	end

	RPC_Table.__index = function(self, k)

		if k == "client" then
			--print("USE SELECTOR")
			rawset(self, "__selectorTarget", nil)
			return rawget(self, "__selector")
		end

		if k == "server" then
			return rawget(self, "__server")
		end

		return rawget(RPC_Table, k)
	end

	function RPC_Table:Init()
		if self.BaseClass.Init then self.BaseClass.Init(self) end

		self.__selectorTarget = nil
		self.__selector = setmetatable({}, CL_Selector)
		self.__selector.parent = self
		self.__server = znet.CreateRPCTable( self, CLIENT, function() self.__factory:Send(self) end )
		self.__client = znet.CreateRPCTable( self, SERVER, function() self.__factory:Send(self, self.__selectorTarget) end )
	end

	function RPC_Table:Send()
		local b,e = pcall(function()
			if SERVER then
				self.__client:Post()
			elseif CLIENT then
				self.__server:Post()
			end
		end)

		if not b then
			ErrorNoHalt(e)
		end
	end

	function RPC_Table:Recv(pl)
		if SERVER then
			self.__client:Receive(pl)
		elseif CLIENT then
			self.__server:Receive()
		end
	end

	return NetworkedTableFactory( networkString, RPC_Table )

end