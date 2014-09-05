function package.inherit(p)
	return function(m) for k,v in pairs(p) do m[k] = v end end
end

--DATA
include("data/data_binary.lua")
include("data/data_base64.lua")
include("data/data_lzw.lua")
include("data/data_stream.lua")
include("data/data_serialize.lua")

AddCSLuaFile("data/data_binary.lua")
AddCSLuaFile("data/data_base64.lua")
AddCSLuaFile("data/data_lzw.lua")
AddCSLuaFile("data/data_stream.lua")
AddCSLuaFile("data/data_serialize.lua")

--NETWORKING
include("network/net_tools.lua")
include("network/net_rpc.lua")
include("network/net_tables.lua")
include("network/net_util.lua")

AddCSLuaFile("network/net_tools.lua")
AddCSLuaFile("network/net_rpc.lua")
AddCSLuaFile("network/net_tables.lua")
AddCSLuaFile("network/net_util.lua")

--MATH
include("math/math_3d.lua")
include("math/math.lua")

AddCSLuaFile("math/math_3d.lua")
AddCSLuaFile("math/math.lua")

--FLOW
include("flow/flow_statemachine.lua")

AddCSLuaFile("flow/flow_statemachine.lua")

--GRAPHICS
if CLIENT then
	include("graphics/graphics_3d.lua")
else
	AddCSLuaFile("graphics/graphics_3d.lua")
end