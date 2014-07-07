--DATA
include("data/data_serialize.lua")

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